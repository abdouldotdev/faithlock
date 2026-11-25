/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'images.ctfassets.net',
      },
    ],
  },
  async redirects() {
    return [
      {
        source: '/learn',
        destination: '/resources',
        permanent: true,
      },
      {
        source: '/learn/:slug',
        destination: '/resources/:slug',
        permanent: true,
      },
      { source: '/stat', destination: '/stats', permanent: false },
    ]
  },
  // The TikTok bio quiz (public/quiz.html), served under clean paths without any redirect: a
  // social app's browser blocks a redirect. The page reads the campaign (emma, emft) from its
  // path and sends the App Store button through that campaign's OneLink.
  async rewrites() {
    return [
      { source: '/quiz', destination: '/quiz.html' },
      { source: '/quiz/:campaign(emma|emft)', destination: '/quiz.html' },
      { source: '/:campaign(emma|emft)', destination: '/quiz.html' },
    ]
  },
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'X-Frame-Options',
            value: 'DENY',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'Referrer-Policy',
            value: 'origin-when-cross-origin',
          },
        ],
      },
    ]
  },
}

module.exports = nextConfig
