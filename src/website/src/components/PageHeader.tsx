import { useState } from "react";
import Head from "next/head";
import Image from "next/image";
import Link from "next/link";
import { FaSearch, FaBars, FaTimes } from "react-icons/fa";

type NavLinkProps = {
  href: string;
  label: string;
  show?: "md" | "lg";
  className?: string;
};

const navLinks: NavLinkProps[] = [
  { href: "/get-started", label: "Get Started", show: "md" },
  { href: "/docs/learn", label: "Learn", show: "lg" },
  { href: "/docs/faq", label: "FAQ", show: "lg" },
];

function NavLink({ href, label, show, className = "", ...props }: NavLinkProps) {
  let visibility = "";
  if (show === "md") visibility = "hidden md:inline";
  else if (show === "lg") visibility = "hidden lg:inline";
  else visibility = "inline";

  return (
    <Link
      href={href}
      className={`${visibility} text-white font-medium hover:text-[#00eaff] transition-colors ${className}`}
      {...props}
    >
      {label}
    </Link>
  );
}

export default function PageHeader() {
  const [menuOpen, setMenuOpen] = useState(false);

  return (
    <>
      <Head>
        <title>Bitcoin Browser Miner</title>
      </Head>
      <header className="w-full border-b border-[#23233a] bg-[#181a20] z-50">
        <div className="relative max-w-4xl mx-auto flex items-center justify-between px-4 py-3">
          {/* Logo and Title */}
          <Link href="/" className="flex items-center gap-2 group z-20 min-w-0">
            <Image
              src="/images/bitcoin.png"
              alt="Bitcoin Logo"
              width={32}
              height={32}
              className="rounded w-8 h-8 sm:w-7 sm:h-7 md:w-8 md:h-8"
            />
            {/* Desktop/Tablet Title */}
            <span className="truncate font-bold text-white group-hover:text-[#00eaff] transition-colors text-xl sm:text-lg md:text-xl hidden md:inline">
              Bitcoin Browser Miner
            </span>
            {/* Mobile Title */}
            <span className="truncate font-bold text-white group-hover:text-[#00eaff] transition-colors text-base sm:text-lg md:text-xl inline md:hidden">
              BTC Browser Miner
            </span>
          </Link>

          {/* Center: Start Mining Button (md+) */}
          <div className="hidden md:block absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2">
            <Link
              href="/start"
              className="bg-gradient-to-br from-[#f7931a] via-[#1a1a2e] to-[#f7931a] text-white font-semibold px-2 py-2 rounded shadow hover:scale-105 transition-transform"
            >
              Start Mining
            </Link>
          </div>

          {/* Right: Nav links, Start Mining (on <md), search, hamburger */}
          <nav className="flex items-center gap-5 z-20">
            {/* Map over navLinks */}
            {navLinks.map((link) => (
              <NavLink key={link.href} {...link} />
            ))}

            {/* Start Mining reduced to Start (on <md) */}
            <Link
              href="/start"
              className="md:hidden bg-gradient-to-br from-[#f7931a] via-[#1a1a2e] to-[#f7931a] text-white font-semibold px-1 py-2 rounded shadow hover:scale-105 transition-transform"
            >
              Start
            </Link>

            {/* Search always visible */}
            <Link
              href="/search"
              className="p-2 rounded hover:bg-[#23233a] transition"
              aria-label="Search"
            >
              <FaSearch className="text-white text-lg" />
            </Link>

            {/* Hamburger menu: visible if "Learn" is hidden (at <lg) */}
            <button
              className="p-2 ml-1 rounded hover:bg-[#23233a] transition lg:hidden"
              aria-label="Open menu"
              onClick={() => setMenuOpen(true)}
            >
              <FaBars className="text-white text-lg" />
            </button>
          </nav>

          {/* Hamburger menu overlay */}
          {menuOpen && (
            <div className="fixed inset-0 bg-black bg-opacity-80 z-40 flex flex-col items-center justify-center">
              <button
                className="absolute top-4 right-4 p-2 rounded hover:bg-[#23233a] transition"
                aria-label="Close menu"
                onClick={() => setMenuOpen(false)}
              >
                <FaTimes className="text-white text-2xl" />
              </button>
              {/* Show all links in mobile menu */}
              {navLinks.map((link) => (
                <Link
                  key={link.href}
                  href={link.href}
                  className="mb-4 text-white text-lg font-medium hover:text-[#00eaff] transition-colors"
                  onClick={() => setMenuOpen(false)}
                >
                  {link.label}
                </Link>
              ))}
            </div>
          )}
        </div>
      </header>
    </>
  );
}
