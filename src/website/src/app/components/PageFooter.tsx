import { FaGithub } from "react-icons/fa";
import { MdCheckCircle, MdLock } from "react-icons/md";

export default function PageFooter() {
  return (
    <section className="w-full border-t border-[#23233a] bg-[#0a0c10]">
      <div className="max-w-4xl mx-auto flex flex-col md:flex-row items-center justify-between gap-4 py-6 px-4 text-sm">
        {/* Links group */}
        <div className="flex flex-wrap items-center gap-2">
          <a
            href="https://github.com/KennyH/mine-bitcoin-online"
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center font-bold px-2 py-1 bg-[#0a0c10] text-white rounded-sm"
          >
            <FaGithub className="mr-1" /> GITHUB
          </a>
          <span className="text-[#23233a] mx-1">|</span>
          <a
            href="/privacy"
            className="flex items-center font-bold px-2 py-1 bg-[#0a0c10] text-white rounded-sm"
          >
            <MdLock className="mr-1" /> PRIVACY
          </a>
          <span className="text-[#23233a] mx-1">|</span>
          <a
            href="/status"
            className="flex items-center font-bold px-2 py-1 bg-[#0a0c10] text-white rounded-sm"
          >
            <MdCheckCircle className="mr-1" /> STATUS
          </a>
        </div>
        {/* Copyright */}
        <div className="text-xs opacity-60 text-white mt-4 md:mt-0">
          &copy; 2025 Bitcoin Browser Miner. All rights reserved.
        </div>
      </div>
    </section>
  );
}
