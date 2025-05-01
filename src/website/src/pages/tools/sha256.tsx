'use client'

import { useEffect, useRef, useState, useCallback } from 'react';

/* --- Compact SHA-256 that emits per-round digests ---------------------- */

const rotr = (x: number, n: number): number => (x >>> n) | (x << (32 - n));
const shr = (x: number, n: number): number => x >>> n;

const Σ0 = (x: number): number => rotr(x, 2) ^ rotr(x, 13) ^ rotr(x, 22);
const Σ1 = (x: number): number => rotr(x, 6) ^ rotr(x, 11) ^ rotr(x, 25);
const σ0 = (x: number): number => rotr(x, 7) ^ rotr(x, 18) ^ shr(x, 3);
const σ1 = (x: number): number => rotr(x, 17) ^ rotr(x, 19) ^ shr(x, 10);

const Ch = (x: number, y: number, z: number): number => (x & y) ^ (~x & z);
const Maj = (x: number, y: number, z: number): number =>
  (x & y) ^ (x & z) ^ (y & z);

/** SHA-256 Round Constants (K) */
const K = /* 64 */ Uint32Array.from([
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1,
    0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786,
    0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
    0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
    0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
    0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
  ]);

/** Initial Hash Values (H) */
const H_INIT = Uint32Array.from([
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c,
    0x1f83d9ab, 0x5be0cd19,
  ]
);
  
type Frame = {
    w: Uint32Array;
    a: number;
    b: number;
    c: number;
    d: number;
    e: number;
    f: number;
    g: number;
    h: number;
};
  
  /** returns {frames, digestHex} */
export function sha256Trace(msg: Uint8Array): {
    frames: Frame[];
    digestHex: string;
  } {
    /* --- Padding --- */
    const l = msg.length * 8; // Original message length in bits
    // Calculate k: number of zero bits needed (excluding the 0x80 bit and the 64-bit length)
    // so that (l + 1 + k + 64) is a multiple of 512
    const k = (448 - ((l + 1) % 512) + 512) % 512;
    // Total padded length in bytes: (l + 1 + k + 64) / 8
    // Ensure length is multiple of 4 bytes for DataView alignment
    const paddedByteLength = (l + 1 + k + 64) / 8;
    const padded = new Uint8Array(paddedByteLength);
  
    padded.set(msg); // Copy original message
    padded[msg.length] = 0x80; // Append '1' bit (0x80 byte)
  
    // Append 64-bit message length (big-endian)
    const dv = new DataView(padded.buffer);
    // Set upper 32 bits of length (assuming l < 2^32)
    dv.setUint32(padded.length - 8, 0, false);
    // Set lower 32 bits of length
    dv.setUint32(padded.length - 4, l >>> 0, false);
  
    /* --- Initialization --- */
    const H = H_INIT.slice(); // Use a mutable copy of initial hash values
    const frames: Frame[] = [];
  
    /* --- Processing --- */
    // Process message in 512-bit (64-byte) chunks
    for (let off = 0; off < padded.length; off += 64) {
      const w = new Uint32Array(64); // Message schedule for this chunk
  
      // 1. Prepare the message schedule (W)
      // a. Copy first 16 words from the chunk
      for (let t = 0; t < 16; ++t) {
        w[t] = dv.getUint32(off + t * 4, false); // Read as big-endian
      }
      // b. Extend the first 16 words into the remaining 48 words
      for (let t = 16; t < 64; ++t) {
        const s0 = σ0(w[t - 15]);
        const s1 = σ1(w[t - 2]);
        // Use `>>> 0` for correct 32-bit unsigned addition
        w[t] = (w[t - 16] + s0 + w[t - 7] + s1) >>> 0;
      }
  
      // 2. Initialize working variables for this chunk
      // Use the *current* hash values (H)
      let a = H[0];
      let b = H[1];
      let c = H[2];
      let d = H[3];
      let e = H[4];
      let f = H[5];
      let g = H[6];
      let h = H[7];
  
      // 3. Main round loop
      for (let t = 0; t < 64; ++t) {
        const S1 = Σ1(e);
        const ch = Ch(e, f, g);
        const temp1 = (h + S1 + ch + K[t] + w[t]) >>> 0; // Use compact functions
        const S0 = Σ0(a);
        const maj = Maj(a, b, c);
        const temp2 = (S0 + maj) >>> 0; // Use compact functions
  
        // Update working variables
        h = g;
        g = f;
        f = e;
        e = (d + temp1) >>> 0;
        d = c;
        c = b;
        b = a;
        a = (temp1 + temp2) >>> 0;
  
        // Capture frame AFTER this round's state is calculated
        // Note: This stores the *entire* 64-word 'w' schedule in *every* frame.
        // Might need to adjust the 'Frame' type and this push if it is too much data.
        frames.push({ w: w.slice(), a, b, c, d, e, f, g, h }); // Push a copy of w
      }
  
      // 4. Compute intermediate hash value for this chunk
      H[0] = (H[0] + a) >>> 0;
      H[1] = (H[1] + b) >>> 0;
      H[2] = (H[2] + c) >>> 0;
      H[3] = (H[3] + d) >>> 0;
      H[4] = (H[4] + e) >>> 0;
      H[5] = (H[5] + f) >>> 0;
      H[6] = (H[6] + g) >>> 0;
      H[7] = (H[7] + h) >>> 0;
    }
  
    /* --- Finalization --- */
    const digestHex = [...H].map((x) => x.toString(16).padStart(8, "0")).join("");
    return { frames, digestHex };
  }

