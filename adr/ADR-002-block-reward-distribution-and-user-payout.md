# ADR: 002 - Block Reward Distribution and User Payout

---

**Status:** Proposed / Draft

---

**Context:**

Our website allows logged-in users to mine Bitcoin blocks using their browsers via WASM mining. While the probability of a user mining a successful block is extremely low, we must have a clear, transparent process for distributing rewards fairly in case this happens. Additionally, we need to ensure user trust and simplify future automation.

We require a phased implementation:

1. **Initial Manual Process** – Manually confirm and distribute rewards.
2. **Semi-Automated Multisig Process** – Bitcoin-native escrow approach.
3. **Fully Automated Smart Contract Process** – Ethereum-based (WBTC) automated payout.

---

**Decision:**

We will use a phased, incremental approach for distributing rewards:

### Phase 1: Manual Process

- **Mining Reward:** Block rewards initially go to a single "pool" wallet managed by our Bitcoin node.
- **User Identification:** Each user will have a unique sub-address derived from a single master wallet. This allows us to identify the winning user easily.
- **Manual Distribution:** Upon block win confirmation, we manually contact the winning user to obtain their preferred Bitcoin address.
- **Payout Split:**
  - Total mined reward is initially received by our platform wallet.
  - From this amount, our platform retains a fixed 5% fee to cover operational costs.
  - Applicable taxes (such as IRS withholding) are deducted from the remaining 95%.
  - The user receives the final amount after tax withholding.

### Phase 2: Semi-Automated (Bitcoin Multisig Escrow)

- **2-of-3 Multisig Wallet:** Created for each potential payout scenario involving:
  - Our platform (1 key)
  - Winning user (1 key)
  - A neutral third-party mediator (1 key)
- **Process:**
  - Mining rewards deposit directly into the multisig wallet.
  - Distribution requires signatures from at least two parties (usually platform and user).
  - Mediator involvement only if disputes arise.

### Phase 3: Fully Automated (Ethereum Smart Contract)

- **WBTC Bridge:** Upon mining a successful block, rewards are converted to Wrapped Bitcoin (WBTC).
- **Ethereum Smart Contract:**
  - Automatically splits and distributes funds:
    - 95% directly to the user's registered Ethereum address.
    - 5% directly to our platform Ethereum address.
    - Tax withholding handled automatically if required.

### User Registration Requirements

- Users must register at least one payout address:
  - Bitcoin address (Phase 1 and 2; Phase 1 registration is optional)
  - Ethereum address for WBTC (Phase 3)
- **Secure Wallet Address Storage:**
  - User payout wallet addresses (BTC and ETH) will be securely stored separately from Cognito user attributes.
  - Wallet data will be encrypted at rest in a secure database (e.g., DynamoDB).
  - Access to wallet data will be strictly controlled via AWS IAM roles and backend APIs.

---

**Consequences:**

- **Pros:**
  - Clear phased approach simplifies initial implementation.
  - Provides trust through incremental automation and transparency.
  - Bitcoin-native multisig and Ethereum-based automation provide educational value.
  - Sub-address system simplifies identification of winning miners.
  - Scalable and secure solutions for different user trust levels.

- **Cons:**
  - Initial manual distribution requires administrative overhead.
  - Complexity increases with each phase.
  - Users must understand tax implications clearly.
  - Automation phases require careful setup and secure management of keys.

---
