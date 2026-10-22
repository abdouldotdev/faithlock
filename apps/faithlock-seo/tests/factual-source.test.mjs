import assert from 'node:assert/strict'
import fs from 'node:fs'
import path from 'node:path'
import test from 'node:test'
import { fileURLToPath } from 'node:url'

const here = path.dirname(fileURLToPath(import.meta.url))
const appRoot = path.resolve(here, '..')
const contentRoot = path.join(appRoot, 'seo-content')
const read = (relativePath) => fs.readFileSync(path.join(appRoot, relativePath), 'utf8')

function publicMarkdownFiles() {
  const files = []
  const visit = (directory) => {
    for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
      const absolute = path.join(directory, entry.name)
      if (entry.isDirectory()) {
        if (entry.name !== 'rules') visit(absolute)
      } else if (entry.name.endsWith('.md')) {
        files.push(absolute)
      }
    }
  }
  visit(contentRoot)
  return files
}

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
  assert.match(data, /displayedPrices: \[\] as const/)
  assert.doesNotMatch(data, /\$4\.99\/week|\$24\.99\/year|iOS 16\+|Android coming soon/)
})

test('core public pages do not publish unverified product claims', () => {
  const corePages = [
    'app/page.tsx',
    'app/(seo)/features/page.tsx',
    'lib/faithlock-data.ts',
    'lib/constants.ts',
    'components/landing/LandingFooter.tsx',
    'components/layout/Footer.tsx',
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

test('public SEO Markdown does not leak prohibited FaithLock pricing or attributed claims', () => {
  const prohibitedEverywhere = [
    /\$4\.99(?:\/week|\s+weekly|\/wk)/i,
    /\$24\.99(?:\/year|\s+annually|\/yr)/i,
    /Android\s+(?:coming|arriving|pending)/i,
    /Q2\s+2026/i,
  ]
  const attributed = [
    /(?:FaithLock|\[FaithLock\])[^\n]{0,100}(?:freemium|free tier|free version|iOS[- ]only|Android[^\n]{0,40}(?:coming|arriving|expected|pending)|30[- ]day covenant|Bible quiz|3-day free trial|works offline|never leaves your device|private and on-device)/i,
  ]
  for (const file of publicMarkdownFiles()) {
    const content = fs.readFileSync(file, 'utf8')
    for (const pattern of prohibitedEverywhere) {
      assert.doesNotMatch(content, pattern, `prohibited FaithLock pricing leaked in ${path.relative(appRoot, file)}`)
    }
    for (const pattern of attributed) {
      assert.doesNotMatch(content, pattern, `prohibited FaithLock claim leaked in ${path.relative(appRoot, file)}`)
    }
  }
})
