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

test('builds the event properties with page surface', () => {
  assert.deepEqual(buildStoreClick(shortLink, '/resources/best-christian-app-blocker', 'comparison_cta', 'Download'), {
    destination_url: shortLink,
    destination_type: 'short_link',
    location: 'comparison_cta',
    button_text: 'Download',
    page_path: '/resources/best-christian-app-blocker',
    source: 'resource_page',
  })
  assert.equal(buildStoreClick(appLink, '/', '', '').source, 'site')
  assert.equal(buildStoreClick(appLink, '/', '').location, 'content')
  assert.equal(buildStoreClick('https://example.com', '/', 'hero'), null)
})
