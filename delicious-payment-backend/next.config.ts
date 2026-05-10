import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  // Remove webpack config - not needed for simple pages
  transpilePackages: [],
};

export default nextConfig;