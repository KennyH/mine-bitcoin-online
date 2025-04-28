import type { AppProps } from "next/app";
import { GeistSans } from "geist/font/sans";
import "./globals.css";
import AmplifyConfig from "../config/AmplifyConfig";
import { AmplifyAuthProvider } from "../context/AmplifyAuthContext";


export default function MyApp({ Component, pageProps }: AppProps) {
  return (
    <div className={`${GeistSans.className} font-sans`}>
      <AmplifyConfig />
      <AmplifyAuthProvider>
        <Component {...pageProps} />
      </AmplifyAuthProvider>
    </div>
  );
}
