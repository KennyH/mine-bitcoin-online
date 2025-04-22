# ADR: 001 - Candidate Block Publishing and Notification

---

**Status:** Proposed / Draft

---

**Context:**

The primary goal of this project is to build a secure, low-cost system for distributing Bitcoin candidate block templates from a private Raspberry Pi node (Pi 5, 8GB RAM, 2TB NVMe SSD) to users mining in browsers via WebAssembly (WASM). Key requirements include real-time notifications, verified solution submissions, protection of the Pi's resources, and cost efficiency with AWS.

Additionally, the system must integrate with distinct `bitcoind` instances on the Pi, supporting `mainnet`, `testnet`, and `regtest`. `Mainnet` allows for potential real block discovery, `testnet` facilitates system testing, and `regtest` provides the ability to create templates for arbitrary-difficulty tasks tailored for browser miners. Users must be able to choose which network's tasks they attempt.

A key security consideration is ensuring miners work on templates that direct the block reward to the pool's address, preventing unauthorized redirection.

---

**Decision:**

We will implement a multi-network architecture using network-specific AWS resources (S3, SQS, IoT topics) and the following process:

1.  **New Block Detection & Local Storage (Raspberry Pi Node):**
    *   Runs and monitors `bitcoind` instances for `mainnet`, `testnet`, and `regtest` (via ZMQ or RPC polling).
    *   When a new block is detected *on any network*, it calls `getblocktemplate` via RPC for the next block height on that specific network.
    *   Extracts and stores *all* necessary template details (including the fixed coinbase transaction structure with the pool payout address, transaction hex, Merkle hashes, extra nonce insertion point, potential work range) into a local encrypted SQLite database, keyed by a `template_identifier` unique per template/network. Records `generation_timestamp`.
    *   Removes local data older than 120 minutes.
    *   Prepares a smaller payload for the cloud, including the essential header fields, potential work range, coinbase structure details, Merkle hashes, `template_identifier`, and the network name.
    *   Obtains temporary AWS credentials via IoT Core Credentials Provider.
    *   Sends the prepared payload to a network-specific trigger service (e.g., publishing to a network-specific IoT topic or calling a network-specific API Gateway endpoint), initiating the cloud process for that network's template. Pi involvement ends here until submission processing.
    *   Security Hygiene: IoT certificates and Role Aliases are documented and managed.

2.  **Cloud Template Processing & Work Distribution (AWS Lambda triggered by Pi):**
    *   A dedicated AWS Lambda function is triggered by the network-specific event from the Pi. The Lambda determines the network from the trigger context/payload.
    *   Uses a fixed `NUM_SQS_MESSAGES_TO_SEND` (e.g., 20) from the potential extra nonce range to create work units (each sized `WORK_UNIT_EXTRA_NONCES`, e.g., 1).
    *   Prepares a `signed_core_template_data_string` including the `template_identifier`, header fields, fixed coinbase structure (including payout address), Merkle hashes, and the network.
    *   Signs this string via KMS (`kms:Sign`), returning signature and Key ID.
    *   Constructs Main Template Object with signed data, signature, Key ID, work unit size, a network-specific SQS Work Queue identifier (URL), and miner data. This object includes the fixed coinbase structure received from the Pi.
    *   Publishes Main Template: Uploads this object to network-specific S3 location (e.g., `s3://<bucket>/<network>/templates/...`). CloudFront serves from these prefixes.
    *   Updates Active Template Reference: Updates a central location (DynamoDB/S3) with the CloudFront URL and SQS Work Queue identifier for this network's active template.
    *   Populates SQS Work Queue: Batch sends messages (identifier, range) to the network-specific SQS Work Queue.
    *   Publishes Notification (Last): Sends a small MQTT notification (via IoT Core) to a network-specific client topic (e.g., `clients/notifications/<network>`) containing the CloudFront URL and SQS Queue identifier. Configured with a DLQ.

3.  **User Login & Notification (AWS Cloud & Browser):**
    *   Users log in, use Cognito Identity Pools for temporary AWS credentials (IoT subscribe, SQS, API Gateway).
    *   Browser connects to AWS IoT Core MQTT and subscribes to the topic for the user's selected network.
    *   Receives notifications specific to the selected network (CloudFront URL, SQS identifier). Miner logic discards current work and fetches the new template upon receiving a *new* notification for the active network.

