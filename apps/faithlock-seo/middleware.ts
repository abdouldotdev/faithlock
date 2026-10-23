import { NextRequest, NextResponse } from 'next/server'

const TARGET_PATH = '/resources/best-app-blockers-iphone'
const SUPPRESS_CTA_HEADER = 'x-faithlock-suppress-global-store-ctas'

export function middleware(request: NextRequest) {
  const requestHeaders = new Headers(request.headers)
  requestHeaders.set(SUPPRESS_CTA_HEADER, request.nextUrl.pathname === TARGET_PATH ? '1' : '0')
  return NextResponse.next({ request: { headers: requestHeaders } })
}

export const config = { matcher: '/resources/:path*' }