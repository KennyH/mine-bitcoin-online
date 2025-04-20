# ADR: 001 - Candidate Block Publishing and Notification

---

**Status:** Proposed / Draft

---

**Context:**

We need a way to send Bitcoin candidate block templates from a private Raspberry Pi node to logged-in users on our website. Users will mine these templates in their browser using WebAssembly (WASM). We need near real-time notifications when a new template is ready. We also need a way to check if a user claiming to have found a solution actually worked on the template we provided, and inform the user of the outcome. The system should be low-cost, must not expose the home network hosting the Pi node, and must avoid storing long-term AWS credentials or signing private keys on the Pi. **To minimize AWS infrastructure costs and offload potential Pi bottlenecks for work assignment, template details will be published less frequently, and work unit distribution within those templates will be managed via an SQS queue consumed directly by miners.**

---

**Decision:**

We will use the following process:

1.  **New Block Detection & Lambda Trigger (Raspberry Pi):**
    *   The Pi node runs `bitcoind` (Mainnet/Testnet) with ZMQ enabled for instant new block detection.
    *   A script on the Pi listens to ZMQ. When a new block is detected, it calls `getblocktemplate` via RPC for the next block height.
    *   The script extracts necessary standard block header data (version, previousblockhash, curtime, bits).
    *   Crucially, the script extracts the **coinbase transaction template details**, including indication of where the extra nonce should be inserted within the `scriptSig`, and the **hashes of all non-coinbase transactions** from the `getblocktemplate` output.
    *   The script calculates the **Merkle tree** based on the extracted transaction hashes and identifies the specific ordered list of **sibling hashes** required to reconstruct the Merkle root path from the coinbase transaction's position upwards.
    *   It defines a **large Work Block range** of extra nonces that will be the basis for the work units distributed from the SQS queue.
    *   **Coinbase Address:** The coinbase transaction template will pay out to a single address controlled by the Pi node's wallet (the "pool address").
    *   The script prepares a payload containing the template identifier (e.g., previous block hash + Work Block start extra nonce), standard header fields, coinbase template details, Merkle sibling hashes, and the Work Block range.
    *   The script obtains temporary AWS credentials using the **AWS IoT Core Credentials Provider (via a Role Alias)**. The associated IAM role grants permission to trigger a specific Lambda function (e.g., via publishing to an SNS topic or calling API Gateway).
    *   The script sends this payload to the trigger service, initiating the cloud-based template and queue management process. The Pi's direct involvement with AWS for this block template ends here until submission processing.

2.  **Template Processing, SQS Work Queue Population & Main Template Publication (AWS Lambda triggered by Pi):**
    *   A **dedicated AWS Lambda function** is triggered by the Pi's notification payload.
    *   The Lambda receives the template data (identifier, header fields, coinbase template, Merkle sibling hashes, Work Block range).
    *   The Lambda performs the following:
        *   **Sign Core Template Data (via KMS):** It creates a standard string representation of the core template data (identifier, header fields, coinbase template details, Merkle sibling hashes, Work Block range) and calls the **`kms:Sign` API** using its execution role to sign this data. The signature and KMS Key ID are returned to the Lambda.
        *   **Generate Sub-Ranges:** It divides the Work Block range into many smaller, sequential `extra_nonce` sub-ranges (e.g., ranges of 10,000 nonces each).
        *   **Populate SQS Work Queue:** For each sub-range, it constructs a message containing the template identifier and the sub-range boundaries (`start_extra_nonce`, `end_extra_nonce`). It uses the AWS SDK to **batch send these messages to the dedicated SQS Work Queue** associated with the current Work Block. It should ensure the queue is empty of previous block's messages or use block identifiers for separation.
        *   **Publish Main Template:** It constructs the main Work Block template JSON object containing the signed core template data (identifier, header fields, coinbase template, Merkle sibling hashes, Work Block range, KMS signature, Key ID). It uses the AWS SDK to upload this JSON to AWS S3 using a unique, versioned name based on the template identifier.
        *   **Publish CloudFront Notification:** It sends a small MQTT notification (via IoT Core) to the client topic containing the CloudFront URL for the newly uploaded main Work Block template JSON.

3.  **User Login & Notification (AWS Cloud & Browser):**
    *   Users log into the website and use Cognito Identity Pools to get temporary AWS credentials, granting permissions for IoT Core and **SQS Work Queue access**.
    *   The browser connects to AWS IoT Core MQTT and subscribes to the notification topic.
    *   When AWS IoT Core pushes the notification message containing the CloudFront URL for a new main Work Block template, the browser receives it.

4.  **Mining & Work Unit Consumption (Browser / WASM & SQS):**
    *   The browser fetches the main Work Block template JSON from the CloudFront URL.
    *   The browser/WASM miner uses its temporary AWS credentials to interact with the **SQS Work Queue**.
    *   When the miner needs a work assignment:
        *   It calls SQS `ReceiveMessage` on the dedicated Work Queue (identified, potentially, by information in the main template).
        *   When a message is received, the miner extracts the template identifier and its assigned `[start_extra_nonce, end_extra_nonce]` sub-range from the message.
        *   It sets the message's visibility timeout to prevent other miners from receiving the same range.
        *   The miner then works on the assigned `extra_nonce` sub-range (iterating extra nonces within this range) using the data from the main Work Block template (standard fields, coinbase template, Merkle sibling hashes). For each extra nonce in its range, it calculates the Merkle root and iterates the main nonce (0 to \(2^{32}-1\)).
    *   When the miner successfully completes its assigned sub-range, it sends an SQS `DeleteMessage` request for the corresponding message.
    *   If a miner crashes or closes, the message's visibility timeout will expire, making the range available for another miner.
    *   If a new main Work Block template notification arrives, the miner discards its current Work Queue message (or lets timeout expire) and starts requesting from the queue associated with the new Work Block.

