# ADR: 001 - Candidate Block Publishing and Notification

---

**Status:** Proposed / Draft

---

**Context:**

We need a way to send Bitcoin candidate block templates from a private Raspberry Pi node to logged-in users on our website. Users will mine these templates in their browser using WebAssembly (WASM). We need near real-time notifications when a new template is ready. We also need a way to check if a user claiming to have found a solution actually worked on the template we provided, and inform the user of the outcome. The system should be low-cost, must not expose the home network hosting the Pi node, and must avoid storing long-term AWS credentials or signing private keys on the Pi. **To minimize AWS infrastructure costs associated with template distribution and leverage distributed client compute, the strategy involves publishing less frequent, optimized templates containing necessary data for client-side Merkle root calculation for varying extra nonces.**

---

**Decision:**

We will use the following process:

1.  **Block Template Generation & Data Preparation (Raspberry Pi & AWS KMS):**
    *   The Pi node runs `bitcoind` (Mainnet/Testnet) with ZMQ enabled for instant new block detection.
    *   A script on the Pi listens to ZMQ. When a new block is detected, it calls `getblocktemplate` via RPC for the next block height.
    *   The script extracts necessary standard block header data (version, previousblockhash, curtime, bits).
    *   Crucially, the script extracts the **coinbase transaction template details**, including indication of where the extra nonce should be inserted within the `scriptSig`, and the **hashes of all non-coinbase transactions** from the `getblocktemplate` output.
    *   The script then calculates the **Merkle tree** based on the extracted transaction hashes (treating the position for the coinbase hash as variable for now) and identifies the specific ordered list of **sibling hashes** required to reconstruct the Merkle root path starting from the coinbase transaction's position upwards. This list of sibling hashes constitutes the Merkle path data needed by the client.
    *   **Coinbase Address:** The coinbase transaction template will pay out to a single address controlled by the Pi node's wallet (the "pool address").
    *   The script identifies a **starting extra nonce value** for client miners to begin their search range.
    *   **Signing via KMS:**
        *   The script creates a standard string representation from the extracted template data, including the standard header fields, the coinbase transaction template details, the **calculated list of Merkle sibling hashes**, and the designated start extra nonce. **Note: This string does NOT include a pre-calculated *full* Merkle Root, as the WASM client will calculate this for varying extra nonces.**
        *   The script obtains temporary AWS credentials using the **AWS IoT Core Credentials Provider (via a Role Alias)**. The associated IAM role grants `kms:Sign` permission on a specific KMS key.
        *   Using the AWS SDK and these credentials, the script calls the **`kms:Sign` API**, sending the standardized string (or its hash) and the KMS Key ID.
        *   **AWS KMS** performs the signature using the private key stored securely within KMS and returns the signature blob to the Pi script. The signing private key never leaves KMS.
    *   The script prepares a JSON object containing the standard template data (version, prev\_hash, curtime, bits), the coinbase transaction template details, the **list of Merkle sibling hashes**, the start extra nonce, the **KMS-generated signature**, and an identifier for the KMS key used (e.g., a combination of previous block hash and start extra nonce).

2.  **Publishing (Raspberry Pi):**
    *   **AWS Credentials:** The Pi script uses the same temporary AWS credentials obtained via the IoT Role Alias (Step 1). The associated IAM role also grants necessary permissions for S3 upload.
    *   Using these temporary credentials, the script uploads the signed JSON object to AWS S3 using a unique, versioned name that includes the identifier (e.g., `template_[ID].json`).
    *   The script connects **outbound** to AWS IoT Core MQTT using its device certificate for MQTT communication.
    *   It publishes a small notification message to a specific IoT topic (e.g., `pi/bitcoin/template/notify`). This message contains the full **CloudFront URL** corresponding to the newly uploaded template JSON.
    *   The Pi script will generate and publish new versions of this template periodically (e.g., every few minutes) by obtaining a new start extra nonce range, potentially updating the timestamp, and repeating steps 1 and 2.

