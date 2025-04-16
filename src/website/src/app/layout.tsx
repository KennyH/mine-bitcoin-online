import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import AmplifyConfig from "./AmplifyConfig";
import { AmplifyAuthProvider } from "./context/AmplifyAuthContext";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Bitcoin Browser Miner",
  description: "Browser-based Bitcoin mining lottery.",
  icons: {
    icon: "/favicon.ico",
  },
};

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="min-h-screen">
      <body className={`${inter.className} min-h-screen flex flex-col`}>
        <AmplifyConfig />
        <AmplifyAuthProvider>{children}</AmplifyAuthProvider>
      </body>
    </html>
  );
}
