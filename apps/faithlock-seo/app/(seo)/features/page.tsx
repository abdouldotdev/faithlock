import { Metadata } from 'next'
import { getAllFeatures } from '@/lib/contentful'
import { APP_STORE_URL } from '@/lib/constants'
import CTAButton from '@/components/ui/CTAButton'

export const metadata: Metadata = {
  title: 'FaithLock Features - Prayer Lock, App Blocking & More',
  description:
    'Explore FaithLock features listed in the App Store: prayer and Bible verse unlocks, app blocking, scheduled lock times, prayer streaks, faith insights, reminders, and dark mode.',
  alternates: {
    canonical: '/features',
  },
}

export default async function FeaturesPage() {
  const features = await getAllFeatures()

  return (
    <div className="cozy-page">
      {/* Hero */}
      <div className="cozy-hero">
        <div className="container-default py-14 md:py-20">
          <nav className="cozy-breadcrumb mb-8">
            <a href="/">Home</a>
            <span className="cozy-breadcrumb-separator">/</span>
            <span>Features</span>
          </nav>

          <span className="cozy-badge-peach mb-4">Features</span>
          <h1 className="text-3xl sm:text-4xl md:text-5xl font-bold mb-4 tracking-tight leading-tight text-cozy-ink">
            Everything You Need to Break Free
          </h1>
          <p className="text-lg md:text-xl text-cozy-ink/70 max-w-2xl">
            Prayer and Bible verse unlocks, scheduled lock times, faith insights, and more.
            FaithLock helps turn phone time into prayer time.
          </p>
        </div>
      </div>

      <div className="container-default py-12 md:py-16">
        {/* Quick Stats */}
        <section className="mb-12 md:mb-16">
          <div className="grid sm:grid-cols-3 gap-4">
            {[
              { value: 'Prayer lock', label: 'Core experience', color: 'primary' },
              { value: '~30s', label: 'Scripture pause', color: 'primary' },
              { value: 'iPhone + iPad', label: 'Verified devices', color: 'gold' },
            ].map((stat) => (
              <div key={stat.label} className="cozy-card p-5 text-center">
                <p className={`text-2xl md:text-3xl font-bold mb-1 ${stat.color === 'gold' ? 'text-cozy-gold' : 'text-cozy-primary'}`}>
                  {stat.value}
                </p>
                <p className="text-xs text-cozy-ink-muted">{stat.label}</p>
              </div>
            ))}
          </div>
        </section>

        {/* Feature List */}
        <section className="mb-16 md:mb-20">
          <h2 className="text-2xl md:text-3xl font-bold mb-8 text-cozy-ink">
            Explore Features
          </h2>
          <div className="space-y-4">
            {features.map((entry) => {
              const f = entry.fields as Record<string, unknown>
              return (
                <a
                  key={entry.sys.id}
                  href={`/features/${f.slug}`}
                  className="cozy-card-interactive p-6 md:p-8 flex flex-col md:flex-row md:items-center gap-4 md:gap-6"
                >
                  <div className="flex-1 min-w-0">
                    <h2 className="text-lg md:text-xl font-bold text-cozy-ink mb-1">
                      {f.name as string}
                    </h2>
                    <p className="text-sm text-cozy-ink-muted mb-3">
                      {f.tagline as string}
                    </p>
                    {Array.isArray(f.benefits) && f.benefits.length > 0 && (
                      <div className="flex flex-wrap gap-2">
                        {(f.benefits as string[]).slice(0, 3).map((benefit, i) => (
                          <span
                            key={i}
                            className="cozy-badge-sage inline-flex items-center gap-1 text-xs"
                          >
                            <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                              <polyline points="20 6 9 17 4 12" />
                            </svg>
                            {benefit}
                          </span>
                        ))}
                      </div>
                    )}
                  </div>
                  <div className="flex-shrink-0">
                    <span className="inline-flex items-center gap-1 text-sm font-medium text-cozy-primary">
                      Learn more
                      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                        <polyline points="9 18 15 12 9 6" />
                      </svg>
                    </span>
                  </div>
                </a>
              )
            })}
          </div>
        </section>

        {/* How It All Works Together */}
        <section className="mb-16 md:mb-20">
          <div className="cozy-card p-8 md:p-10 bg-cozy-surface-muted border-cozy-border">
            <h2 className="text-2xl md:text-3xl font-bold mb-6 text-cozy-ink">
              How It All Works Together
            </h2>
            <div className="grid sm:grid-cols-3 gap-6">
              {[
                {
                  step: '1',
                  title: 'Choose Your Distractions',
                  description: 'Lock social media, games, browsers—anything stealing your attention.',
                },
                {
                  step: '2',
                  title: 'Unlock with Scripture',
                  description: 'Read a daily Bible verse to access your apps. Takes 30 seconds.',
                },
                {
                  step: '3',
                  title: 'Build the Habit',
                  description: 'Track your streak, earn insights, and watch your faith grow.',
                },
              ].map((item) => (
                <div key={item.step} className="flex gap-4">
                  <div className="w-9 h-9 bg-cozy-peach border-[2px] border-cozy-ink rounded-xl flex items-center justify-center flex-shrink-0">
                    <span className="text-sm font-bold text-cozy-ink">
                      {item.step}
                    </span>
                  </div>
                  <div>
                    <h3 className="font-bold text-cozy-ink mb-1 text-sm">
                      {item.title}
                    </h3>
                    <p className="text-sm text-cozy-ink/85 leading-relaxed">
                      {item.description}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* CTA */}
        <section className="bg-cozy-primary text-white p-10 md:p-16 border-[2.5px] border-cozy-ink rounded-cozy-lg shadow-cozy-hard-lg text-center">
          <h2 className="text-2xl md:text-4xl font-bold mb-4 text-balance text-white">
            Explore the listed features without inferring paywall entitlements.
          </h2>
          <p className="text-lg mb-8 text-white/80">
            Join Christians transforming phone addiction into spiritual growth.
          </p>
          <CTAButton
            text="Try FaithLock Free"
            href={APP_STORE_URL}
            variant="white"
            size="large"
            showAppleIcon
            trackingLocation="features_index_cta"
          />
        </section>
      </div>
    </div>
  )
}
