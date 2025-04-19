# ADR: 002 - Block Reward Distribution and User Payout

---

**Status:** Proposed / Draft

---

**Context:**

Our website allows logged-in users to mine Bitcoin blocks using their browsers via WASM mining. While the probability of a user mining a successful block is extremely low, we must have a clear, transparent process for distributing rewards fairly if this happens. The initial block reward (Coinbase) goes to a central pool address, so we need a mechanism to identify the winning user from submission records and manage the subsequent payout.

We require a phased implementation:

1.  **Initial Manual Process** – Manually confirm and distribute rewards.
2.  **Semi-Automated Multisig Process** – Bitcoin-native escrow approach after initial receipt.
3.  **Fully Automated Smart Contract Process** – Ethereum-based (WBTC) automated payout after initial receipt and bridging.

---

**Decision:**

We will use a phased, incremental approach for distributing rewards:

### Phase 1: Manual Process

*   **Mining Reward Receipt:** Block rewards (Coinbase + fees) initially go to a single "pool" wallet address controlled by our Bitcoin node, as dictated by the block template (see ADR-001).
*   **User Identification:** When a block is successfully submitted via the process in ADR-001, the final step records the `AcceptedBlockHash` and the associated `UserID` (from the user's session during submission) in the DynamoDB submission table. This record definitively identifies the winning user.
*   **Manual Distribution:** Upon confirmation of a successful block mined via our system (by checking the submission table against the blockchain), we manually contact the winning user (identified via `UserID`) to obtain/confirm their preferred Bitcoin payout address.
*   **Payout Split:**
    *   The total mined reward is held in our platform's pool wallet.
    *   From this amount, our platform retains a fixed 5% fee.
    *   Applicable taxes are calculated on the remaining 95%.
    *   The user receives the final amount (after fee and tax withholding) via a manual Bitcoin transaction from the pool wallet to their provided payout address.

### Phase 2: Semi-Automated (Bitcoin Multisig Escrow)

*   **Reward Receipt:** As in Phase 1, the reward first lands in the central pool address.
*   **User Identification:** As in Phase 1, the winning user is identified via the DynamoDB submission record.
*   **Multisig Setup & Transfer:**
    *   Upon confirmation of a successful block, the platform initiates the creation of a 2-of-3 Bitcoin multisig address involving:
        *   Our platform (1 key)
        *   The winning user (1 key, provided during registration or confirmation)
        *   A neutral third-party mediator (1 key, optional, for dispute resolution)
    *   The platform calculates the user's share (e.g., 95% minus taxes) and transfers *that amount* from the pool wallet to this newly created multisig address.
*   **Distribution:** Payout from the multisig address requires signatures from at least two parties (typically platform and user) to the user's final payout address. Mediator involvement only if disputes arise.

### Phase 3: Fully Automated (Ethereum Smart Contract)

*   **Reward Receipt & Identification:** As in Phase 1, reward lands in the pool address, and the user is identified via the DynamoDB record.
*   **Bridging & Contract Interaction:**
    *   Upon confirmation, an automated process (e.g., a secure backend service monitoring the submission table and pool wallet) initiates the conversion of the *user's share* (e.g., 95% minus taxes) of the Bitcoin reward into Wrapped Bitcoin (WBTC).
    *   This WBTC is then sent to a dedicated Ethereum Smart Contract designed for payouts.
*   **Smart Contract Distribution:**
    *   The Smart Contract automatically sends the received WBTC to the winning user's registered Ethereum payout address.
    *   (Optional: The platform's 5% fee could potentially be handled similarly via bridging and a separate contract transfer).

### User Registration Requirements

*   Users must register at least one payout address relevant to the active or planned payout phases:
    *   Bitcoin address (for Phase 1 and 2 payouts)
    *   Ethereum address (for Phase 3 WBTC payouts)
*   **Secure Wallet Address Storage:**
    *   User payout wallet addresses (BTC and ETH) will be securely stored separately from Cognito user attributes.
    *   Wallet data will be encrypted at rest in a secure database (e.g., DynamoDB).
    *   Access to wallet data will be strictly controlled via AWS IAM roles and backend APIs.

---

**Consequences:**

*   **Pros:**
    *   Clear phased approach simplifies initial implementation.
    *   Provides trust through incremental automation and transparency.
    *   Bitcoin-native multisig and Ethereum-based automation provide educational value.
    *   Clear identification of winning user via submission records.
    *   Scalable and secure solutions for different user trust levels.
    *   Aligns with technical constraints of Bitcoin mining (single Coinbase address).
*   **Cons:**
    *   Initial manual distribution requires administrative overhead.
    *   Complexity increases with each phase (multisig setup, bridging, smart contracts).
    *   Users must understand tax implications clearly.
    *   Automation phases require careful setup and secure management of keys/processes.
    *   Requires users to provide payout addresses separately.

---
