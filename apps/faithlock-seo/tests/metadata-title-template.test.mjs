import assert from 'node:assert/strict'
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

function readMetaTitle(relativePath) {
  const source = fs.readFileSync(path.join(appRoot, relativePath), 'utf8')
  const match = source.match(/^meta_title:\s*["']?(.*?)["']?\s*$/m)
  assert.ok(match, `${relativePath} must define meta_title`)
  return match[1]
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
