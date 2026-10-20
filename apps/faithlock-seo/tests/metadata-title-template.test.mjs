import assert from 'node:assert/strict'
import crypto from 'node:crypto'
import fs from 'node:fs'
import path from 'node:path'
import test from 'node:test'
import { fileURLToPath } from 'node:url'

const here = path.dirname(fileURLToPath(import.meta.url))
const appRoot = path.resolve(here, '..')
const targets = [
  'seo-content/new-pages/bible-verses/bible-verses-about-gods-presence.md',
  'seo-content/new-pages/best-bible-verse-lock-screen-apps.md',
]
const lettingGoPath = 'seo-content/new-pages/bible-verses/bible-verses-about-letting-go.md'
const lettingGoVariant = '10 Bible Verses About Letting Go (With Practical Steps)'
const lettingGoBodySha256 = '6aed82dbc2dfa35e944c88520738ec59aa2571692fa1168bde3fd50a821af33b'

function readMetaTitle(relativePath) {
  const source = fs.readFileSync(path.join(appRoot, relativePath), 'utf8')
  const match = source.match(/^meta_title:\s*["']?(.*?)["']?\s*$/m)
  assert.ok(match, `${relativePath} must define meta_title`)
  return match[1]
}

function readFrontmatter(relativePath) {
  const source = fs.readFileSync(path.join(appRoot, relativePath), 'utf8')
  const match = source.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/)
  assert.ok(match, `${relativePath} must have YAML frontmatter`)
  const metadata = Object.fromEntries(
    match[1]
      .split('\n')
      .filter(Boolean)
      .map((line) => {
        const separator = line.indexOf(':')
        return [line.slice(0, separator), line.slice(separator + 1).trim().replace(/^"|"$/g, '')]
      }),
  )
  return { metadata, body: match[2] }
}

test('global layout owns the FaithLock title suffix', () => {
  const layout = fs.readFileSync(path.join(appRoot, 'app/layout.tsx'), 'utf8')
  assert.match(layout, /template:\s*`%s \| \$\{SITE_NAME\}`/)
})

test('local SEO meta titles do not duplicate the global FaithLock suffix', () => {
  for (const target of targets) {
    const title = readMetaTitle(target)
    assert.doesNotMatch(
      title,
      /\s\|\sFaithLock$/,
      `${target} must leave the FaithLock suffix to app/layout.tsx`,
    )
  }
})

test('letting-go CTR variant keeps title, meta description, H1 source, and article body stable', () => {
  const { metadata, body } = readFrontmatter(lettingGoPath)

  assert.equal(metadata.title, lettingGoVariant)
  assert.equal(metadata.meta_title, lettingGoVariant)
  assert.equal(
    metadata.meta_description,
    'Explore 10 Bible verses about letting go of hurt, control, and the past, with practical steps to help you release what you are carrying.',
  )
  assert.equal(
    crypto.createHash('sha256').update(body).digest('hex'),
    lettingGoBodySha256,
    'the SEO experiment must not change the article body',
  )
})
