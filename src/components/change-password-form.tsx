"use client";

import { useState } from "react";
import { Loader2, KeyRound, CheckCircle2 } from "lucide-react";

export function ChangePasswordForm() {
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [message, setMessage] = useState({ type: "", text: "" });

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (newPassword !== confirmPassword) {
      setMessage({ type: "error", text: "Las contraseñas nuevas no coinciden" });
      return;
    }

    setIsLoading(true);
    setMessage({ type: "", text: "" });

    try {
      const response = await fetch("/api/auth/change-password", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ currentPassword, newPassword }),
      });

      const data = await response.json();

      if (response.ok) {
        setMessage({ type: "success", text: data.message });
        setCurrentPassword("");
        setNewPassword("");
        setConfirmPassword("");
      } else {
        setMessage({ type: "error", text: data.message });
      }
    } catch (err) {
      setMessage({ type: "error", text: "Error al conectar con el servidor" });
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <div className="rounded-2xl border border-border bg-bg-card p-6">
      <div className="mb-6 flex items-center space-x-3">
        <div className="bg-brand-green/10 p-2 rounded-lg text-brand-green">
          <KeyRound className="h-5 w-5" />
        </div>
        <h3 className="text-lg font-semibold text-white">Cambiar Contraseña</h3>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label className="block text-sm font-medium text-gray-400 mb-1">
            Contraseña Actual
          </label>
          <input
            type="password"
            required
            value={currentPassword}
            onChange={(e) => setCurrentPassword(e.target.value)}
            className="block w-full rounded-md border border-border bg-bg-main px-4 py-2 text-white focus:border-brand-green focus:outline-none focus:ring-1 focus:ring-brand-green sm:text-sm"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-400 mb-1">
            Nueva Contraseña
          </label>
          <input
            type="password"
            required
            value={newPassword}
            onChange={(e) => setNewPassword(e.target.value)}
            className="block w-full rounded-md border border-border bg-bg-main px-4 py-2 text-white focus:border-brand-green focus:outline-none focus:ring-1 focus:ring-brand-green sm:text-sm"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-400 mb-1">
            Confirmar Nueva Contraseña
          </label>
          <input
            type="password"
            required
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
            className="block w-full rounded-md border border-border bg-bg-main px-4 py-2 text-white focus:border-brand-green focus:outline-none focus:ring-1 focus:ring-brand-green sm:text-sm"
          />
        </div>

        {message.text && (
          <div
            className={`rounded-md p-3 text-sm flex items-center space-x-2 ${
              message.type === "success"
                ? "bg-green-900/20 text-green-400 border border-green-900/50"
                : "bg-red-900/20 text-red-400 border border-red-900/50"
            }`}
          >
            {message.type === "success" && <CheckCircle2 className="h-4 w-4" />}
            <span>{message.text}</span>
          </div>
        )}

        <button
          type="submit"
          disabled={isLoading}
          className="flex w-full justify-center rounded-md bg-brand-green px-4 py-2 text-sm font-medium text-black hover:bg-brand-green-dark disabled:opacity-50 transition-colors"
        >
          {isLoading ? (
            <Loader2 className="h-5 w-5 animate-spin" />
          ) : (
            "Actualizar Contraseña"
          )}
        </button>
      </form>
    </div>
  );
}
