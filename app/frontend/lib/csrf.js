export function csrfToken() {
  const match = document.cookie.match(/(?:^|;\s*)CSRF-TOKEN=([^;]*)/)
  return match ? decodeURIComponent(match[1]) : null
}
