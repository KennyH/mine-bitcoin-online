'use client';

import React from "react";

export default function Modal({
  open,
  onClose,
  children,
}: {
  open: boolean;
  onClose: () => void;
  children: React.ReactNode;
}) {
  if (!open) return null;
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-60">
      <div className="bg-[#181a20] rounded-lg shadow-lg p-6 min-w-[320px] max-w-[90vw]">
        <button
          className="absolute top-4 right-4 text-white text-5xl p-3 rounded-full hover:bg-[#23233a] transition-all flex items-center justify-center"
          onClick={onClose}
          aria-label="Close"
        >
          ×
        </button>
        {children}
      </div>
    </div>
  );
}