4.  **Initial Template Retrieval (AWS Cloud & Browser):**
    *   On login/page load, browser calls an API Gateway endpoint, providing the selected network.
    *   Backed by a Lambda, which queries the central location for the currently active template URL and SQS Queue identifier for that network.
    *   Lambda returns this information to the browser.

5.  **Mining & Work Unit Consumption (Browser / WASM & SQS):**
    *   Browser fetches the main template JSON from the network-specific CloudFront URL.
    *   WASM miner uses temporary credentials to interact with the network-specific SQS Work Queue.
    *   Gets work: Calls SQS `ReceiveMessage` on the network's queue, extracts identifier and range, sets message visibility timeout.
    *   Works on the assigned range using template data. The miner's logic uses the provided fixed coinbase transaction template details (including the pool payout address) and only manipulates the `scriptSig` for the `extra_nonce`.
    *   Upon completing the range without solution, sends SQS `DeleteMessage`. Visibility timeout handles miner failure.

6.  **Solution Submission & Initial Verification (Browser -> AWS Lambda -> Submission SQS Queue):**
    *   If miner finds a solution:
        *   Browser generates Submission ID.
        *   Browser sends Submission ID, `template_identifier`, found `main_nonce`, `extra_nonce`, `kms_key_id`, `kms_signature`, `signed_core_template_data_string`, and the network to a secure backend endpoint (API Gateway + Solution Verification Lambda, configured with a DLQ).
        *   Solution Verification Lambda performs validation: `kms:Verify` signature, extract data from verified string. Using the verified fixed coinbase template details (including the pool payout address) and the submitted winning `extra_nonce`, calculates the hash of the coinbase transaction and the Merkle Root. Reconstructs header with verified standard fields, calculated Merkle Root, and submitted `main_nonce`. Calculates the final block hash and checks against the difficulty target. This verification confirms that the submitted solution corresponds to a block using the original fixed coinbase structure and pool payout address.
        *   If validation passes, constructs submission message and places it onto a network-specific Submission SQS Queue. Updates DynamoDB status ("Pending Node Processing").

7.  **Final Assembly & Submission Processing (Raspberry Pi Polling Submission SQS Queue):**
    *   A script on the Pi uses its secure IoT connection to obtain temporary AWS credentials, granting permission to **`sqs:ReceiveMessage`, `sqs:DeleteMessage`** on the Submission SQS Queue and DynamoDB update permissions.
    *   The Pi script polls the network-specific Submission SQS Queue(s) periodically (alternatively explore the possibility to explore an IoT MQTT notification).
    *   When a message is received, the Pi knows the network from the queue (or message content).
    *   Queries its local encrypted SQLite DB using `template_identifier` to retrieve stored full data for that network (including the original full transaction hex and fixed coinbase structure).
        *   If found: Assembles the full block using the submitted `extra_nonce` and `main_nonce` and stored data. Reconstructs the coinbase transaction with the correct `scriptSig` and the **original fixed payout structure**. Calculates the correct Merkle root. Constructs the 80-byte header. Serializes to binary, converts to hex.
        *   If *not* found (cleaned up): Logs error, updates DynamoDB ("Node Data Not Found"), deletes SQS message.
    *   If data found: Calls the correct `bitcoind` instance for the network (`bitcoin-cli -conf=... -datadir=... submitblock <final_block_hex>`).
    *   Captures result, updates DynamoDB status, sends SQS `DeleteMessage`.
    *   *Table Schema Example:* `SubmissionID (PK)`, `UserID`, `Timestamp`, `TemplateIdentifier`, `Network`, `WinningNonce`, `WinningExtraNonce`, `LambdaStatus`, `NodeStatus`, `NodeRejectReason`, `AcceptedBlockHash`.

---

**Specified Formats:**

*   Hashes (previousblockhash, Merkle sibling hashes): Hexadecimal, big-endian.
*   Nonces (extra_nonce, main_nonce): Numeric, unsigned 32-bit integers.
*   Coinbase Structure: Explicit JSON detailing insertion points for extra nonce, including the fixed pool payout `scriptPubKey` in hexadecimal.
*   Template Identifier: String format e.g., `previousblockhash-timestamp-network` (ensuring uniqueness across networks).
*   Core Template Data String: Canonically formatted JSON string including `template_identifier`, header fields, fixed coinbase structure, Merkle hashes, and the network, used for KMS signing.
*   Network: String, one of "mainnet", "testnet", "regtest".

