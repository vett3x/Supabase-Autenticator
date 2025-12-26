import { NextResponse } from "next/server";
import db from "@/lib/db";
import bcrypt from "bcryptjs";
import { cookies } from "next/headers";
import { jwtVerify } from "jose";

const JWT_SECRET = new TextEncoder().encode(
  process.env.JWT_SECRET || "default_secret_key_change_me_in_production"
);

export async function POST(request: Request) {
  try {
    const token = (await cookies()).get("auth_token")?.value;

    if (!token) {
      return NextResponse.json({ message: "No autorizado" }, { status: 401 });
    }

    try {
      await jwtVerify(token, JWT_SECRET);
    } catch (e) {
      return NextResponse.json({ message: "Sesión inválida" }, { status: 401 });
    }

    const { currentPassword, newPassword } = await request.json();

    const user: any = db.prepare("SELECT * FROM users WHERE username = ?").get("admin");

    if (!user || !bcrypt.compareSync(currentPassword, user.password)) {
      return NextResponse.json(
        { message: "La contraseña actual es incorrecta" },
        { status: 400 }
      );
    }

    const hashedNewPassword = bcrypt.hashSync(newPassword, 10);
    db.prepare("UPDATE users SET password = ?, updated_at = CURRENT_TIMESTAMP WHERE username = ?")
      .run(hashedNewPassword, "admin");

    return NextResponse.json({ message: "Contraseña actualizada correctamente" });
  } catch (error) {
    console.error("Change password error:", error);
    return NextResponse.json(
      { message: "Error al actualizar la contraseña" },
      { status: 500 }
    );
  }
}
