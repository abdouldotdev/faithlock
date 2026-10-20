import test from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { join } from 'node:path'

const contentRoot = join(import.meta.dirname, '..', 'seo-content', 'new-pages')
const pages = {
  'bible-verses-about-gods-presence': join(
    contentRoot,
    'bible-verses',
    'bible-verses-about-gods-presence.md',
  ),
  'best-bible-verse-lock-screen-apps': join(
    contentRoot,
    'best-bible-verse-lock-screen-apps.md',
  ),
}

function readMetaTitle(filePath) {
  const source = readFileSync(filePath, 'utf8')
  const match = source.match(/^meta_title:\s*(?:"([^"]*)"|'([^']*)'|(.+))$/m)
  assert.ok(match, `missing meta_title in ${filePath}`)
  return (match[1] ?? match[2] ?? match[3]).trim()
}

test('resource meta titles leave the FaithLock suffix to the root layout', () => {
  for (const [slug, filePath] of Object.entries(pages)) {
    const title = readMetaTitle(filePath)
    assert.doesNotMatch(title, /\s\|\sFaithLock$/i, `${slug} must not duplicate the layout suffix`)
    assert.doesNotMatch(title, /(?:\s\|\sFaithLock){2,}$/i, `${slug} must not contain repeated suffixes`)
  }
})
