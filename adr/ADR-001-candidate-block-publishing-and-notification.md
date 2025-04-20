# ADR: 001 - Candidate Block Publishing and Notification

---

**Status:** Proposed / Draft

---

**Context:**

We need a secure, low-cost method to send Bitcoin candidate block templates from a private Raspberry Pi (Pi 5, 8GB RAM, 2TB NVMe SSD) node to logged-in users who will mine these templates in their browsers using WebAssembly (WASM). The solution must include near real-time notifications, verification of submitted solutions, protect the Pi node's network and credentials, and minimize overall AWS infrastructure costs.

---

**Decision:**

We will use the following process:

1.  **New Block Detection & Data Storage (Raspberry Pi Node):**
    *   Runs `bitcoind` (Mainnet/Testnet) with ZMQ enabled for instant new block detection.
    *   Listens to ZMQ. When a new block is detected, it calls `getblocktemplate` via RPC for the next block height.
    *   **Data Extraction and Local Storage:** It extracts *all* necessary block template details: the full coinbase structure, transaction hex data for all non-coinbase transactions, Merkle sibling hashes needed for the coinbase path, and the actual extra nonce insertion point within the `scriptSig`. It defines a **potential Work Block range** of extra nonces from the `getblocktemplate` output that the cloud system will use as the basis for work units.
    *   It **stores the full transaction hex data, the full coinbase template details, Merkle sibling hashes, and the extra nonce insertion point** from the `getblocktemplate` output into a local encrypted SQLite database using SQLCipher, using a generated `template_identifier` as the primary key. It also records a `generation_timestamp`. This storage happens *before* triggering the Lambda, ensuring the data is locally available when needed for submission processing.
    *   **Local Cleanup:** After storing new data, it removes entries older than 120 minutes (based on `generation_timestamp`) from the SQLite database.
    *   **Payload Preparation:** It prepares a smaller payload for the cloud, containing the essential, non-bulky data: the `template_identifier`, standard header fields (version, previousblockhash, curtime, bits), the *potential* Work Block range (start and end extra nonce values), the **relevant coinbase template structure information** required to insert an extra nonce and re-calculate the coinbase hash (as defined in the 'Specified Formats' section below), and the calculated **Merkle sibling hashes**.
    *   Obtains temporary AWS credentials using the **AWS IoT Core Credentials Provider (via a Role Alias)**. The associated IAM role grants permission to trigger a specific Lambda function (e.g., via publishing to an SNS topic or calling API Gateway).
    *   Sends the prepared payload (excluding the bulky transaction hex data) to the trigger service (e.g., API Gateway), initiating the cloud process. The Pi's direct involvement ends here until submission processing.
    *   **Security Hygiene:** IoT certificates and Role Aliases will be clearly documented and managed through automated provisioning and renewal processes.

2.  **Template Processing, SQS Work Queue Population & Main Template Publication (AWS Lambda triggered by Pi):**
    *   A **dedicated AWS Lambda function** is triggered by the Pi's notification payload.
    *   The Lambda receives the template data from the Pi (identifier, standard header fields, potential Work Block range, relevant coinbase template structure, Merkle sibling hashes). **This Lambda will use the first `NUM_SQS_MESSAGES_TO_SEND` extra nonces from the potential Work Block range to generate work units.**
    *   The Lambda performs the following operations, with robust error handling (acknowledging full atomicity is challenging; Step Functions are a future enhancement). This Lambda is configured with a **Dead Letter Queue (DLQ)**.
        *   **Define Work Unit Granularity:** Uses `WORK_UNIT_EXTRA_NONCES = 1`.
        *   **Define Initial Work Units:** Uses `NUM_SQS_MESSAGES_TO_SEND = 20` (adjustable).
        *   **Generate Sub-Ranges:** Divides the *first `NUM_SQS_MESSAGES_TO_SEND`* extra nonces from the potential range into sequential sub-ranges of size 1.
        *   **Prepare Signed Core Template Data String:** Constructs a standardized string representation of the *core template data* (template identifier, standard header fields, coinbase template structure details, Merkle sibling hashes). The format of this string must be strictly defined and immutable to ensure consistent signing and verification.
        *   **Sign Core Template Data (via KMS):** Calls `kms:Sign` using its role. Returns signature and KMS Key ID.
        *   **Construct Main Template Object:** Creates a JSON object with: `signed_core_template_data_string`, `kms_signature`, `kms_key_id`, `work_unit_size`, SQS Work Queue identifier (URL), and the structured data for the miner (standard header fields, parsed coinbase template details, Merkle sibling hashes).
        *   **Publish Main Template (S3 First):** Uploads this JSON to AWS S3 using a unique, versioned name.
        *   **Update Active Template Reference:** Updates a central location (DynamoDB/S3) with the CloudFront URL and SQS Queue identifier for this template.
        *   **Populate SQS Work Queue:** For each generated sub-range (up to 20 messages), constructs a message (`template_identifier`, `[start_extra_nonce, end_extra_nonce]`) and **batch sends these to the dedicated SQS Work Queue**.
        *   **Publish CloudFront Notification (Last):** Sends a small MQTT notification (via IoT Core) to the client topic containing the CloudFront URL and SQS Queue identifier.

