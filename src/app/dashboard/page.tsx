import { LayoutDashboard, Database, Shield, LogOut, Settings } from "lucide-react";
import { ChangePasswordForm } from "@/components/change-password-form";

export default function Dashboard() {
  const supabaseUrl = "/supabase/";

  return (
    <div className="min-h-screen bg-bg-main text-white font-sans">
      <nav className="border-b border-border bg-bg-card px-6 py-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <div className="bg-brand-green/20 p-1.5 rounded-lg">
              <Shield className="h-6 w-6 text-brand-green" />
            </div>
            <span className="text-xl font-bold tracking-tight">Supabase Proxy</span>
          </div>
          <div className="flex items-center space-x-4">
            <div className="hidden md:flex items-center space-x-2 px-3 py-1 rounded-full bg-brand-green/10 border border-brand-green/20">
              <div className="h-2 w-2 rounded-full bg-brand-green animate-pulse" />
              <span className="text-xs font-medium text-brand-green">Sistema Protegido</span>
            </div>
            <form action="/api/auth/logout" method="POST">
              <button
                type="submit"
                className="flex items-center space-x-2 text-sm text-gray-400 hover:text-white transition-colors py-2 px-4 rounded-lg hover:bg-white/5"
              >
                <LogOut className="h-4 w-4" />
                <span>Cerrar Sesión</span>
              </button>
            </form>
          </div>
        </div>
      </nav>

      <main className="container mx-auto max-w-6xl p-8">
        <div className="mb-10">
          <h2 className="text-2xl font-bold">Bienvenido al Portal</h2>
          <p className="text-gray-400 mt-1">Gestiona tu instancia local de Supabase de forma segura.</p>
        </div>

        <div className="grid gap-8 lg:grid-cols-3">
          <div className="lg:col-span-2 space-y-6">
            <div className="grid gap-6 md:grid-cols-2">
              <a
                href={supabaseUrl}
                className="group relative flex flex-col overflow-hidden rounded-2xl border border-border bg-bg-card p-6 transition-all hover:border-brand-green/50 hover:shadow-2xl hover:shadow-brand-green/10"
              >
                <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-xl bg-brand-green/10 text-brand-green transition-all group-hover:scale-110 group-hover:bg-brand-green group-hover:text-black">
                  <LayoutDashboard className="h-6 w-6" />
                </div>
                <h3 className="text-lg font-semibold text-white">Supabase Studio</h3>
                <p className="mt-2 text-sm text-gray-400 leading-relaxed">
                  Accede al panel de control completo. Todo el tráfico se redirige internamente a través de este portal.
                </p>
                <div className="mt-4 flex items-center text-xs font-medium text-brand-green opacity-0 transition-opacity group-hover:opacity-100">
                  Abrir Studio 
                  <span className="ml-1">→</span>
                </div>
              </a>

              <div className="flex flex-col rounded-2xl border border-border bg-bg-card p-6 border-dashed">
                <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-xl bg-gray-500/10 text-gray-500">
                  <Database className="h-6 w-6" />
                </div>
                <h3 className="text-lg font-semibold text-white">Estado del Servidor</h3>
                <div className="mt-4 space-y-3">
                  <div className="flex justify-between text-xs">
                    <span className="text-gray-500">Uptime</span>
                    <span className="text-gray-300">99.9%</span>
                  </div>
                  <div className="h-1.5 w-full bg-gray-800 rounded-full overflow-hidden">
                    <div className="h-full w-full bg-brand-green/40" />
                  </div>
                  <p className="text-[10px] text-gray-500 italic text-center mt-2">
                    Monitorización activa via Docker
                  </p>
                </div>
              </div>
            </div>

            <div className="rounded-2xl bg-gradient-to-br from-brand-green/5 to-transparent border border-brand-green/10 p-8">
              <div className="flex items-start space-x-4">
                <div className="bg-brand-green/20 p-2 rounded-lg">
                  <Shield className="h-5 w-5 text-brand-green" />
                </div>
                <div>
                  <h4 className="font-semibold text-white">Capa de Seguridad Activa</h4>
                  <p className="text-sm text-gray-400 mt-2 max-w-2xl leading-relaxed">
                    Este portal actúa como un guardián (Proxy) delante de tu instancia de Supabase. 
                    Solo las peticiones con un token JWT válido pueden acceder a las rutas internas. 
                  </p>
                </div>
              </div>
            </div>
          </div>

          <div className="space-y-6">
            <div className="flex items-center space-x-2 text-gray-400 mb-2 px-1">
              <Settings className="h-4 w-4" />
              <span className="text-sm font-medium uppercase tracking-wider">Configuración</span>
            </div>
            <ChangePasswordForm />
          </div>
        </div>
      </main>
    </div>
  );
}

