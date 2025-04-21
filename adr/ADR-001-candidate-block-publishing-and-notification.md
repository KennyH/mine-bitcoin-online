# ADR: 001 - Candidate Block Publishing and Notification

---

**Status:** Proposed / Draft

---

**Context:**

The primary goal of this project is to build a secure, low-cost system for distributing Bitcoin candidate block templates from a private Raspberry Pi node (Pi 5, 8GB RAM, 2TB NVMe SSD) to users mining in browsers via WebAssembly (WASM). Key requirements include real-time notifications, verified solution submissions, protection of the Pi's resources, and cost efficiency with AWS.

Additionally, the system must integrate with distinct `bitcoind` instances on the Pi, supporting `mainnet`, `testnet`, and `regtest`. `Mainnet` allows for potential real block discovery, `testnet` facilitates system testing, and `regtest` provides the ability to create templates for arbitrary-difficulty tasks tailored for browser miners. Users must be able to choose which network's tasks they attempt.

---

**Decision:**

We will implement a multi-network architecture using network-specific AWS resources (S3, SQS, IoT topics) and the following process:

1.  **New Block Detection & Local Storage (Raspberry Pi Node):**
    *   Runs and monitors `bitcoind` instances for `mainnet`, `testnet`, and `regtest` (via ZMQ or RPC polling).
    *   When a new block is detected *on any network*, it calls `getblocktemplate` via RPC for the next block height on that specific network.
    *   Extracts and stores *all* necessary template details (coinbase, transaction hex, Merkle hashes, extra nonce insertion, potential work range) into a local encrypted SQLite database, keyed by a `template_identifier` unique per template/network. Records `generation_timestamp`.
    *   Removes local data older than 120 minutes.
    *   Prepares a smaller payload for the cloud, including the essential header fields, potential work range, coinbase structure details, Merkle hashes, `template_identifier`, and the network name.
    *   Obtains temporary AWS credentials via IoT Core Credentials Provider.
    *   Sends the prepared payload to a network-specific trigger service (e.g., publishing to a network-specific IoT topic or calling a network-specific API Gateway endpoint), initiating the cloud process for that network's template. Pi involvement ends here until submission processing.
    *   Security Hygiene: IoT certificates and Role Aliases are documented and managed.

2.  **Cloud Template Processing & Work Distribution (AWS Lambda triggered by Pi):**
    *   A dedicated AWS Lambda function is triggered by the network-specific event from the Pi. The Lambda determines the network from the trigger context/payload.
    *   Uses a fixed `NUM_SQS_MESSAGES_TO_SEND` (e.g., 20) from the potential extra nonce range to create work units (each sized `WORK_UNIT_EXTRA_NONCES`, e.g., 1).
    *   Prepares a `signed_core_template_data_string` including the `template_identifier`, header fields, coinbase details, Merkle hashes, and the network.
    *   Signs this string via KMS (`kms:Sign`), returning signature and Key ID.
    *   Constructs Main Template Object with signed data, signature, Key ID, work unit size, a network-specific SQS Work Queue identifier (URL), and miner data.
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
    *   Works on the assigned range using template data.
    *   Upon completing the range without solution, sends SQS `DeleteMessage`. Visibility timeout handles miner failure.

6.  **Solution Submission & Initial Verification (Browser -> AWS Lambda -> Submission SQS Queue):**
    *   If miner finds a solution:
        *   Browser generates Submission ID.
        *   Browser sends Submission ID, `template_identifier`, found `main_nonce`, `extra_nonce`, `kms_key_id`, `kms_signature`, `signed_core_template_data_string`, and the network to a secure backend endpoint (API Gateway + Solution Verification Lambda, configured with a DLQ).
        *   Solution Verification Lambda performs validation: `kms:Verify` signature, extract data from verified string, calculate coinbase/Merkle Root using submitted `extra_nonce`, reconstruct header with submitted `main_nonce`, check hash against difficulty.
        *   If validation passes, constructs submission message and places it onto a network-specific Submission SQS Queue. Updates DynamoDB status ("Pending Node Processing").