3.  **User Login & Notification (AWS Cloud & Browser):**
    *   Users log into the website and use Cognito Identity Pools to get temporary AWS credentials for IoT Core and **SQS Work Queue access**.
    *   Browser connects to AWS IoT Core MQTT and subscribes.
    *   Receives notification (CloudFront URL, SQS Queue identifier). Upon receiving a *new* notification, miner logic discards current work and fetches the new template.

4.  **Initial Template Retrieval (AWS Cloud & Browser):**
    *   On login/page load, browser calls an API Gateway endpoint.
    *   Backed by a **dedicated AWS Lambda**, which queries the central location (updated in Step 2) for the *currently active* template's CloudFront URL and SQS Queue identifier.
    *   Lambda returns this information to the browser.

5.  **Mining & Work Unit Consumption (Browser / WASM & SQS):**
    *   Browser fetches the main template JSON from CloudFront URL.
    *   Browser/WASM miner uses temporary AWS credentials to interact with the **SQS Work Queue**.
    *   To get work: Calls SQS `ReceiveMessage`, extracts template identifier and assigned `[start_extra_nonce, end_extra_nonce]` (size 1), sets message visibility timeout.
    *   Miner works on the assigned `extra_nonce` using data from the main template, iterating the main nonce.
    *   Upon completing the assigned extra nonce range without finding a solution, sends SQS `DeleteMessage` for the message.
    *   If miner crashes/closes, visibility timeout expires, making the range available.

6.  **Solution Submission & Initial Verification (Browser -> AWS Lambda -> Submission SQS Queue):**
    *   If WASM miner finds a solution (`main_nonce` for its `extra_nonce`):
        *   Browser generates Submission ID.
        *   Browser sends Submission ID, `template_identifier`, found `main_nonce`, `extra_nonce`, `kms_key_id`, `kms_signature`, and `signed_core_template_data_string` to a secure backend endpoint (API Gateway + **Solution Verification Lambda**, configured with a DLQ).
        *   Solution Verification Lambda performs initial validation:
            *   Retrieves User ID from Cognito.
            *   Calls `kms:Verify` (fails if signature/data mismatch).
            *   Using *verified* `signed_core_template_data_string`, extracts necessary details.
            *   Using verified data and *submitted* `extra_nonce`, calculates coinbase hash and Merkle Root.
            *   Reconstructs header using verified standard fields, calculated Merkle Root, and submitted `main_nonce`.
            *   Calculates final block hash and checks against difficulty (fails if invalid).
            *   **(Optional/Future) Range Verification:** (Acknowledged as missing in current v1).
        *   If all validation passes, constructs a submission message and places it onto a **Submission SQS Queue**. Updates DynamoDB with "Pending Node Processing" status.

7.  **Final Assembly & Submission Processing (Raspberry Pi Polling Submission SQS Queue):**
    *   A script on the **Raspberry Pi** uses its secure IoT connection to get temporary AWS credentials for SQS (`ReceiveMessage`, `DeleteMessage`) and DynamoDB.
    *   Pi script **polls the Submission SQS Queue** periodically.
    *   When a message is received, extracts submission details.
    *   Queries its **local encrypted SQLite database** using `template_identifier` to retrieve stored full data.
        *   If found: Proceeds with assembly.
        *   If *not* found (cleaned up after 120 min): Logs error, updates DynamoDB to "Node Data Not Found", deletes SQS message.
    *   If data found: **Assembles the full block** (transaction hex, reconstructed coinbase with submitted `extra_nonce`, calculated Merkle root, header with winning `main_nonce`). Serializes to binary block format.
    *   Converts binary block to hex.
    *   Calls local `bitcoind` **`submitblock <final_block_hex>` RPC command**.
    *   Captures result from `submitblock`.
    *   Updates DynamoDB item with final status.
    *   Sends SQS `DeleteMessage` for the processed submission.
    *   *Table Schema Example:* `SubmissionID (PK)`, `UserID`, `Timestamp`, `TemplateIdentifier`, `WinningNonce`, `WinningExtraNonce`, `LambdaStatus`, `NodeStatus`, `NodeRejectReason`, `AcceptedBlockHash`.