/* ------------------------------------------------------------------------ */
/* Canvas visualizer                                                      */

function Sha256Canvas() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [msg, setMsg] = useState("The quick brown fox jumps over the lazy dog");
  const [frameIdx, setFrameIdx] = useState(0);
  const [frames, setFrames] = useState<Frame[]>([]);
  const [digest, setDigest] = useState("");
  const [isAutoPlaying, setIsAutoPlaying] = useState(false); // Track auto-play state

  // Refs to store timer IDs
  const autoSlideTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const autoSlideIntervalRef = useRef<NodeJS.Timeout | null>(null);

  const cell = 4; // px per bit
  const cols = 512; // we’ll only draw first 512 bits for now
  // const height = 100; 

  // --- Effect 1: Run SHA-256 calculation when message changes ---
  useEffect(() => {
    // Clear any pending/active auto-slide timers when msg changes
    if (autoSlideTimeoutRef.current) clearTimeout(autoSlideTimeoutRef.current);
    if (autoSlideIntervalRef.current) clearInterval(autoSlideIntervalRef.current);
    setIsAutoPlaying(false); // Stop auto-play

    // Perform the hashing
    const { frames: fr, digestHex } = sha256Trace(
      new TextEncoder().encode(msg || ""), // Handle empty string case
    );
    setFrames(fr);
    setDigest(digestHex);
    setFrameIdx(0); // Reset slider to the beginning
    // Auto-sliding will be triggered by the effect below watching 'frames'
  }, [msg]);

  // --- Effect 2: Draw on canvas when frame index or frames change ---
  useEffect(() => {
    if (!canvasRef.current || frames.length === 0 || frameIdx >= frames.length)
      return;

    const ctx = canvasRef.current.getContext("2d")!;
    ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);
    const f = frames[frameIdx];

    /* draw a 512-bit row from the schedule */
    for (let i = 0; i < cols; ++i) {
      // Ensure we don't read past the 16 words usually visualized
      const wordIdx = i >> 5;
      if (wordIdx >= f.w.length) continue; // Safety check

      const word = f.w[wordIdx];
      const bit = (word >>> (31 - (i & 31))) & 1;
      ctx.fillStyle = bit ? "#00eaff" : "#033c44";
      ctx.fillRect(i * cell, 0, cell, cell);
    }

    /* draw a–h bars */
    const regs = [f.a, f.b, f.c, f.d, f.e, f.f, f.g, f.h];
    regs.forEach((val, idx) => {
      const y = 20 + idx * 10;
      ctx.fillStyle = "#08909d";
      // Ensure val is treated as unsigned 32-bit for percentage calculation
      const percentage = (val >>> 0) / 0xffffffff;
      ctx.fillRect(0, y, percentage * cols * cell, 6);
      ctx.fillStyle = "#e0e6ed";
      ctx.fillText("abcdefgh"[idx], cols * cell + 4, y + 6);
    });
  }, [frameIdx, frames, cell, cols]); // Dependencies: redraw when these change

  // --- Function to stop auto-sliding ---
  const stopAutoSlide = useCallback(() => {
    if (autoSlideTimeoutRef.current) clearTimeout(autoSlideTimeoutRef.current);
    if (autoSlideIntervalRef.current) clearInterval(autoSlideIntervalRef.current);
    setIsAutoPlaying(false);
  }, []); // No dependencies, safe to memoize

  // --- Effect 3: Handle auto-sliding ---
  useEffect(() => {
    // Don't start if there are no frames
    if (frames.length === 0) {
      stopAutoSlide();
      return;
    }

    // Start the initial delay timer
    autoSlideTimeoutRef.current = setTimeout(() => {
      setIsAutoPlaying(true);
      // Start the interval timer after the delay
      autoSlideIntervalRef.current = setInterval(() => {
        setFrameIdx((prevIdx) => {
          const nextIdx = prevIdx + 1;
          // If we reached the end, stop the interval
          if (nextIdx >= frames.length) {
            if (autoSlideIntervalRef.current)
              clearInterval(autoSlideIntervalRef.current);
            setIsAutoPlaying(false);
            return prevIdx; // Stay at the last frame
          }
          return nextIdx; // Otherwise, move to the next frame
        });
      }, 500); // 500ms interval
    }, 1000); // 1000ms initial delay

    // Cleanup function: clear timers when component unmounts or 'frames' changes
    return () => {
      stopAutoSlide();
    };
  }, [frames, stopAutoSlide]); // Dependency: run when frames array changes

  // --- Handler for manual slider change ---
  const handleSliderChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    stopAutoSlide(); // Stop auto-play on manual interaction
    setFrameIdx(+e.target.value);
  };

  return (
    <div className="w-full max-w-full">
      {/* Input - No button needed */}
      <div className="flex items-center gap-2 my-4">
        <input
          value={msg}
          onChange={(e) => setMsg(e.target.value)}
          placeholder="Enter message to hash..."
          className="flex-1 p-2 bg-[#122126] text-[#e0f3f7] border border-[#28444a] rounded"
        />
        {/* Optional: Add a play/pause button maybe? For now, interaction stops it. */}
      </div>

      <canvas
        ref={canvasRef}
        width={cols * cell + 60} // Add space for labels
        height={120} // Fixed height based on original
        className="border border-[#00eaff]/40"
      />

      {frames.length > 0 && (
        <>
          <input
            type="range"
            min={0}
            max={frames.length - 1}
            value={frameIdx}
            onChange={handleSliderChange}
            className="w-full my-2"
            // Optional: Disable slider during auto-play?
            // disabled={isAutoPlaying}
          />
          <p className="text-sm text-gray-400">
            Round {frameIdx + 1}/{frames.length}
            {isAutoPlaying ? " (Auto-playing)" : ""}
            &nbsp;&nbsp;|&nbsp;&nbsp;Digest: <code>{digest}</code>
          </p>
        </>
      )}
    </div>
  );
}

/* ------------------------------------------------------------------------ */

export default function Sha256Page() {
  return (
    <>
      <div>
        <title>SHA-256 Visualizer</title>
      </div>
      <main className="flex flex-col items-center justify-center min-h-[60vh] text-[#e0e6ed]">
        <h1 className="text-3xl font-bold mb-4">SHA-256 Visualizer</h1>
        <Sha256Canvas />
      </main>
    </>
  );
}