import assert from 'node:assert/strict'
import fs from 'node:fs'
import path from 'node:path'
import test from 'node:test'
import { fileURLToPath } from 'node:url'

const here = path.dirname(fileURLToPath(import.meta.url))
const appRoot = path.resolve(here, '..')
const read = (relativePath) => fs.readFileSync(path.join(appRoot, relativePath), 'utf8')

test('factual registry names only authoritative sources and excludes look-alike apps', () => {
  const facts = read('seo-content/rules/FAITHLOCK_FACTS.md')
  assert.match(facts, /https:\/\/apps\.apple\.com\/us\/app\/faith-lock-bible-prayer-focus\/id6754208209/)
  assert.match(facts, /https:\/\/www\.getfaithlock\.com\//)
  assert.doesNotMatch(facts, /https:\/\/faithlock\.net\//)
  assert.match(facts, /id6786329834/)
  assert.match(facts, /id6756815467/)
})

test('shared product data matches the verified App Store identity and platform', () => {
  const data = read('lib/faithlock-data.ts')
  assert.match(data, /Appbiz Studio, LLC/)
  assert.match(data, /available: \['iPhone', 'iPad'\]/)
  assert.match(data, /minVersion: 'iOS 13\.0\+/)
  assert.match(data, /displayedPrices: \['\$6\.99', '\$39\.99'\]/)
  assert.doesNotMatch(data, /\$4\.99\/week|\$24\.99\/year|iOS 16\+|Android coming soon/)
})

test('core public pages do not publish unverified product claims', () => {
  const corePages = [
    'app/page.tsx',
    'app/(seo)/features/page.tsx',
    'lib/faithlock-data.ts',
    'lib/constants.ts',
  ].map(read).join('\n')
  for (const pattern of [
    /100k\+/i,
    /private and on-device/i,
    /all data stays on your device/i,
    /\$4\.99\/week/i,
    /\$24\.99\/year/i,
    /iOS 16\+/i,
    /Android coming soon/i,
  ]) {
    assert.doesNotMatch(corePages, pattern, `unverified claim leaked: ${pattern}`)
  }
})
