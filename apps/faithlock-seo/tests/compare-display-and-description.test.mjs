import assert from 'node:assert/strict'
import test from 'node:test'

import {
  getComparisonDescription,
  getComparisonTitle,
  getCompetitorDisplayName,
} from '../lib/compare-metadata.ts'
import {
  coerceToPlainText,
  MAX_META_DESCRIPTION_LENGTH,
  toMetaDescription,
} from '../lib/meta-description.ts'

// Every compare URL published in the Production sitemap on 2026-11-11.
const publishedSlugs = [
  'faithlock-vs-one-sec',
  'faithlock-vs-bible-mode',
  'faithlock-vs-holy-focus',
  'faithlock-vs-pray-screen-time',
  'faithlock-vs-bible-break',
  'faithlock-vs-appblock',
  'faithlock-vs-christian-app-blocker-comparison',
  'faithlock-vs-cold-turkey',
  'faithlock-vs-opal',
  'faithlock-vs-ios-vs-android-christian-apps',
  'faithlock-vs-freedom',
  'faithlock-vs-best-christian-screen-time-apps',
  'faithlock-vs-free-vs-paid-christian-apps',
]

// Regression: Production rendered the raw Contentful slug in the H1,
// breadcrumb and table header on the entries whose `name` is a slug, e.g.
// "FaithLock vs faithlock-vs-opal" (observed 2026-11-11).
test('a slug-shaped competitor name is humanized for visible copy', () => {
  const name = getCompetitorDisplayName({ name: 'faithlock-vs-opal' }, 'faithlock-vs-opal')
  assert.equal(name, 'Opal')
  assert.doesNotMatch(name, /faithlock-vs-/i)
})

test('an editorial competitor name is never rewritten', () => {
  assert.equal(getCompetitorDisplayName({ name: 'Bible Mode' }, 'faithlock-vs-bible-mode'), 'Bible Mode')
  assert.equal(getCompetitorDisplayName({ name: 'One Sec' }, 'faithlock-vs-one-sec'), 'One Sec')
})

test('a bare slug name is humanized and an empty name falls back to the route', () => {
  assert.equal(getCompetitorDisplayName({ name: 'cold-turkey' }, 'faithlock-vs-cold-turkey'), 'Cold Turkey')
  assert.equal(getCompetitorDisplayName({ name: '' }, 'faithlock-vs-opal'), 'Opal')
  assert.equal(getCompetitorDisplayName({ name: undefined }, 'faithlock-vs-opal'), 'Opal')
})

test('no published compare slug leaks a raw slug into the visible name', () => {
  for (const slug of publishedSlugs) {
    const name = getCompetitorDisplayName({ name: slug }, slug)
    assert.doesNotMatch(name, /faithlock-vs-/i, `${slug} leaked the raw slug: ${name}`)
    assert.ok(name.trim(), `${slug} produced an empty display name`)
  }
})

// Regression: eight of the thirteen compare URLs shipped with no meta
// description at all (measured on Production 2026-11-11).
test('a missing seoDescription produces a bounded, non-empty fallback', () => {
  for (const slug of publishedSlugs) {
    const description = getComparisonDescription({ name: slug, seoDescription: '' }, slug)
    assert.ok(description.trim(), `${slug} produced an empty description`)
    assert.ok(
      description.length <= MAX_META_DESCRIPTION_LENGTH,
      `${slug} description is ${description.length} chars`,
    )
    assert.doesNotMatch(description, /faithlock-vs-/i, `${slug} leaked the raw slug: ${description}`)
  }
})

test('fallback descriptions are unique per compare URL', () => {
  const descriptions = publishedSlugs.map((slug) =>
    getComparisonDescription({ name: slug, seoDescription: '' }, slug),
  )
  assert.equal(new Set(descriptions).size, descriptions.length)
})

