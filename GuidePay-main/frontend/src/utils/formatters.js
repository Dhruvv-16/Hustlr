export const formatINR = (n) =>
  `₹${Number(n).toLocaleString('en-IN')}`

export const formatINRShort = (n) => {
  if (n >= 100000) return `₹${(n / 100000).toFixed(1)}L`
  if (n >= 1000) return `₹${(n / 1000).toFixed(0)}K`
  return `₹${n}`
}

export const formatDate = (d) =>
  new Date(d).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' })

export const formatPhone = (p) => {
  const d = p.replace(/\D/g, '').slice(-10)
  return `+91 ${d.slice(0, 5)} ${d.slice(5)}`
}
