'use client';

import { useState, useEffect } from 'react';
import Head from 'next/head';
import Image from 'next/image';
import Link from 'next/link';
import { FaSearch, FaBars, FaTimes } from 'react-icons/fa';
import { useRouter } from 'next/router';
import SignUpModal from './SignUpModal';
import { useCognitoUser } from '@/context/CognitoUserContext';

type NavLinkProps = {
  href: string;
  label: string;
  show?: "md" | "lg";
  className?: string;
};

const navLinks: NavLinkProps[] = [
  { href: "/docs/learn", label: "Learn", show: "lg" },
  { href: "/docs/faq", label: "FAQ", show: "lg" },
  { href: "/search", label: "Search", show: "md" },
];

function NavLink({ href, label, show, className = "", ...props }: NavLinkProps) {
  let visibilityClass = "";
  if (show === "md") visibilityClass = "hidden md:inline-block";
  else if (show === "lg") visibilityClass = "hidden lg:inline-block";
  else visibilityClass = "inline-block";

  return (
    <Link
      href={href}
      className={`${visibilityClass} noselect text-white font-medium hover:text-[#f7931a] hover:scale-105 active:scale-95 hover:shadow-lg active:shadow-sm transition-[transform,box-shadow,colors] duration-300 ease-in-out ${className}`}
      {...props}
    >
      {label}
    </Link>
  );
}

type PageHeaderProps = {
  showStartButton?: boolean;
} 

