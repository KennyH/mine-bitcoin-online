# ADR: 001 - Candidate Block Publishing and Notification

---

**Status:** Proposed / Draft

---

**Context:**

We need a way to send Bitcoin candidate block templates from a private Raspberry Pi node to logged-in users on our website. Users will mine these templates in their browser using WASM. We need near real-time notifications when a new template is ready. We also need a way to check if a user claiming to have found a solution actually worked on the template we provided, and inform the user of the outcome. The system should be low-cost, must not expose the home network hosting the Pi node, and must avoid storing long-term AWS credentials or signing private keys on the Pi.

---

**Decision:**

We will use the following process:

1.  **Block Template Generation & Signing (Raspberry Pi & AWS KMS):**
    *   The Pi node runs `bitcoind` (Mainnet/Testnet) with ZMQ enabled for instant new block detection.
    *   A script on the Pi listens to ZMQ. When a new block is detected, it calls `getblocktemplate` via RPC.
    *   The script extracts necessary data (version, previousblockhash, merkle_root, curtime, bits).
    *   **Coinbase Address:** The coinbase transaction within the template will pay out to a single address controlled by the Pi node's wallet (the "pool address"). *Rationale: Modifying the coinbase per-user dynamically is complex and incompatible with the simple broadcast model. If a block is found, the reward goes to the pool address, and the system identifies the winning user via the submission record (Step 6) for later payout.*
    *   **Signing via KMS:**
        *   The script creates a standard string from the template data (e.g., concatenating version, prev_hash, merkle_root, time, bits).
        *   The script obtains temporary AWS credentials using the **AWS IoT Core Credentials Provider (via a Role Alias)**. The associated IAM role grants `kms:Sign` permission on a specific KMS key.
        *   Using the AWS SDK and these credentials, the script calls the **`kms:Sign` API**, sending the standardized string (or its hash) and the KMS Key ID.
        *   **AWS KMS** performs the signature using the private key stored securely within KMS and returns the signature blob to the Pi script. The signing private key never leaves KMS.
    *   The script prepares a JSON object containing the template data, the **KMS-generated signature**, and an identifier for the KMS key used.

2.  **Publishing (Raspberry Pi):**
    *   **AWS Credentials:** The Pi script uses the same temporary AWS credentials obtained via the IoT Role Alias (Step 1). The associated IAM role also grants necessary permissions for S3 upload.
    *   Using these temporary credentials, the script uploads the signed JSON template to AWS S3 using a unique, versioned name (e.g., `template_[PREVHASH].json`).
    *   The script connects **outbound** to AWS IoT Core MQTT using its device certificate for MQTT communication.
    *   It publishes a small notification message to a specific IoT topic (e.g., `pi/bitcoin/template/notify`). This message contains the full **CloudFront URL** corresponding to the newly uploaded template JSON.

3.  **User Login & Notification (AWS Cloud & Browser):**
    *   Users log into the website using AWS Cognito User Pools (configured for desired login method, e.g., passwordless email+code).
    *   After login, the browser uses Cognito Identity Pools to get temporary AWS credentials. These credentials grant permission to connect to AWS IoT Core.
    *   The browser connects **outbound** to AWS IoT Core MQTT over WebSockets Secure (WSS) using the temporary credentials.
    *   The browser subscribes to the notification topic (`pi/bitcoin/template/notify`).
    *   When AWS IoT Core pushes the notification message, the browser receives the CloudFront URL.

4.  **Mining (Browser):**
    *   The browser fetches the signed template JSON from the CloudFront URL.
    *   The browser passes the template data (version, prev_hash, merkle_root, time, bits) to the WASM miner. The signature and KMS key ID are kept alongside.
    *   The WASM miner loops through nonces, hashing the block header.

