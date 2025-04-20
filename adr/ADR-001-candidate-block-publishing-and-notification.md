# ADR: 001 - Candidate Block Publishing and Notification

---

**Status:** Proposed / Draft

---

**Context:**

We need a way to send Bitcoin candidate block templates from a private Raspberry Pi (Pi 5, 8GB RAM, 2TB NVMe SSD) node to logged-in users on our website. Users will mine these templates in their browser using WebAssembly (WASM). We need near real-time notifications when a new template is ready. We also need a way to check if a user claiming to have found a solution actually worked on the template we provided, and inform the user of the outcome. The system should be low-cost, must not expose the home network hosting the Pi node, and must avoid storing long-term AWS credentials or signing private keys on the Pi. To minimize AWS infrastructure costs and offload potential Pi bottlenecks for work assignment, template details will be published less frequently, and work unit distribution within those templates will be managed via an SQS queue consumed directly by miners.

---

**Decision:**

We will use the following process:

1.  **New Block Detection & Lambda Trigger (Raspberry Pi):**
    *   The Pi node runs `bitcoind` (Mainnet/Testnet) with ZMQ enabled for instant new block detection.
    *   A script on the Pi listens to ZMQ. When a new block is detected, it calls `getblocktemplate` via RPC for the next block height.
    *   The script extracts necessary standard block header data (version, previousblockhash, curtime, bits).
    *   The script extracts the **full coinbase transaction template details** (including indication of where the extra nonce should be inserted within the `scriptSig`) and the **full hex data for all non-coinbase transactions** from the `getblocktemplate` output.
    *   The script calculates the **Merkle tree** based on the extracted transaction hashes and identifies the specific ordered list of ** Merkle sibling hashes** required to reconstruct the Merkle root path from the coinbase transaction's position upwards.
    *   It defines a **potential Work Block range** of extra nonces from the `getblocktemplate` output that the cloud system *could* use as the basis for work units.
    *   **Coinbase Address:** The coinbase transaction template will pay out to a single address controlled by the Pi node's wallet (the "pool address").
    *   The script prepares a payload containing: the template identifier (e.g., previous block hash + a timestamp or sequence number), standard header fields (version, previousblockhash, curtime, bits), the *potential* Work Block range (start and end extra nonce values), the **relevant coinbase template structure information** (specifically, the parts of the coinbase transaction template required to insert an extra nonce and re-calculate the coinbase hash, including the scriptSig placeholder details), and the calculated ** Merkle sibling hashes**. This payload contains the essential, non-bulky data the cloud needs to define and sign the core template.
    *   **Local Data Storage:** The script **stores the full transaction hex data, the full coinbase template details, Merkle sibling hashes, and the *actual* extra nonce insertion point** from the `getblocktemplate` output into a **local SQLite database**, using the generated `template_identifier` as the primary key. It also records a `generation_timestamp`. This storage happens *before* triggering the Lambda, ensuring the data is locally available when needed for submission processing.
    *   **Local Cleanup:** After storing the new template data, the script runs a cleanup command on the SQLite database to remove entries older than 120 minutes (based on `generation_timestamp`).
    *   The script obtains temporary AWS credentials using the **AWS IoT Core Credentials Provider (via a Role Alias)**. The associated IAM role grants permission to trigger a specific Lambda function (e.g., via publishing to an SNS topic or calling API Gateway).
    *   The script sends the prepared payload (excluding the bulky transaction hex data) to the trigger service (e.g., API Gateway), initiating the cloud-based template and queue management process. The Pi's direct involvement with AWS for this block template ends here until submission processing.

