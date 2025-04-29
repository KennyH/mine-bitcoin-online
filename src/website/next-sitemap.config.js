const isProd = process.env.NEXT_PUBLIC_ENVIRONMENT === 'prod';

/** @type {import('next-sitemap').IConfig} */
module.exports = {
    siteUrl: process.env.NEXT_PUBLIC_SITE_URL || 'https://dev-env.bitcoinbrowserminer.com', // fallback
    generateRobotsTxt: true,
    generateIndexSitemap: isProd,
    exclude: isProd ? [] : ['/**'],
    robotsTxtOptions: {
        policies: isProd
        ? [
            { userAgent: '*', allow: '/' },
          ]
        : [
            { userAgent: '*', disallow: '/' },
            { userAgent: 'GPTBot', disallow: '/' },
            { userAgent: 'ChatGPT-User', disallow: '/' },
            { userAgent: 'Googlebot', disallow: '/' },
            { userAgent: 'Bingbot', disallow: '/' },
            { userAgent: 'anthropic-ai', disallow: '/' },
            { userAgent: 'ClaudeBot', disallow: '/' },
          ],
    },
};
