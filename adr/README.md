# Architecture Decision Records (ADRs)

This folder contains records of important architectural decisions made for this project.

ADRs help us document *why* certain technical choices were made, providing context for future development and understanding.

## Records

*   [ADR-001: Candidate Block Publishing and Notification](./ADR-001-candidate-block-publishing-and-notification.md) - Describes how Bitcoin block templates are generated, signed, published, and how users are notified via AWS IoT Core.
*   [ADR: 002 - Block Reward Distribution and User Payout](./ADR-002-block-reward-distribution-and-user-payout.md) - Defines the phased approach for securely managing and distributing Bitcoin mining rewards to users.
*   [ADR: 003 - Browser Miner Implementation (Initial Phase: Web Worker + Single-Threaded WASM)](./ADR-003-browser-miner-implementation-initial-phase.md) - Details the initial architecture for the client-side browser miner using Rust WASM running in a Web Worker for UI responsiveness, including handling work units, throttling, and hash rate display.
