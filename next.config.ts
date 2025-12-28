import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  serverExternalPackages: ["better-sqlite3"],
  async rewrites() {
    return [
      {
        source: "/supabase",
        destination: "http://supabase:this_password_is_insecure_change_it@localhost:8000/",
      },
      {
        source: "/supabase/:path*",
        destination: "http://supabase:this_password_is_insecure_change_it@localhost:8000/:path*",
      },
      {
        // Proxy para assets y APIs que Supabase Studio busca en la raíz
        source: "/:path((?!api/auth|dashboard|_next|favicon.ico|$).*)",
        destination: "http://supabase:this_password_is_insecure_change_it@localhost:8000/:path*",
      },
    ];
  },
};

export default nextConfig;
