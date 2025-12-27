import Database from "better-sqlite3";
import path from "path";
import bcrypt from "bcryptjs";

const dbPath = path.join(process.cwd(), "auth.db");
const db = new Database(dbPath);

// Asegurar que la tabla existe
db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE,
    email TEXT UNIQUE,
    password TEXT
  )
`);

const email = process.argv[2];
const password = process.argv[3];

if (!email || !password) {
  console.error("Uso: node change-password-cli.js <email> <password>");
  process.exit(1);
}

const hashedPassword = bcrypt.hashSync(password, 10);

try {
  const result = db.prepare("UPDATE users SET email = ?, password = ? WHERE username = ?").run(email, hashedPassword, "admin");
  
  if (result.changes > 0) {
    console.log(`Éxito: Contraseña actualizada para ${email}`);
  } else {
    // Si por alguna razón no existe el usuario admin, lo creamos
    db.prepare("INSERT INTO users (username, email, password) VALUES (?, ?, ?)").run("admin", email, hashedPassword);
    console.log(`Éxito: Usuario creado con email ${email}`);
  }
} catch (error) {
  console.error("Error al actualizar la contraseña:", error);
  process.exit(1);
}
