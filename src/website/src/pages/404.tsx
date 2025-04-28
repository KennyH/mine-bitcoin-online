import Link from 'next/link';

export default function Custom404() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-[#0a0c10] text-[#e0e6ed] font-sans px-4">
      <h1 className="text-2xl font-bold mb-2">
        404 - Not Found
      </h1>
      <p className="text-lg mb-8 text-center">
        These aren't the droids you're looking for.
      </p>
      <Link href="/" passHref legacyBehavior>
          <a className="bg-gradient-to-br from-[#f7931a] via-[#1a1a2e] to-[#f7931a] text-white font-semibold px-1 py-2 rounded shadow hover:scale-105 transition-transform">
            Go Home
          </a>
      </Link>
    </div>
  );
}
