# Website - Bitcoin Browser Miner
This is the user-facing frontend to the project.

It requires users to sign up / sign in before they will be able to start mining. The sign in is required, as there needs to be a secure way to send and transmit data to the backend, and also a way to limit the number of concurrent users active (if things get too expensive to run).

The site is a [Next.js](https://nextjs.org) project bootstrapped with [`create-next-app`](https://nextjs.org/docs/app/api-reference/cli/create-next-app). It uses the following AWS services:

- S3
- CloudFront
- Cognito (with some lambdas to support OTP logins)
- Cloudflare Turnstile (with a lambda)
- Route53
- API Gateway (and lambdas)

These services and the site are deployed via GitHub actions with Terraform (see: ../backend/terraform/).

## Setting up local environment

- Copy `.env.local.example` to `.env.local` and fill in the necessary credentials and secrets. You csan get these after deploying the terraform and logging into AWS Console for Cognito. You will also need to [open a Cloudflare account](https://dash.cloudflare.com/sign-up) and create a new Turnstyle component (and get/set the site (for nextjs) and secret (for terraform) keys. --make sure you add `localhost` to the allowed hostname, for local dev env).

```bash
cp .env.local.example .env.local
echo "fill out the values in .env.local"
```

## Setting up remote environment

- You will need to set corresponding env variables (from `.env.local`) in your cloud environment (e.g., GitHub secrets).

## Getting Started

First, install the development server:

```bash
npm install
```

Then run the server:

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

################################## delete below eventually

You can start editing the page by modifying `app/page.tsx`. The page auto-updates as you edit the file.

This project uses [`next/font`](https://nextjs.org/docs/app/building-your-application/optimizing/fonts) to automatically optimize and load [Geist](https://vercel.com/font), a new font family for Vercel.

## Run tests

### Jest unit tests
```
npm test
```

### Playwright E2E tests
This uses [Playwright](https://playwright.dev/).

Start a dev server:
```
npm run dev
```
Then in another terminal, run the tests:
```
npm run test:e2e
```

## Learn More About Next.js

To learn more about Next.js, take a look at the following resources:

- [Next.js Documentation](https://nextjs.org/docs) - learn about Next.js features and API.
- [Learn Next.js](https://nextjs.org/learn) - an interactive Next.js tutorial.

You can check out [the Next.js GitHub repository](https://github.com/vercel/next.js).
