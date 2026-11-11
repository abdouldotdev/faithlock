import assert from 'node:assert/strict'
import test from 'node:test'
import fs from 'node:fs'
import path from 'node:path'
import { createRequire } from 'node:module'
import { fileURLToPath } from 'node:url'

import ts from 'typescript'

import { getComparisonQuickSummary } from '../lib/compare-summary.ts'
import { getCompetitorDisplayName } from '../lib/compare-metadata.ts'

const require = createRequire(import.meta.url)
const here = path.dirname(fileURLToPath(import.meta.url))
const appRoot = path.resolve(here, '..')

// Every compare URL published in the Production sitemap on 2026-11-11 —
// the same 13 URLs the acceptance criterion covers.
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

const BODY =
  'FaithLock focuses on Scripture-based app blocking with Bible verse unlocking. ' +
  'The best choice depends on your priorities — we compare both below.'

function expectedSummary(slug) {
  const name = getCompetitorDisplayName({ name: slug }, slug)
  return `FaithLock vs ${name}. ${BODY}`
}

/** The tagline Contentful serves today: the importer's own default. */
function legacyTagline(slug) {
  return `Compare FaithLock vs ${slug.replace('faithlock-vs-', '').replace(/-/g, ' ')}`
}

// ─── Minimal TSX loader ────────────────────────────────────────────────
// The Quick Summary block is rendered for real (no jsdom shim, no snapshot
// copy of the markup): the .tsx is compiled with the project's TypeScript and
// evaluated with a `require` that resolves only the imports listed in `mocks`
// plus React's runtime. Any new import fails loudly instead of being faked.

function resolveModule(fromFile, specifier) {
  const base = path.resolve(path.dirname(fromFile), specifier)
  for (const candidate of [base, `${base}.ts`, `${base}.tsx`]) {
    if (fs.existsSync(candidate) && fs.statSync(candidate).isFile()) return candidate
  }
  throw new Error(`cannot resolve ${specifier} from ${fromFile}`)
}

function loadModule(filePath, mocks = {}) {
  const source = fs.readFileSync(filePath, 'utf8')
  const { outputText } = ts.transpileModule(source, {
    compilerOptions: {
      module: ts.ModuleKind.CommonJS,
      target: ts.ScriptTarget.ES2020,
      jsx: ts.JsxEmit.ReactJSX,
      esModuleInterop: true,
    },
    fileName: filePath,
  })

  const loaded = { exports: {} }
  const localRequire = (specifier) => {
    if (Object.prototype.hasOwnProperty.call(mocks, specifier)) return mocks[specifier]
    if (specifier === 'react') return require('react')
    if (specifier === 'react/jsx-runtime') return require('react/jsx-runtime')
    if (specifier.startsWith('.')) return loadModule(resolveModule(filePath, specifier), mocks)
    throw new Error(`unexpected import "${specifier}" in ${path.basename(filePath)}`)
  }
  new Function('require', 'module', 'exports', outputText)(localRequire, loaded, loaded.exports)
  return loaded.exports
}

const helper = loadModule(path.join(appRoot, 'lib', 'compare-summary.ts'))
const { default: ComparisonQuickSummary } = loadModule(
  path.join(appRoot, 'components', 'templates', 'ComparisonQuickSummary.tsx'),
  { '@/lib/compare-summary': helper },
)
const React = require('react')
const { renderToStaticMarkup } = require('react-dom/server')

function renderQuickSummary(slug) {
  return renderToStaticMarkup(
    React.createElement(ComparisonQuickSummary, {
      competitorName: getCompetitorDisplayName({ name: slug }, slug),
      // Realistic Contentful field: the template must ignore it.
      tagline: legacyTagline(slug),
    }),
  )
}

/** The single paragraph of the block, decoded, with whitespace collapsed. */
function renderedParagraph(html) {
  const match = html.match(/<p class="text-cozy-ink\/80 leading-relaxed">([\s\S]*?)<\/p>/)
  assert.ok(match, `Quick Summary paragraph not found in:\n${html}`)
  return match[1]
    .replace(/<[^>]+>/g, '')
    .replace(/&mdash;/g, '—')
    .replace(/&amp;/g, '&')
    .replace(/&#x27;/g, "'")
    .replace(/\s+/g, ' ')
    .trim()
}

// ─── Contract ──────────────────────────────────────────────────────────

test('the summary is the mandated answer-first sentence for one competitor', () => {
  assert.equal(getComparisonQuickSummary('Opal'), `FaithLock vs Opal. ${BODY}`)
})

test('all 13 published compare slugs produce the exact mandated sentence', () => {
  assert.equal(publishedSlugs.length, 13)
  for (const slug of publishedSlugs) {
    const summary = expectedSummary(slug)
    assert.equal(
      getComparisonQuickSummary(getCompetitorDisplayName({ name: slug }, slug)),
      summary,
      `${slug} summary drifted`,
    )
    assert.doesNotMatch(summary, /compare faithlock vs/i, `${slug} kept the duplicated tagline`)
    assert.match(summary, /^FaithLock vs \S/, `${slug} must open with the h1 wording`)
  }
})

test('the rendered Quick Summary block of all 13 slugs carries the exact sentence', () => {
  for (const slug of publishedSlugs) {
    const html = renderQuickSummary(slug)
    assert.equal(renderedParagraph(html), expectedSummary(slug), `${slug} rendered paragraph drifted`)
    assert.doesNotMatch(html, /compare faithlock vs/i, `${slug} rendered the duplicated tagline`)
    assert.match(html, /Quick Summary/, `${slug} lost the block heading`)
  }
})

test('the rendered block keeps the h1 wording and drops the competitor tagline dependency', () => {
  // Sanity on the rendered paragraph: it starts exactly like the h1.
  const html = renderQuickSummary('faithlock-vs-opal')
  assert.match(renderedParagraph(html), /^FaithLock vs Opal\./)

  // The full page render needs Contentful credentials, so the h1 and the
  // tagline independence are asserted on the template source instead.
  const template = fs.readFileSync(
    path.join(appRoot, 'components', 'templates', 'ComparisonTemplate.tsx'),
    'utf8',
  )
  assert.match(template, /FaithLock vs \{competitor\.name\}/, 'the h1 wording must stay unchanged')
  assert.doesNotMatch(template, /competitor\.tagline/, 'the compare template must not read taglines')
})

test('the helper never echoes a tagline-shaped string', () => {
  for (const slug of publishedSlugs) {
    const name = getCompetitorDisplayName({ name: slug }, slug)
    assert.doesNotMatch(getComparisonQuickSummary(name), /faithlock-vs-/i, `${slug} leaked a slug`)
  }
})

test('an empty competitor name still yields a readable sentence', () => {
  const summary = getComparisonQuickSummary('   ')
  assert.match(summary, /^FaithLock vs this app\./)
  assert.doesNotMatch(summary, /compare faithlock vs/i)
})
