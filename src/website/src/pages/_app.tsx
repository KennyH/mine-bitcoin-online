'use client';

import type { AppProps } from 'next/app';
import { useRouter } from 'next/router';
import { GeistSans } from 'geist/font/sans';
import './globals.css';
import { CognitoUserProvider } from '@/context/CognitoUserContext';
import Layout from '@/components/Layout';
import { pageSettings } from '@/pageSettings';

type WithLayoutSettings = {
  showBanner?: boolean;
  showTagline?: boolean;
  showStartButton?: boolean;
};

type AppWithLayoutProps = AppProps & {
  Component: AppProps["Component"] & WithLayoutSettings;
};

export default function App({ Component, pageProps }: AppWithLayoutProps) {
  const router = useRouter();
  const settings = pageSettings[router.pathname] || {};
  return (
    <CognitoUserProvider>
      <Layout showBanner={settings.showBanner}
              showTagline={settings.showTagline}
              showStartButton={settings.showStartButton}
      >
        <div className={`${GeistSans.className} font-sans`}>
            <Component {...pageProps} />
        </div>
      </Layout>
    </CognitoUserProvider>
  );
}
