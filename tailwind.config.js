/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./src/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          green: "#00c7b3",
          "green-dark": "#00a896",
        },
        bg: {
          main: "#0f2321",
          card: "#173632",
        },
        border: "#2e6b65",
      },
    },
  },
  plugins: [],
}
