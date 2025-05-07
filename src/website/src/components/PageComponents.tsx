import type { ReactNode } from 'react';

/**
 * Reusable section block with orange heading + spacing
 */
export function Section({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="space-y-4">
      <h2 className="text-xl font-bold text-[#f7931a] border-b-2 border-[#f7931a] inline-block pb-1">
        {title}
      </h2>
      {children}
    </section>
  );
}

/**
 * Simple external‑link wrapper: opens in new tab + consistent styling
 */
export function Outbound({ href, children }: { href: string; children: ReactNode }) {
  return (
    <a
      href={href}
      target="_blank"
      rel="noopener noreferrer"
      className="underline text-[#00eaff] hover:text-[#f7931a] transition-colors"
    >
      {children}
    </a>
  );
}