import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import test from 'node:test'

const pagePath = new URL('../seo-content/new-pages/best-bible-verse-widgets-iphone.md', import.meta.url)

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

test('CTR variant targets free iPhone widgets and distinguishes widget surfaces', async () => {
  const source = await readFile(pagePath, 'utf8')
  const meta = frontmatter(source)

  assert.match(meta.title, /Free Bible Widgets for iPhone/)
  assert.match(meta.meta_title, /Free Bible Widgets for iPhone/)
  assert.match(meta.meta_description, /free Bible widgets for iPhone/i)
  assert.match(meta.meta_description, /home-screen.*lock-screen/i)
  assert.doesNotMatch(`${meta.meta_title}${meta.meta_description}`, /[—–]/)

  assert.match(source, /Free Bible Widgets for iPhone: Home Screen vs Lock Screen/)
  assert.match(source, /App Store ID \*\*id6754208209\*\*/)
  assert.match(source, /FaithLock does not offer a native lock-screen widget/)
  assert.match(source, /https:\/\/apps\.apple\.com\/us\/app\/faith-lock-bible-prayer-focus\/id6754208209/g)
  assert.doesNotMatch(source, /FaithLock \| Free\//)
  assert.doesNotMatch(source, /Premium \(\$24\.99\/year\)/)
  assert.doesNotMatch(source, /\|\| FaithLock \|/)
})
