"use client";

import { LoginForm } from "@/components/login-form";
import { useEffect, useState } from "react";
import { translations, Language } from "@/lib/translations";

export default function Home() {
  const [lang, setLang] = useState<Language>("en");

  useEffect(() => {
    const browserLang = navigator.language.split("-")[0];
    if (browserLang === "es") {
      setLang("es");
    } else {
      setLang("en");
    }
  }, []);

  const t = translations[lang];

  return (
    <main className="min-h-screen bg-[#0f2321] flex overflow-hidden font-sans">
      {/* Left Section: Authentication Form */}
      <div className="flex-1 flex flex-col justify-center px-8 sm:px-12 lg:flex-none lg:px-24 xl:px-32 relative z-10 bg-[#0f2321]">
        <div className="mx-auto w-full max-w-sm lg:w-[400px]">
          {/* Logo Header */}
          <div className="flex items-center gap-3 mb-12">
            <img 
              src="https://supabase.com/dashboard/img/supabase-dark.svg" 
              alt="Supabase Logo" 
              className="w-24 h-24"
            />
          </div>

          {/* Page Heading */}
          <div className="mb-10">
            <h1 className="text-3xl font-bold tracking-tight text-white mb-2">{t.welcome_back}</h1>
            <p className="text-sm text-[#8dcec8]">
              {t.enter_details}
            </p>
          </div>

          <div className="space-y-8">
            {/* Login Form Component */}
            <LoginForm />

            {/* Footer Links */}
            <div className="text-center text-sm text-[#8dcec8] space-y-4">
              <div>
                {t.no_account}
                <a className="font-medium text-[#00c7b3] hover:text-[#00a896] transition-colors ml-1" href="#">
                  {t.sign_up_now}
                </a>
              </div>
              <div className="pt-8 border-t border-[#2e6b65]/30">
                <p className="text-xs font-medium tracking-widest uppercase text-[#00c7b3]/60">
                  {t.developed_by}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Right Section: Visual / Image */}
      <div className="hidden lg:block relative flex-1 bg-[#0f2321]">
        {/* Abstract pattern / Image */}
        <div className="absolute inset-0 bg-black/20 z-10"></div>
        <img 
          alt="Supabase abstract visual" 
          className="absolute inset-0 h-full w-full object-cover opacity-80" 
          src="https://images.unsplash.com/photo-1639322537228-f710d846310a?q=80&w=2000&auto=format&fit=crop"
        />
        
        {/* Quote Overlay */}
        <div className="absolute bottom-20 left-12 right-12 z-20">
          <blockquote className="space-y-4">
            <p className="text-xl font-medium text-white italic leading-relaxed max-w-2xl">
              {t.quote}
            </p>
            <footer className="flex items-center gap-3">
              <span className="text-base font-semibold text-[#00c7b3]">Vett3x</span>
              <span className="h-1 w-1 rounded-full bg-[#2e6b65]"></span>
              <span className="text-base text-[#8dcec8]">Lead Developer</span>
            </footer>
          </blockquote>
        </div>
      </div>
    </main>
  );
}
