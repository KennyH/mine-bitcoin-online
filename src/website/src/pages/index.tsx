'use client';

import { useCognitoUser } from '@/context/CognitoUserContext';

export default function Home() {
  const { loading } = useCognitoUser();
  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-[#f7931a] text-2xl font-semibold">Loading...</div>
      </div>
    );
  }

  return (
    <>
      <nav className="w-full flex justify-center gap-8 py-6 bg-transparent text-lg font-medium border-b border-[#23233a]">
        <a href="#about" className="hover:text-[#f7931a] transition-colors">About</a>
        <a href="#how-it-works" className="hover:text-[#f7931a] transition-colors">How It Works</a>
        <a href="#contact" className="hover:text-[#f7931a] transition-colors">Contact</a>
      </nav>

      <main className="flex-1 w-full">
        {/* ABOUT SECTION */}
        <section id="about" className="w-full py-16 px-4 border-b border-[#23233a]">
          <div className="max-w-2xl mx-auto">
            <h2 className="text-2xl font-bold text-[#f7931a] mb-4 border-b-2 border-[#f7931a] inline-block">
              About the Project
            </h2>
            <p className="mt-2 text-lg">
              Currently under construction, this is an educational project allowing users to participate in Bitcoin mining using their browser through WebAssembly (Wasm) technology. The goal is to offer users an easy, engaging way to learn about blockchain technology, Bitcoin mining, and decentralization. It’s like entering a lottery—you might even win!
            </p>
          </div>
        </section>

        {/* HOW IT WORKS SECTION */}
        <section id="how-it-works" className="w-full py-16 px-4 border-b border-[#23233a]">
          <div className="max-w-2xl mx-auto">
            <h2 className="text-2xl font-bold text-[#f7931a] mb-4 border-b-2 border-[#f7931a] inline-block">
              How It Works
            </h2>
            <ul className="list-disc list-inside space-y-2 text-lg">
              <li>Your browser utilizes Wasm to attempt solving the current Bitcoin block.</li>
              <li>The likelihood of success is very low—but it’s possible!</li>
              <li>If you successfully mine the block, you’ll receive the full Bitcoin block reward and mining fees, minus a 5% administrative fee and any applicable tax withholdings.</li>
              <li>Successful miners will be directly contacted to facilitate the reward transfer.</li>
            </ul>
          </div>
        </section>

        {/* CONTACT SECTION */}
        <section id="contact" className="w-full py-16 px-4">
          <div className="max-w-2xl mx-auto">
            <h2 className="text-2xl font-bold text-[#f7931a] mb-4 border-b-2 border-[#f7931a] inline-block">
              Contact
            </h2>
            <p className="text-lg">
              Email: <a href="mailto:info@bitcoinbrowserminer.com" className="text-[#00eaff] underline">info@bitcoinbrowserminer.com</a>
            </p>
            <p className="text-lg">
              Discord: <span className="opacity-70">Join our community channel (Coming soon)</span>
            </p>
          </div>
        </section>
      </main>
    </>
  );
}
