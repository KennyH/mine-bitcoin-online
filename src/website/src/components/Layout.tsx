import { ReactNode } from "react";
import PageHeader from './PageHeader';
import PageBanner from './PageBanner';
import PageFooter from './PageFooter';

type LayoutProps = {
  children: ReactNode;
  showBanner?: boolean;
  showTagline?: boolean;
};

export default function Layout({ children, showBanner = true, showTagline = false }: LayoutProps) {
  function renderBanner() {
    if (!showBanner) return null;
    return <PageBanner showTagline={showTagline} />;
  }

  return (
    <div className="min-h-screen flex flex-col bg-[#0a0c10] text-[#e0e6ed] font-sans">
      <PageHeader />
      { renderBanner() }
      {children}
      <PageFooter />
    </div>
  );
}