---

**Encryption in Transit Policy:**

*   All communication (Pi <-> AWS, AWS <-> Browser) uses HTTPS/TLS (v1.2 or higher enforced).

---

**AWS Temporary Credentials Lifecycle and Cognito Role Management:**

*   AWS Cognito issues short-lived temporary credentials with minimum permissions (network-specific IoT subscribe, SQS access, specific API Gateway invoke).
*   Credential lifespan: Shortest practical (~1 hour), auto-renewed by clients.
*   Roles/Policies: Configured with IaC (e.g., Terraform), regularly reviewed for least privilege on network-specific resources.

---

**Future Enhancements and Notes:**

*   Single Point of Failure (Pi Node): Lack of redundancy; consider failover.
*   Dynamic SQS Work Unit Allocation: Explore dynamic SQS queue population based on demand/range.
*   Event-Driven Work Distribution (Alternative to Polling): Explore event-driven work assignment (e.g., direct IoT messages) instead of SQS polling by miners.
*   Comprehensive Testing: Crucial for all paths (Merkle, coinbase, verification, security).
*   Miner-Specific Assignment Verification: Implement mechanism to verify miner was assigned submitted extra nonce range.
*   Event-Driven Submission Processing: Explore push models (e.g., IoT messages to Pi) instead of SQS polling for lower latency on submissions.
*   Network-Specific Monitoring & Metrics: Implement per-network tracking of work unit consumption, submissions, and `submitblock` results.
*   Segregated Payouts: Future enhancement to support directing block rewards to user-specific addresses instead of a single pool address.

---

**Consequences:**

*   **Pros:**
    *   Home network secure (outbound from Pi).
    *   Low-latency notifications via network-specific IoT topics for *new main templates*.
    *   Mechanism for late-connecting users per network.
    *   Scalable work distribution via network-specific SQS Work Queues consumed directly by miners, minimizing load on the Pi for individual work assignments.
    *   Pi's core task focused on `bitcoind` interaction and submission processing.
    *   Fixed coinbase payout address enforced through template structure and verification, preventing miner redirection.
    *   Lower AWS costs (small S3/CloudFront objects, less frequent main template pub).
    *   Low IoT Core costs.
    *   KMS signing key secured.
    *   No long-term AWS credentials on Pi, uses IoT Role Alias.
    *   Signed core template data enables backend verification of the template's authenticity without full S3 lookup.
    *   Submission results persisted in DynamoDB (including network).
    *   Uses standard, scalable AWS services.
    *   Secure communication paths (TLS enforced).
    *   Initial validation load on Lambda.
    *   Leverages distributed client compute.
    *   Network-specific SQS Submission Queues decouple Pi processing, provide durability and isolation. DLQs included.
    *   Initial SQS Work Queue costs low (batch send of 20 messages/block per network).
    *   Local encrypted SQLite on Pi performant for recent template data storage.
    *   Improved isolation and independent scalability per network.

*   **Cons:**
    *   Relies on Pi uptime and home connection. Pi submission processing per network is a potential bottleneck.
    *   Increased setup complexity (multiple sets of AWS services per network, Pi scripts manage multiple instances/queues, browser logic handles network selection).
    *   Secure management of Pi's IoT device certificate/key is **critical**.
    *   Coinbase pays to a single pool address currently.
    *   Browser mining has near-zero chance of finding a real block on Mainnet/Testnet.
    *   Increased complexity for WASM miner (handle network selection, fetch template from correct URL, interact with correct SQS queue, template transitions).
    *   Increased complexity in Lambdas/Pi for verification/assembly (using submitted extra nonce, deriving/retrieving details for the correct network, using the fixed coinbase structure).
    *   Pi needs to manage local storage and cleanup per network. Submissions for older templates rejected if data cleaned up.
    *   Slight latency for miner requesting new work unit (network-specific SQS `ReceiveMessage`).
    *   Requires careful network-specific SQS message visibility timeout management.
    *   Fixed SQS message count (20) limits concurrent *initial* work assignment per template update per network. Scaling concurrent work assignment requires adjusting `NUM_SQS_MESSAGES_TO_SEND` and increases SQS costs.
    *   Lack of verification that the submitted `extra_nonce` range was *actually received* by the specific miner from SQS.

---
