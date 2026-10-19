import assert from 'node:assert/strict'
import { readFileSync, readdirSync, statSync } from 'node:fs'
import { join } from 'node:path'
import test from 'node:test'

import {
  OFFICIAL_FAITHLOCK_APP_STORE_URL,
  normalizeAppStoreUrl,
  sanitizeAppStoreLinksInHtml,
} from '../lib/app-store-links.ts'

test('normalizes every FaithLock App Store URL to the official app', () => {
  assert.equal(
    normalizeAppStoreUrl('https://apps.apple.com/app/faithlock'),
    OFFICIAL_FAITHLOCK_APP_STORE_URL,
  )
  assert.equal(
    normalizeAppStoreUrl('https://apps.apple.com/us/app/faithlock/id6754208209'),
    OFFICIAL_FAITHLOCK_APP_STORE_URL,
  )
})

test('rejects competitor and generic App Store URLs', () => {
  assert.equal(normalizeAppStoreUrl('https://apps.apple.com/app/bible-mode/id6502637936'), null)
  assert.equal(normalizeAppStoreUrl('https://apps.apple.com/app/bitbible-daily-bible-verses/id1586high'), null)
  assert.equal(normalizeAppStoreUrl('https://apps.apple.com'), null)
})

test('removes competitor anchors while preserving their visible labels', () => {
  const html = [
    '<p><a href="https://apps.apple.com/app/bible-mode/id6502637936">Bible Mode</a></p>',
    '<p><a href="https://apps.apple.com/app/faithlock">FaithLock</a></p>',
  ].join('')
  const cleaned = sanitizeAppStoreLinksInHtml(html)
  assert.match(cleaned, /<p>Bible Mode<\/p>/)
  assert.doesNotMatch(cleaned, /href="[^"]*bible-mode/)
  assert.match(cleaned, new RegExp(`href="${OFFICIAL_FAITHLOCK_APP_STORE_URL}"`))
})

function filesUnder(root) {
  const out = []
  for (const name of readdirSync(root)) {
    const path = join(root, name)
    if (statSync(path).isDirectory()) out.push(...filesUnder(path))
    else out.push(path)
  }
  return out
}

test('SEO source content contains no App Store links to competitors', () => {
  const root = new URL('../seo-content/', import.meta.url).pathname
  const violations = []
  for (const path of filesUnder(root).filter((p) => p.endsWith('.md'))) {
    const body = readFileSync(path, 'utf8')
    for (const match of body.matchAll(/https:\/\/apps\.apple\.com[^\s)>]*/g)) {
      if (normalizeAppStoreUrl(match[0]) !== OFFICIAL_FAITHLOCK_APP_STORE_URL) {
        violations.push(`${path}:${match[0]}`)
      }
    }
  }
  assert.deepEqual(violations, [])
})
