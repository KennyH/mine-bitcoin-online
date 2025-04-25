import type { Metadata } from "next";
import { GeistSans } from "geist/font/sans";
import "./globals.css";
import AmplifyConfig from "./AmplifyConfig";
import { AmplifyAuthProvider } from "./context/AmplifyAuthContext";

export const metadata: Metadata = {
  title: "Bitcoin Browser Miner",
  description: "Browser-based Bitcoin mining lottery.",
  icons: {
    icon: "/favicon.ico",
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="min-h-screen">
      <body
        className={`${GeistSans.className} min-h-screen flex flex-col bg-[#0a0c10] text-[#e0e6ed]`}
      >
        <AmplifyConfig />
        <AmplifyAuthProvider>{children}</AmplifyAuthProvider>
      </body>
    </html>
  );
}
