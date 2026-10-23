import Header from '@/components/layout/Header'
import Footer from '@/components/layout/Footer'
import { headers } from 'next/headers'

const SUPPRESS_CTA_HEADER = 'x-faithlock-suppress-global-store-ctas'

export default function SeoLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const suppressStoreCta = headers().get(SUPPRESS_CTA_HEADER) === '1'
  return (
    <>
      <Header suppressStoreCta={suppressStoreCta} />
      <main className="min-h-screen">{children}</main>
      <Footer suppressStoreCta={suppressStoreCta} />
    </>
  )
}
