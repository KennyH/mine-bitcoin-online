/** @type {import('next-sitemap').IConfig} */
module.exports = {
    siteUrl: process.env.NEXT_PUBLIC_SITE_URL || 'https://dev-env.bitcoinbrowserminer.com', // fallback
    //generateRobotsTxt: true,
    outDir: 'out',
    //exclude: process.env.NEXT_PUBLIC_ENVIRONMENT === 'dev' ? ['/'] : [],
  }
  