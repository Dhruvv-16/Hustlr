export default function Skeleton({ className = '', width, height, borderRadius = '8px' }) {
  return (
    <div
      className={`${className}`}
      style={{
        width,
        height,
        borderRadius,
        background: 'linear-gradient(90deg, #F0F0F2 25%, #E4E4E7 50%, #F0F0F2 75%)',
        backgroundSize: '200% 100%',
        animation: 'shimmer 1.5s infinite',
      }}
    />
  )
}
