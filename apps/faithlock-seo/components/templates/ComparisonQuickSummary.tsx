// Quick Summary block of /compare pages — the answer-first paragraph a visitor
// reads before the comparison table.
//
// Kept as its own component so the rendered HTML of this block can be asserted
// without a Contentful connection (see tests/compare-quick-summary.test.mjs).
//
// The sentence comes from getComparisonQuickSummary and depends on the
// competitor display name only. It deliberately ignores the Contentful
// `tagline`: that field used to carry "Compare FaithLock vs <slug>", which
// rendered as "Opal compare faithlock vs opal." — a lowercase duplicate of the
// h1 on 8 of the 13 published pages (ABD-807 / ABD-811).
import { getComparisonQuickSummary } from '@/lib/compare-summary'

interface ComparisonQuickSummaryProps {
  competitorName: string
}

export default function ComparisonQuickSummary({
  competitorName,
}: ComparisonQuickSummaryProps) {
  return (
    <div className="cozy-card-soft max-w-2xl p-6">
      <p className="text-sm font-semibold text-cozy-primary-dark mb-2 uppercase tracking-wide">
        Quick Summary
      </p>
      <p className="text-cozy-ink/80 leading-relaxed">
        {getComparisonQuickSummary(competitorName)}
      </p>
    </div>
  )
}
