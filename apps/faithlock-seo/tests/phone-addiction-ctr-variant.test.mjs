import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import test from 'node:test'

const pagePath = new URL('../seo-content/new-pages/bible-verses-phone-addiction.md', import.meta.url)
const approvedTitle = '15 Bible Verses About Phone Addiction (+ How to Actually Use Them)'
const approvedDescription =
  "15 Bible verses about phone addiction, with practical ways to use each passage to break the scroll and refocus on God's Word."

// The answer-first revision (ABD-715) replaced the earlier `pim.ms` short-link CTA
// with one in-body link to the official App Store listing that carries its own
// `data-store-location`, so the click is attributable per placement. A2 (OneLink
// CTA on resource pages) remains deferred by the ABD-782 decision; until it is
// decided, the body CTA must stay on the official listing.
const officialStoreUrl = 'https://apps.apple.com/us/app/faith-lock-bible-prayer-focus/id6754208209'
const storeLocation = 'bible_verses_phone_addiction_answer_first_cta'
const ctaTag = `<a href="${officialStoreUrl}" data-store-location="${storeLocation}">`
const practiceSectionHeading = '## When a structured pause would help'

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

test('phone addiction answer-first variant keeps the approved metadata and one tracked in-body CTA', async () => {
  const source = await readFile(pagePath, 'utf8')
  const meta = frontmatter(source)
  const practiceSection = source.indexOf(practiceSectionHeading)
  const ctaPosition = source.indexOf(ctaTag)
  const ctaCount = source.split(ctaTag).length - 1

  assert.equal(meta.title, approvedTitle)
  assert.equal(meta.meta_title, approvedTitle)
  assert.equal(meta.meta_description, approvedDescription)
  assert.ok(practiceSection > -1, `page must keep the "${practiceSectionHeading}" section`)
  assert.equal(ctaCount, 1, 'page must expose exactly one in-body App Store CTA')
  assert.ok(ctaPosition > practiceSection, 'CTA must follow the practice section')
  assert.doesNotMatch(source, /pim\.ms\/kTxgKF4/, 'the retired short-link CTA must not reappear in the body')
})
