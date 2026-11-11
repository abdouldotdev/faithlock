// Answer-first "Quick Summary" paragraph rendered at the top of every
// /compare page.
//
// The sentence is derived from the competitor display name only. It must never
// echo a Contentful `tagline`: the importer used to emit
// "Compare FaithLock vs <slug>" (scripts/import-seo-content.mjs), which the
// template lower-cased into "<Name> compare faithlock vs <slug>." — a visible
// duplicate of the h1 on 8 of the 13 published pages (ABD-807 / ABD-811).
export function getComparisonQuickSummary(competitorName: string): string {
  const name = (competitorName ?? '').trim() || 'this app'
  return `FaithLock vs ${name}. FaithLock focuses on Scripture-based app blocking with Bible verse unlocking. The best choice depends on your priorities — we compare both below.`
}
