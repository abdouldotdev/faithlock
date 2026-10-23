import test from 'node:test'
import assert from 'node:assert/strict'
import { buildStoreClick, storeDestinationType } from '../lib/store-click.ts'

const shortLink = 'https://pim.ms/kTxgKF4'
const appLink = 'https://apps.apple.com/us/app/faith-lock-bible-prayer-focus/id6754208209'

test('recognizes both FaithLock store destinations', () => {
  assert.equal(storeDestinationType(shortLink), 'short_link')
  assert.equal(storeDestinationType(appLink), 'app_store')
  assert.equal(storeDestinationType('https://apps.apple.com/fr/app/faithlock/id6754208209'), 'app_store')
})

test('ignores other apps, look-alike ids and non-https links', () => {
  assert.equal(storeDestinationType('https://apps.apple.com/us/app/opal-screen-time-control/id1497465230'), null)
  assert.equal(storeDestinationType('https://apps.apple.com/us/app/x/id67542082099'), null)
  assert.equal(storeDestinationType('https://apps.apple.com/us/app/other/id6786329834'), null)
  assert.equal(storeDestinationType('http://pim.ms/kTxgKF4'), null)
  assert.equal(storeDestinationType('https://pim.ms/other'), null)
  assert.equal(storeDestinationType('/resources/foo'), null)
})

test('builds the contract receipt with CTA, market, source and destination', () => {
  assert.deepEqual(buildStoreClick(shortLink, '/resources/best-christian-app-blocker', 'comparison_cta', 'Download'), {
    cta_id: 'comparison_cta',
    market: 'en-US',
    source: 'resource_page',
    destination: 'official_app_store',
    destination_url: shortLink,
    destination_type: 'short_link',
    location: 'comparison_cta',
    button_text: 'Download',
    page_path: '/resources/best-christian-app-blocker',
  })
  assert.equal(buildStoreClick(appLink, '/', '', '').source, 'site')
  assert.equal(buildStoreClick(appLink, '/', '').cta_id, 'content')
  assert.equal(buildStoreClick('https://example.com', '/', 'hero'), null)
})

test('the Rosary CTA has a stable accessible tracking id and official app destination', async () => {
  const page = await (await import('node:fs/promises')).readFile(
    new URL('../seo-content/new-pages/catholic/how-to-pray-the-rosary.md', import.meta.url),
    'utf8',
  )
  assert.match(page, /<a href="https:\/\/apps\.apple\.com\/us\/app\/faith-lock-bible-prayer-focus\/id6754208209" data-store-location="rosary_faithlock_cta">Get FaithLock on the App Store<\/a>/)
  const receipt = buildStoreClick(appLink, '/resources/how-to-pray-the-rosary', 'rosary_faithlock_cta', 'Get FaithLock on the App Store')
  assert.deepEqual(receipt && {
    cta_id: receipt.cta_id,
    market: receipt.market,
    source: receipt.source,
    destination: receipt.destination,
  }, {
    cta_id: 'rosary_faithlock_cta',
    market: 'en-US',
    source: 'resource_page',
    destination: 'official_app_store',
  })
  assert.equal(receipt?.destination_url.endsWith('/id6754208209'), true)
})