---

**Specified Formats:**

*   Hashes (previousblockhash, Merkle sibling hashes): Hexadecimal, big-endian format.
*   Nonces (extra_nonce, main_nonce): Numeric, unsigned 32-bit integers.
*   Coinbase Structure: Explicit JSON detailing insertion points clearly, including the extra nonce placeholder.
*   Template Identifier: String format e.g., `previousblockhash-timestamp` (ensuring uniqueness).
*   Core Template Data String: Canonically formatted JSON string (exact key order, spacing, etc., strictly defined and documented).

---

**Encryption in Transit Policy:**

*   All communication between Raspberry Pi, AWS services (API Gateway, IoT Core, SQS, KMS, S3, DynamoDB), and user browsers occurs exclusively over HTTPS/TLS.
*   AWS SDKs and browser APIs must enforce TLS v1.2 or higher.

---

**AWS Temporary Credentials Lifecycle and Cognito Role Management:**

*   AWS Cognito will issue short-lived temporary credentials with minimum necessary permissions (IoT subscribe, SQS access, specific API Gateway invoke).
*   Credential lifespan configured to shortest practical duration (~1 hour).
*   Renewal upon expiry handled automatically by client browsers (e.g., via AWS Amplify).
*   Cognito roles and IAM policies are configured using Infrastructure as Code (e.g., Terraform) and regularly reviewed to ensure least privilege.

---

**Future Enhancements and Notes:**

*   **Single Point of Failure (Pi Node):** Current design has no redundancy; future work may consider secondary nodes or cloud-hosted failover.
*   **Dynamic SQS Work Unit Allocation:** Instead of a fixed 20 messages, explore dynamically populating the SQS queue based on miner demand or the full potential range.
*   **Event-Driven Work Distribution (Alternative to Polling):** Future enhancements could explore event-driven models for work assignment (e.g., AWS IoT direct message driven).
*   **Comprehensive Testing:** Critical Merkle path calculations, coinbase assembly, submission verification, and security protocols must undergo thorough unit and integration testing.
*   **Miner-Specific Assignment Verification:** Implement a mechanism (e.g., including SQS message ID or a derived value in submission) to verify the miner was assigned the submitted extra nonce. (Acknowledged as a missing feature in v1).

---

**Consequences:**

*   **Pros:**
    *   Home network remains secure (only outbound from Pi).
    *   Low-latency notifications via IoT Core for *new main templates*.
    *   Mechanism for late-connecting users.
    *   **Highly scalable work distribution via SQS Work Queue consumption** by miners, offloading Pi.
    *   **Pi focused on `bitcoind`, local data, and submission processing.**
    *   Lower AWS costs (smaller S3/CloudFront objects, less frequent pub).
    *   Low IoT Core costs.
    *   **KMS signing key secured.**
    *   **No long-term AWS credentials on Pi**, uses IoT Role Alias.
    *   Signed core template data enables backend verification without full S3 object lookup on submission.
    *   Submission results persisted in DynamoDB.
    *   Uses standard, scalable AWS services.
    *   Secure communication paths (TLS enforced).
    *   Initial validation load on Lambda.
    *   **Leverages distributed client compute.**
    *   **SQS Submission Queue decouples Pi processing**, provides durability. DLQs added.
    *   **Initial SQS Work Queue costs low** (20 messages/block).
    *   **Local encrypted SQLite on Pi** provides performant storage for assembly data for recent templates.

*   **Cons:**
    *   Relies on Pi uptime and home connection. Pi submission processing is a potential bottleneck.
    *   Increased setup complexity (multiple AWS services, Pi scripts, local DB).
    *   Secure management of Pi's **IoT device certificate/key is critical**.
    *   Coinbase pays to a single pool address.
    *   Browser mining has near-zero chance of finding a real block.
    *   **Increased complexity for WASM miner** (fetch template, SQS interaction, mining logic, template transitions).
    *   **Increased complexity in Lambdas/Pi for verification/assembly** (using submitted extra nonce, deriving/retrieving details).
    *   Pi needs to manage storage and cleanup (120 min window). Submissions for older templates rejected ("Node Data Not Found").
    *   Slight latency for miner requesting new work unit (SQS `ReceiveMessage`).
    *   Requires careful SQS message visibility timeout management.
    *   Fixed 20 SQS messages limit concurrent work per template update. Scaling requires manual adjustment and increases SQS costs.
    *   Lack of validation that the submitted `extra_nonce` was assigned to the specific miner. (Acknowledged as future enhancement).

---
