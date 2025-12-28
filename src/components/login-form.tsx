"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { Loader2, Eye, EyeOff } from "lucide-react";
import { translations, Language } from "@/lib/translations";

export function LoginForm() {
  const [email, setEmail] = useState("admin@supabase.local");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");
  const [lang, setLang] = useState<Language>("en");
  const router = useRouter();

  useEffect(() => {
    // Detect language from browser
    const browserLang = navigator.language.split("-")[0];
    if (browserLang === "es") {
      setLang("es");
    } else {
      setLang("en");
    }
  }, []);

  const t = translations[lang];

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setIsLoading(true);
    setError("");

    try {
      const response = await fetch("/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      });

      if (response.ok) {
        // Usar window.location.href para asegurar una carga completa del dashboard
        window.location.href = "/dashboard";
      } else {
        const data = await response.json();
        setError(data.message || t.error_invalid);
      }
    } catch (err) {
      setError(t.error_server);
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      <div>
        <label className="block text-sm font-medium leading-6 text-white mb-2" htmlFor="email">
          {t.email_label}
        </label>
        <div className="mt-2">
          <input 
            autoComplete="email" 
            className="block w-full rounded-lg border-0 py-2.5 px-4 text-white shadow-sm ring-1 ring-inset ring-[#2e6b65] placeholder:text-[#8dcec8]/50 focus:ring-2 focus:ring-inset focus:ring-[#00c7b3] sm:text-sm sm:leading-6 bg-[#173632]" 
            id="email" 
            name="email" 
            placeholder={t.email_placeholder} 
            required
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />
        </div>
      </div>
      <div>
        <label className="block text-sm font-medium leading-6 text-white mb-2" htmlFor="password">
          {t.password_label}
        </label>
        <div className="relative mt-2 rounded-lg shadow-sm">
          <input 
            autoComplete="current-password" 
            className="block w-full rounded-lg border-0 py-2.5 px-4 pr-12 text-white ring-1 ring-inset ring-[#2e6b65] placeholder:text-[#8dcec8]/50 focus:ring-2 focus:ring-inset focus:ring-[#00c7b3] sm:text-sm sm:leading-6 bg-[#173632]" 
            id="password" 
            name="password" 
            placeholder={t.password_placeholder} 
            required 
            type={showPassword ? "text" : "password"}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
          <button
            type="button"
            className="absolute inset-y-0 right-0 flex items-center pr-3 text-[#8dcec8] hover:text-white"
            onClick={() => setShowPassword(!showPassword)}
          >
            {showPassword ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
          </button>
        </div>
      </div>

      {error && (
        <div className="rounded-lg bg-red-900/20 p-3 text-sm text-red-400 border border-red-900/50">
          {error}
        </div>
      )}

      <div className="flex items-center justify-between">
        <div className="flex items-center">
          <input 
            className="h-4 w-4 rounded border-[#2e6b65] text-[#00c7b3] focus:ring-[#00c7b3] bg-[#173632]" 
            id="remember-me" 
            name="remember-me" 
            type="checkbox"
          />
          <label className="ml-2 block text-sm text-[#8dcec8]" htmlFor="remember-me">
            {t.remember_me}
          </label>
        </div>
        <div className="text-sm">
          <a className="font-medium text-[#00c7b3] hover:text-[#00a896] transition-colors" href="#">
            {t.forgot_password}
          </a>
        </div>
      </div>
      
      <div>
        <button 
          className="flex w-full justify-center rounded-lg bg-[#00c7b3] px-3 py-3 text-sm font-semibold leading-6 text-[#0f2321] shadow-sm hover:bg-[#00a896] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#00c7b3] transition-all duration-200 disabled:opacity-50" 
          type="submit"
          disabled={isLoading}
        >
          {isLoading ? (
            <Loader2 className="h-5 w-5 animate-spin" />
          ) : (
            t.sign_in
          )}
        </button>
      </div>
    </form>
  );
}
