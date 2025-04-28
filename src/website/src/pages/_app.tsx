import type { AppProps } from "next/app";
import { GeistSans } from "geist/font/sans";
import "./globals.css";
import AmplifyConfig from "@/config/AmplifyConfig"
import { AmplifyAuthProvider } from "@/context/AmplifyAuthContext";
import Layout from "@/components/Layout";

type WithLayoutSettings = {
  showBanner?: boolean;
  showTagline?: boolean;
};

type AppWithLayoutProps = AppProps & {
  Component: AppProps["Component"] & WithLayoutSettings;
};

export default function MyApp({ Component, pageProps }: AppWithLayoutProps) {
  const showBanner = Component.showBanner ?? true;
  const showTagline = Component.showTagline ?? false;
  return (
    <Layout showBanner={showBanner} showTagline={showTagline}>
      <div className={`${GeistSans.className} font-sans`}>
        <AmplifyConfig />
        <AmplifyAuthProvider>
          <Component {...pageProps} />
        </AmplifyAuthProvider>
      </div>
    </Layout>
  );
}
