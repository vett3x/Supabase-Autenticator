import { NextResponse } from "next/server";
import { SignJWT } from "jose";
import { cookies } from "next/headers";
import db from "@/lib/db";
import bcrypt from "bcryptjs";

const JWT_SECRET = new TextEncoder().encode(
  process.env.JWT_SECRET || "default_secret_key_change_me_in_production"
);

export async function POST(request: Request) {
  try {
    const { email, password } = await request.json();

    // Buscar el usuario por email o username
    const user: any = db.prepare("SELECT * FROM users WHERE email = ? OR username = ?").get(email, email);

    if (user && bcrypt.compareSync(password, user.password)) {
      const token = await new SignJWT({ authenticated: true })
        .setProtectedHeader({ alg: "HS256" })
        .setExpirationTime("24h")
        .sign(JWT_SECRET);

      const cookieStore = await cookies();
      cookieStore.set("auth_token", token, {
        httpOnly: true,
        secure: false, // Deshabilitado para permitir acceso via IP (HTTP) en redes locales
        sameSite: "lax",
        maxAge: 60 * 60 * 24, // 24 hours
        path: "/",
      });

      return NextResponse.json({ message: "Login exitoso" });
    }

    return NextResponse.json(
      { message: "Contraseña incorrecta" },
      { status: 401 }
    );
  } catch (error) {
    console.error("Login error:", error);
    return NextResponse.json(
      { message: "Error en el servidor" },
      { status: 500 }
    );
  }
}
