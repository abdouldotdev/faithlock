'use client'

import { useState } from 'react'
import { NAV_LINKS, OFFICIAL_APP_STORE_URL } from '@/lib/constants'
import { trackCTAClick, trackNavClick } from '@/lib/analytics'

export default function Header({ suppressStoreCta = false }: { suppressStoreCta?: boolean }) {
  const [mobileOpen, setMobileOpen] = useState(false)

  return (
    <header className="bg-cozy-cream/90 backdrop-blur-md sticky top-0 z-50 border-b-[2.5px] border-cozy-ink">
      <div className="container-wide py-3 flex items-center justify-between">
        {/* Logo */}
        <a href="/" className="flex items-center gap-2.5 group">
          <img
            src="/app-icon.png"
            alt="FaithLock"
            width={32}
            height={32}
            className="w-8 h-8 rounded-lg border-[1.5px] border-cozy-ink shadow-cozy-hard-sm group-hover:scale-105 transition-transform"
          />
          <span className="text-xl font-bold text-cozy-ink tracking-tight">
            FaithLock
          </span>
        </a>

        {/* Desktop Nav */}
        <nav className="hidden md:flex items-center gap-8">
          {NAV_LINKS.map((link) => (
            <a
              key={link.href}
              href={link.href}
              className="text-sm font-medium text-cozy-ink/80 hover:text-cozy-primary transition-colors relative after:absolute after:bottom-0 after:left-0 after:w-0 after:h-0.5 after:bg-cozy-primary hover:after:w-full after:transition-all after:duration-300"
              onClick={() => trackNavClick(link.label, link.href, 'header')}
            >
              {link.label}
            </a>
          ))}
        </nav>

        {/* CTA + Mobile Toggle */}
        <div className="flex items-center gap-3">
          {!suppressStoreCta && <a
            href={OFFICIAL_APP_STORE_URL}
            className="hidden sm:inline-flex items-center gap-2 bg-cozy-primary text-white border-[2.5px] border-cozy-ink px-5 py-2.5 rounded-full font-bold text-sm shadow-cozy-hard transition-all duration-150 hover:-translate-x-0.5 hover:-translate-y-0.5 hover:shadow-cozy-hard-lg"
            target="_blank"
            rel="noopener noreferrer"
            data-store-location="header"
            onClick={() => trackCTAClick('header', 'Download now')}
          >
            <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
              <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
            </svg>
            Download now
          </a>}

          {/* Mobile hamburger */}
          <button
            onClick={() => setMobileOpen(!mobileOpen)}
            className="md:hidden p-2 rounded-lg text-cozy-ink hover:bg-cozy-surface-muted transition-colors"
            aria-label="Toggle menu"
          >
            <svg
              width="22"
              height="22"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
            >
              {mobileOpen ? (
                <>
                  <line x1="18" y1="6" x2="6" y2="18" />
                  <line x1="6" y1="6" x2="18" y2="18" />
                </>
              ) : (
                <>
                  <line x1="3" y1="6" x2="21" y2="6" />
                  <line x1="3" y1="12" x2="21" y2="12" />
                  <line x1="3" y1="18" x2="21" y2="18" />
                </>
              )}
            </svg>
          </button>
        </div>
      </div>

      {/* Mobile Nav */}
      {mobileOpen && (
        <div className="md:hidden border-t-[2.5px] border-cozy-ink bg-cozy-cream animate-fade-in">
          <nav className="container-wide py-4 flex flex-col gap-1">
            {NAV_LINKS.map((link) => (
              <a
                key={link.href}
                href={link.href}
                className="px-4 py-3 rounded-xl text-cozy-ink hover:bg-cozy-surface-muted hover:text-cozy-primary font-medium transition-colors"
                onClick={() => {
                  trackNavClick(link.label, link.href, 'mobile_menu')
                  setMobileOpen(false)
                }}
              >
                {link.label}
              </a>
            ))}
            {!suppressStoreCta && <a
              href={OFFICIAL_APP_STORE_URL}
              className="mt-2 flex items-center justify-center gap-2 bg-cozy-primary text-white border-[2.5px] border-cozy-ink px-5 py-3 rounded-full font-bold text-sm shadow-cozy-hard transition-all duration-150 hover:-translate-x-0.5 hover:-translate-y-0.5 hover:shadow-cozy-hard-lg"
              target="_blank"
              rel="noopener noreferrer"
              data-store-location="mobile_menu"
              onClick={() => trackCTAClick('mobile_menu', 'Download now on iOS')}
            >
              Download now on iOS
            </a>}
          </nav>
        </div>
      )}
    </header>
  )
}
