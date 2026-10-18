'use client'

import { useEffect } from 'react'
import posthog from 'posthog-js'
import { getArticleStoreClick } from '@/lib/resource-store-click'

/** Measures outbound clicks, including links rendered from Contentful rich text. */
export default function ResourceStoreClickTracker() {
  useEffect(() => {
    function handleClick(event: MouseEvent) {
      if (!(event.target instanceof Element)) return
      const anchor = event.target.closest('a[href]') as HTMLAnchorElement | null
      if (!anchor) return

      const pagePath = window.location.pathname
      const article = document.querySelector('article.cozy-page')
      if (!article) return
      const props = getArticleStoreClick(article, anchor, pagePath)
      if (props) posthog.capture('faithlock_store_click', props)
      // Do not prevent navigation or await analytics: the destination must work offline.
    }

    document.addEventListener('click', handleClick)
    return () => document.removeEventListener('click', handleClick)
  }, [])

  return null
}
