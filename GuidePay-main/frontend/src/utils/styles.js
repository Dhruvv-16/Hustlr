// Style utility — use these instead of Tailwind color classes
// Ensures dark mode compatibility via CSS variables

export const s = {
  // Backgrounds
  bgPrimary: { background: 'var(--bg-primary)' },
  bgSecondary: { background: 'var(--bg-secondary)' },
  bgTertiary: { background: 'var(--bg-tertiary)' },
  bgCard: { background: 'var(--bg-card)' },
  bgBrand: { background: 'var(--brand-light)' },

  // Text
  textPrimary: { color: 'var(--text-primary)' },
  textSecondary: { color: 'var(--text-secondary)' },
  textTertiary: { color: 'var(--text-tertiary)' },
  textDisabled: { color: 'var(--text-disabled)' },
  textBrand: { color: 'var(--brand)' },
  textSuccess: { color: 'var(--success)' },
  textWarning: { color: 'var(--warning)' },
  textDanger: { color: 'var(--danger)' },

  // Borders
  border: { border: '1px solid var(--border)' },
  borderLight: { borderBottom: '1px solid var(--border-light)' },
  borderTop: { borderTop: '1px solid var(--border-light)' },

  // Cards
  card: {
    background: 'var(--bg-card)',
    borderRadius: 16,
    boxShadow: 'var(--shadow-card)',
  },

  // Fonts
  display: { fontFamily: 'Bricolage Grotesque, sans-serif' },
  body: { fontFamily: 'Inter, sans-serif' },
}
