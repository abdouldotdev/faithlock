import assert from 'node:assert/strict'
import { readFile, readdir } from 'node:fs/promises'
import { fileURLToPath } from 'node:url'
import { join, relative } from 'node:path'
import test from 'node:test'

const contentRoot = fileURLToPath(new URL('../seo-content/', import.meta.url))
const factsPath = new URL('../seo-content/rules/FAITHLOCK_FACTS.md', import.meta.url)
const forbiddenSuperlative = 'The most comprehensive Christian screen time app'
const forbiddenSolutionSuperlative = 'the most comprehensive Christian screen time solution'
const faithLockIos16Pattern = /FaithLock[^\n]{0,240}iOS 16(?:\+|(?:\.0)?\s+or\s+later|\s+and\s+later)|iOS 16(?:\+|(?:\.0)?\s+or\s+later|\s+and\s+later)[^\n]{0,240}FaithLock/i

async function markdownFiles(directory, files = []) {
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name)
    if (entry.isDirectory()) await markdownFiles(path, files)
    else if (entry.isFile() && entry.name.endsWith('.md')) files.push(path)
  }
  return files
}

test('versioned facts record the official FaithLock App Store minimum iOS requirement', async () => {
  const facts = await readFile(factsPath, 'utf8')
  assert.match(facts, /Faith Lock: Bible Prayer Focus/)
  assert.match(facts, /id6754208209/)
  assert.match(facts, /Requires iOS 13\.0 or later/)
  assert.match(facts, /FaithLock requires iOS 13\.0 or later/)
})

test('public SEO Markdown contains no unsupported FaithLock iOS 16 requirement or exact superlative', async () => {
  const files = (await markdownFiles(contentRoot)).filter((path) => !relative(contentRoot, path).startsWith('rules/'))
  assert.ok(files.length > 0, 'public SEO Markdown must exist')

  const violations = []
  for (const path of files) {
    const source = await readFile(path, 'utf8')
    if (source.includes(forbiddenSuperlative) || source.toLowerCase().includes(forbiddenSolutionSuperlative)) {
      violations.push(`${relative(contentRoot, path)}: unsupported superlative`)
    }
    for (const [index, line] of source.split('\n').entries()) {
      if (faithLockIos16Pattern.test(line)) violations.push(`${relative(contentRoot, path)}:${index + 1}: unsupported FaithLock iOS 16 claim`)
    }
  }

  assert.deepEqual(violations, [])
})
