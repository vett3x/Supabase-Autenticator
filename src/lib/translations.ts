type Translations = {
  welcome_back: string;
  enter_details: string;
  email_label: string;
  email_placeholder: string;
  password_label: string;
  password_placeholder: string;
  remember_me: string;
  forgot_password: string;
  sign_in: string;
  no_account: string;
  sign_up_now: string;
  quote: string;
  location: string;
  error_invalid: string;
  error_server: string;
  logging_in: string;
  developed_by: string;
};

export const translations: Record<string, Translations> = {
  en: {
    welcome_back: "Welcome back",
    enter_details: "Enter your details below to access the dashboard.",
    email_label: "Email Address",
    email_placeholder: "you@example.com",
    password_label: "Password",
    password_placeholder: "Your password",
    remember_me: "Remember me",
    forgot_password: "Forgot password?",
    sign_in: "Sign In",
    no_account: "Don't have an account?",
    sign_up_now: "Sign Up Now",
    quote: '"Supabase gives us the power of a full Postgres database with the ease of use of a modern backend-as-a-service."',
    location: "San Francisco, CA",
    error_invalid: "Invalid credentials",
    error_server: "Server error",
    logging_in: "Signing in...",
    developed_by: "Developed by Vett3x",
  },
  es: {
    welcome_back: "Bienvenido de nuevo",
    enter_details: "Introduce tus datos a continuación para acceder al panel.",
    email_label: "Correo Electrónico",
    email_placeholder: "tu@ejemplo.com",
    password_label: "Contraseña",
    password_placeholder: "Tu contraseña",
    remember_me: "Recordarme",
    forgot_password: "¿Olvidaste tu contraseña?",
    sign_in: "Iniciar Sesión",
    no_account: "¿No tienes una cuenta?",
    sign_up_now: "Regístrate ahora",
    quote: '"Supabase nos da el poder de una base de datos Postgres completa con la facilidad de uso de un backend-as-a-service moderno."',
    location: "San Francisco, CA",
    error_invalid: "Credenciales inválidas",
    error_server: "Error del servidor",
    logging_in: "Iniciando sesión...",
    developed_by: "Desarrollado por Vett3x",
  },
};

export type Language = "en" | "es";