5.  **Solution Submission & Initial Verification (Browser -> AWS Lambda -> Submission SQS Queue):**
    *   If the WASM miner finds a nonce solution within its assigned SQS range:
        *   The browser generates a unique Submission ID.
        *   The browser sends the Submission ID, the **original main Work Block template JSON** it received (containing the signed core data), the **found `main_nonce`**, and the **`extra_nonce` that resulted in the solution** to a secure backend endpoint (API Gateway + **Solution Verification Lambda**).
        *   The Solution Verification Lambda performs initial validation:
            *   Retrieves User ID from Cognito context.
            *   Extracts KMS Key ID and signature from the main template JSON.
            *   Reconstructs the original standardized core template string.
            *   Calls **`kms:Verify`** to validate the Pi/Template Management Lambda's signature. If verification fails, record rejection and stop.
            *   Using the verified core template data (coinbase template, Merkle sibling hashes) and the *submitted winning `extra_nonce`*, calculates the hash of the coinbase transaction and the Merkle Root.
            *   Reconstructs the block header components using verified standard fields, the calculated Merkle Root, and the submitted `main_nonce`.
            *   Calculates the final block hash and checks against the difficulty target. If invalid, record rejection and stop.
            *   **(Optional/Future) Range Verification:** Could potentially verify that the submitted `extra_nonce` falls within the Work Block range specified in the signed main template. For added robustness (though more complex), it could verify it was within a range *assigned* from the SQS queue (requires tracking assignments). For now, basic validity against the main template is sufficient.
        *   If all validation passes, the Lambda constructs a submission message (Submission ID, user ID, winning nonces, template identifier, etc.) and places it onto a **Submission SQS Queue**. It updates DynamoDB with a "Pending Node Processing" status.

6.  **Final Assembly & Submission Processing (Raspberry Pi Polling Submission SQS Queue):**
    *   A script on the **Raspberry Pi** uses its secure IoT connection to obtain temporary AWS credentials, granting permission to **`sqs:ReceiveMessage`, `sqs:DeleteMessage`** on the Submission SQS Queue and DynamoDB update permissions.
    *   The Pi script **polls the Submission SQS Queue** periodically for new messages.
    *   When a submission message is received, the Pi extracts the submission details.
    *   The Pi needs access to the **full original block transaction data** corresponding to the template identifier (from local cache or storage). It also needs the Merkle sibling hashes (could be included in the submission message or retrieved based on the identifier).
    *   It **assembles the full block**: uses the original transaction hex, reconstructs the coinbase transaction *using the submitted winning `extra_nonce`*, calculates the coinbase txid and Merkle root (using sibling hashes). Constructs the 80-byte header using original verified components, calculated Merkle root, and the winning `main_nonce`. Serializes to binary block format.
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
    *   **Highly scalable work distribution via SQS Work Queue consumption** by miners, minimizing load on the Pi for individual work assignments.
    *   **Pi's core task is focused on `bitcoind` interaction and submission processing**, offloading template/queue management to Lambda.
    *   **Significantly lower AWS costs for S3 and CloudFront** due to much smaller template JSON size and less frequent main template publication.
    *   Low costs for IoT Core.
    *   **KMS signing key secured within AWS KMS**.
    *   **No long-term AWS credentials stored on the Pi**, uses secure IoT Role Alias mechanism.
    *   Signed core template data allows backend verification of the template's authenticity.
    *   Submission results persisted.
    *   Uses standard, scalable AWS services.
    *   Secure communication paths.
    *   Initial validation load on Lambda.
    *   **Leverages distributed client compute for full mining work.**
    *   **SQS Submission Queue decouples submission processing from the Lambda verification**, allowing the Pi to process them at its own pace and providing durability.
*   **Cons:**
    *   System relies on the Pi node's uptime and home internet connection for `bitcoind` and final submission.
    *   Increased setup complexity (Pi scripts, multiple Lambda functions/roles, SQS queues/permissions, API Gateway, Cognito, IoT policies/Role Alias, S3/CloudFront, KMS).
    *   Securely managing the **IoT device certificate/key** on the Pi is critical.
    *   Coinbase pays to a pool address, requiring manual/separate payout.
    *   Browser mining has a near-zero chance of finding a real block.
    *   **Increased complexity for the WASM miner** (must fetch main template, interact directly with SQS for work units, implement mining logic).
    *   **Increased complexity in Lambdas and Pi verification** (must use submitted extra nonce and Merkle sibling hashes).
    *   The Pi needs to store or retrieve the full transaction data and potentially the Merkle sibling hashes for a submitted template version.
    *   Adds slight latency for a miner requesting a new work unit (SQS `ReceiveMessage` call).
    *   Requires careful management of SQS message visibility timeouts to prevent work from being lost if a miner fails mid-range.

---
