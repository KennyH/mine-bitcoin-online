export type PageSettings = {
    showBanner?: boolean;
    showTagline?: boolean;
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
    "/search": {
      showBanner: false,
      pageTitle: "Search",
      metaDescription: "Search the whole site.",
      layoutVariant: "minimal",
    },
    "/404": {
      showBanner: false,
      pageTitle: "404 - Not found",
      metaDescription: "Sorry, this page does not exist.",
      layoutVariant: "minimal",
    },
  };
