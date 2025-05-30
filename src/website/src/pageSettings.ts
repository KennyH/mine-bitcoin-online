export type PageSettings = {
    authRequired?: boolean;
    showBanner?: boolean;
    showTagline?: boolean;
    showStartButton?: boolean;
    pageTitle?: string;
    metaDescription?: string;
    layoutVariant?: "full" | "default" | "minimal";
  };

  export const pageSettings: Record<string, PageSettings> = {
    "/": {
      showBanner: true,
      showTagline: true,
      // TODO work on the title, meta, etc when pages are more full.
      pageTitle: "Bitcoin Browser Miner",
      metaDescription: "Mining Bitcoin with your browser!",
      layoutVariant: "full",
    },
    "/start": {
      authRequired: true,
      showBanner: false,
      showStartButton: false,
      pageTitle: "Start",
      metaDescription: "Start page for WASM bitcoin mining, after logged in.",
      layoutVariant: "minimal",
    },
    "/docs/terms": {
      showBanner: false,
      pageTitle: "Terms of Service",
      metaDescription: "Terms of service documentation for Bitcoin Browser Miner.",
      layoutVariant: "minimal",
    },
    "/search": {
      showBanner: false,
      pageTitle: "Search",
      metaDescription: "Search the whole site.",
      layoutVariant: "minimal",
    },
    "/tools/sha256visual": {
      showBanner: false,
      pageTitle: "SHA-256 Visualizer",
      metaDescription: "An interactive visualization of the SHA-256 algorithm.",
      layoutVariant: "minimal",
    },
    "/404": {
      showBanner: false,
      pageTitle: "404 - Not found",
      metaDescription: "Sorry, this page does not exist.",
      layoutVariant: "minimal",
    },
  };
