# mine-bitcoin-online
Service that allows users to mine Bitcoin though their browser




# Customer Contacting
- I'd like to setup SES to do the email forwarding, but for now I will use [improvmx](https://app.improvmx.com/domains/bitcoinbrowserminer.com/aliases) to foward emails from info@ to me.

# To Do List
- Cognito setup
- Cognito login on site
- Raspberry pi bitcoin Node setup
- aws iot on the pi (see how we can automate others)
- api built to ping pi and get data (block to solve)
- api built to validate solution on lambda
- api built to submit solution
- site stuff -> cool graphics for block visualization
- site stuff -> cool graphics for overall visualization
- site stuff -> faq
- wasm cpu solver
- wasm gpu solver
- variable rate control and timeline viewer
- page like solution for when a block is solved and verified
- db lifecycle and backuper solution
- GDPR solution (consent, data deletion, data retrieval)



# Project Structure

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
