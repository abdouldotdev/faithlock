import assert from 'node:assert/strict'
import test from 'node:test'

import { getComparisonTitle } from '../lib/compare-metadata.ts'

const targetedSlugs = [
  'faithlock-vs-bible-mode',
  'faithlock-vs-holy-focus',
  'faithlock-vs-pray-screen-time',
  'faithlock-vs-one-sec',
  'faithlock-vs-opal',
  'faithlock-vs-forest',
  'faithlock-vs-freedom',
  'faithlock-vs-appblock',
]

test('every targeted compare slug gets a deterministic, unique non-empty title', () => {
  const titles = targetedSlugs.map((slug) =>
    getComparisonTitle({ name: slug.replace('faithlock-vs-', ''), seoTitle: '' }, slug),
  )

  assert.equal(new Set(titles).size, targetedSlugs.length)
  for (const title of titles) {
    assert.ok(title.trim())
    assert.match(title, /^FaithLock vs /)
  }
})

test('existing editorial seoTitle remains unchanged', () => {
  assert.equal(
    getComparisonTitle(
      { name: 'Opal', seoTitle: 'FaithLock vs Opal: A Christian Alternative' },
      'faithlock-vs-opal',
    ),
    'FaithLock vs Opal: A Christian Alternative',
  )
})

test('fallback is stable and uses the route slug when Contentful fields are incomplete', () => {
  const fields = { name: '', seoTitle: '' }
  const slug = 'faithlock-vs-representative-tool'
  const first = getComparisonTitle(fields, slug)

  assert.equal(getComparisonTitle(fields, slug), first)
  assert.equal(first, 'FaithLock vs Representative Tool')
})

// Regression: 2026-11-11 Production titles on /compare/* exposed the raw
// Contentful slug, e.g. "FaithLock vs faithlock-vs-opal — Opal comparison".
test('a Contentful name that is itself a prefixed slug never leaks the slug', () => {
  const title = getComparisonTitle(
    { name: 'faithlock-vs-opal', seoTitle: '' },
    'faithlock-vs-opal',
  )

  assert.equal(title, 'FaithLock vs Opal')
  assert.doesNotMatch(title, /faithlock-vs-/i)
})

test('a Contentful name that is a bare slug is humanized', () => {
  const title = getComparisonTitle(
    { name: 'christian-app-blocker-comparison', seoTitle: '' },
    'faithlock-vs-christian-app-blocker-comparison',
  )

  assert.equal(title, 'FaithLock vs Christian App Blocker Comparison')
  assert.doesNotMatch(title, /comparison comparison/i)
})

test('a lowercase Contentful name is title-cased instead of dropped', () => {
  assert.equal(
    getComparisonTitle({ name: 'opal', seoTitle: '' }, 'faithlock-vs-opal'),
    'FaithLock vs Opal',
  )
})

test('route tokens keep acronyms and interior small words readable', () => {
  assert.equal(
    getComparisonTitle({ name: '', seoTitle: '' }, 'faithlock-vs-ios-vs-android-christian-apps'),
    'FaithLock vs iOS vs Android Christian Apps',
  )
})

test('the comparison suffix is only used when the competitor name adds information', () => {
  assert.equal(
    getComparisonTitle({ name: 'Appblock', seoTitle: '' }, 'faithlock-vs-appblock'),
    'FaithLock vs Appblock',
  )
  assert.equal(
    getComparisonTitle({ name: 'Secular Focus Timer', seoTitle: '' }, 'faithlock-vs-one-sec'),
    'FaithLock vs Secular Focus Timer — One Sec comparison',
  )
})

test('no fallback title exceeds a SERP-safe length', () => {
  const long = 'faithlock-vs-best-christian-screen-time-apps-for-families-2026'
  const title = getComparisonTitle({ name: long, seoTitle: '' }, long)

  assert.ok(title.length <= 70, `${title} is ${title.length} chars`)
  assert.match(title, /^FaithLock vs /)
})
