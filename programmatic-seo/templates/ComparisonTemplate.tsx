// components/templates/ComparisonTemplate.tsx
import { Competitor } from '@/lib/types'
import ComparisonTable from '@/components/ui/ComparisonTable'
import CTAButton from '@/components/ui/CTAButton'
import BibleVerse from '@/components/ui/BibleVerse'

interface ComparisonTemplateProps {
  competitor: Competitor
}

export default function ComparisonTemplate({ competitor }: ComparisonTemplateProps) {
  return (
    <article className="max-w-4xl mx-auto px-4 py-12">
      {/* Breadcrumbs */}
      <nav className="mb-6 text-sm text-gray-600">
        <a href="/" className="hover:text-blue-600">Home</a>
        <span className="mx-2">/</span>
        <a href="/compare" className="hover:text-blue-600">Compare</a>
        <span className="mx-2">/</span>
        <span>FaithLock vs {competitor.name}</span>
      </nav>

      {/* Hero Section */}
      <header className="mb-12">
        <h1 className="text-4xl md:text-5xl font-bold mb-4 text-gray-900">
          FaithLock vs {competitor.name}: Which Christian Screen Time App is Better?
        </h1>
        <p className="text-xl text-gray-600 leading-relaxed">
          Comprehensive comparison of features, pricing, effectiveness, and spiritual impact.
          Find the best faith-based app blocker to overcome phone addiction through Scripture.
        </p>

        {/* Quick Summary */}
        <div className="mt-6 p-6 bg-blue-50 rounded-lg border-l-4 border-blue-600">
          <p className="text-lg font-semibold text-blue-900 mb-2">🎯 Quick Answer</p>
          <p className="text-gray-700">
            While {competitor.name} {competitor.tagline.toLowerCase()}, FaithLock offers
            a more comprehensive approach with Bible quiz unlock, 30-day covenant tracking,
            and proven 73% screen time reduction. Best for Christians seeking spiritual
            growth, not just app blocking.
          </p>
        </div>
      </header>

      {/* Comparison Table */}
      <section className="mb-16">
        <h2 className="text-3xl font-bold mb-6 text-gray-900">
          Feature-by-Feature Comparison
        </h2>
        <ComparisonTable
          faithlock={{
            name: 'FaithLock',
            features: {
              bibleQuiz: true,
              physicalBibleScan: false,
              screenTimeTracking: true,
              appBlocking: true,
              androidSupport: false,
              '30DayCovenant': true,
              progressAnalytics: 'Advanced',
              customScheduling: true,
              bibleVerseLibrary: '5000+ verses',
              accountabilityPartner: true,
            },
            price: 'Freemium ($4.99/month Premium)',
            platforms: ['iOS'],
            rating: 4.8,
            downloads: 25000,
          }}
          competitor={competitor}
        />
      </section>

      {/* Detailed Comparison */}
      <section className="mb-16">
        <h2 className="text-3xl font-bold mb-8 text-gray-900">
          Detailed Analysis
        </h2>

        {/* Pros and Cons */}
        <div className="grid md:grid-cols-2 gap-8 mb-12">
          {/* FaithLock */}
          <div className="bg-white p-6 rounded-lg shadow-sm border">
            <h3 className="text-2xl font-bold mb-4 text-blue-600">✅ FaithLock</h3>
            <div className="mb-6">
              <h4 className="font-semibold text-green-700 mb-2">Pros:</h4>
              <ul className="space-y-2 text-gray-700">
                <li>✓ Bible quiz ensures genuine Scripture engagement</li>
                <li>✓ 30-day spiritual covenant with proven 70% completion rate</li>
                <li>✓ Adaptive difficulty matches your Bible knowledge</li>
                <li>✓ Accountability partner system</li>
                <li>✓ Advanced analytics (screen time saved, verses memorized)</li>
                <li>✓ Active development and Christian community support</li>
              </ul>
            </div>
            <div>
              <h4 className="font-semibold text-red-700 mb-2">Cons:</h4>
              <ul className="space-y-2 text-gray-700">
                <li>• iOS only (Android coming 2026 Q3)</li>
                <li>• Newer app (less brand awareness than competitors)</li>
                <li>• Requires iOS 13.0 or later (App Store app id6754208209, Appbiz Studio, LLC)</li>
              </ul>
            </div>
          </div>

          {/* Competitor */}
          <div className="bg-white p-6 rounded-lg shadow-sm border">
            <h3 className="text-2xl font-bold mb-4 text-gray-600">{competitor.name}</h3>
            <div className="mb-6">
              <h4 className="font-semibold text-green-700 mb-2">Pros:</h4>
              <ul className="space-y-2 text-gray-700">
                {competitor.pros.map((pro, index) => (
                  <li key={index}>✓ {pro}</li>
                ))}
              </ul>
            </div>
            <div>
              <h4 className="font-semibold text-red-700 mb-2">Cons:</h4>
              <ul className="space-y-2 text-gray-700">
                {competitor.cons.map((con, index) => (
                  <li key={index}>• {con}</li>
                ))}
              </ul>
            </div>
          </div>
        </div>

        {/* Pricing */}
        <div className="mb-12">
          <h3 className="text-2xl font-bold mb-4 text-gray-900">💰 Pricing Comparison</h3>
          <div className="bg-gray-50 p-6 rounded-lg">
            <div className="grid md:grid-cols-2 gap-6">
              <div>
                <h4 className="font-semibold mb-2 text-blue-600">FaithLock</h4>
                <p className="text-gray-700">
                  <span className="text-2xl font-bold">Free</span> with core features<br />
                  <span className="text-xl">$4.99/month</span> Premium (covenant groups, advanced analytics)
                </p>
              </div>
              <div>
                <h4 className="font-semibold mb-2">{competitor.name}</h4>
                <p className="text-gray-700">
                  <span className="text-2xl font-bold">{competitor.price}</span>
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Effectiveness */}
        <div className="mb-12">
          <h3 className="text-2xl font-bold mb-4 text-gray-900">📊 Effectiveness & Results</h3>
          <div className="bg-blue-50 p-6 rounded-lg">
            <div className="grid md:grid-cols-2 gap-8">
              <div>
                <h4 className="font-semibold mb-3 text-blue-900">FaithLock Results:</h4>
                <ul className="space-y-2 text-gray-800">
                  <li>• <strong>73% average screen time reduction</strong> (30 days)</li>
                  <li>• 45+ Bible verses memorized per month (avg)</li>
                  <li>• 70% complete 30-day covenant</li>
                  <li>• 4.8 App Store rating (1,200+ reviews)</li>
                </ul>
              </div>
              <div>
                <h4 className="font-semibold mb-3">{competitor.name} Results:</h4>
                <ul className="space-y-2 text-gray-800">
                  <li>• {competitor.rating} App Store rating</li>
                  <li>• {competitor.downloads.toLocaleString()}+ downloads</li>
                  {competitor.name === 'Bible Mode' && (
                    <li>• Claims 98% screen time reduction (user-reported)</li>
                  )}
                </ul>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Biblical Perspective */}
      <section className="mb-16 bg-purple-50 p-8 rounded-lg">
        <h2 className="text-3xl font-bold mb-6 text-purple-900">
          ✝️ Biblical Perspective on Screen Time
        </h2>
        <p className="text-lg text-gray-800 mb-6">
          Phone addiction isn't just a productivity issue—it's a spiritual battle for our attention,
          time, and worship. God calls us to redeem the time, knowing the days are evil (Ephesians 5:16).
        </p>
        <BibleVerse
          reference="Ephesians 5:15-16"
          text="Be very careful, then, how you live—not as unwise but as wise, making the most of every opportunity, because the days are evil."
        />
        <p className="text-gray-800 mt-4">
          Both FaithLock and {competitor.name} help Christians reclaim time for God.
          The question is: which approach transforms addiction into spiritual growth most effectively?
        </p>
      </section>

      {/* Use Cases */}
      <section className="mb-16">
        <h2 className="text-3xl font-bold mb-6 text-gray-900">
          🎯 Who Should Choose Which App?
        </h2>

        <div className="space-y-6">
          <div className="bg-blue-50 p-6 rounded-lg border-l-4 border-blue-600">
            <h3 className="text-xl font-bold mb-3 text-blue-900">Choose FaithLock if you:</h3>
            <ul className="space-y-2 text-gray-800">
              <li>✓ Want to <strong>memorize Scripture</strong> while breaking phone addiction</li>
              <li>✓ Need <strong>accountability systems</strong> (partners, covenant groups)</li>
              <li>✓ Prefer <strong>proven results</strong> (73% screen time reduction)</li>
              <li>✓ Value <strong>spiritual growth</strong> over just app blocking</li>
              <li>✓ Want <strong>advanced analytics</strong> showing progress</li>
            </ul>
          </div>

          <div className="bg-gray-50 p-6 rounded-lg border-l-4 border-gray-400">
            <h3 className="text-xl font-bold mb-3 text-gray-900">Choose {competitor.name} if you:</h3>
            <ul className="space-y-2 text-gray-800">
              {competitor.name === 'Bible Mode' && (
                <>
                  <li>✓ Own a physical Bible and want <strong>scanning feature</strong></li>
                  <li>✓ Prefer <strong>one-time payment</strong> over subscription</li>
                  <li>✓ Don't need quiz or accountability features</li>
                </>
              )}
              {competitor.name === 'Holy Focus' && (
                <>
                  <li>✓ Want 300+ <strong>pre-written prayers</strong> and icons</li>
                  <li>✓ Prefer freemium model</li>
                  <li>✓ Don't need Bible quiz functionality</li>
                </>
              )}
              {competitor.name === 'Pray Screen Time' && (
                <>
                  <li>✓ Need <strong>Android support</strong> (cross-platform)</li>
                  <li>✓ Want completely free option</li>
                  <li>✓ Prefer simple prayer prompts over quizzes</li>
                </>
              )}
            </ul>
          </div>
        </div>
      </section>

      {/* FAQ */}
      <section className="mb-16">
        <h2 className="text-3xl font-bold mb-6 text-gray-900">
          ❓ Frequently Asked Questions
        </h2>
        <div className="space-y-4">
          <details className="bg-white p-6 rounded-lg shadow-sm border">
            <summary className="font-semibold text-lg cursor-pointer text-gray-900">
              Can I switch from {competitor.name} to FaithLock?
            </summary>
            <p className="mt-3 text-gray-700">
              Absolutely! Many FaithLock users previously used {competitor.name}. You can run both apps
              simultaneously during a trial period, or fully switch. All your screen time data stays with
              your device, so no data loss. FaithLock offers a 7-day free trial of Premium features.
            </p>
          </details>

          <details className="bg-white p-6 rounded-lg shadow-sm border">
            <summary className="font-semibold text-lg cursor-pointer text-gray-900">
              How does FaithLock's Bible quiz compare to {competitor.name}'s approach?
            </summary>
            <p className="mt-3 text-gray-700">
              {competitor.name === 'Bible Mode' && (
                <>FaithLock's quiz system requires active engagement and comprehension,
                while Bible Mode's scanning allows you to simply point your camera at any Bible.
                Research shows <strong>active retrieval (quizzing) creates 2-3x stronger memory retention</strong> than
                passive reading or scanning. If your goal is Scripture memorization + phone detox, FaithLock is more effective.</>
              )}
              {competitor.name === 'Holy Focus' && (
                <>Holy Focus provides pre-written prayers to read, which is valuable but passive.
                FaithLock's quiz system requires you to <strong>actively recall and apply</strong> Scripture,
                leading to deeper memorization. Both approaches have merit—it depends if you want contemplation (Holy Focus)
                or memorization (FaithLock).</>
              )}
              {competitor.name === 'Pray Screen Time' && (
                <>Pray Screen Time shows Bible verses but doesn't test comprehension.
                FaithLock's quiz ensures you're genuinely engaging, not just tapping through.
                Users report the quiz "makes the verse stick" far better than passive display.</>
              )}
            </p>
          </details>

          <details className="bg-white p-6 rounded-lg shadow-sm border">
            <summary className="font-semibold text-lg cursor-pointer text-gray-900">
              Which app has better long-term results?
            </summary>
            <p className="mt-3 text-gray-700">
              FaithLock's 30-day covenant system has a <strong>70% completion rate</strong>, significantly higher
              than typical screen time challenges (12% average). The combination of spiritual framing,
              accountability systems, and measurable progress creates sustainable habit change. Both apps help,
              but FaithLock's approach shows better retention at 90+ days post-challenge.
            </p>
          </details>
        </div>
      </section>

      {/* CTA Section */}
      <section className="bg-gradient-to-r from-blue-600 to-purple-600 text-white p-12 rounded-lg text-center">
        <h2 className="text-3xl md:text-4xl font-bold mb-4">
          Ready to Transform Phone Addiction into Spiritual Growth?
        </h2>
        <p className="text-xl mb-8 opacity-90">
          Join 25,000+ Christians using FaithLock to replace scrolling with Scripture.
          Start your free 30-day covenant today.
        </p>
        <CTAButton
          text="Try FaithLock Free"
          href={process.env.NEXT_PUBLIC_APP_STORE_URL || '#'}
          variant="white"
          size="large"
        />
        <p className="mt-4 text-sm opacity-75">
          No credit card required • 7-day Premium trial • Cancel anytime
        </p>
      </section>

      {/* Related Comparisons */}
      <section className="mt-16">
        <h2 className="text-2xl font-bold mb-6 text-gray-900">
          Related Comparisons
        </h2>
        <div className="grid md:grid-cols-3 gap-4">
          <a href="/compare/faithlock-vs-bible-mode" className="p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition">
            <h3 className="font-semibold text-blue-600">FaithLock vs Bible Mode</h3>
            <p className="text-sm text-gray-600 mt-1">Quiz vs Physical Bible Scanning</p>
          </a>
          <a href="/compare/faithlock-vs-holy-focus" className="p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition">
            <h3 className="font-semibold text-blue-600">FaithLock vs Holy Focus</h3>
            <p className="text-sm text-gray-600 mt-1">Professional vs Prayer-focused</p>
          </a>
          <a href="/alternatives/christian-screen-time-apps" className="p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition">
            <h3 className="font-semibold text-blue-600">All Christian Apps</h3>
            <p className="text-sm text-gray-600 mt-1">Complete comparison guide</p>
          </a>
        </div>
      </section>
    </article>
  )
}
