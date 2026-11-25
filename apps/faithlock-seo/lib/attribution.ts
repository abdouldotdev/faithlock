// Install attribution for App Store clicks: every FaithLock store link leaves the
// site through the AppsFlyer OneLink, tagged with where the visitor came from.
// AppsFlyer then reports installs under pid=website, split by af_channel.
//
// Query params appended to the short link are merged by AppsFlyer:
//   af_channel  traffic source of the visit (chatgpt, google, reddit, direct…)
//   af_sub1     page the click happened on
//   af_sub2     landing page of the visit
//   af_sub3     CTA location on the page
//   af_sub4     utm_campaign of the visit, when present

export const ONELINK_URL = 'https://faithlock.onelink.me/l3EF/web'
export const ONELINK = { host: 'faithlock.onelink.me', pathPrefix: '/l3EF/' }

const SITE_HOSTS = ['getfaithlock.com']

// Referrer host suffix → channel. First match wins, so specific hosts come first.
const REFERRER_CHANNELS: Array<[string, string]> = [
  ['chatgpt.com', 'chatgpt'],
  ['chat.openai.com', 'chatgpt'],
  ['openai.com', 'chatgpt'],
  ['perplexity.ai', 'perplexity'],
  ['claude.ai', 'claude'],
  ['gemini.google.com', 'gemini'],
  ['copilot.microsoft.com', 'copilot'],
  ['you.com', 'you'],
  ['search.brave.com', 'brave'],
  ['duckduckgo.com', 'duckduckgo'],
  ['ecosia.org', 'ecosia'],
  ['search.yahoo.com', 'yahoo'],
  ['yandex.ru', 'yandex'],
  ['yandex.com', 'yandex'],
  ['bing.com', 'bing'],
  ['facebook.com', 'facebook'],
  ['instagram.com', 'instagram'],
  ['t.co', 'x'],
  ['x.com', 'x'],
  ['twitter.com', 'x'],
  ['tiktok.com', 'tiktok'],
  ['reddit.com', 'reddit'],
  ['youtube.com', 'youtube'],
  ['pinterest.com', 'pinterest'],
  ['linkedin.com', 'linkedin'],
]

export interface VisitAttribution {
  channel: string
  landing: string
  campaign?: string
}

function hostMatches(host: string, suffix: string): boolean {
  return host === suffix || host.endsWith(`.${suffix}`)
}

function sanitize(value: string): string {
  return value.toLowerCase().replace(/[^a-z0-9_.-]/g, '_').slice(0, 50)
}

/** Maps a host (or a host-like utm_source such as "chatgpt.com") to a channel. */
export function channelFromHost(rawHost: string): string {
  const host = rawHost.toLowerCase().replace(/^www\./, '')
  if (/(^|\.)google\.[a-z.]+$/.test(host) && !hostMatches(host, 'gemini.google.com')) return 'google'
  for (const [suffix, channel] of REFERRER_CHANNELS) {
    if (hostMatches(host, suffix)) return channel
  }
  return sanitize(host)
}

/** Traffic source of a visit: utm_source first, then the external referrer, else direct. */
export function classifyVisit(search: string, referrer: string, landing: string): VisitAttribution {
  const params = new URLSearchParams(search)
  const campaign = params.get('utm_campaign')?.trim()
  const base = { landing, ...(campaign ? { campaign: sanitize(campaign) } : {}) }

  const utmSource = params.get('utm_source')?.trim()
  if (utmSource) return { channel: channelFromHost(utmSource), ...base }

  if (referrer) {
    try {
      const host = new URL(referrer).hostname.toLowerCase().replace(/^www\./, '')
      if (host && !SITE_HOSTS.some((h) => hostMatches(host, h))) {
        return { channel: channelFromHost(host), ...base }
      }
    } catch {
      // malformed referrer: fall through to direct
    }
  }
  return { channel: 'direct', ...base }
}

/** OneLink for one click, carrying the visit source, the page and the CTA. */
export function buildOneLink(visit: VisitAttribution, pagePath: string, location: string): string {
  const url = new URL(ONELINK_URL)
  url.searchParams.set('af_channel', visit.channel)
  url.searchParams.set('af_sub1', pagePath)
  url.searchParams.set('af_sub2', visit.landing)
  url.searchParams.set('af_sub3', location || 'content')
  if (visit.campaign) url.searchParams.set('af_sub4', visit.campaign)
  return url.toString()
}

// ─── Browser-side first touch (one per tab session) ─────────────
const STORAGE_KEY = 'fl_visit_attribution'
let memoryVisit: VisitAttribution | null = null

/** Records the visit source on the first page of the session; later pages reuse it. */
export function getVisitAttribution(): VisitAttribution {
  if (memoryVisit) return memoryVisit
  try {
    const stored = sessionStorage.getItem(STORAGE_KEY)
    if (stored) {
      memoryVisit = JSON.parse(stored) as VisitAttribution
      return memoryVisit
    }
  } catch {
    // storage blocked: keep the in-memory value only
  }
  memoryVisit = classifyVisit(window.location.search, document.referrer, window.location.pathname)
  try {
    sessionStorage.setItem(STORAGE_KEY, JSON.stringify(memoryVisit))
  } catch {
    // storage blocked
  }
  return memoryVisit
}