5.  **Solution Submission & Initial Verification (Browser -> AWS Lambda & KMS):**
    *   If the WASM miner finds a nonce that results in a hash below the target (`bits`):
        *   The browser generates a unique Submission ID.
        *   The browser sends the Submission ID, the **original signed template JSON** (containing the KMS signature and Key ID) it received, and the **found nonce** to a secure backend endpoint (API Gateway + Lambda).
        *   The **Lambda function** performs initial validation:
            *   Retrieves the User ID from the Cognito context.
            *   Extracts the KMS Key ID and signature from the template JSON.
            *   Reconstructs the original standardized string from the template data.
            *   Calls the **`kms:Verify` API** using its execution role (which needs `kms:Verify` permission), sending the KMS Key ID, original string (or hash), and the signature. **If verification fails (signature invalid), record rejection in DynamoDB (Step 6) and stop.**
            *   Reconstructs the block header *components* using the now-verified template data and the submitted nonce.
            *   Calculates the block hash based on these components.
            *   Checks if the hash meets the difficulty target (`bits`). If invalid, record rejection in DynamoDB (Step 6) and stop.
        *   If all validation passes, the Lambda records "Pending Node Validation" status in DynamoDB (Step 6) and **publishes an MQTT message** (containing Submission ID, winning `nonce`, and a `template_identifier` like `previousblockhash`) to a specific "submission" topic on **AWS IoT Core**.

6.  **Final Assembly, Verification & Result Persistence (Pi -> DynamoDB):**
    *   A script on the **Raspberry Pi** (subscribed to the submission topic via its secure IoT connection) receives the MQTT message (Submission ID, `nonce`, `template_identifier`) from Lambda.
    *   The Pi script **retrieves the full original block data** (including all transaction hex) associated with the `template_identifier` (e.g., from a temporary cache or by re-querying necessary data).
    *   It **assembles the full block**: constructs the 80-byte header using the original components plus the winning `nonce`, then serializes the header and all original transactions into the final binary block format.
    *   It **converts the binary block to hex**.
    *   The Pi script calls the local `bitcoind` **`submitblock <final_block_hex>` RPC command**.
    *   The Pi script captures the result from `submitblock` (e.g., success/accepted with block hash, or rejection reason like "duplicate", "invalid", etc.).
    *   **AWS Credentials:** The Pi script again uses the **AWS IoT Core Credentials Provider** to obtain temporary credentials. The associated IAM role grants necessary permissions for DynamoDB update.
    *   Using these temporary credentials, the Pi script **updates the DynamoDB table** item (identified by Submission ID) with the final status: "Node Accepted: [blockhash]" or "Node Rejected: [reason]".
    *   *Table Schema Example:* `SubmissionID (PK)`, `UserID`, `Timestamp`, `TemplatePrevHash`, `Nonce`, `LambdaStatus`, `NodeStatus`, `NodeRejectReason`, `AcceptedBlockHash`.
    *   The website frontend can query this DynamoDB table (via a separate secure API endpoint) to display the submission status back to the user.

---

**Consequences:**

*   **Pros:**
    *   Home network remains secure (only outbound connections from Pi).
    *   Low-latency notifications via IoT Core push.
    *   Low cost (uses generous free tiers for Cognito, IoT Core, S3, CloudFront, Lambda, DynamoDB, KMS).
    *   **Signing private key secured within AWS KMS**, never stored on the Pi.
    *   **No long-term AWS credentials stored on the Pi**, uses secure IoT Role Alias mechanism.
    *   Template signing allows backend verification, preventing fake submissions.
    *   Submission results are persisted for user feedback.
    *   Uses standard, scalable AWS services for cloud components.
    *   Secure communication path for submissions (Browser -> API GW -> Lambda -> IoT Core -> Pi) without tunnels/VPNs.
    *   Initial validation load handled by Lambda.
*   **Cons:**
    *   System relies on the Pi node's uptime and home internet connection.
    *   Increased setup complexity (Pi scripts, KMS key setup, Cognito, IoT policies/Role Alias, Lambda function/role, DynamoDB table/permissions, result query API).
    *   Securely managing the **IoT device certificate/key** on the Pi is critical.
    *   Coinbase pays to a pool address, requiring manual/separate payout process if a block is found.
    *   Browser mining has a near-zero chance of finding a real block (must be clearly stated to users).
    *   Small latency increase during template generation due to KMS API call.

---
