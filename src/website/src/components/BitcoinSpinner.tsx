import React from 'react';
import Image from 'next/image';

interface BitcoinSpinnerProps {
  size?: number;
  speed?: number; // Tailwind default spin is 1s linear
  alt?: string;
  className?: string;
  animateOnLoad?: boolean;
  dropDuration?: number;
}

export default function BitcoinSpinner({
  size = 50,
  speed = 1,
  alt = "Loading...",
  className = "",
}: BitcoinSpinnerProps){
  return (
    <Image
      src="/images/bitcoin-lg.png"
      alt={alt}
      width={size}
      height={size}
      className={`animate-spin ${className}`}
      style={{ animationDuration: `${speed}s` }}
      priority
      unoptimized={false}
    />
  );
}
