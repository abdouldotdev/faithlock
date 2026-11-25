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
      // Short links to the AppsFlyer OneLinks of the video series. Temporary, so a link can be
      // repointed without browsers keeping the old target.
      {
        source: '/emmas',
        destination: 'https://faithlock.onelink.me/l3EF/emmas',
        permanent: false,
      },
      {
        source: '/emft',
        destination: 'https://faithlock.onelink.me/l3EF/emft',
        permanent: false,
      },
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
