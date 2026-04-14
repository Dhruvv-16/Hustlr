export const PLATFORMS = [
  { id: 'zepto',   name: 'Zepto',   emoji: '🟢', sub: 'Q-commerce' },
  { id: 'swiggy',  name: 'Swiggy',  emoji: '🟠', sub: 'Food delivery' },
  { id: 'blinkit', name: 'Blinkit', emoji: '🔴', sub: 'Q-commerce' },
  { id: 'amazon',  name: 'Amazon',  emoji: '🔵', sub: 'E-commerce' },
]

export const ZONE_SUGGESTIONS = [
  { id: 'kondapur-hyderabad',     name: 'Kondapur',     city: 'Hyderabad', lat: 17.4700, lng: 78.3560 },
  { id: 'kurla-mumbai',           name: 'Kurla',        city: 'Mumbai',    lat: 19.0728, lng: 72.8826 },
  { id: 'koramangala-bengaluru',  name: 'Koramangala',  city: 'Bengaluru', lat: 12.9352, lng: 77.6245 },
  { id: 'hitech-hyderabad',       name: 'HiTech City',  city: 'Hyderabad', lat: 17.4486, lng: 78.3908 },
  { id: 'bandra-mumbai',          name: 'Bandra',       city: 'Mumbai',    lat: 19.0596, lng: 72.8295 },
  { id: 'indiranagar-bengaluru',  name: 'Indiranagar',  city: 'Bengaluru', lat: 12.9719, lng: 77.6412 },
]

export const ZONE_RISK = {
  'kondapur-hyderabad':    { flood: 'HIGH',   outage: 'MED', curfew: 'LOW' },
  'kurla-mumbai':          { flood: 'HIGH',   outage: 'MED', curfew: 'LOW' },
  'koramangala-bengaluru': { flood: 'LOW',    outage: 'HIGH', curfew: 'LOW' },
  default:                 { flood: 'MED',    outage: 'MED', curfew: 'LOW' },
}
