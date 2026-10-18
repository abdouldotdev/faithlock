import test from 'node:test'
import assert from 'node:assert/strict'
import { buildResourceStoreClick, getArticleStoreClick } from '../lib/resource-store-click.ts'

const page = '/resources/best-bible-verse-lock-screen-apps'
const shortLink = 'https://pim.ms/kTxgKF4'
const appLink = 'https://apps.apple.com/us/app/faith-lock-bible-prayer-focus/id6754208209'

test('tracks only official FaithLock store destinations on the two approved resources', () => {
  assert.deepEqual(buildResourceStoreClick({ href: shortLink, pagePath: page, position: 1, section: 'content' }), {
    cta_id: 'best-bible-verse-lock-screen-apps_store_1',
    page_path: page,
    link_position: 'content',
    market: 'US',
    source: 'resource_page',
    destination_url: shortLink,
    destination_type: 'short_link',
  })
  assert.equal(buildResourceStoreClick({ href: 'https://apps.apple.com/us/app/faithlock-pray-first/id6786329834', pagePath: page, position: 2, section: 'content' }), null)
  assert.equal(buildResourceStoreClick({ href: appLink, pagePath: '/resources/other', position: 1, section: 'content' }), null)
})

test('distinguishes official direct App Store links and rejects misleading domains', () => {
  const result = buildResourceStoreClick({ href: appLink, pagePath: '/resources/best-christian-app-blocker', position: 2, section: 'biblical-view' })
  assert.equal(result?.destination_type, 'app_store')
  assert.equal(result?.cta_id, 'best-christian-app-blocker_store_2')
  assert.equal(buildResourceStoreClick({ href: 'https://apps.apple.com.evil.example/us/app/id6754208209', pagePath: page, position: 1, section: 'content' }), null)
  assert.equal(buildResourceStoreClick({ href: 'https://pim.ms/kTxgKF4-evil', pagePath: page, position: 1, section: 'content' }), null)
})

test('article-only ordinal ignores a dynamic mobile header link and outside clicks', () => {
  const first = { href: shortLink, closest: () => ({ id: 'content' }) }
  const second = { href: appLink, closest: () => ({ id: 'content' }) }
  const mobileHeaderLink = { href: shortLink, closest: () => null }
  const article = {
    contains: (anchor) => anchor === first || anchor === second,
    querySelectorAll: () => [first, second],
  }
  assert.equal(getArticleStoreClick(article, second, page)?.cta_id, 'best-bible-verse-lock-screen-apps_store_2')
  assert.equal(getArticleStoreClick(article, mobileHeaderLink, page), null)
  // A mobile header link is outside the article and cannot shift its IDs.
  assert.equal(getArticleStoreClick(article, second, page)?.cta_id, 'best-bible-verse-lock-screen-apps_store_2')
})
