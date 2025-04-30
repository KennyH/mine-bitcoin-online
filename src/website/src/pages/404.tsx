'use client';

import { useRouter } from 'next/router';
import Image from 'next/image';
import { useState } from 'react';

export default function Custom404() {
  const router = useRouter();
  const [loaded, setLoaded] = useState(false);

  return (
    <>
      <main className="flex flex-col min-h-[calc(100vh-200px)] items-center justify-center bg-[#0a0c10] text-[#e0e6ed] font-sans px-4 pt-12">
        <div className="w-full max-w-2xl flex flex-col items-center space-y-6">
          <div className={`transition-opacity duration-1000 ${loaded ? 'opacity-100' : 'opacity-0'}`}>
          <div className="transform transition-transform duration-500 ease-in-out hover:scale-105">
              <Image
                src="/images/droids.png"
                alt="Two lost robots in a desert with a Bitcoin theme"
                className="rounded-lg shadow-lg"
                width={800}
                height={533}
                onLoad={() => setLoaded(true)}
                priority
              />
            </div>
          </div>
          <h1 className="text-2xl font-bold mb-2">
            404 - Not Found
          </h1>
          <p className="text-lg mb-6 text-center">
            These aren’t the droids you’re looking for.
          </p>
          <button
            onClick={() => router.back()}
            className="noselect bg-gradient-to-br from-[#f7931a] via-[#1a1a2e] to-[#f7931a] text-white font-semibold px-6 py-3 rounded shadow hover:scale-105 active:scale-95 hover:shadow-lg active:shadow-sm transition-transform duration-300 ease-in-out"
          >
            Go Back
          </button>
        </div>
      </main>
    </>
  );
}
