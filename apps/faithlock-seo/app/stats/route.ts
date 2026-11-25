// /stats: the TikTok bio quiz funnel (public/quiz.html) and the app's installs, read from PostHog on
// each request. Private: opened with the code in STATS_PASSWORD, then kept for 30 days in a cookie.
// Server-side only settings:
//   POSTHOG_PERSONAL_API_KEY  a PostHog personal API key with « query:read » on both projects below
//   POSTHOG_PROJECT_ID        the website's project, « Faithlock - landing page » (324483): the quiz
//                             events. Not « FaithLock », the app's project, which has none of them.
//   POSTHOG_APP_PROJECT_ID    optional, the app's project (default 239251): the installs
//   POSTHOG_API_HOST          optional, default https://us.posthog.com
// ?days=7 sets the window (1 to 365, default 7).

import { createHash } from 'node:crypto'

export const dynamic = 'force-dynamic'

const EVENTS = [
  'diagnostic_view',
  'diagnostic_answer',
  'diagnostic_result',
  'diagnostic_slide',
  'faithlock_store_click',
  'diagnostic_escape_shown',
  'diagnostic_link_copied',
  'diagnostic_browser_open',
]
const QUIZ_PAGES = `(properties.url LIKE '/quiz%' OR properties.url IN ('/emma', '/emft'))`

const METRICS = `
  uniqIf(distinct_id, event = 'diagnostic_view') AS visitors,
  uniqIf(distinct_id, event = 'diagnostic_view' AND properties.in_app_browser = 'tiktok') AS in_tiktok,
  uniqIf(distinct_id, event = 'diagnostic_answer' AND toString(properties.step) = '1') AS started,
  uniqIf(distinct_id, event = 'diagnostic_result') AS completed,
  uniqIf(distinct_id, event = 'diagnostic_slide' AND toString(properties.index) = '4') AS reached_cta,
  uniqIf(distinct_id, event = 'faithlock_store_click' AND properties.location = 'quiz_result') AS store_clicks,
  uniqIf(distinct_id, event = 'faithlock_store_click' AND properties.location = 'quiz_result' AND properties.destination_type = 'onelink') AS onelink_clicks,
  uniqIf(distinct_id, event = 'diagnostic_escape_shown') AS blocked,
  uniqIf(distinct_id, event = 'diagnostic_browser_open') AS reopened`

// The mobile app's PostHog project. On its first launch the app sends `install_attributed` there, with
// what the AppsFlyer SDK reports (af_status, af_media_source, af_campaign): installs and their
// attribution are read from it, with no call to AppsFlyer's own API.
const APP_PROJECT_ID = process.env.POSTHOG_APP_PROJECT_ID || '239251'

type Row = Record<string, number | string>

