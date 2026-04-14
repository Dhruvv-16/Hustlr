/**
 * IncomeTierBadge — Shows Bronze / Silver / Gold tier based on daily orders.
 * Props: dailyOrders (number)
 */
export default function IncomeTierBadge({ dailyOrders = 0, size = 'md' }) {
  const tier =
    dailyOrders >= 15 ? 'Gold'
    : dailyOrders >= 8 ? 'Silver'
    : 'Bronze'

  const config = {
    Gold: {
      label: 'Gold',
      icon: '🥇',
      bg: '#FFFBEB',
      border: '#F59E0B',
      color: '#92400E',
      sub: '15+ orders/day',
    },
    Silver: {
      label: 'Silver',
      icon: '🥈',
      bg: '#EFF8FF',
      border: '#2E90FA',
      color: '#1D4ED8',
      sub: '8–14 orders/day',
    },
    Bronze: {
      label: 'Bronze',
      icon: '🥉',
      bg: '#F9FAFB',
      border: '#9CA3AF',
      color: '#374151',
      sub: '<8 orders/day',
    },
  }[tier]

  const isSmall = size === 'sm'

  return (
    <div
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: isSmall ? 4 : 6,
        background: config.bg,
        border: `1.5px solid ${config.border}`,
        borderRadius: 999,
        padding: isSmall ? '3px 8px' : '5px 12px',
      }}
    >
      <span style={{ fontSize: isSmall ? 12 : 16 }}>{config.icon}</span>
      <div>
        <span
          style={{
            fontSize: isSmall ? 11 : 13,
            fontWeight: 700,
            fontFamily: 'Inter, sans-serif',
            color: config.color,
          }}
        >
          {config.label} Tier
        </span>
        {!isSmall && (
          <span
            style={{
              fontSize: 10,
              color: config.color,
              opacity: 0.7,
              fontFamily: 'Inter, sans-serif',
              marginLeft: 4,
            }}
          >
            · {config.sub}
          </span>
        )}
      </div>
    </div>
  )
}
