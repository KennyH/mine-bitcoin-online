# Source Code

## Project Structure

```
mine-bitcoin-online/
├── .github/                 # actions for deployment
├── package.json
├── src/
│   ├── backend/
│   │   ├── lambdas/
│   │   └── terraform/
│   │       ├── dev/
│   │       ├── modules/     # backend IaC
│   │       ├── prod/
│   │       └── setup/       # setup for Terraform state
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