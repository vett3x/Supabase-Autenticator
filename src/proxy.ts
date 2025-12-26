import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { jwtVerify } from "jose";

const JWT_SECRET = new TextEncoder().encode(
  process.env.JWT_SECRET || "default_secret_key_change_me_in_production"
);

export async function proxy(request: NextRequest) {
  const token = request.cookies.get("auth_token")?.value;

  // Si estamos en la página de login y ya tenemos token, ir al dashboard
  if (request.nextUrl.pathname === "/" || request.nextUrl.pathname === "/api/auth/login") {
    if (token) {
      try {
        await jwtVerify(token, JWT_SECRET);
        return NextResponse.redirect(new URL("/dashboard", request.url));
      } catch (e) {
        // Token inválido, dejar pasar al login
      }
    }
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
     */
    "/((?!_next/static|_next/image|favicon.ico).*)",
  ],
};
