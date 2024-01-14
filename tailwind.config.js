/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./pages/**/*.{html,html.erb}",
  ],
  theme: {
    extend: {},
  },
  plugins: [
    require("daisyui"),
  ],
};
