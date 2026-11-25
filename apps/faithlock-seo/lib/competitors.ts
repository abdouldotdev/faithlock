// Outbound links we never give: competitor apps, their app-store listings,
// their help centers and the blogs they run. Text stays, the link goes.
export const COMPETITOR_HOSTS = [
  'opalapp.com',
  'getbrick.com',
  'getbrick.app',
  'screenzen.co',
  'one-sec.app',
  'freedom.to',
  'getcoldturkey.com',
  'forestapp.cc',
  'appfinca.com',
  'jomo.so',
  'getclearspace.com',
  'unpluq.com',
  'appblock.app',
  'holyfocus.app',
  'fridaylabs.co',
  'covenanteyes.com',
  'bark.us',
  'canopy.us',
  'truple.io',
  'accountable2you.com',
  'qustodio.com',
  'lockpact.app',
  'blok.so',
  'tryhugo.app',
  'nibble-app.com',
  'abide.com',
  'pray.com',
]

const APP_STORE_HOSTS = ['apps.apple.com', 'play.google.com', 'chromewebstore.google.com']
const FAITHLOCK_APP_ID = 'id6754208209'

function hostMatches(host: string, domain: string): boolean {
  return host === domain || host.endsWith(`.${domain}`)
}

export function isCompetitorUrl(href: string): boolean {
  let url: URL
  try {
    url = new URL(href)
  } catch {
    return false
  }
  const host = url.hostname.toLowerCase()
  if (APP_STORE_HOSTS.includes(host)) return !url.pathname.includes(FAITHLOCK_APP_ID)
  return COMPETITOR_HOSTS.some((d) => hostMatches(host, d))
}

/** Replace every `<a href="competitor">text</a>` in rendered HTML by its text. */
export function unlinkCompetitors(html: string): string {
  return html.replace(/<a\b[^>]*\bhref="([^"]*)"[^>]*>([\s\S]*?)<\/a>/gi, (match, href: string, text: string) =>
    isCompetitorUrl(href) ? text : match
  )
}
