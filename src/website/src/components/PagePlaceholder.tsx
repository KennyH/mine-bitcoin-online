"use client";

import Layout from './Layout';

type PagePlaceholderProps = {
    title: string;
    showBanner?: boolean;
    showTagline?: boolean;
};

export default function PagePlaceholder({ title, showBanner, showTagline }: PagePlaceholderProps){
  return (
    <Layout showBanner={showBanner} showTagline={showTagline}>
      <div className="flex flex-col items-center justify-center min-h-[60vh]">
        <h1 className="text-2xl font-bold mb-2">{title}</h1>
        <p className="text-gray-400">This page is under construction.</p>
      </div>
    </Layout>
  )
}
