'use client'

import { useEffect } from 'react'
import posthog from 'posthog-js'
import { trackResourceStoreClick } from '@/lib/resource-store-click'

/** Measures outbound clicks, including links rendered from Contentful rich text. */
export default function ResourceStoreClickTracker() {
  useEffect(() => {
    function handleClick(event: MouseEvent) {
      const article = document.querySelector('article.cozy-page')
      if (article) trackResourceStoreClick(event.target, window.location.pathname, article, posthog.capture.bind(posthog))
    }

    document.addEventListener('click', handleClick)
    return () => document.removeEventListener('click', handleClick)
  }, [])

  return null
}
