// Navigation deep-link builder
// Priority: Google Maps app → Apple Maps app → Google Maps web

export function buildNavigateUrl(destination: string): {
  google: string
  apple: string
  web: string
} {
  const encoded = encodeURIComponent(destination)
  return {
    google: `comgooglemaps://?daddr=${encoded}&directionsmode=driving`,
    apple: `maps://maps.apple.com/?daddr=${encoded}&dirflg=d`,
    web: `https://www.google.com/maps/dir/?api=1&destination=${encoded}&travelmode=driving`,
  }
}

export function buildRouteDayUrl(waypoints: string[]): {
  google: string
  apple: string
  web: string
} {
  if (waypoints.length === 0) return buildNavigateUrl('')
  const dest = waypoints[waypoints.length - 1]
  return {
    google: `comgooglemaps://?saddr=${encodeURIComponent(waypoints[0])}&daddr=${waypoints.map(encodeURIComponent).join('+to:')}&directionsmode=driving`,
    apple: `maps://maps.apple.com/?saddr=${encodeURIComponent(waypoints[0])}&daddr=${waypoints.map(encodeURIComponent).join('+to:')}`,
    web: `https://www.google.com/maps/dir/${waypoints.map(encodeURIComponent).join('/')}`,
  }
}

export function formatDriveTime(minutes: number): string {
  if (minutes < 60) return `${minutes} min`
  const h = Math.floor(minutes / 60)
  const m = minutes % 60
  return m > 0 ? `${h}h ${m}m` : `${h}h`
}

export const STOP_TYPE_ICONS: Record<string, string> = {
  drive: '🚗',
  hotel: '🛏️',
  sightseeing: '🏛️',
  activity: '🎯',
  viewpoint: '📸',
  town: '🏘️',
  restaurant: '🍽️',
  cafe: '☕',
  pub: '🍺',
  beach: '🏖️',
  nature: '🌿',
  castle: '🏰',
  distillery: '🥃',
  museum: '🖼️',
  fuel: '⛽',
  other: '📍',
}