3.  **User Login & Notification (AWS Cloud & Browser):**
    *   Users log into the website using AWS Cognito User Pools (configured for desired login method).
    *   After login, the browser uses Cognito Identity Pools to get temporary AWS credentials. These credentials grant permission to connect to AWS IoT Core.
    *   The browser connects **outbound** to AWS IoT Core MQTT over WebSockets Secure (WSS) using the temporary credentials.
    *   The browser subscribes to the notification topic (`pi/bitcoin/template/notify`).
    *   When AWS IoT Core pushes the notification message, the browser receives the CloudFront URL for the latest template JSON.

4.  **Mining (Browser):**
    *   The browser fetches the signed template JSON from the CloudFront URL.
    *   The browser passes the template data (standard fields, coinbase template details, **list of Merkle sibling hashes**, start extra nonce, KMS signature, Key ID) to the WASM miner.
    *   The WASM miner processes this data:
        *   It stores the standard fields and the list of Merkle sibling hashes.
        *   It takes the `start_extra_nonce` provided.
        *   It enters a loop to iterate the `extra_nonce` (starting from the provided value and incrementing).
        *   For each `extra_nonce` value:
            *   It constructs the coinbase transaction bytes by inserting/modifying the `scriptSig` using the coinbase transaction template and the current `extra_nonce`.
            *   It calculates the hash of this specific coinbase transaction (\(TxID_0'\)).
            *   It calculates the **Merkle Root** by taking \(TxID_0'\) and iteratively hashing it with the provided **list of Merkle sibling hashes** in the correct order up the tree path.
            *   It constructs the full 80-byte block header using the standard fields (version, prev\_hash, curtime, bits), the *newly calculated Merkle root*, and the *main nonce* (starting from 0).
            *   It enters a nested loop to iterate the `main_nonce` from 0 to \(2^{32}-1\). For each `main_nonce`, it hashes the constructed header using SHA256 and checks if it meets the difficulty target (`bits`).
            *   If the `main_nonce` loop completes, it increments the `extra_nonce` and repeats the process.
            *   If a valid hash is found within the `main_nonce` loop, the miner records the winning `main_nonce` and the current `extra_nonce` being used.

5.  **Solution Submission & Initial Verification (Browser -> AWS Lambda & KMS):**
    *   If the WASM miner finds a nonce solution:
        *   The browser generates a unique Submission ID.
        *   The browser sends the Submission ID, the **original signed template JSON** it received (containing the full template data including the **list of Merkle sibling hashes**, KMS signature, and Key ID), the **found `main_nonce`**, and the **`extra_nonce` that resulted in the solution** to a secure backend endpoint (API Gateway + Lambda).
        *   The **Lambda function** performs initial validation:
            *   Retrieves the User ID from the Cognito context.
            *   Extracts the KMS Key ID and signature from the submitted template JSON.
            *   Reconstructs the original standardized string *from the template data within the submitted JSON* (standard fields, coinbase template, **list of Merkle sibling hashes**, start extra nonce).
            *   Calls the **`kms:Verify` API** using its execution role (needs `kms:Verify` permission), sending the KMS Key ID, original string (or hash), and the signature. **If verification fails (signature invalid), record rejection in DynamoDB (Step 6) and stop. This validates the template data given to the client was authentic.**
            *   Using the now-verified template data (specifically, the coinbase template details and the **list of Merkle sibling hashes**) and the *submitted winning `extra_nonce`*, the Lambda function **calculates the hash of the coinbase transaction and then calculates the Merkle Root** by iteratively hashing with the provided sibling hashes.
            *   Reconstructs the block header *components* using the verified standard fields from the template, the *newly calculated Merkle Root (derived from the submitted extra nonce and sibling hashes)*, and the *submitted winning `main_nonce`*.
            *   Calculates the block hash based on these components.
            *   Checks if the hash meets the difficulty target (`bits`). If invalid, record rejection in DynamoDB (Step 6) and stop.
        *   If all validation passes, the Lambda records "Pending Node Validation" status in DynamoDB (Step 6) and **publishes an MQTT message** (containing Submission ID, winning `main_nonce`, winning `extra_nonce`, and the template identifier) to a specific "submission" topic on **AWS IoT Core**.

6.  **Final Assembly, Verification & Result Persistence (Pi -> DynamoDB):**
    *   A script on the **Raspberry Pi** (subscribed to the submission topic via its secure IoT connection) receives the MQTT message (Submission ID, `main_nonce`, `extra_nonce`, template identifier) from Lambda.
    *   The Pi script needs access to the **full original block data** (including all transaction hex) that was used to generate the specific template version the user worked on. It should retrieve this based on the template identifier (e.g., from a temporary cache or persistent storage). It also needs access to the specific **list of Merkle sibling hashes** that was included in the template corresponding to the submission.
    *   It **assembles the full block**: uses the original transaction hex, reconstructs the coinbase transaction *using the submitted winning `extra_nonce`*, calculates the coinbase txid. It then calculates the correct Merkle root by iteratively hashing the coinbase txid with the appropriate list of Merkle sibling hashes for that template version (which should match the root the Lambda calculated). Constructs the 80-byte header using the original verified components (version, prev\_hash, curtime, bits) plus the calculated Merkle root and the winning `main_nonce`. It serializes the header and all original transactions into the final binary block format.
    *   It **converts the binary block to hex**.
    *   The Pi script calls the local `bitcoind` **`submitblock <final_block_hex>` RPC command**.
    *   The Pi script captures the result from `submitblock`.
    *   **AWS Credentials:** The Pi script again uses the **AWS IoT Core Credentials Provider** to obtain temporary credentials. The associated IAM role grants necessary permissions for DynamoDB update.
    *   Using these temporary credentials, the Pi script **updates the DynamoDB table** item (identified by Submission ID) with the final status.
    *   *Table Schema Example:* `SubmissionID (PK)`, `UserID`, `Timestamp`, `TemplateIdentifier`, `WinningNonce`, `WinningExtraNonce`, `LambdaStatus`, `NodeStatus`, `NodeRejectReason`, `AcceptedBlockHash`.
    *   The website frontend can query this DynamoDB table to display the submission status.

---

**Consequences:**

*   **Pros:**
    *   Home network remains secure (only outbound connections from Pi).
    *   Low-latency notifications via IoT Core push.
    *   **Significantly lower AWS costs for S3 and CloudFront** due to much smaller template JSON size.
    *   Lower costs for IoT Core and KMS due to less frequent template publishing.
    *   **Signing private key secured within AWS KMS**, never stored on the Pi.
    *   **No long-term AWS credentials stored on the Pi**, uses secure IoT Role Alias mechanism.
    *   Template data signing allows backend verification that the user worked on an authentic template.
    *   Submission results are persisted for user feedback.
    *   Uses standard, scalable AWS services for cloud components.
    *   Secure communication path for submissions.
    *   Initial validation load handled by Lambda.
    *   **Leverages distributed client compute power** for a significant portion of the mining work (calculating coinbase hash, calculating Merkle root path, and hashing headers).
*   **Cons:**
    *   System relies on the Pi node's uptime and home internet connection.
    *   Increased setup complexity (Pi scripts, KMS key setup, Cognito, IoT policies/Role Alias, Lambda function/role, DynamoDB table/permissions, result query API).
    *   Securely managing the **IoT device certificate/key** on the Pi is critical.
    *   Coinbase pays to a pool address, requiring manual/separate payout process if a block is found.
    *   Browser mining has a near-zero chance of finding a real block (must be clearly stated to users).
    *   **Increased complexity for the WASM miner** (must implement coinbase construction and Merkle path calculation logic).
    *   **Increased complexity in Lambda and Pi verification** (must correctly use the submitted extra nonce and stored/provided Merkle sibling hashes to recalculate the Merkle root).
    *   The Pi needs to store or be able to retrieve the full transaction data for a submitted template version to assemble the final block for `submitblock`.

---
