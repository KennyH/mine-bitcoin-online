// import Link from 'next/link';
import { useLayoutContext } from '@/context/LayoutContext';
import { Section, Outbound } from '../../components/PageComponents';

export default function PrivacyPage() {
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

      {/* Main Privacy container */}
      <div className="w-full max-w-3xl space-y-8">
        {/* HEADER */}
        <header className="space-y-1">
          <h1 className="text-3xl font-extrabold tracking-tight">
            Bitcoin Browser Miner – Privacy Policy
          </h1>
          <p className="text-sm italic text-gray-400">Last updated: May 7, 2025</p>
        </header>

        {/* 1. Overview */}
        <Section title="1. Overview of the Privacy Policy">
          <p>
            Under Construction. <Outbound href="https://github.com/KennyH/mine-bitcoin-online">GitHub</Outbound>.
          </p>
        </Section>

        <hr className="border-[#23233a]" />

      </div>
    </div>
  );
}
