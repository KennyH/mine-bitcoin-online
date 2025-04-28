import type { AppProps } from "next/app";
import { GeistSans } from "geist/font/sans";
import "./globals.css";
import AmplifyConfig from "../config/AmplifyConfig";
import { AmplifyAuthProvider } from "../context/AmplifyAuthContext";


export default function MyApp({ Component, pageProps }: AppProps) {
  return (
    <div className={`${GeistSans.className} min-h-screen flex flex-col bg-[#0a0c10] text-[#e0e6ed]`}>
      <AmplifyConfig />
      <AmplifyAuthProvider>
        <Component {...pageProps} />
      </AmplifyAuthProvider>
    </div>
  );
}
