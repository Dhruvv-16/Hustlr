/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        brand: {
          DEFAULT: '#D97757',
          light: '#FDF1ED',
          dark: '#B85C3A',
        },
        success: {
          DEFAULT: '#12B76A',
          light: '#ECFDF3',
        },
        warning: {
          DEFAULT: '#F79009',
          light: '#FFFAEB',
        },
        danger: {
          DEFAULT: '#F04438',
          light: '#FEF3F2',
        },
        grey: {
          50: '#F7F7F8',
          100: '#F0F0F2',
          200: '#E4E4E7',
          300: '#C4C4C4',
          400: '#9B9B9B',
          500: '#6B6B6B',
          900: '#0F0F0F',
        },
      },
      fontFamily: {
        display: ['Bricolage Grotesque', 'sans-serif'],
        body: ['Inter', 'sans-serif'],
      },
      boxShadow: {
        card: '0 2px 12px rgba(0,0,0,0.06)',
        md: '0 4px 6px rgba(0,0,0,0.05), 0 2px 4px rgba(0,0,0,0.04)',
        lg: '0 10px 24px rgba(0,0,0,0.08), 0 4px 8px rgba(0,0,0,0.04)',
      },
      borderRadius: {
        card: '16px',
        button: '12px',
        pill: '999px',
        input: '12px',
      },
    },
  },
  plugins: [],
}

