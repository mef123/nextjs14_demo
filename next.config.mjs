// next.config.mjs
const nextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'nextjs.org',
        pathname: '/icons/**',
      },
      {
        protocol: 'https',
        hostname: 'unpkg.com', // Likely source for Heroicons
        pathname: '/**',
      },
    ],
  },
};

export default nextConfig;
