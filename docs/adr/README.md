# Architecture Decision Records (ADRs)

This folder contains records of important architectural decisions made for this project.

ADRs help us document *why* certain technical choices were made, providing context for future development and understanding.

## Records

*   [ADR-001: Candidate Block Publishing and Notification](./ADR-001-candidate-block-publishing-and-notification.md) - Describes how Bitcoin block templates are generated, signed, published, and how users are notified via AWS IoT Core.
*   [ADR: 002 - Block Reward Distribution and User Payout](./ADR-002-block-reward-distribution-and-user-payout.md) - Defines the phased approach for securely managing and distributing Bitcoin mining rewards to users.
*   [ADR: 003 - Browser Miner Implementation (Initial Phase: Web Worker + Single-Threaded WASM)](./ADR-003-browser-miner-implementation-initial-phase.md) - Details the initial architecture for the client-side browser miner using Rust WASM running in a Web Worker for UI responsiveness, including handling work units, throttling, and hash rate display.
*   [ADR-004: Static Website Hosting Strategy](./ADR-004-static-website-hosting-strategy.md) - Explains the decision to use S3 Static Website Hosting (with public-read access) instead of a private S3 bucket + OAI/OAC for the Next.js static site to ensure clean URLs, simplicity, and low cost.
*   [ADR-005: CAPTCHA Provider Selection](./ADR-005-captcha-provider-selection.md) - Documents the choice of Cloudflare Turnstile as a privacy-focused, free CAPTCHA solution for user sign-up and sign-in.
