"use client";

import { useLayoutContext } from '@/context/LayoutContext';

type PagePlaceholderProps = {
    title: string;
};

export default function PagePlaceholder({ title }: PagePlaceholderProps) {
  const layout = useLayoutContext();
  return (
    <div className="flex flex-col items-center justify-center min-h-[60vh]">
      <h1 className="text-2xl font-bold mb-2">{title}</h1>
      <p className="text-gray-400">
        {layout.showBanner}
        {layout.showTagline}
        This page is under construction.
      </p>
    </div>
  )
}