export default function PageHeader({ showStartButton = true }: PageHeaderProps) {
  const [menuOpen, setMenuOpen] = useState(false);
  const [showSignUp, setShowSignUp] = useState(false);
  const [createdUser, setCreatedUser] = useState(false);
  const { user, loading, logout } = useCognitoUser();
  const router = useRouter();

  const handleLogout = (e: React.MouseEvent) => {
    e.preventDefault();
    logout();
    router.push('/');
  };

  // look at localstorage to see if user has signed up.
  useEffect(() => {
    const syncFlag = () =>
      setCreatedUser(localStorage.getItem("created_user") === "true");
  
    syncFlag();
    window.addEventListener("storage", syncFlag);
  
    return () => window.removeEventListener("storage", syncFlag);
  }, []);

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
              className="noselect rounded w-8 h-8 sm:w-7 sm:h-7 md:w-8 md:h-8"
            />
            {/* Desktop/Tablet Title */}
            <span className="noselect truncate font-bold text-white group-hover:text-[#f7931a] transition-colors text-xl sm:text-lg md:text-xl hidden md:inline">
              Bitcoin Browser Miner
            </span>
            {/* Mobile Title */}
            <span className="noselect truncate font-bold text-white group-hover:text-[#f7931a] transition-colors text-base sm:text-lg md:text-xl inline md:hidden">
              BTC Miner
            </span>
          </Link>

          {/* Center: Show only one button based on login state (md+) */}
          <div className="hidden md:block absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2">
            {!loading && user ? (
              showStartButton && (
                <Link
                  href="/start"
                  className="noselect inline-block bg-gradient-to-br from-[#f7931a] via-[#1a1a2e] to-[#f7931a] text-white font-semibold px-4 py-3 rounded shadow hover:scale-105 active:scale-95 hover:shadow-lg active:shadow-sm transition-[transform,box-shadow] duration-300 ease-in-out"
                >
                  Start Mining
                </Link>)
            ) : !loading ? (
              <button
                onClick={() => setShowSignUp(true)}
                className="noselect inline-block bg-gradient-to-br from-[#f7931a] via-[#1a1a2e] to-[#f7931a] text-white font-semibold px-4 py-3 rounded shadow hover:scale-105 active:scale-95 hover:shadow-lg active:shadow-sm transition-[transform,box-shadow] duration-300 ease-in-out"
              >
                Get Started
              </button>
            ) : null}
          </div>

          {/* Right: Nav links, Start/Logout (on <md), search (icon), hamburger */}
          <nav className="flex items-center gap-5 z-20">
            {navLinks.filter(l => l.label != "Search").map((link) => (
              <NavLink key={link.href} {...link} />
            ))}

            {/* Show Start or Get Started on mobile */}
            {!loading && user ? (
              showStartButton && (
                <Link
                  href="/start"
                  className="md:hidden noselect inline-block bg-gradient-to-br from-[#f7931a] via-[#1a1a2e] to-[#f7931a] text-white font-semibold px-4 py-3 rounded shadow hover:scale-105 active:scale-95 hover:shadow-lg active:shadow-sm transition-[transform,box-shadow] duration-300 ease-in-out"
                >
                  Start
                </Link>
              )
            ) : !loading ? (
              <button
                className="md:hidden noselect inline-block bg-gradient-to-br from-[#f7931a] via-[#1a1a2e] to-[#f7931a] text-white font-semibold px-2 py-3 rounded shadow hover:scale-105 active:scale-95 hover:shadow-lg active:shadow-sm transition-[transform,box-shadow] duration-300 ease-in-out"
                onClick={() => setShowSignUp(true)}
              >
                Get Started
              </button>
            ) : null}

            {/* Show Log out button on header only if logged in */}
            {!loading && user && (
              <button
                onClick={handleLogout}
                className="noselect text-white font-medium hover:text-[#f7931a] hover:scale-105 active:scale-95 hover:shadow-lg active:shadow-sm transition-[transform,box-shadow,colors] duration-300 ease-in-out"
              >
                Log out
              </button>
            )}

            {/* Search not visible on mobile */}
            <Link
              href="/search"
              className="hidden md:inline-block noselect p-2 rounded hover:bg-[#23233a] hover:scale-105 active:scale-95 hover:shadow-lg active:shadow-sm transition-[transform,box-shadow] duration-300 ease-in-out"
              aria-label="Search"
            >
              <FaSearch className="text-white text-lg" />
            </Link>

            {/* Hamburger menu: visible if "Learn" is hidden (at <lg) */}
            <button
              className="noselect p-2 ml-1 rounded hover:bg-[#23233a] lg:hidden inline-block hover:scale-105 active:scale-95 hover:shadow-lg active:shadow-sm transition-[transform,box-shadow] duration-300 ease-in-out"
              aria-label="Open menu"
              onClick={() => setMenuOpen(true)}
            >
              <FaBars className="text-white text-lg" />
            </button>
          </nav>

          <SignUpModal open={showSignUp} onClose={() => setShowSignUp(false)} createdUser={createdUser}/>

          {/* Hamburger menu overlay */}
          {menuOpen && (
            <div className="fixed inset-0 bg-black bg-opacity-80 z-40 flex flex-col items-center justify-center space-y-10">
              <button
                className="absolute top-4 right-4 p-2 rounded hover:bg-[#23233a] inline-block hover:scale-105 active:scale-95 hover:shadow-lg active:shadow-sm transition-[transform,box-shadow] duration-300 ease-in-out"
                aria-label="Close menu"
                onClick={() => setMenuOpen(false)}
              >
                <FaTimes className="text-white text-2xl" />
              </button>
              {/* Show nav links in mobile menu */}
              {navLinks.map((link) => (
                <Link
                  key={link.href}
                  href={link.href}
                  className="noselect text-white text-lg font-medium hover:text-[#f7931a] transition-colors"
                  onClick={() => setMenuOpen(false)}
                >
                  {link.label}
                </Link>
              ))}
              {/* Show Start/Logout or Get Started in mobile menu */}
              {!loading && user ? (
                <>
                  {showStartButton && (
                    <Link
                      href="/start"
                      className="noselect text-white text-lg font-medium hover:text-[#f7931a] transition-colors"
                      onClick={() => setMenuOpen(false)}
                    >
                      Start Mining
                    </Link>
                  )}
                  <button
                    onClick={(e) => {
                      setMenuOpen(false);
                      handleLogout(e);
                    }}
                    className="noselect text-white text-lg font-medium hover:text-[#f7931a] transition-colors"
                  >
                    Log out
                  </button>
                </>
              ) : !loading ? (
                <button
                  className="noselect text-white text-lg font-medium hover:text-[#f7931a] transition-colors"
                  onClick={() => {
                    setMenuOpen(false);
                    setShowSignUp(true);
                  }}
                >
                  Get Started
                </button>
              ) : null}
            </div>
          )}
        </div>
      </header>
    </>
  );
}
