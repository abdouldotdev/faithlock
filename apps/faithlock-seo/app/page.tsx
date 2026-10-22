import type { Metadata } from 'next'
import { COMPANY, APP_STORE_URL } from '@/lib/constants'
import InteractivePhone from '@/components/landing/InteractivePhone'
import TypewriterHeadline from '@/components/landing/TypewriterHeadline'
import ScrollReveal from '@/components/landing/ScrollReveal'
import LandingTracker from '@/components/landing/LandingTracker'
import LandingFooter from '@/components/landing/LandingFooter'

const APP_LINK = APP_STORE_URL

export const metadata: Metadata = {
  title: 'FaithLock — Stop scrolling. Start Scripture.',
  description:
    'FaithLock blocks distracting apps and unlocks them with Bible verses—building a consistent Scripture habit without relying on willpower alone.',
  alternates: {
    canonical: '/',
  },
  openGraph: {
    url: '/',
    title: 'FaithLock — Stop scrolling. Start Scripture.',
    description:
      'FaithLock blocks distracting apps and unlocks them with Bible verses—building a consistent Scripture habit without relying on willpower alone.',
  },
}

export default function LandingPage() {
  return (
    <div className="bg-cozy-cream text-cozy-ink font-sans antialiased overflow-x-hidden pb-32 md:pb-0">
      <ScrollReveal />
      <LandingTracker />

      {/* ── Navigation ── */}
      <nav className="fixed top-0 w-full z-50 border-b-[2.5px] border-cozy-ink bg-cozy-cream/90 backdrop-blur-xl transition-all duration-500">
        <div className="max-w-6xl mx-auto px-6 h-16 flex items-center justify-between">
          <a href="/" className="flex items-center gap-2 group">
            <img
              src="/app-icon.png"
              alt="FaithLock"
              width={32}
              height={32}
              className="w-8 h-8 rounded-lg shadow-cozy-hard-sm group-hover:scale-105 transition-transform duration-300"
            />
            <span className="text-cozy-ink font-bold tracking-tight text-sm">FaithLock</span>
          </a>

          <div className="hidden md:flex items-center gap-8 text-sm font-medium text-cozy-ink">
            <a href="#how-it-works" className="hover:text-cozy-primary transition-colors" data-track-nav="How it Works">How it Works</a>
            <a href="#reviews" className="hover:text-cozy-primary transition-colors" data-track-nav="Stories">Stories</a>
            <a href="#faq" className="hover:text-cozy-primary transition-colors" data-track-nav="FAQ">FAQ</a>
            <a href="/compare" className="hover:text-cozy-primary transition-colors" data-track-nav="Compare">Compare</a>
            <a href="/resources" className="hover:text-cozy-primary transition-colors" data-track-nav="Resources">Resources</a>
            <a href="/features" className="hover:text-cozy-primary transition-colors" data-track-nav="Features">Features</a>
          </div>

          <div className="hidden md:flex items-center gap-4">
            <a
              href={APP_LINK}
              className="relative group overflow-hidden text-xs font-bold bg-cozy-primary text-white border-[2.5px] border-cozy-ink px-5 py-2.5 rounded-full shadow-cozy-hard hover:-translate-x-0.5 hover:-translate-y-0.5 hover:shadow-cozy-hard-lg transition-all duration-150 flex items-center gap-2"
              data-track-cta="nav_bar"
            >
              <span className="relative z-10 flex items-center gap-2">
                Get App
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="-mr-1 group-hover:translate-x-0.5 transition-transform" strokeLinecap="round" strokeLinejoin="round">
                  <polyline points="9 18 15 12 9 6" />
                </svg>
              </span>
            </a>
          </div>
        </div>
      </nav>

      {/* ── Mobile Sticky CTA ── */}
      <div className="md:hidden fixed bottom-0 left-0 w-full z-[60] px-5 py-4 sticky-blur flex items-center justify-between gap-4">
        <div className="flex flex-col">
          <span className="text-cozy-ink text-sm font-bold">Try it free</span>
          <span className="text-xs text-cozy-ink-muted">Available on iOS</span>
        </div>
        <a
          href={APP_LINK}
          className="bg-cozy-primary text-white border-[2.5px] border-cozy-ink h-11 px-6 rounded-full font-bold text-sm flex items-center justify-center gap-2 shadow-cozy-hard active:scale-95 transition-transform"
          data-track-cta="mobile_sticky"
        >
          Get Started
        </a>
      </div>

      {/* ── Hero ── */}
      <header className="relative pt-32 pb-16 md:pt-48 md:pb-32 overflow-hidden" data-track-section="hero">
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[200%] h-[600px] md:w-[1000px] bg-cozy-primary/15 rounded-[100%] blur-[100px] pointer-events-none opacity-40 animate-pulse-slow" />

        <div className="max-w-6xl mx-auto px-6 grid lg:grid-cols-2 gap-12 lg:gap-16 items-center relative z-10">
          <div className="text-center lg:text-left flex flex-col items-center lg:items-start">
            {/* Social Proof Pill */}
            <a
              href="#reviews"
              className="reveal-view inline-flex items-center gap-2 mb-8 p-1 pl-1 pr-3 rounded-full border-[2px] border-cozy-ink bg-cozy-surface backdrop-blur-md hover:-translate-y-0.5 transition-transform cursor-pointer shadow-cozy-hard-sm group"
            >
              <div className="flex -space-x-2">
                <div className="w-6 h-6 rounded-full border-2 border-cozy-ink bg-cozy-primary flex items-center justify-center text-[8px] text-white font-bold">J</div>
                <div className="w-6 h-6 rounded-full border-2 border-cozy-ink bg-cozy-peach flex items-center justify-center text-[8px] text-cozy-ink font-bold">M</div>
                <div className="w-6 h-6 rounded-full border-2 border-cozy-ink bg-cozy-sage flex items-center justify-center text-[8px] text-cozy-ink font-bold">S</div>
              </div>
              <span className="text-xs font-medium text-cozy-ink group-hover:text-cozy-primary transition-colors">
                Join the Movement
              </span>
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="text-cozy-primary" strokeLinecap="round" strokeLinejoin="round">
                <line x1="5" y1="12" x2="19" y2="12" /><polyline points="12 5 19 12 12 19" />
              </svg>
            </a>

            <div className="reveal-view reveal-delay-100">
              <TypewriterHeadline />
            </div>

            <p className="reveal-view reveal-delay-200 text-base md:text-lg text-cozy-ink/85 max-w-lg leading-relaxed mb-10">
              The only app blocker that unlocks your phone with Scripture. Break the dopamine loop and reconnect with God in seconds.
            </p>

            <div className="reveal-view reveal-delay-300 flex flex-col sm:flex-row items-center gap-4 w-full md:w-auto">
              <a
                href={APP_LINK}
                className="w-full sm:w-auto px-8 py-4 bg-cozy-primary text-white border-[2.5px] border-cozy-ink rounded-full font-bold text-sm shadow-cozy-hard hover:-translate-x-0.5 hover:-translate-y-0.5 hover:shadow-cozy-hard-lg active:scale-95 transition-all duration-150 flex items-center justify-center gap-2"
                data-track-cta="hero"
              >
                <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
                </svg>
                Download for iOS
              </a>
              <div className="flex flex-col items-center sm:items-start gap-1 ml-2">
                <div className="flex text-cozy-gold text-xs gap-0.5">
                  {[...Array(5)].map((_, i) => (
                    <svg key={i} width="12" height="12" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" /></svg>
                  ))}
                </div>
                <span className="text-[10px] text-cozy-ink-muted">Available on the App Store</span>
              </div>
            </div>
          </div>

          {/* Interactive Phone */}
          <div className="reveal-view reveal-delay-200">
            <InteractivePhone />
          </div>
        </div>
      </header>

      {/* ── How it Works / Features ── */}
      <section id="how-it-works" className="py-20 bg-cozy-cream relative" data-track-section="how_it_works">
        <div className="max-w-6xl mx-auto px-6">
          <div className="text-center mb-16 max-w-2xl mx-auto">
            <span className="text-cozy-primary-dark font-bold text-xs tracking-widest uppercase mb-2 block">What&apos;s inside</span>
            <h2 className="reveal-view text-3xl md:text-4xl font-bold text-cozy-ink tracking-tight mb-4">
              Everything you need to redirect your attention.
            </h2>
            <p className="reveal-view reveal-delay-100 text-cozy-ink/85 text-sm leading-relaxed">
              A gentle system that turns your greatest distraction into a doorway back to God — one verse, one prayer, one bloom at a time.
            </p>
          </div>

          {/* Bento Grid */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
            {/* Card 1: The Verse Barrier (signature, wide) */}
            <div className="md:col-span-2 bento-card rounded-[2rem] p-8 md:p-10 relative overflow-hidden group reveal-view reveal-delay-100 cursor-default">
              <div className="relative z-10 flex flex-col h-full items-start">
                <div className="w-12 h-12 bg-cozy-peach text-cozy-ink border-[2px] border-cozy-ink rounded-cozy-sm flex items-center justify-center mb-6">
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z" />
                    <path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z" />
                  </svg>
                </div>
                <h3 className="text-xl md:text-2xl font-bold text-cozy-ink mb-2">The Verse Barrier</h3>
                <p className="text-cozy-ink/85 text-sm max-w-sm leading-relaxed">
                  A brief Scripture pause before you open a distracting app.
                </p>
              </div>
              <div className="absolute right-0 bottom-0 translate-y-8 translate-x-8 group-hover:translate-y-4 group-hover:translate-x-4 transition-transform duration-500">
                <div className="bg-cozy-surface border-[2.5px] border-cozy-ink rounded-tl-2xl p-4 shadow-cozy-hard w-56">
                  <div className="flex items-center gap-3 mb-3">
                    <div className="w-2 h-2 rounded-full bg-cozy-primary" />
                    <div className="h-1.5 w-20 bg-cozy-surface-muted rounded-full" />
                  </div>
                  <div className="h-1.5 w-32 bg-cozy-surface-muted rounded-full mb-2" />
                  <div className="h-1.5 w-24 bg-cozy-surface-muted rounded-full" />
                </div>
              </div>
            </div>

            {/* Card 2: Garden of Grace (gamification, tall) */}
            <div className="md:col-span-1 md:row-span-2 bento-card rounded-[2rem] p-8 flex flex-col relative overflow-hidden group reveal-view reveal-delay-200">
              <div className="flex items-center justify-between mb-6">
                <div className="w-12 h-12 bg-cozy-peach text-cozy-ink border-[2px] border-cozy-ink rounded-cozy-sm flex items-center justify-center">
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M12 22V12" />
                    <path d="M12 12c0-3 2-5 5-5 0 3-2 5-5 5z" />
                    <path d="M12 14c0-3-2-5-5-5 0 3 2 5 5 5z" />
                    <path d="M5 22h14" />
                  </svg>
                </div>
                <span className="text-[10px] uppercase font-bold text-cozy-ink tracking-wider bg-cozy-sage border-[2px] border-cozy-ink px-2 py-0.5 rounded-cozy-sm">Gamified</span>
              </div>
              <h4 className="text-lg font-bold text-cozy-ink">Garden of Grace</h4>
              <p className="text-xs text-cozy-ink/85 mt-2 mb-8 leading-relaxed">
                Watch a hand-painted garden grow with your practice. Every verse read, prayer, and streak day makes it
                bloom — neglect it and it wilts. Your spiritual growth, made visible.
              </p>
              <div className="mt-auto relative h-32 flex items-end justify-between gap-2 px-2">
                <div className="w-full bg-cozy-surface-muted border-[1.5px] border-cozy-ink rounded-t-sm h-[40%]" />
                <div className="w-full bg-cozy-sage border-[1.5px] border-cozy-ink rounded-t-sm h-[60%]" />
                <div className="w-full bg-cozy-primary border-[1.5px] border-cozy-ink rounded-t-sm h-[85%] group-hover:h-[100%] transition-all duration-500 relative">
                  <div className="absolute -top-6 left-1/2 -translate-x-1/2 text-[9px] font-bold text-cozy-primary-dark opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap">
                    Bloom
                  </div>
                </div>
                <div className="w-full bg-cozy-gold border-[1.5px] border-cozy-ink rounded-t-sm h-[55%]" />
              </div>
            </div>

            {/* Card 3: The Companion (chat) */}
            <div className="md:col-span-1 bento-card rounded-[2rem] p-8 relative overflow-hidden group reveal-view reveal-delay-200">
              <div className="relative z-10">
                <div className="w-12 h-12 bg-cozy-peach text-cozy-ink border-[2px] border-cozy-ink rounded-cozy-sm flex items-center justify-center mb-4">
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z" />
                    <path d="M12 8l.7 1.8L14.5 10.5l-1.8.7L12 13l-.7-1.8L9.5 10.5l1.8-.7L12 8z" />
                  </svg>
                </div>
                <h4 className="text-lg font-bold text-cozy-ink">The Companion</h4>
                <p className="text-xs text-cozy-ink/85 mt-2 leading-relaxed">
                  A warm, Scripture-grounded chat woven into the Bible. Ask about any verse and get grounded, gentle
                  answers — read aloud if you like.
                </p>
              </div>
            </div>

            {/* Card 4: The Bible (reader) */}
            <div className="md:col-span-1 bento-card rounded-[2rem] p-8 relative overflow-hidden group reveal-view reveal-delay-300">
              <div className="relative z-10">
                <div className="w-12 h-12 bg-cozy-peach text-cozy-ink border-[2px] border-cozy-ink rounded-cozy-sm flex items-center justify-center mb-4">
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20" />
                    <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z" />
                  </svg>
                </div>
                <h4 className="text-lg font-bold text-cozy-ink">The Bible</h4>
                <p className="text-xs text-cozy-ink/85 mt-2 leading-relaxed">
                  A calm, cozy Bible reader with reflection notes and your favorite public-domain translations — the
                  place your redirected attention lands.
                </p>
              </div>
            </div>

            {/* Card 5: Sabbath Mode (Pro) */}
            <div className="md:col-span-1 bento-card rounded-[2rem] p-8 relative overflow-hidden group reveal-view reveal-delay-300">
              <div className="relative z-10">
                <div className="flex items-center gap-3 mb-4">
                  <div className="w-12 h-12 bg-cozy-gold text-cozy-ink border-[2px] border-cozy-ink rounded-cozy-sm flex items-center justify-center">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
                      <path d="M12 8v4" /><path d="M12 16h.01" />
                    </svg>
                  </div>
                  <span className="text-[10px] uppercase font-bold text-cozy-ink tracking-wider bg-cozy-gold border-[2px] border-cozy-ink px-2 py-0.5 rounded-cozy-sm">Pro</span>
                </div>
                <h4 className="text-lg font-bold text-cozy-ink">Sabbath Mode</h4>
                <p className="text-xs text-cozy-ink/85 mt-2 leading-relaxed">
                  Lock apps completely for set durations — perfect for deep prayer, family time, or sleep.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── Reviews ── */}
      <section id="reviews" className="py-24 border-t-[2.5px] border-cozy-ink bg-cozy-surface-muted" data-track-section="reviews">
        <div className="max-w-6xl mx-auto px-6">
          <h2 className="reveal-view text-2xl md:text-3xl font-bold text-cozy-ink text-center mb-4">
            Stories from the Community
          </h2>
          <p className="reveal-view text-cozy-ink-muted text-sm text-center mb-16 max-w-lg mx-auto">
            Real words from real believers. From our App Store reviews.
          </p>

          <div className="columns-1 md:columns-2 lg:columns-3 gap-4 space-y-4">
            {[
              {
                text: 'I used to scroll TikTok for an hour before bed. Now I read a Psalm to unlock it, and honestly, half the time I don\'t even open TikTok afterwards. The desire just fades.',
                name: 'James D.',
                role: 'Youth Pastor',
                initials: 'JD',
                highlight: true,
              },
              {
                text: 'My wife noticed before I did. She said "you\'re actually here at dinner now." That hit me. I didn\'t realize how checked-out I was until the phone stopped pulling me away every 5 minutes.',
                name: 'David R.',
                role: 'Father of 3',
                initials: 'DR',
                highlight: false,
              },
              {
                text: 'This isn\'t just an app blocker, it\'s a liturgy. It has completely changed my morning routine from doomscrolling to prayer.',
                name: 'Marcus L.',
                role: 'Entrepreneur',
                initials: 'ML',
                highlight: true,
              },
              {
                text: 'I\'m a college student and I was spending 6 hours a day on my phone. I couldn\'t study, couldn\'t focus in chapel, couldn\'t even sit through a meal without checking Instagram. Two weeks with FaithLock and I\'m down to 2 hours. Not perfect, but I\'m actually present again.',
                name: 'Alyssa M.',
                role: 'College Junior',
                initials: 'AM',
                highlight: false,
              },
              {
                text: 'Finally an app that helps me use my phone less without making me feel guilty. It just redirects my attention to what matters.',
                name: 'Sarah H.',
                role: 'Student',
                initials: 'SH',
                highlight: false,
              },
              {
                text: 'I tried Opal, One Sec, Forest. They all worked for about 3 days. The difference with FaithLock is that the Bible verse actually makes me pause and think. It\'s not just friction — it\'s meaning.',
                name: 'Kevin T.',
                role: 'Software Engineer',
                initials: 'KT',
                highlight: false,
              },
              {
                text: 'I recommended it to my youth group. 14 kids downloaded it the same night. Three weeks later, half of them are still going. That\'s better than any sermon I\'ve preached on phone addiction.',
                name: 'Pastor Mike',
                role: 'Youth Ministry Leader',
                initials: 'PM',
                highlight: true,
              },
              {
                text: 'I\'m 58 years old and I was embarrassed to admit I had a phone problem. But I was staying up until midnight scrolling news. Now the phone locks at 9pm and I read my Bible. I sleep better. My wife sleeps better. Simple as that.',
                name: 'Robert W.',
                role: 'Retired Teacher',
                initials: 'RW',
                highlight: false,
              },
              {
                text: 'The 30-day covenant feature changed everything for me. When I made that commitment, it felt like a real promise to God, not just a setting I could toggle off. I\'m on day 47 now.',
                name: 'Grace K.',
                role: 'Nurse',
                initials: 'GK',
                highlight: false,
              },
              {
                text: 'My screen time went from 7 hours to 3. But honestly, the bigger change is that I memorized 12 verses in the first month without even trying. They just stick when you read them 5 times a day before opening apps.',
                name: 'Daniel P.',
                role: 'Seminary Student',
                initials: 'DP',
                highlight: true,
              },
            ].map((review, i) => (
              <div
                key={i}
                className={`reveal-view break-inside-avoid bento-card p-6 rounded-2xl ${review.highlight ? 'bg-cozy-peach' : ''} transition-colors`}
              >
                <div className="flex gap-1 text-cozy-gold mb-4 text-[10px]">
                  {[...Array(5)].map((_, j) => (
                    <svg key={j} width="12" height="12" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" /></svg>
                  ))}
                </div>
                <p className={`${review.highlight ? 'text-cozy-ink font-bold' : 'text-cozy-ink/85'} text-sm leading-relaxed mb-6`}>
                  &ldquo;{review.text}&rdquo;
                </p>
                <div className="flex items-center gap-3 pt-4 border-t-[2px] border-cozy-ink/15">
                  <div className={`w-9 h-9 rounded-full border-[2px] border-cozy-ink ${review.highlight ? 'bg-cozy-primary text-white' : 'bg-cozy-peach text-cozy-ink'} flex items-center justify-center text-xs font-bold`}>
                    {review.initials}
                  </div>
                  <div>
                    <div className="text-cozy-ink text-xs font-bold">{review.name}</div>
                    <div className="text-cozy-ink-muted text-[10px]">{review.role}</div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── FAQ ── */}
      <section id="faq" className="py-16 bg-cozy-cream" data-track-section="faq">
        <div className="max-w-3xl mx-auto px-6">
          <h2 className="text-2xl font-bold text-cozy-ink mb-8">Frequently Asked</h2>
          <div className="space-y-4">
            {[
              {
                q: 'Does it really work for TikTok and Instagram?',
                a: 'FaithLock uses iOS Screen Time capabilities to block selected apps until the Scripture pause is complete.',
              },
              {
                q: 'Is it easy to uninstall?',
                a: "We don't hold your phone hostage. You can uninstall anytime, but we bet you won't want to once you feel the peace it brings.",
              },
              {
                q: 'How does FaithLock handle data?',
                a: 'See the Privacy Policy for the current data practices and the Terms of Use for subscription and service terms.',
              },
            ].map((faq, i) => (
              <details
                key={i}
                className="group bg-cozy-surface rounded-cozy border-[2.5px] border-cozy-ink overflow-hidden"
                data-track-faq={faq.q}
                data-track-faq-index={i}
              >
                <summary className="flex justify-between items-center p-4 cursor-pointer">
                  <span className="text-sm font-bold text-cozy-ink">{faq.q}</span>
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="text-cozy-ink transition-transform group-open:rotate-180 flex-shrink-0 ml-2" strokeLinecap="round" strokeLinejoin="round">
                    <polyline points="6 9 12 15 18 9" />
                  </svg>
                </summary>
                <div className="px-4 pb-4 text-xs text-cozy-ink/85 leading-relaxed">{faq.a}</div>
              </details>
            ))}
          </div>
        </div>
      </section>

      {/* ── CTA ── */}
      <section className="py-16 md:py-24 px-4 md:px-6" data-track-section="cta_bottom">
        <div id="download" className="reveal-view max-w-5xl mx-auto relative rounded-cozy-lg overflow-hidden bg-cozy-primary border-[2.5px] border-cozy-ink shadow-cozy-hard-lg group">
          <div className="absolute top-0 right-0 w-64 h-64 bg-white/10 rounded-full blur-[80px]" />

          <div className="relative z-10 flex flex-col md:flex-row items-center justify-between p-10 md:p-16 gap-10">
            <div className="text-center md:text-left flex-1">
              <h2 className="text-3xl md:text-5xl font-bold text-white tracking-tight mb-6">
                Build the habit<br />today.
              </h2>
              <p className="text-white/85 text-base mb-8 max-w-sm mx-auto md:mx-0">
                Join Christians using technology to fuel their faith.
              </p>

              <a
                href={APP_LINK}
                className="inline-flex bg-cozy-surface text-cozy-ink border-[2.5px] border-cozy-ink px-8 py-4 rounded-full font-bold text-sm shadow-cozy-hard hover:-translate-x-0.5 hover:-translate-y-0.5 hover:shadow-cozy-hard-lg active:scale-95 transition-all duration-150 items-center justify-center gap-2 w-full md:w-auto"
                data-track-cta="bottom_cta"
              >
                <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
                </svg>
                Download on App Store
              </a>

              <div className="mt-6 flex flex-wrap justify-center md:justify-start gap-x-6 gap-y-2 text-xs font-medium text-white/85">
                <span className="flex items-center gap-1">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" /><polyline points="22 4 12 14.01 9 11.01" /></svg>
                  Free to start
                </span>
                <span className="flex items-center gap-1">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" /></svg>
                  Privacy and terms are available on the site.
                </span>
              </div>
            </div>

            <div className="relative w-full md:w-80 flex justify-center">
              <div className="w-40 h-40 bg-cozy-surface text-cozy-ink border-[2.5px] border-cozy-ink rounded-cozy-lg flex flex-col items-center justify-center shadow-cozy-hard rotate-6 group-hover:rotate-0 transition-all duration-500">
                <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                  <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
                  <path d="M7 11V7a5 5 0 0 1 9.9-1" />
                  <circle cx="12" cy="16" r="1" />
                </svg>
              </div>
              <div className="absolute top-4 -right-4 bg-cozy-surface text-cozy-primary-dark border-[2px] border-cozy-ink px-3 py-1 rounded-full text-xs font-bold shadow-cozy-hard-sm animate-bounce">
                Start Free
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── Footer ── */}
      <LandingFooter />
    </div>
  )
}
