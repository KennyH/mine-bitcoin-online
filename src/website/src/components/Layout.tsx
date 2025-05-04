'use client';

import { ReactNode } from "react";
import PageHeader from './PageHeader';
import PageBanner from './PageBanner';
import PageFooter from './PageFooter';

type LayoutProps = {
  children: ReactNode;
  showBanner?: boolean;
  showTagline?: boolean;
  showStartButton?: boolean;
};

export default function Layout({ children, showBanner = true, showTagline = false, showStartButton = true }: LayoutProps) {
  function renderBanner() {
    if (!showBanner) return null;
    return <PageBanner showTagline={showTagline} />;
  }

  return (
    <div className="min-h-screen flex flex-col bg-[#0a0c10] text-[#e0e6ed] font-sans">
      <PageHeader showStartButton={showStartButton} />
      { renderBanner() }
      <main className="flex-grow w-full max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {children}
      </main>
      <PageFooter />
    </div>
  );
}
