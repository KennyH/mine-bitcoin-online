'use client';

import Link from 'next/link';
import { useLayoutContext } from '@/context/LayoutContext';
import { Section, Outbound } from '../../components/PageComponents';

export default function TosPage() {
  const layout = useLayoutContext();

  return (
    <div className="flex flex-col items-center px-4 py-12 min-h-[60vh] text-[#e0e6ed]">
      {/* Optional banner & tagline */}
      {layout?.showBanner && (
        <div className="mb-6 text-center text-sm font-semibold text-[#00eaff]">
          {layout.showBanner}
        </div>
      )}
      {layout?.showTagline && (
        <div className="mb-8 text-center text-xs text-gray-400">
          {layout.showTagline}
        </div>
      )}

      {/* Main TOS container */}
      <div className="w-full max-w-3xl space-y-8">
        {/* HEADER */}
        <header className="space-y-1">
          <h1 className="text-3xl font-extrabold tracking-tight">
            Bitcoin Browser Miner – Terms of Service
          </h1>
          <p className="text-sm italic text-gray-400">Last updated: May 4, 2025</p>
        </header>

        {/* 1. Overview */}
        <Section title="1. Overview of the Service">
          <p>
            Bitcoin Browser Miner lets registered users log in and run JavaScript/WebAssembly (WASM) code in their web
            browsers to attempt to mine Bitcoin by hashing candidate block templates supplied by our backend (see{' '}
            <Outbound href="https://github.com/KennyH/mine-bitcoin-online/blob/main/docs/adr/ADR-001-candidate-block-publishing-and-notification.md">ADR‑001</Outbound>
            ). <strong>The Service is provided primarily for educational and demonstrative purposes.</strong>
          </p>
          <p>
            The complete source code for both the frontend miner and backend infrastructure is published under the{' '}
            <Outbound href="https://www.apache.org/licenses/LICENSE-2.0">Apache License 2.0</Outbound> at{' '}
            <Outbound href="https://github.com/KennyH/mine-bitcoin-online">github.com</Outbound>. While that license grants you broad rights to inspect, copy,
            modify, and redistribute the code, use of the <em>live hosted Service</em> remains subject to the additional terms and risk disclosures below.
          </p>
        </Section>

        {/* 2. Eligibility */}
        <Section title="2. Eligibility and Account Registration">
          <p>
            You must be at least 18 years old and legally able to enter into contracts to create an account. When you
            register you must provide accurate information and keep it up to date. You are responsible for maintaining
            the confidentiality of your login credentials and for all activities that occur under your account.
          </p>
        </Section>

        {/* 3. Odds */}
        <Section title="3. Astronomical Odds of Success">
          <p>
            Mining Bitcoin with a typical consumer browser is <strong>extraordinarily unlikely</strong> to solve a valid
            main‑net block. <strong>Statistically, the odds approach zero.</strong> <strong>You should expect to earn nothing.</strong>{' '}
            Any hash‑rate, profit, or reward figures displayed by the Service are theoretical estimates only and are{' '}
            <strong>not a guarantee of income</strong>.
          </p>
        </Section>

        {/* 4. Educational */}
        <Section title="4. Educational Use; No Professional Advice">
          <p>
            The Service, documentation, blog posts, ADRs, code samples, and all related content are offered solely for
            general information and educational purposes. <strong>Nothing in the Service constitutes financial, legal,
            tax, or investment advice.</strong> You should consult qualified professionals before making decisions based
            on any information obtained through the Service.
          </p>
        </Section>

        {/* 5. Risks */}
        <Section title="5. User Risks and Waiver of Liability">
          <p>
            Running miner code may increase CPU usage, battery drain, power consumption, device temperature, and fan
            noise, and could shorten hardware life. Although we test our software, <strong>we do not guarantee it is
            free of defects or security vulnerabilities.</strong>
          </p>
          <ul className="list-disc list-inside space-y-2">
            <li>Accept all risks associated with running the miner.</li>
            <li>
              Agree that the Service is provided “AS IS” and “AS AVAILABLE” <strong>without any warranty of any kind</strong>.
            </li>
            <li>
              <strong>Waive and release</strong> Bitcoin Browser Miner and its owners, developers, employees, and agents
              from all claims, losses, and damages arising out of or related to your use of the Service.
            </li>
          </ul>
        </Section>

        {/* 6. Rewards */}
        <Section title="6. Block Reward Distribution & Fees">
          <p>
            If a main‑net block is successfully mined through the Service (see{' '}
            <Outbound href="https://github.com/KennyH/mine-bitcoin-online/blob/main/docs/adr/ADR-002-block-reward-distribution-and-user-payout.md">ADR‑002</Outbound>):
          </p>
          <ol className="list-decimal list-inside space-y-2">
            <li>The full coinbase reward is paid to a pool wallet controlled by Provider.</li>
            <li><strong>Provider retains a five‑percent (5 %) fee</strong>.</li>
            <li>The remaining 95 % (minus taxes) is paid to the winning user after a 100‑block maturity (~16 hours).</li>
            <li>Payout may be manual, multisig, or smart‑contract based at Provider’s discretion.</li>
            <li>You are solely responsible for any taxes on payouts.</li>
          </ol>
        </Section>

        {/* 7. Acceptable Use */}
        <Section title="7. Acceptable Use">
          <p>
            The code is open source under Apache 2.0 (see{' '}
            <Outbound href="https://github.com/KennyH/mine-bitcoin-online/blob/main/docs/adr/ADR-003-browser-miner-implementation-initial-phase.md">ADR‑003</Outbound>). When connecting to the
            hosted Service you <strong>must not</strong>:
          </p>
          <ul className="list-disc list-inside space-y-2">
            <li>Redirect rewards, falsify shares, or otherwise compromise fairness.</li>
            <li>Use the Service to violate law or third‑party rights.</li>
            <li>Gain unauthorized access to servers or data.</li>
            <li>Interfere with security, integrity, or performance.</li>
          </ul>
        </Section>

        {/* 8. IP */}
        <Section title="8. Intellectual‑Property and Licensing">
          <p>
            Source code is licensed under Apache 2.0. Branding and non‑code content remain Provider’s property; you may
            not use them without permission.
          </p>
        </Section>

        {/* 9. Privacy */}
        <Section title="9. Privacy">
          <p>
            Your use of the Service is also governed by our <Link href="/docs/privacy" className="underline">Privacy Policy</Link>, which explains what
            personal data we collect, how we use it, and your rights and choices. By using the Service you consent to
            those data practices.
          </p>
        </Section>

        {/* 10. Warranty */}
        <Section title="10. No Warranty">
          <p>
            <strong>
              THE SERVICE IS PROVIDED “AS IS” AND “AS AVAILABLE.” PROVIDER EXPRESSLY DISCLAIMS ALL WARRANTIES, WHETHER
              EXPRESS, IMPLIED, STATUTORY, OR OTHERWISE, INCLUDING WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
              PARTICULAR PURPOSE, TITLE, AND NON‑INFRINGEMENT.
            </strong> Provider does not warrant that the Service will be uninterrupted, secure, or error‑free.
          </p>
        </Section>

        {/* 11. Liability */}
        <Section title="11. Limitation of Liability">
          <p>TO THE MAXIMUM EXTENT PERMITTED BY LAW, PROVIDER’S TOTAL LIABILITY FOR ANY CLAIM ARISING OUT OF OR RELATED TO THESE TERMS OR THE SERVICE WILL NOT EXCEED <strong>US $100</strong>. IN NO EVENT WILL PROVIDER BE LIABLE FOR INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, OR ANY LOSS OF PROFITS, DATA, OR GOODWILL.</p>
        </Section>

        {/* 12. Indemnification */}
        <Section title="12. Indemnification">
          <p>You agree to defend, indemnify, and hold harmless Provider from and against all claims, liabilities, damages, losses, and expenses (including reasonable attorneys’ fees) arising out of or relating to your use of the Service or violation of these Terms.</p>
        </Section>
        
        {/* 13. Modifications */}
        <Section title="13. Modification of the Terms">
          <p>Provider may update these Terms at any time by posting a revised version on the website or within the Service. Material changes take effect <strong>30 days</strong> after posting. Your continued use of the Service after the effective date constitutes acceptance of the revised Terms.</p>
        </Section>

        {/* 14. Suspension */}
        <Section title="14. Suspension and Termination">
          <p>You may stop using the Service at any time. Provider may suspend or terminate the Service or your account, or remove or disable content, if we reasonably believe you violate these Terms or applicable law, or if your use poses a security risk or legal liability.</p>
        </Section>

        {/* 15. Governing Law */}
        <Section title="15. Governing Law &amp; Dispute Resolution">
          <p>These Terms are governed by the laws of the State of Washington, USA, without regard to its conflict‑of‑law rules. Any dispute that cannot be resolved informally will be settled <strong>exclusively by binding arbitration</strong> in Seattle, Washington, under the Commercial Arbitration Rules of the American Arbitration Association. YOU AND PROVIDER WAIVE THE RIGHT TO A JURY TRIAL AND TO PARTICIPATE IN CLASS ACTIONS.</p>
        </Section>

        {/* 16. Severability */}
        <Section title="16. Severability; Entire Agreement">
        <p>If any provision of these Terms is held invalid or unenforceable, the remaining provisions remain in full force. These Terms (together with the Privacy Policy) constitute the entire agreement between you and Provider regarding the Service and supersede all prior agreements or understandings.</p>
        </Section>

        {/* 17. Contact */}
        <Section title="17. Contact">
          <p>
            Questions about these Terms? Email{' '}
            <Outbound href="mailto:legal@bitcoinbrowserminer.com">
              legal@bitcoinbrowserminer.com
            </Outbound>
            .
          </p>
        </Section>

        <hr className="border-[#23233a]" />
        <p className="text-center font-semibold">
          By clicking “I Agree” or creating an account, you acknowledge that you have read, understood, and agree to be
          bound by these Terms.
        </p>
      </div>
    </div>
  );
}
