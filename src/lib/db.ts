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

// Intentar crear el usuario administrador solo si no existe
// Usamos una transacción para evitar condiciones de carrera durante el build de Next.js
try {
  const adminExists = db.prepare("SELECT id FROM users WHERE username = 'admin' OR email = 'admin@supabase.local'").get();
  
  if (!adminExists) {
    const defaultPassword = process.env.AUTH_PASSWORD || "admin123";
    const hashedPassword = bcrypt.hashSync(defaultPassword, 10);
    
    // Usar INSERT OR IGNORE como doble seguridad
    db.prepare("INSERT OR IGNORE INTO users (username, email, password) VALUES (?, ?, ?)")
      .run("admin", "admin@supabase.local", hashedPassword);
    
    console.log("Usuario administrador inicializado.");
  }
} catch (error) {
  // Ignorar errores de base de datos bloqueada durante el build
  console.log("Aviso: La base de datos está siendo inicializada por otro proceso.");
}

export default db;
