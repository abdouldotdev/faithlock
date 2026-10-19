'use client'

import posthog from 'posthog-js'
import { PostHogProvider as PHProvider } from 'posthog-js/react'
import { useEffect } from 'react'
import { trackStoreClick } from '@/lib/analytics'
import { storeDestinationType, storeLinkLocation } from '@/lib/store-click'

export function PostHogProvider({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    posthog.init(process.env.NEXT_PUBLIC_POSTHOG_KEY!, {
      api_host: process.env.NEXT_PUBLIC_POSTHOG_HOST,
      person_profiles: 'identified_only',
      capture_pageview: true,
      capture_pageleave: true,
    })
  }, [])

  // Single source of `faithlock_store_click`: catches every store link on every
  // page (components, landing, markdown content) so no CTA can be missed.
  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (e.type === 'auxclick' && e.button !== 1) return
      const link = (e.target as HTMLElement | null)?.closest('a[href]') as HTMLAnchorElement | null
      if (!link || !storeDestinationType(link.href)) return
      trackStoreClick(link.href, storeLinkLocation(link), link.textContent?.trim())
    }

    document.addEventListener('click', handleClick, true)
    document.addEventListener('auxclick', handleClick, true)
    return () => {
      document.removeEventListener('click', handleClick, true)
      document.removeEventListener('auxclick', handleClick, true)
    }
  }, [])

  return <PHProvider client={posthog}>{children}</PHProvider>
}