test('an editorial seoDescription survives untouched', () => {
  const configured = 'FaithLock vs Opal: a Christian alternative to a secular screen time app.'
  assert.equal(
    getComparisonDescription({ name: 'Opal', seoDescription: configured }, 'faithlock-vs-opal'),
    configured,
  )
})

test('toMetaDescription collapses whitespace and bounds long text on a word boundary', () => {
  assert.equal(toMetaDescription('  spaced   out\n\ntext '), 'spaced out text')
  assert.equal(toMetaDescription(''), undefined)
  assert.equal(toMetaDescription('   '), undefined)
  assert.equal(toMetaDescription(undefined), undefined)

  const long = 'Doomscrolling is the compulsive behaviour of continuously consuming distressing content. '.repeat(4)
  const bounded = toMetaDescription(long)
  assert.ok(bounded.length <= MAX_META_DESCRIPTION_LENGTH, `length ${bounded.length}`)
  assert.ok(bounded.endsWith('…'), bounded)
  assert.doesNotMatch(bounded, /\s…$/)
})

test('toMetaDescription keeps short text verbatim', () => {
  assert.equal(toMetaDescription('What is doomscrolling?'), 'What is doomscrolling?')
})

// Regression (ABD-800): Contentful returns Rich text documents for
// `seoDescription` on the five entries whose Production meta description was
// literally "[object Object]", and `getComparisonDescription` called `.trim()`
// on it. That threw during prerendering and failed the whole Vercel build:
//   TypeError: e.seoDescription?.trim is not a function
//   Export encountered errors on following paths:
//     /(seo)/compare/[slug]/page: /compare/faithlock-vs-one-sec (and 4 more)
const contentfulRichText = (text) => ({
  nodeType: 'document',
  data: {},
  content: [
    {
      nodeType: 'paragraph',
      data: {},
      content: [{ nodeType: 'text', value: text, marks: [], data: {} }],
    },
  ],
})

test('a Rich text seoDescription is read as text instead of crashing the build', () => {
  const configured = 'FaithLock vs Opal: features, pricing and a biblical perspective.'
  assert.equal(
    getComparisonDescription(
      { name: 'Opal', seoDescription: contentfulRichText(configured) },
      'faithlock-vs-opal',
    ),
    configured,
  )
})

test('a Rich text seoTitle is read as text instead of crashing the build', () => {
  const configured = 'FaithLock vs Opal | FaithLock'
  assert.equal(
    getComparisonTitle({ name: 'Opal', seoTitle: contentfulRichText(configured) }, 'faithlock-vs-opal'),
    configured,
  )
})

test('no published compare URL can render an object-shaped description', () => {
  for (const slug of publishedSlugs) {
    const description = getComparisonDescription(
      { name: slug, seoDescription: contentfulRichText(`Editorial copy for ${slug}.`) },
      slug,
    )
    assert.ok(description.trim(), `${slug} produced an empty description`)
    assert.doesNotMatch(description, /\[object Object\]/, `${slug} leaked an object`)
  }
})

test('coerceToPlainText flattens rich text, locale wrappers and arrays', () => {
  assert.equal(coerceToPlainText(contentfulRichText('Hello world')), 'Hello world')
  assert.equal(coerceToPlainText({ 'en-US': 'Localised copy' }), 'Localised copy')
  assert.equal(coerceToPlainText([contentfulRichText('First'), contentfulRichText('Second')]), 'First Second')
  assert.equal(coerceToPlainText('  plain   text '), 'plain text')
  assert.equal(coerceToPlainText(''), undefined)
  assert.equal(coerceToPlainText(null), undefined)
  assert.equal(coerceToPlainText(42), undefined)
  assert.equal(coerceToPlainText({}), undefined)
})

test('toMetaDescription accepts a Rich text value', () => {
  assert.equal(
    toMetaDescription(contentfulRichText('Bounded rich text description.')),
    'Bounded rich text description.',
  )
  assert.equal(toMetaDescription({}), undefined)
})
