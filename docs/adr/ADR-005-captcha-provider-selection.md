# ADR: 005 - CAPTCHA Provider Selection

---

**Status:** Accepted

---

**Context:**

To prevent automated sign-ups and logins, the site needs a CAPTCHA solution. Options considered were Google reCAPTCHA, hCaptcha, and Cloudflare Turnstile. Key requirements are strong bot protection, low or no cost, and user privacy.

Google reCAPTCHA was not chosen due to its user tracking and data collection practices. 

hCaptcha was considered but not chosen because, while it is free for most use cases, it still collects some user data and displays third-party branding.

Cloudflare Turnstile offers a more privacy-focused experience with minimal branding.

---

**Decision:**

We will use *Cloudflare Turnstile* for CAPTCHA on sign-up and sign-in forms.

---

**Consequences:**

*   **Pros:**
    *   Free to use.
    *   No user tracking; privacy-focused.
    *   Easy to integrate with static sites and AWS Lambda.
    *   Minimal branding (removable only with Enterprise plan).

*   **Cons:**
    *   Newer, less widely recognized than Google reCAPTCHA.
    *   Requires a small backend (AWS Api Gateway & Lambda) for token verification.

---