async function hogql(query: string, projectId = process.env.POSTHOG_PROJECT_ID): Promise<Row[]> {
  const host = (process.env.POSTHOG_API_HOST || 'https://us.posthog.com').replace(/\/+$/, '')
  const res = await fetch(`${host}/api/projects/${projectId}/query/`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${process.env.POSTHOG_PERSONAL_API_KEY}`, 'Content-Type': 'application/json' },
    // PostHog caches API queries by default, and these keep the same text from one load to the next:
    // without `force_blocking` the page showed figures 40 minutes old. Always recompute.
    body: JSON.stringify({ query: { kind: 'HogQLQuery', query }, refresh: 'force_blocking' }),
    cache: 'no-store',
  })
  if (!res.ok) throw new Error(`PostHog ${res.status}: ${(await res.text()).slice(0, 300)}`)
  const data = (await res.json()) as { columns: string[]; results: unknown[][] }
  return data.results.map((r) => Object.fromEntries(data.columns.map((c, i) => [c, r[i] as number | string])))
}

const esc = (s: unknown) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]!)
const num = (v: unknown) => Number(v) || 0
const pct = (a: unknown, b: unknown) => (num(b) ? `${Math.round((num(a) / num(b)) * 100)} %` : '—')

const COOKIE = 'fl_stats'
/** What the cookie holds: a hash of the code, never the code itself. */
const token = () => createHash('sha256').update(`faithlock-stats:${process.env.STATS_PASSWORD}`).digest('hex')

function authorized(req: Request): boolean {
  if (!process.env.STATS_PASSWORD) return false
  const cookie = (req.headers.get('cookie') || '').split(/;\s*/).find((c) => c.startsWith(`${COOKIE}=`))
  return cookie?.slice(COOKIE.length + 1) === token()
}

const codeForm = (wrong: boolean) =>
  page(
    `<h1>Stats</h1><form method="post" style="margin-top:20px;display:flex;gap:10px;flex-wrap:wrap">
<input name="code" type="password" inputmode="numeric" autocomplete="one-time-code" placeholder="Code" autofocus
 style="font:inherit;font-size:20px;padding:12px 16px;border:2.5px solid #3D2B1F;border-radius:14px;background:#FFFDF8;width:180px">
<button style="font:inherit;font-weight:800;font-size:17px;padding:12px 22px;border:2.5px solid #3D2B1F;border-radius:99px;background:#D68A4E;color:#fff;box-shadow:2px 3px 0 #3D2B1F">Ouvrir</button>
</form>${wrong ? '<p style="color:#C0763C;font-weight:700">Code incorrect.</p>' : ''}`,
    wrong ? 401 : 200,
  )

export async function POST(req: Request) {
  const code = String((await req.formData()).get('code') || '')
  if (!process.env.STATS_PASSWORD || code !== process.env.STATS_PASSWORD) return codeForm(true)
  return new Response(null, {
    status: 303,
    headers: {
      Location: '/stats',
      'Set-Cookie': `${COOKIE}=${token()}; Path=/stats; Max-Age=2592000; HttpOnly; Secure; SameSite=Lax`,
    },
  })
}

function page(body: string, status = 200, extra: Record<string, string> = {}) {
  const html = `<!doctype html><html lang="fr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta name="robots" content="noindex"><title>Stats quiz | FaithLock</title>
<style>
body{margin:0;background:#FBF3E2;color:#3D2B1F;font:15px/1.5 -apple-system,BlinkMacSystemFont,Inter,sans-serif}
.w{max-width:980px;margin:0 auto;padding:28px 20px 60px}h1{margin:0;font-size:26px}h2{margin:36px 0 12px;font-size:18px}
.k{display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:12px;margin-top:20px}
.c{background:#FFFDF8;border:2.5px solid #3D2B1F;border-radius:18px;padding:14px 16px;box-shadow:2px 3px 0 #3D2B1F}
.c b{display:block;font-size:28px;line-height:1.1}.c span{font-size:13px;color:#9C8773;font-weight:700}.c i{font-style:normal;font-size:13px;font-weight:700;color:#C0763C}
table{width:100%;border-collapse:collapse;background:#FFFDF8;border:2.5px solid #3D2B1F;border-radius:14px;overflow:hidden}
th,td{padding:9px 12px;text-align:right;border-bottom:1px solid #EAD9BC;white-space:nowrap}th:first-child,td:first-child{text-align:left}
th{font-size:12px;color:#9C8773}.n{color:#9C8773;font-size:13px}nav a{margin-right:12px;color:#C0763C;font-weight:700}
.t{overflow-x:auto}</style></head><body><div class="w">${body}</div></body></html>`
  return new Response(html, { status, headers: { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-store', 'X-Robots-Tag': 'noindex', ...extra } })
}

export async function GET(req: Request) {
  if (!process.env.STATS_PASSWORD) return page('<h1>Stats</h1><p>STATS_PASSWORD n’est pas configuré.</p>', 503)
  if (!authorized(req)) return codeForm(false)
  if (!process.env.POSTHOG_PERSONAL_API_KEY || !process.env.POSTHOG_PROJECT_ID) {
    return page('<h1>Stats</h1><p>Il manque POSTHOG_PERSONAL_API_KEY ou POSTHOG_PROJECT_ID dans les variables Vercel.</p>', 503)
  }

  const days = Math.min(365, Math.max(1, Math.round(Number(new URL(req.url).searchParams.get('days')) || 7)))
  const where = `timestamp >= now() - INTERVAL ${days} DAY AND event IN (${EVENTS.map((e) => `'${e}'`).join(', ')}) AND ${QUIZ_PAGES}`

  let total: Row, byVariant: Row[], byPage: Row[], byDay: Row[]
  try {
    ;[[total], byVariant, byPage, byDay] = await Promise.all([
      hogql(`SELECT ${METRICS} FROM events WHERE ${where}`),
      hogql(`SELECT coalesce(nullIf(toString(properties.variant), ''), 'quiz') AS variant, ${METRICS} FROM events WHERE ${where} GROUP BY variant ORDER BY variant DESC`),
      hogql(`SELECT replaceRegexpOne(toString(properties.url), '\\\\.html$', '') AS page, ${METRICS} FROM events WHERE ${where} GROUP BY page ORDER BY visitors DESC`),
      hogql(`SELECT toDate(timestamp) AS day, ${METRICS} FROM events WHERE ${where} GROUP BY day ORDER BY day DESC`),
    ])
  } catch (e) {
    return page(`<h1>Stats</h1><p>Lecture PostHog impossible : ${esc((e as Error).message)}</p>`, 502)
  }

  // Installs, from the app's project. A failure here (a key that cannot read that project) must not
  // hide the quiz figures: the section says what went wrong instead.
  let installsByDay: Row[] = []
  let campaigns: Row[] = []
  let installsError = ''
  try {
    const installed = `timestamp >= now() - INTERVAL ${days} DAY AND event = 'install_attributed'`
    const attributed = `toString(properties.af_status) = 'Non-organic'`
    ;[installsByDay, campaigns] = await Promise.all([
      hogql(
        `SELECT toDate(timestamp) AS day, uniq(distinct_id) AS installs, uniqIf(distinct_id, ${attributed}) AS attributed FROM events WHERE ${installed} GROUP BY day ORDER BY day DESC`,
        APP_PROJECT_ID,
      ),
      hogql(
        `SELECT coalesce(nullIf(toString(properties.af_media_source), ''), '—') AS source, coalesce(nullIf(toString(properties.af_campaign), ''), '—') AS campaign, uniq(distinct_id) AS installs FROM events WHERE ${installed} AND ${attributed} GROUP BY source, campaign ORDER BY installs DESC LIMIT 20`,
        APP_PROJECT_ID,
      ),
    ])
  } catch (e) {
    installsError = (e as Error).message
  }

  const card = (label: string, value: unknown, rate?: string) =>
    `<div class="c"><span>${label}</span><b>${num(value)}</b>${rate ? `<i>${rate}</i>` : ''}</div>`
  const table = (rows: Row[], first: string, key: string) =>
    `<div class="t"><table><tr><th>${first}</th><th>Visiteurs</th><th>Dans TikTok</th><th>Commencé</th><th>Terminé</th><th>Écran final</th><th>Clic App Store</th><th>Conversion</th><th>Bloqués</th><th>Rouverts</th></tr>${rows
      .map(
        (r) =>
          `<tr><td>${esc(r[key])}</td><td>${num(r.visitors)}</td><td>${num(r.in_tiktok)}</td><td>${num(r.started)}</td><td>${num(r.completed)} <span class="n">${pct(r.completed, r.started)}</span></td><td>${num(r.reached_cta)}</td><td>${num(r.store_clicks)}</td><td>${pct(r.store_clicks, r.visitors)}</td><td>${num(r.blocked)}</td><td>${num(r.reopened)}</td></tr>`,
      )
      .join('') || '<tr><td colspan="10">Aucune donnée sur la période.</td></tr>'}</table></div>`

  // Installs beside the quiz's App Store clicks, day by day (UTC on both sides).
  const installsTotal = installsByDay.reduce((n, r) => n + num(r.installs), 0)
  const attributedTotal = installsByDay.reduce((n, r) => n + num(r.attributed), 0)
  const installsOf = new Map(installsByDay.map((r) => [String(r.day), r]))
  // Only a click that went through the OneLink can be matched to an install: inside a social app the
  // button went straight to the App Store, with no link AppsFlyer could see.
  const clicksOf = new Map(byDay.map((r) => [String(r.day), num(r.onelink_clicks)]))
  const allDays = Array.from(new Set(installsByDay.map((r) => String(r.day)).concat(byDay.map((r) => String(r.day)))))
    .sort()
    .reverse()

  // One row per bio link, shown even at zero: the people its page sent through its OneLink, and the
  // installs AppsFlyer matched to that link's campaign (told apart by the campaign's name).
  const linkOfPage = (p: string) => (/emma/i.test(p) ? 'emma' : /emft/i.test(p) ? 'emft' : 'quiz (sans compte)')
  const linkOfCampaign = (c: string) => (/^emma/i.test(c) ? 'emma' : /emft/i.test(c) ? 'emft' : c)
  const links = new Map<string, { clicks: number; installs: number; campaigns: string[] }>()
  const link = (k: string) => links.get(k) ?? links.set(k, { clicks: 0, installs: 0, campaigns: [] }).get(k)!
  link('emma')
  link('emft')
  byPage.forEach((r) => (link(linkOfPage(String(r.page))).clicks += num(r.onelink_clicks)))
  campaigns.forEach((r) => {
    const l = link(linkOfCampaign(String(r.campaign)))
    l.installs += num(r.installs)
    l.campaigns.push(String(r.campaign))
  })
  const linkRows: string[] = []
  links.forEach((v, k) => {
    if (k !== 'emma' && k !== 'emft' && !v.clicks && !v.installs) return
    linkRows.push(`<tr><td>${esc(k)}</td><td>${v.clicks}</td><td>${v.installs}</td><td>${esc(v.campaigns.join(', ') || '—')}</td></tr>`)
  })

  const installs = installsError
    ? `<p class="n">Lecture des installations impossible : ${esc(installsError)}</p>`
    : `<div class="k">
${card('Venues du lien', attributedTotal, 'attribuées par AppsFlyer')}
${card('Clics via OneLink', total.onelink_clicks, 'les seuls qu’AppsFlyer peut rapprocher')}
${card('Toutes sources', installsTotal, `dont ${installsTotal - attributedTotal} sans lien`)}
</div>
<h2>Par lien</h2>
<div class="t"><table><tr><th>Lien</th><th>Clics via OneLink</th><th>Installations venues du lien</th><th>Campagne AppsFlyer</th></tr>${linkRows.join('')}</table></div>
<h2>Par jour</h2>
<div class="t"><table><tr><th>Jour</th><th>Clics via OneLink</th><th>Installations venues du lien</th><th>Installations, toutes sources</th></tr>${
        allDays
          .map((d) => {
            const r = installsOf.get(d)
            return `<tr><td>${esc(d)}</td><td>${clicksOf.get(d) ?? 0}</td><td>${num(r?.attributed)}</td><td>${num(r?.installs)}</td></tr>`
          })
          .join('') || '<tr><td colspan="4">Aucune installation sur la période.</td></tr>'
      }</table></div>
<p class="n">« Venues du lien » : la personne a touché le lien OneLink (le bouton du quiz, ou le lien posé directement), installé l'app puis l'a ouverte, et AppsFlyer a fait le rapprochement. Il en manque : des installations suivent un clic de quelques minutes et restent comptées sans lien. « Toutes sources » compte chaque première ouverture de l'app, d'où qu'elle vienne. Chiffres lus dans le projet PostHog de l'app (événement install_attributed), en jours UTC.</p>`

  return page(`
<h1>Quiz TikTok, ${days} derniers jours</h1>
<nav><a href="?days=1">24 h</a><a href="?days=7">7 jours</a><a href="?days=30">30 jours</a><a href="?days=90">90 jours</a></nav>
<div class="k">
${card('Visiteurs', total.visitors)}
${card('Ont commencé', total.started, pct(total.started, total.visitors) + ' des visiteurs')}
${card('Ont terminé', total.completed, pct(total.completed, total.started) + ' de ceux qui commencent')}
${card('Écran final', total.reached_cta, pct(total.reached_cta, total.completed) + ' de ceux qui terminent')}
${card('Clic App Store', total.store_clicks, pct(total.store_clicks, total.visitors) + ' des visiteurs')}
${card('Bloqués par TikTok', total.blocked)}
${card('Rouverts dans Safari', total.reopened)}
</div>
<p class="n">Visiteurs uniques par appareil et par navigateur : une personne qui rouvre la page dans Safari compte deux fois.</p>
<h2>Installations venues du lien</h2>${installs}
<h2>Test A/B : quiz ou écran direct</h2>${table(byVariant, 'Version', 'variant')}
<p class="n">« direct » saute les questions : comparez la colonne Conversion (clics App Store sur visiteurs).</p>
<h2>Quiz, par lien</h2>${table(byPage, 'Page', 'page')}
<h2>Quiz, par jour</h2>${table(byDay, 'Jour', 'day')}`)
}