2.  **Template Processing, SQS Work Queue Population & Main Template Publication (AWS Lambda triggered by Pi):**
    *   A **dedicated AWS Lambda function** is triggered by the Pi's notification payload.
    *   The Lambda receives the template data from the Pi (identifier, standard header fields, potential Work Block range, relevant coinbase template structure, Merkle sibling hashes).
    *   The Lambda performs the following operations, with robust error handling and retry logic in case of failure (acknowledging full atomicity across SQS, S3, IoT is challenging; a future enhancement could use AWS Step Functions). This Lambda should be configured with a **Dead Letter Queue (DLQ)** to capture messages that fail processing repeatedly.
        *   **Define Work Unit Granularity:** It uses a configuration parameter (`WORK_UNIT_EXTRA_NONCES = 1`) defining that each SQS message will assign a range of 1 extra nonce value.
        *   **Define Number of Work Units to Send:** It uses a configuration parameter (`NUM_SQS_MESSAGES_TO_SEND = 20`) to determine how many work units to generate from the *beginning* of the potential Work Block range. This is a hardcoded initial limit for cost control, assuming few initial miners. This parameter will be manually adjusted as miner count increases.
        *   **Generate Sub-Ranges:** It divides the *first `NUM_SQS_MESSAGES_TO_SEND`* extra nonces from the potential Work Block range into individual sequential sub-ranges of size `WORK_UNIT_EXTRA_NONCES`.
        *   **Prepare Signed Core Template Data String:** It constructs a standardized string representation of the *core template data* necessary for miner work and backend verification. This string will include the template identifier, standard header fields, the relevant coinbase template structure details, and the Merkle sibling hashes (all received in the payload from the Pi). The format of this string must be strictly defined and immutable.
        *   **Sign Core Template Data (via KMS):** It calls the **`kms:Sign` API** using its execution role to sign this standardized core template data string. The signature and KMS Key ID are returned.
        *   **Construct Main Template Object:** It constructs the main Work Block template JSON object containing:
            *   The `signed_core_template_data_string`
            *   The `kms_signature`
            *   The `kms_key_id`
            *   A definition of the Work Unit granularity (e.g., `work_unit_size: 1` extra nonce)
            *   The identifier for the SQS Work Queue (e.g., URL)
            *   The **structured data required by the miner to perform calculations**: This includes the standard header fields (version, previousblockhash, curtime, bits), the parsed coinbase template details (especially the components around the extra nonce insertion point), and the ordered list of Merkle sibling hashes. This is derived from the data received from the Pi and is the primary content the miner uses.
        *   **Publish Main Template (S3 First):** It uses the AWS SDK to upload this JSON to AWS S3 using a unique, versioned name based on the template identifier.
        *   **Update Active Template Reference:** The Lambda updates a central location (e.g., a specific DynamoDB item or S3 object) with the CloudFront URL and SQS Queue identifier for this newly published template. This allows late-connecting clients to discover the current work.
        *   **Populate SQS Work Queue:** For each generated sub-range (up to 20 messages initially), it constructs a message containing the template identifier and its assigned `[start_extra_nonce, end_extra_nonce]` sub-range boundaries (where `start_extra_nonce` and `end_extra_nonce` are the same value since the range size is 1). It uses the AWS SDK to **batch send these messages to the dedicated SQS Work Queue**. Messages are implicitly separated by their `template_identifier`.
        *   **Publish CloudFront Notification (Last):** It sends a small MQTT notification (via IoT Core) to the client topic containing the CloudFront URL for the newly uploaded main Work Block template JSON and the SQS Work Queue identifier (ARN/URL).

3.  **User Login & Notification (AWS Cloud & Browser):**
    *   Users log into the website and use Cognito Identity Pools to get temporary AWS credentials, granting permissions for IoT Core and **SQS Work Queue access**.
    *   The browser connects to AWS IoT Core MQTT and subscribes to the notification topic.
    *   When AWS IoT Core pushes the notification message containing the CloudFront URL for a new main Work Block template and the SQS Queue identifier, the browser receives it. Upon receiving a *new* notification, the miner logic should discard its current work unit (or allow the visibility timeout to expire) and fetch the new template. (Note: Detailed miner behavior on template updates is out of scope for this ADR).

4.  **Initial Template Retrieval (AWS Cloud & Browser):**
    *   When a user logs into the website or the page loads/refless, the browser makes a single API call to a dedicated endpoint (e.g., via API Gateway).
    *   This endpoint is backed by a **dedicated AWS Lambda function**.
    *   This Lambda function queries the central location (updated in Step 2) to retrieve the CloudFront URL and SQS Work Queue identifier for the *currently active* block template.
    *   The Lambda returns this information to the browser. This ensures users who connect after the initial IoT push notification receive the necessary details to start mining immediately on the latest available template.

