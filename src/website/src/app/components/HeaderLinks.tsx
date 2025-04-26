import Image from "next/image";
import Link from "next/link";
import { FaSearch } from "react-icons/fa";

export default function HeaderLinks() {
  return (
    <header className="w-full border-b border-[#23233a] bg-[#181a20]">
      <div className="relative max-w-4xl mx-auto flex items-center justify-between px-4 py-3">
        {/* Logo and Title */}
        <Link href="/" className="flex items-center gap-2 group">
          <Image
            src="/bitcoin.png"
            alt="Bitcoin Logo"
            width={32}
            height={32}
            className="rounded"
          />
          <span className="text-xl font-bold text-white group-hover:text-[#00eaff] transition-colors">
            Bitcoin Browser Miner
          </span>
        </Link>

        {/* Center: Start Mining Button */}
        <div className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2">
          <Link
            href="/start"
            className="bg-gradient-to-br from-[#f7931a] via-[#1a1a2e] to-[#f7931a] text-white font-semibold px-4 py-2 rounded shadow hover:scale-105 transition-transform"
          >
            Start Mining
          </Link>
        </div>

        {/* Right: Other Links */}
        <nav className="flex items-center gap-4 z-10">
          <Link
            href="/get-started"
            className="text-white font-medium hover:text-[#00eaff] transition-colors"
          >
            Get Started
          </Link>
          <Link
            href="/blog"
            className="text-white font-medium hover:text-[#00eaff] transition-colors"
          >
            Blog
          </Link>
          <Link
            href="/search"
            className="p-2 rounded hover:bg-[#23233a] transition"
            aria-label="Search"
          >
            <FaSearch className="text-white text-lg" />
          </Link>
        </nav>
      </div>
    </header>
  );
}
