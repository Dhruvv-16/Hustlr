/**
 * Theme utility — CSS custom property helpers
 * Usage: import { t } from '../utils/theme'
 *        style={{ color: t.textPrimary, background: t.bgCard }}
 */
export const t = {
  // Backgrounds
  bgPrimary:   'var(--bg-primary)',
  bgSecondary: 'var(--bg-secondary)',
  bgCard:      'var(--bg-card)',
  bgTertiary:  'var(--bg-tertiary)',

  // Text
  textPrimary:   'var(--text-primary)',
  textSecondary: 'var(--text-secondary)',
  textTertiary:  'var(--text-tertiary)',
  textDisabled:  'var(--text-disabled)',

  // Brand
  brand:      'var(--brand)',
  brandLight: 'var(--brand-light)',

  // Semantic
  success:      'var(--success)',
  warning:      'var(--warning)',
  danger:       'var(--danger)',
  warningLight: 'var(--warning-light)',
  dangerLight:  'var(--danger-light)',

  // Borders & shadows
  border:      'var(--border)',
  borderLight: 'var(--border-light)',
  shadowCard:  'var(--shadow-card)',
  shadowSm:    'var(--shadow-sm)',
  shadowMd:    'var(--shadow-md)',
}

/**
 * CSS variable getter for dynamic values
 * Usage: getCssVar('--brand') → '#D97757' (computed at runtime)
 */
export function getCssVar(name) {
  return getComputedStyle(document.documentElement).getPropertyValue(name).trim()
}
