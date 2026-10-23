import { OFFICIAL_APP_STORE_URL } from '@/lib/constants'

export default function SubtleCallout({ suppressStoreCta = false }: { suppressStoreCta?: boolean }) {
  if (suppressStoreCta) return null
  return (
    <aside className="mb-16 md:mb-20 cozy-card-soft p-6 md:p-8">
      <div className="flex flex-col sm:flex-row items-start sm:items-center gap-4">
        <div className="flex-1">
          <p className="text-sm font-bold text-cozy-ink mb-1">
            Looking for a tool to help?
          </p>
          <p className="text-sm text-cozy-ink-muted">
            FaithLock uses Scripture-based app blocking to build daily Bible
            habits. Free on iOS.
          </p>
        </div>
        <a
          href={OFFICIAL_APP_STORE_URL}
          data-store-location="subtle_callout"
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center gap-2 bg-cozy-primary text-white border-[2.5px] border-cozy-ink shadow-cozy-hard-sm px-4 py-2 rounded-full text-sm font-bold transition-all duration-150 hover:-translate-x-0.5 hover:-translate-y-0.5 hover:shadow-cozy-hard flex-shrink-0"
        >
          <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
            <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
          </svg>
          Try Free
        </a>
      </div>
    </aside>
  )
}
