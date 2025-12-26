import Database from "better-sqlite3";
import path from "path";
import bcrypt from "bcryptjs";

const dbPath = path.join(process.cwd(), "auth.db");
const db = new Database(dbPath);

// Inicializar la tabla de usuarios
db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE,
    email TEXT UNIQUE,
    password TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )
`);

// Verificar si existe el usuario administrador, si no, crearlo
const adminUser = db.prepare("SELECT * FROM users WHERE username = ? OR email = ?").get("admin", "admin@supabase.local");

if (!adminUser) {
  const defaultPassword = process.env.AUTH_PASSWORD || "admin123";
  const hashedPassword = bcrypt.hashSync(defaultPassword, 10);
  db.prepare("INSERT INTO users (username, email, password) VALUES (?, ?, ?)").run("admin", "admin@supabase.local", hashedPassword);
  console.log("Usuario administrador creado con contraseña por defecto.");
} else {
  // Asegurarse de que el usuario existente tenga email si se creó antes de esta actualización
  const user: any = adminUser;
  if (!user.email) {
    db.prepare("UPDATE users SET email = ? WHERE id = ?").run("admin@supabase.local", user.id);
  }
}

export default db;
