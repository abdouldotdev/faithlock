import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import test from 'node:test'

const pagePath = new URL('../seo-content/new-pages/bible-verses-phone-addiction.md', import.meta.url)
const approvedTitle = '15 Bible Verses About Phone Addiction (+ How to Actually Use Them)'
const approvedDescription =
  "15 Bible verses about phone addiction, with practical ways to use each passage to break the scroll and refocus on God's Word."
const approvedCta = '[Try FaithLock Free](https://pim.ms/kTxgKF4)'

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

test('phone addiction CTR variant keeps the approved metadata and contextual CTA', async () => {
  const source = await readFile(pagePath, 'utf8')
  const meta = frontmatter(source)
  const practicalSection = source.indexOf('## How to Actually Use These Verses (Not Just Read Them)')
  const ctaPosition = source.indexOf(approvedCta)

  assert.equal(meta.title, approvedTitle)
  assert.equal(meta.meta_title, approvedTitle)
  assert.equal(meta.meta_description, approvedDescription)
  assert.equal(source.split(approvedCta).length - 1, 1)
  assert.ok(ctaPosition > practicalSection, 'CTA must follow the practical-use section')
})
