# ADR-004: Static Website Hosting Strategy

---

**Status:** Accepted / Implemented

---

**Context:**

The project requires hosting the primary static website (`bitcoinbrowserminer.com`), built with Next.js (v15.2+, Pages Router, `output: 'export'`, `trailingSlash: true`), on AWS, and include:
1.  Low Cost: Minimize AWS infrastructure and operational expenses.
2.  SEO & User Experience: Ensure clean, canonical URLs (e.g., `/start/` instead of `/start.html`) that users can link to directly.
3.  Simplicity & Maintainability: Prefer simpler solutions suitable for an open-source project.
4.  Appropriate Security: Follow reasonable security practices for hosting public web assets.

Initial attempts focused on keeping the S3 bucket private using Origin Access Identity (OAI) or Origin Access Control (OAC) with CloudFront. However, the S3 API endpoint (used with OAI/OAC) does not natively behave like a web server. It doesn't automatically serve `index.html` for directory requests (e.g., `/start/`) or handle trailing slash redirects (`/start` -> `/start/`). This required a CloudFront Function for URL rewriting, which proved problematic and led to errors (e.g., redirect loops, 403s).

---

**Decision:**

We will use the `S3 Static Website Hosting` feature for the S3 bucket containing the static website assets. CloudFront will be configured to use the bucket's `S3 website endpoint` (e.g., `bitcoinbrowserminer.com.s3-website-us-west-2.amazonaws.com`) as its HTTP origin.

Consequently:
*   The S3 bucket policy will be configured to allow public read access (`s3:GetObject`) only. Listing (`s3:ListBucket`) and writing will be denied.
*   OAI/OAC will not be used for this CloudFront distribution, as they are incompatible with S3 website endpoints (OAC), or limit the behavior expected by SEO (OAI).
*   CloudFront Functions previously used for URL rewriting/redirects related to `index.html` or trailing slashes will be removed, as S3 Website Hosting handles this natively.

---

**Rationale:**

1.  Clean URL Handling: S3 Static Website Hosting directly addresses the core problem encountered with the private bucket approach. It automatically serves the `index.html` document for directory requests (e.g., `/start/`) and handles the necessary redirects for trailing slashes (e.g., `/start` to `/start/`), aligning with Next.js static export requirements and ensuring good SEO and UX without custom logic.
2.  Simplicity: This approach significantly simplifies the CloudFront configuration by removing the need for complex Lambda@Edge or CloudFront Functions for basic URL routing. This reduces potential points of failure and maintenance overhead, which is beneficial for an open-source project.
3.  Cost-Effectiveness: Eliminating CloudFront Functions reduces compute costs (not that it was a significant cost, but not having them ensures no additional cost). S3 Website Hosting itself is highly cost-effective.
4.  Acceptable Security for Static Assets: While the bucket is technically public-read, the risk is minimal and acceptable for hosting non-sensitive, static website content. The bucket policy strictly limits access to `s3:GetObject`, preventing data modification or bucket enumeration. This is a standard industry practice for hosting static websites. CloudFront continues to provide HTTPS termination, caching, and DDoS protection for user-facing traffic.
5.  Failure of Alternatives: The alternative (private S3 + OAI/OAC + CloudFront Functions) failed to provide a stable and simple solution for clean URL handling due to the inherent limitations of the S3 API endpoint when treated as a web origin.

---

**Alternatives Considered:**

*   Private S3 Bucket + OAI/OAC + CloudFront Functions: This was the initial approach. It was rejected due to the complexity, instability (redirect loops, 403 errors), and operational overhead required to replicate basic web server behavior (index document serving, trailing slash redirects) using CloudFront Functions when interacting with the S3 API endpoint.

*   Server-Side Rendering (SSR) with Lambda@Edge or similar compute: This was considered as a way to potentially handle URL routing dynamically. It was rejected because the website is intentionally built as a fully static export (`output: 'export'`). Implementing SSR would add unnecessary complexity and compute costs (Lambda@Edge invocations) without providing any required functionality, directly contradicting the goals of simplicity and low cost.

---

**Consequences:**

*   **Pros:**
    *   Correctly handles clean URLs and `index.html` resolution required by Next.js static export.
    *   Significantly simpler CloudFront configuration and overall architecture.
    *   Lower operational overhead and fewer potential points of failure.
    *   Aligns with standard, cost-effective practices for static site hosting.
    *   Improved SEO and user experience due to reliable URL handling.
*   **Cons:**
    *   S3 bucket is not strictly private; requires a public-read (`s3:GetObject`) policy.
    *   Cannot leverage OAI/OAC for origin access control between CloudFront and S3 for this specific distribution.
    *   CloudFront communicates with the S3 website endpoint origin via HTTP (user traffic remains secured via HTTPS at CloudFront).

---
