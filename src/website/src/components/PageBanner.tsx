'use client';

type PageBannerProps = {
    showTagline?: boolean;
};

export default function PageBanner({ showTagline = false}: PageBannerProps) {
    const tagline = showTagline ? "Use your browser to join the Bitcoin mining lottery. Learn, explore, and maybe even win!" : "";
    return (
        <header className="w-full py-16 px-4 bg-gradient-to-br from-[#00eaff] via-[#1a1a2e] to-[#f7931a] text-center shadow-lg">
            <h1 className="noselect text-5xl md:text-6xl font-extrabold tracking-tight text-white">
            Bitcoin Browser Miner
            </h1>
            <p className="text-xl md:text-2xl mt-4 opacity-90 max-w-2xl mx-auto">
            {tagline}
            </p>
        </header>
    );
}