5.  **Mining & Work Unit Consumption (Browser / WASM & SQS):**
    *   The browser fetches the main Work Block template JSON from the CloudFront URL.
    *   The browser/WASM miner uses its temporary AWS credentials to interact with the **SQS Work Queue identified in the main template**.
    *   When the miner needs a work assignment:
        *   It calls SQS `ReceiveMessage` on the specified Work Queue.
        *   When a message is received, the miner extracts the template identifier and its assigned `[start_extra_nonce, end_extra_nonce]` sub-range from the message.
        *   It sets the message's visibility timeout to prevent other miners from receiving the same range.
        *   The miner then works on the assigned `extra_nonce` (or single value since range size is 1) using the data from the main Work Block template (standard fields, coinbase template structure, Merkle sibling hashes, etc.). It iterates the main nonce (0 to \(2^{32}-1\)) for the assigned extra nonce value.
    *   When the miner successfully completes its assigned sub-range (i.e., iterates all main nonces for its assigned extra nonce without finding a solution), it sends an SQS `DeleteMessage` request for the corresponding message.
    *   If a miner crashes or closes, the message's visibility timeout will expire, making the range available for another miner.

6.  **Solution Submission & Initial Verification (Browser -> AWS Lambda -> Submission SQS Queue):**
    *   If the WASM miner finds a nonce solution within its assigned SQS range:
        *   The browser generates a unique Submission ID.
        *   The browser sends the Submission ID, the **template identifier**, the **found `main_nonce`**, the **`extra_nonce` that resulted in the solution**, the **`kms_key_id`**, the **`kms_signature`**, and the **`signed_core_template_data_string`** it received in the main template JSON to a secure backend endpoint (API Gateway + **Solution Verification Lambda**). This Lambda should be configured with a **Dead Letter Queue (DLQ)** for failed submissions.
        *   The Solution Verification Lambda performs initial validation:
            *   Retrieves User ID from Cognito context.
            *   Calls **`kms:Verify`** using the submitted `kms_key_id`, `kms_signature`, and `signed_core_template_data_string`. If verification fails, record rejection (in DynamoDB) and stop.
            *   Using the **verified `signed_core_template_data_string`**, it extracts the coinbase template structure, Merkle sibling hashes, and standard header fields.
            *   Using the verified core template data and the *submitted winning `extra_nonce`*, calculates the hash of the coinbase transaction and the Merkle Root.
            *   Reconstructs the block header components using verified standard fields, the calculated Merkle Root, and the submitted `main_nonce`.
            *   Calculates the final block hash and checks against the difficulty target. If invalid, record rejection (in DynamoDB) and stop.
            *   **(Optional/Future) Range Verification:** Could potentially verify that the submitted `extra_nonce` falls within the original potential Work Block range specified in the signed main template. For now, basic validity against the main template is sufficient.
        *   If all validation passes, the Lambda constructs a submission message (Submission ID, user ID, winning nonces, template identifier, etc.) and places it onto a **Submission SQS Queue**. It updates DynamoDB with a "Pending Node Processing" status for the Submission ID.

7.  **Final Assembly & Submission Processing (Raspberry Pi Polling Submission SQS Queue):**
    *   A script on the **Raspberry Pi** uses its secure IoT connection to obtain temporary AWS credentials, granting permission to **`sqs:ReceiveMessage`, `sqs:DeleteMessage`** on the Submission SQS Queue and DynamoDB update permissions.
    *   The Pi script **polls the Submission SQS Queue** periodically for new messages.
    *   When a submission message is received, the Pi extracts the submission details (Submission ID, `template_identifier`, winning nonces).
    *   The Pi queries its **local SQLite database** using the `template_identifier` to retrieve the stored **full original transaction hex data**, coinbase template details, and Merkle sibling hashes corresponding to that template.
        *   If data is found: Proceeds with assembly.
        *   If data is *not* found (because it was cleaned up after 120 minutes): Logs an error, updates the DynamoDB item with a "Node Data Not Found" status, and deletes the SQS message for this submission. This indicates the submission was too old to process locally.
    *   If data is found: It **assembles the full block**: uses the retrieved transaction hex, reconstructs the coinbase transaction *using the submitted winning `extra_nonce` and the stored coinbase template details*, calculates the coinbase txid and Merkle root (using stored sibling hashes). Constructs the 80-byte header using original stored verified components (from the signed data, likely stored in SQLite as well or derivable), calculated Merkle root, and the winning `main_nonce`. Serializes to binary block format.
    *   It converts the binary block to hex.
    *   The Pi script calls the local `bitcoind` **`submitblock <final_block_hex>` RPC command**.
    *   The Pi script captures the result from `submitblock`.
    *   Using temporary credentials, it updates the DynamoDB table item for the Submission ID with the final status from `submitblock`.
    *   The Pi script sends an SQS `DeleteMessage` for the processed submission message.
    *   *Table Schema Example:* `SubmissionID (PK)`, `UserID`, `Timestamp`, `TemplateIdentifier`, `WinningNonce`, `WinningExtraNonce`, `LambdaStatus`, `NodeStatus`, `NodeRejectReason`, `AcceptedBlockHash`.

