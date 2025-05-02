# ADR: 006 - Ethereum Node Setup (Nethermind + Lighthouse)

---

**Status:** Proposed

---

**Context:**

To support the future goal of deploying and interacting with an Ethereum smart contract for Bitcoin mining reward distribution (detailed in [ADR-002](./ADR-002-block-reward-distribution-and-user-payout.md)), we need reliable access to the Ethereum network. Relying solely on third-party services can introduce costs, rate limits, and potential points of failure. We have acquired dedicated hardware (Raspberry Pi 5, 16GB RAM, 2TB NVMe SSD) suitable for running a full Ethereum node. Running our own node provides direct, trustless access for reading blockchain data and submitting transactions. Since The Merge, a full node requires both an Execution Layer (EL) client and a Consensus Layer (CL) client. We do not plan to stake 32 ETH, so this will be a non-validating node. Choosing clients other than the most dominant ones helps improve the network's client diversity.

---

**Decision:**

We will set up a full, non-validating Ethereum node on the Raspberry Pi 5 using the *Nethermind* Execution Layer (EL) client and the *Lighthouse* Consensus Layer (CL) client.

**Alternatives Considered:**

*   Other EL Clients:
    *   *Geth:* The most widely used client, very mature, but running it reduces client diversity.
    *   *Besu:* A stable Java-based option.
    *   *Erigon:* Focuses on high disk efficiency after initial sync.
*   Other CL Clients:
    *   *Prysm:* A very popular and mature client, but like Geth, running it reduces diversity.
    *   *Teku:* A stable Java-based option, often paired with Besu.
    *   *Nimbus:* Focuses on being very lightweight.

**Reasoning for Choice:**

*   Nethermind (EL): Chosen over alternatives primarily for its good performance, and stability. It also significantly contributes to client diversity compared to Geth.
*   Lighthouse (CL): Chosen over alternatives for its high performance, and security focus. It pairs well with Nethermind and also improves client diversity compared to Prysm.

This setup will provide the necessary infrastructure to:
*   Independently verify Ethereum blockchain data.
*   Submit transactions directly to the network, specifically for deploying and triggering the future reward distribution smart contract (likely on an L2, interacting via this L1 node or L2 RPCs).

---

**Consequences:**

*   **Pros:**
    *   Provides direct, reliable, and trustless read/write access to the Ethereum network.
    *   Avoids reliance on third-party API providers and their potential limitations/costs.
    *   Supports the planned smart contract deployment and interaction ([ADR-002](./ADR-002-block-reward-distribution-and-user-payout.md)).
    *   Chosen hardware (16GB RAM, NVMe SSD) provides sufficient resources for stable operation.
    *   Contributes to Ethereum network health and decentralization.
    *   Improves client diversity by using Nethermind and Lighthouse.
    *   Leverages author's technical interest in .NET and Rust.
*   **Cons:**
    *   Requires initial setup effort and ongoing maintenance (client updates, monitoring).
    *   Consumes local hardware resources (CPU, RAM, disk space, bandwidth) on the Pi.
    *   Requires a stable, unmetered internet connection.
    *   Potential need for troubleshooting if sync issues or client bugs occur.
    *   Does not generate staking rewards (as it's non-validating).

---
