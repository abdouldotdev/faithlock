import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import test from 'node:test'

const pagePath = new URL('../seo-content/new-pages/best-bible-verse-wallpaper-apps.md', import.meta.url)

function frontmatter(source) {
  const match = source.match(/^---\n([\s\S]*?)\n---\n/)
  assert.ok(match, 'page must have YAML frontmatter')
  return Object.fromEntries(
    match[1]
      .split('\n')
      .filter(Boolean)
      .map((line) => {
        const separator = line.indexOf(':')
        return [line.slice(0, separator), line.slice(separator + 1).trim().replace(/^"|"$/g, '')]
      }),
  )
}

test('wallpaper CTR variant keeps the approved iPhone metadata and CTA destination', async () => {
  const source = await readFile(pagePath, 'utf8')
  const meta = frontmatter(source)

  assert.equal(meta.title, 'Best Bible Verse Wallpaper Apps for iPhone (6 Free & Paid Picks) | FaithLock')
  assert.equal(meta.meta_title, meta.title)
  assert.equal(
    meta.meta_description,
    'Looking for a Bible verse wallpaper app for iPhone? Compare 6 free and paid options with real examples to choose the right fit for your phone.',
  )
  assert.match(source, /\[Try FaithLock Free\]\(https:\/\/pim\.ms\/kTxgKF4\)/)
})
