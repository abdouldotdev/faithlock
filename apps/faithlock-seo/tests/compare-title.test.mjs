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
  assert.equal(first, 'FaithLock vs Representative Tool — Representative Tool comparison')
})
