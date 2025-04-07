export default function Home() {
  return (
    <div className="bg-[#121212] text-white font-inter min-h-screen">
      <header className="bg-gradient-to-r from-orange-500 to-pink-600 text-center py-16 px-4">
        <h1 className="text-5xl font-bold">Bitcoin Browser Miner</h1>
        <p className="text-xl opacity-90 mt-2">
          Use your browser to join the Bitcoin mining lottery—learn, explore, and even win!
        </p>
      </header>

      <nav className="bg-gray-800 py-4 text-center space-x-4">
        <a href="#about" className="hover:text-orange-500">About</a>
        <a href="#how-it-works" className="hover:text-orange-500">How It Works</a>
        <a href="#contact" className="hover:text-orange-500">Contact</a>
      </nav>

      <main className="max-w-3xl mx-auto py-12 px-4 space-y-8">
        <section id="about" className="bg-gray-800 rounded-lg shadow-lg p-6">
          <h2 className="text-orange-500 text-2xl border-b-2 border-orange-500 inline-block mb-4">
            About the Project
          </h2>
          <p>
            This is an innovative, educational project allowing users to participate in Bitcoin mining using their browser through WebAssembly technology. The goal is to offer users an easy, engaging way to learn about blockchain technology, Bitcoin mining, and decentralization. It's like entering a lottery—you might win!
          </p>
        </section>

        <section id="how-it-works" className="bg-gray-800 rounded-lg shadow-lg p-6">
          <h2 className="text-orange-500 text-2xl border-b-2 border-orange-500 inline-block mb-4">
            How It Works
          </h2>
          <ul className="list-disc list-inside space-y-2">
            <li>Your browser utilizes WebAssembly to attempt solving the current Bitcoin block.</li>
            <li>The likelihood of success is very low—but it's possible!</li>
            <li>If you successfully mine the block, you'll receive the full Bitcoin block reward and mining fees, minus a 5% administrative fee and any applicable tax withholdings.</li>
            <li>Successful miners will be directly contacted to facilitate the reward transfer.</li>
          </ul>
        </section>

        <section id="contact" className="bg-gray-800 rounded-lg shadow-lg p-6">
          <h2 className="text-orange-500 text-2xl border-b-2 border-orange-500 inline-block mb-4">
            Contact
          </h2>
          <p>Email: info@bitcoinbrowserminer.com</p>
          <p>Discord: Join our community channel (Coming soon)</p>
        </section>
      </main>

      <footer className="bg-gray-900 text-center py-4 fixed bottom-0 w-full opacity-80">
        &copy; 2025 Bitcoin Browser Miner. All rights reserved.
      </footer>
    </div>
  );
}
