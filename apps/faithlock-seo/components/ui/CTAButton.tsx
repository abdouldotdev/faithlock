'use client'

import { trackCTAClick } from '@/lib/analytics'

interface CTAButtonProps {
  text: string
  href: string
  variant?: 'primary' | 'white' | 'outline' | 'dark'
  size?: 'small' | 'medium' | 'large'
  showAppleIcon?: boolean
  trackingLocation?: string
}

export default function CTAButton({
  text,
  href,
  variant = 'primary',
  size = 'medium',
  showAppleIcon = false,
  trackingLocation = 'unknown',
}: CTAButtonProps) {
  const baseStyles =
    'inline-flex items-center justify-center gap-2 font-bold rounded-full border-[2.5px] border-cozy-ink transition-all duration-150 text-center hover:-translate-x-0.5 hover:-translate-y-0.5 active:translate-x-0 active:translate-y-0'

  const sizeStyles = {
    small: 'px-4 py-2 text-sm',
    medium: 'px-6 py-3 text-sm',
    large: 'px-8 py-4 text-base',
  }

  const variantStyles = {
    primary:
      'bg-cozy-primary text-white shadow-cozy-hard hover:shadow-cozy-hard-lg active:shadow-cozy-hard-sm',
    white:
      'bg-cozy-surface text-cozy-ink shadow-cozy-hard hover:shadow-cozy-hard-lg active:shadow-cozy-hard-sm',
    outline:
      'bg-transparent text-cozy-ink hover:bg-cozy-surface-muted shadow-cozy-hard hover:shadow-cozy-hard-lg active:shadow-cozy-hard-sm',
    dark:
      'bg-cozy-ink text-cozy-cream shadow-cozy-hard hover:shadow-cozy-hard-lg active:shadow-cozy-hard-sm',
  }

  return (
    <a
      href={href}
      className={`${baseStyles} ${sizeStyles[size]} ${variantStyles[variant]}`}
      target="_blank"
      rel="noopener noreferrer"
      data-store-location={trackingLocation}
      onClick={() => trackCTAClick(trackingLocation, text)}
    >
      {showAppleIcon && (
        <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" className="flex-shrink-0">
          <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
        </svg>
      )}
      {text}
    </a>
  )
}
