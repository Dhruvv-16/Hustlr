import { useState, useEffect, useRef } from 'react'
import { GoogleMap, useLoadScript, Marker, Circle } from '@react-google-maps/api'
import { MapPin } from 'lucide-react'

const LIBRARIES = ['places']

const LIGHT_MAP_STYLE = [
  { elementType: 'geometry', stylers: [{ color: '#f8f8f8' }] },
  { featureType: 'road.highway', elementType: 'geometry', stylers: [{ color: '#ffffff' }, { weight: 1.5 }] },
  { featureType: 'road.local', elementType: 'geometry', stylers: [{ color: '#f0f0f0' }] },
  { featureType: 'water', elementType: 'geometry', stylers: [{ color: '#d4e6f5' }] },
  { featureType: 'poi', stylers: [{ visibility: 'off' }] },
  { featureType: 'transit', stylers: [{ visibility: 'off' }] },
  { elementType: 'labels.text.fill', stylers: [{ color: '#6b6b6b' }] },
  { elementType: 'labels.icon', stylers: [{ visibility: 'off' }] },
]

export default function ZoneMap({ onLocationSelect, selectedZone, center }) {
  const [userLocation, setUserLocation] = useState(center || null)
  const [mapCenter, setMapCenter] = useState(center || { lat: 17.4401, lng: 78.3489 })
  const [isLocating, setIsLocating] = useState(false)
  const mapRef = useRef(null)

  const { isLoaded } = useLoadScript({
    googleMapsApiKey: import.meta.env.VITE_GOOGLE_MAPS_KEY || '',
    libraries: LIBRARIES,
  })

  useEffect(() => {
    if (center) {
      setUserLocation(center)
      setMapCenter(center)
      return
    }
    setIsLocating(true)
    if (!navigator.geolocation) { setIsLocating(false); return }
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const loc = { lat: pos.coords.latitude, lng: pos.coords.longitude }
        setUserLocation(loc)
        setMapCenter(loc)
        setIsLocating(false)
        reverseGeocode(loc)
      },
      () => setIsLocating(false),
      { enableHighAccuracy: true, timeout: 10000 }
    )
  }, [center])

  const reverseGeocode = (loc) => {
    if (!window.google) return
    const geocoder = new window.google.maps.Geocoder()
    geocoder.geocode({ location: loc }, (results, status) => {
      if (status === 'OK' && results[0]) {
        const area = results[0].address_components
          .find((c) => c.types.includes('sublocality_level_1'))
          ?.long_name || results[0].formatted_address
        onLocationSelect?.({ coords: loc, name: area, address: results[0].formatted_address })
      }
    })
  }

  const handleMapClick = (e) => {
    const loc = { lat: e.latLng.lat(), lng: e.latLng.lng() }
    setUserLocation(loc)
    setMapCenter(loc)
    reverseGeocode(loc)
  }

  if (!isLoaded) {
    return (
      <div
        className="w-full rounded-xl flex items-center justify-center"
        style={{ height: 200, background: 'var(--bg-tertiary)' }}
      >
        <div className="flex flex-col items-center gap-2">
          <div className="w-6 h-6 border-2 border-[var(--brand)] border-t-transparent rounded-full animate-spin" />
          <p className="text-[13px] font-body" style={{ color: 'var(--text-tertiary)' }}>
            Loading map...
          </p>
        </div>
      </div>
    )
  }

  // No API key — show placeholder
  if (!import.meta.env.VITE_GOOGLE_MAPS_KEY || import.meta.env.VITE_GOOGLE_MAPS_KEY === 'your_key_here') {
    return (
      <div
        className="w-full rounded-xl flex flex-col items-center justify-center gap-3"
        style={{ height: 200, background: 'linear-gradient(135deg, #f8f8f8, #f0f0f2)' }}
      >
        <MapPin size={32} style={{ color: 'var(--brand)' }} />
        <div className="text-center">
          <p className="text-[14px] font-semibold font-body" style={{ color: 'var(--text-primary)' }}>
            {selectedZone?.name || 'Your delivery zone'}
          </p>
          <p className="text-[12px] font-body mt-1" style={{ color: 'var(--text-tertiary)' }}>
            5km monitoring radius · Add VITE_GOOGLE_MAPS_KEY to enable live map
          </p>
        </div>
      </div>
    )
  }

  return (
    <div className="relative rounded-xl overflow-hidden" style={{ height: 200 }}>
      {isLocating && (
        <div className="absolute inset-0 z-10 bg-white/80 flex flex-col items-center justify-center gap-2">
          <div className="w-8 h-8 border-2 border-[var(--brand)] border-t-transparent rounded-full animate-spin" />
          <p className="text-[13px] font-body" style={{ color: 'var(--text-secondary)' }}>
            Finding your location...
          </p>
        </div>
      )}
      <GoogleMap
        mapContainerStyle={{ width: '100%', height: '100%' }}
        center={mapCenter}
        zoom={15}
        options={{
          styles: LIGHT_MAP_STYLE,
          disableDefaultUI: true,
          zoomControl: true,
          gestureHandling: 'cooperative',
        }}
        onClick={handleMapClick}
        onLoad={(map) => { mapRef.current = map }}
      >
        {userLocation && (
          <>
            <Marker
              position={userLocation}
              icon={window.google ? {
                path: window.google.maps.SymbolPath.CIRCLE,
                scale: 10,
                fillColor: '#D97757',
                fillOpacity: 1,
                strokeColor: '#ffffff',
                strokeWeight: 3,
              } : undefined}
            />
            <Circle
              center={userLocation}
              radius={5000}
              options={{
                fillColor: '#D97757',
                fillOpacity: 0.08,
                strokeColor: '#D97757',
                strokeOpacity: 0.3,
                strokeWeight: 1.5,
              }}
            />
          </>
        )}
      </GoogleMap>
      <div className="absolute bottom-2 left-0 right-0 flex justify-center">
        <div className="bg-white/90 rounded-full px-3 py-1 text-[11px] font-body shadow-sm" style={{ color: 'var(--text-tertiary)' }}>
          Tap map to adjust your zone
        </div>
      </div>
    </div>
  )
}
