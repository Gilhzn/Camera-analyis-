import type { Metadata } from "next"
import { Heebo } from "next/font/google"
import "./globals.css"

const heebo = Heebo({
  subsets: ["hebrew", "latin"],
  variable: "--font-heebo",
  display: "swap",
})

export const metadata: Metadata = {
  title: "AutoParts3D — חלקי חילוף לרכב",
  description:
    "חוויית גלילה תלת-מימדית לחלקי חילוף מקוריים לרכב. גלה את החלקים תוך כדי גלילה.",
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="he" dir="rtl" className={heebo.variable}>
      <body>{children}</body>
    </html>
  )
}
