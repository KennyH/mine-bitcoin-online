'use client';

import { useRouter } from 'next/router';
import PageHeader from '@/components/PageHeader';
import PageFooter from '@/components/PageFooter';

export default function Custom404() {
  const router = useRouter();

  return (
    <>
      <PageHeader/>
      <div className="min-h-screen flex flex-col items-center justify-center bg-[#0a0c10] text-[#e0e6ed] font-sans px-4">
        <h1 className="text-2xl font-bold mb-2">
          404 - Not Found
        </h1>
        <p className="text-lg mb-8 text-center">
          These aren’t the droids you're looking for.
        </p>
        <button
          onClick={() => router.back()}
          className="bg-gradient-to-br from-[#f7931a] via-[#1a1a2e] to-[#f7931a] text-white font-semibold px-1 py-2 rounded shadow hover:scale-105 transition-transform"
        >
          Go Back
        </button>
      </div>
      <PageFooter/>
    </>
  );
}
