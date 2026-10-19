import Header from '@/components/layout/Header'
import Footer from '@/components/layout/Footer'
import ResourceStoreClickTracker from '@/components/templates/ResourceStoreClickTracker'

export default function SeoLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <>
      <Header />
      <ResourceStoreClickTracker />
      <main className="min-h-screen">{children}</main>
      <Footer />
    </>
  )
}
