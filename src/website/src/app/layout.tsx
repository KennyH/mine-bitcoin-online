import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import AmplifyConfig from "./AmplifyConfig";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Bitcoin Browser Miner",
  description: "Browser-based Bitcoin mining lottery.",
};

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="min-h-screen">
      <body className={`${inter.className} min-h-screen flex flex-col`}>
        <AmplifyConfig />
        {children}
      </body>
    </html>
  );
}
