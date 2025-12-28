import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { jwtVerify } from "jose";

const JWT_SECRET = new TextEncoder().encode(
  process.env.JWT_SECRET || "default_secret_key_change_me_in_production"
);

export async function middleware(request: NextRequest) {
  const token = request.cookies.get("auth_token")?.value;

  // Si estamos en la página de login, dejar pasar siempre.
  // No redirigimos automáticamente al dashboard para evitar bucles con el proxy
  if (request.nextUrl.pathname === "/" || request.nextUrl.pathname === "/api/auth/login") {
    return NextResponse.next();
  }

  // Para cualquier otra página (como /dashboard o proxy), verificar token
  if (!token) {
    return NextResponse.redirect(new URL("/", request.url));
  }

  try {
    await jwtVerify(token, JWT_SECRET);
    return NextResponse.next();
  } catch (e) {
    return NextResponse.redirect(new URL("/", request.url));
  }
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - api/auth/login (permitir login)
     */
    "/((?!_next/static|_next/image|favicon.ico|api/auth/login).*)",
  ],
};
