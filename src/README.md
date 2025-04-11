# Source Code

## Project Structure

```
mine-bitcoin-online/
├── .github/
├── package.json
├── src/
│   ├── backend/             # backend IaC
│   │   ├── lambdas/
│   │   └── terraform/
│   │       ├── dev/
│   │       ├── modules/
│   │       ├── prod/
│   │       └── setup/       # for setting up Terraform state
│   │
│   ├── wasm-miner/          # WASM mining module src
│   │   ├── Cargo.toml
│   │   ├── pkg/             # wasm-pack build output
│   │   └── src/
│   │       └── lib.rs
│   │
│   └── website/             # Next.js site src
│       ├── public/
│       └── src/
│           ├── app/
│           ├── components/
│           ├── hooks/
│           ├── lib/
│           └── wasm/        # compiled WASM
│
└── etc...
```