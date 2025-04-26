'use client';
import { useAuth } from './context/AmplifyAuthContext';
import FooterLinks from './components/FooterLinks';
import HeaderLinks from './components/HeaderLinks';

export default function Home() {
  const { user, email, loading, login, logout } = useAuth();

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-[#00eaff] text-2xl font-semibold">Loading...</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex flex-col bg-[#0a0c10] text-[#e0e6ed] font-sans">
      {/* HEADER */}
      <HeaderLinks/>
      <header className="w-full py-16 px-4 bg-gradient-to-br from-[#00eaff] via-[#1a1a2e] to-[#f7931a] text-center shadow-lg">
        <h1 className="text-5xl md:text-6xl font-extrabold tracking-tight text-white">
          Bitcoin Browser Miner
        </h1>
        <p className="text-xl md:text-2xl mt-4 opacity-90 max-w-2xl mx-auto">
          Use your browser to join the Bitcoin mining lottery—learn, explore, and even win!
        </p>
      </header>

      {/* NAV */}
      <nav className="w-full flex justify-center gap-8 py-6 bg-transparent text-lg font-medium border-b border-[#23233a]">
        <a href="#about" className="hover:text-[#00eaff] transition-colors">About</a>
        <a href="#how-it-works" className="hover:text-[#00eaff] transition-colors">How It Works</a>
        <a href="#contact" className="hover:text-[#00eaff] transition-colors">Contact</a>
      </nav>

      <main className="flex-1 w-full">
        {/* ABOUT SECTION */}
        <section id="about" className="w-full py-16 px-4 border-b border-[#23233a]">
          <div className="max-w-2xl mx-auto">
            <h2 className="text-2xl font-bold text-[#00eaff] mb-4 border-b-2 border-[#00eaff] inline-block">
              About the Project
            </h2>
            <p className="mt-2 text-lg">
              Currently under construction, this is an educational project allowing users to participate in Bitcoin mining using their browser through WebAssembly (Wasm) technology. The goal is to offer users an easy, engaging way to learn about blockchain technology, Bitcoin mining, and decentralization. It’s like entering a lottery—you might win!
            </p>
          </div>
        </section>

        {/* HOW IT WORKS SECTION */}
        <section id="how-it-works" className="w-full py-16 px-4 border-b border-[#23233a]">
          <div className="max-w-2xl mx-auto">
            <h2 className="text-2xl font-bold text-[#00eaff] mb-4 border-b-2 border-[#00eaff] inline-block">
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
            <h2 className="text-2xl font-bold text-[#00eaff] mb-4 border-b-2 border-[#00eaff] inline-block">
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

      {/* BOTTOM LINKS SECTION */}
      <FooterLinks />
    </div>
  );
}