---

**Consequences:**

*   **Pros:**
    *   Home network remains secure (only outbound connections from Pi).
    *   Low-latency notifications via IoT Core push for *new main templates*.
    *   Mechanism for late-connecting users to get the current template.
    *   **Highly scalable work distribution via SQS Work Queue consumption** by miners, minimizing load on the Pi for individual work assignments.
    *   **Pi's core task is focused on `bitcoind` interaction, local data management (SQLite), and submission processing**, offloading template/queue management to Lambda.
    *   **Significantly lower AWS costs for S3 and CloudFront** due to much smaller main template JSON size and less frequent main template publication.
    *   Low costs for IoT Core.
    *   **KMS signing key secured within AWS KMS**.
    *   **No long-term AWS credentials stored on the Pi**, uses secure IoT Role Alias mechanism.
    *   Signed core template data allows backend verification of the template's authenticity without relying on the full, potentially large, S3 object in the submission payload.
    *   Submission results persisted in DynamoDB.
    *   Uses standard, scalable AWS services.
    *   Secure communication paths.
    *   Initial validation load on Lambda.
    *   **Leverages distributed client compute for full mining work.**
    *   **SQS Submission Queue decouples submission processing from the Lambda verification**, allowing the Pi to process them at its own pace and providing durability. Dead Letter Queues added for robustness in Lambdas.
    *   **Initial SQS Work Queue costs are negligible** by sending a small, hardcoded number of messages (20) per block template update, keeping usage within the free tier for initial development/low usage.
    *   **Local SQLite database on the Pi** provides performant and reliable storage for the full template data needed for final assembly, handling submissions for recent (up to 120 min old) templates. Extended cleanup window (120 min) reduces, but does not eliminate, the risk of submissions failing due to expired local data.
*   **Cons:**
    *   System relies on the Pi node's uptime and home internet connection for `bitcoind` and final submission. The Pi's submission processing capacity could become a bottleneck under very high submission rates.
    *   Increased setup complexity (Pi scripts, local SQLite, multiple Lambda functions/roles, SQS queues/permissions, API Gateway, Cognito, IoT policies/Role Alias, S3/CloudFront, KMS, DynamoDB).
    *   Securely managing the **IoT device certificate/key** on the Pi is critical.
    *   Coinbase pays to a pool address, requiring manual/separate payout.
    *   Browser mining has a near-zero chance of finding a real block.
    *   **Increased complexity for the WASM miner** (must fetch main template, interact directly with SQS for work units, implement mining logic, handle template transitions).
    *   **Increased complexity in Lambdas and Pi verification/assembly** (must use submitted extra nonce, derive/retrieve Merkle sibling hashes and coinbase structure from signed data/local storage).
    *   The Pi needs to manage storage and cleanup (120 min window) of transaction data in its local SQLite database. Submissions arriving after the 120-minute window for the template will be rejected by the Pi due to missing local data ("Node Data Not Found").
    *   Adds slight latency for a miner requesting a new work unit (SQS `ReceiveMessage` call).
    *   Requires careful management of SQS message visibility timeouts to prevent work from being lost if a miner fails mid-range.
    *   The fixed number of SQS messages (20) is an initial limit; scaling up to handle more concurrent miners will require adjusting this configuration, potentially increasing SQS costs proportionally. This limits the total immediate work available from a single block template update.
    *   Lack of validation that the submitted `extra_nonce` was actually assigned to the miner's specific work unit (optional/future).

---
