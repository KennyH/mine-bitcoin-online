'use client';

import { Html, Head, Main, NextScript } from "next/document";

export default function Document() {
  return (
    <Html lang="en" className={`min-h-screen ${""}`}>
      <Head>
        <meta name="description" content="Browser-based Bitcoin mining lottery." />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <body className={"min-h-screen flex flex-col bg-[#0a0c10] text-[#e0e6ed]"}>
        <Main />
        <NextScript />
      </body>
    </Html>
  );
}
