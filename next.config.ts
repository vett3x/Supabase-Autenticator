import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  serverExternalPackages: ["better-sqlite3"],
  // Ignorar errores de lint y TS durante el build para ahorrar memoria en Proxmox
  eslint: {
    ignoreDuringBuilds: true,
  },
  typescript: {
    ignoreBuildErrors: true,
  },
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