7.  **Final Assembly & Submission Processing (Raspberry Pi Polling Submission SQS Queue):**
    *   A script on the Pi uses IoT connection for SQS/DynamoDB credentials.
    *   Pi script polls the network-specific Submission SQS Queue(s) periodically.
    *   When a message is received, the Pi knows the network from the queue (or message content).
    *   Queries its local encrypted SQLite DB using `template_identifier` to retrieve stored full data for that network.
        *   If found: Assembles the full block using the submitted `extra_nonce` and `main_nonce` and stored data. Serializes to binary, converts to hex.
        *   If *not* found (cleaned up): Logs error, updates DynamoDB ("Node Data Not Found"), deletes SQS message.
    *   If data found: Calls the correct `bitcoind` instance for the network (`bitcoin-cli -conf=... -datadir=... submitblock <final_block_hex>`).
    *   Captures result, updates DynamoDB status, sends SQS `DeleteMessage`.
    *   *Table Schema Example:* `SubmissionID (PK)`, `UserID`, `Timestamp`, `TemplateIdentifier`, `Network`, `WinningNonce`, `WinningExtraNonce`, `LambdaStatus`, `NodeStatus`, `NodeRejectReason`, `AcceptedBlockHash`.

---

**Specified Formats:**

*   Hashes (previousblockhash, Merkle sibling hashes): Hexadecimal, big-endian.
*   Nonces (extra_nonce, main_nonce): Numeric, unsigned 32-bit integers.
*   Coinbase Structure: Explicit JSON detailing insertion points, including extra nonce placeholder.
*   Template Identifier: String format e.g., `previousblockhash-timestamp-network` (ensuring uniqueness across networks).
*   Core Template Data String: Canonically formatted JSON string including `template_identifier`, header fields, coinbase details, Merkle hashes, and the network.
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
*   Event-Driven Work Distribution (Alternative to Polling): Explore event-driven work assignment (e.g., direct IoT messages).
*   Comprehensive Testing: Crucial for all paths (Merkle, coinbase, verification, security).
*   Miner-Specific Assignment Verification: Implement mechanism to verify miner was assigned submitted extra nonce.
*   Event-Driven Submission Processing: Explore push models (e.g., IoT messages to Pi) instead of SQS polling for lower latency.
*   Network-Specific Monitoring & Metrics: Implement per-network tracking of work unit consumption, submissions, and `submitblock` results.

---

**Consequences:**

*   **Pros:**
    *   Home network secure (outbound from Pi).
    *   Low-latency notifications via network-specific IoT topics.
    *   Mechanism for late-connecting users per network.
    *   Scalable work distribution via network-specific SQS Work Queues, offloading Pi.
    *   Pi focused on `bitcoind`, local data, submission processing per network.
    *   Lower AWS costs (small S3/CloudFront objects, less frequent pub).
    *   Low IoT Core costs.
    *   KMS signing key secured.
    *   No long-term AWS credentials on Pi, uses IoT Role Alias.
    *   Signed core template data enables backend verification without full S3 lookup.
    *   Submission results persisted in DynamoDB (including network).
    *   Uses standard, scalable AWS services.
    *   Secure communication paths (TLS enforced).
    *   Initial validation load on Lambda.
    *   Leverages distributed client compute.
    *   Network-specific SQS Submission Queues decouple Pi processing, provide durability and isolation. DLQs included.
    *   Initial SQS Work Queue costs low (20 messages/block per network).
    *   Local encrypted SQLite on Pi performant for recent template data storage.
    *   Improved isolation and independent scalability per network.

*   **Cons:**
    *   Relies on Pi uptime and home connection. Pi submission processing per network is a potential bottleneck.
    *   Increased setup complexity (multiple sets of AWS services per network, Pi scripts manage multiple instances/queues, browser logic handles network selection).
    *   Secure management of Pi's IoT device certificate/key is **critical**.
    *   Coinbase pays to a single pool address.
    *   Browser mining has near-zero chance of finding a real block on Mainnet/Testnet.
    *   Increased complexity for WASM miner (handle network selection, fetch template from correct URL, interact with correct SQS queue, template transitions).
    *   Increased complexity in Lambdas/Pi for verification/assembly (using submitted extra nonce, deriving/retrieving details for the correct network).
    *   Pi needs to manage storage and cleanup per network. Submissions for older templates rejected.
    *   Slight latency for miner requesting new work unit (network-specific SQS `ReceiveMessage`).
    *   Requires careful network-specific SQS message visibility timeout management.
    *   Fixed 20 SQS messages limit concurrent work per template update per network. Scaling requires manual adjustment and increases SQS costs.
    *   Lack of validation that the submitted `extra_nonce` was assigned to the specific miner.

---
