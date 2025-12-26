import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  async rewrites() {
    return [
      {
        source: "/supabase/:path*",
        destination: `${process.env.SUPABASE_STUDIO_URL || "http://localhost:8000"}/:path*`,
      },
    ];
  },
};

export default nextConfig;
