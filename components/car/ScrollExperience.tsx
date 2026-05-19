"use client"

import { useEffect, useRef, useState } from "react"
import dynamic from "next/dynamic"
import Sections from "./Sections"
import { SECTIONS, CAR_PARTS } from "./parts"
import { clamp } from "@/lib/utils"

const Scene = dynamic(() => import("./Scene"), { ssr: false })

export default function ScrollExperience() {
  const containerRef = useRef<HTMLDivElement>(null)
  const [scroll, setScroll] = useState(0)
  const [activeSection, setActiveSection] = useState(0)
  const [hoveredPart, setHoveredPart] = useState<string | null>(null)

  useEffect(() => {
    const onScroll = () => {
      const el = containerRef.current
      if (!el) return
      const total = el.scrollHeight - window.innerHeight
      const p = clamp(window.scrollY / Math.max(total, 1), 0, 1)
      setScroll(p)
      const idx = Math.round(p * (SECTIONS.length - 1))
      setActiveSection(idx)
    }
    onScroll()
    window.addEventListener("scroll", onScroll, { passive: true })
    window.addEventListener("resize", onScroll)
    return () => {
      window.removeEventListener("scroll", onScroll)
      window.removeEventListener("resize", onScroll)
    }
  }, [])

  // The active part is what the user hovers; otherwise pick a representative
  // part from the current section so the side panel never feels disconnected.
  const sectionDefaultPart =
    CAR_PARTS.find((p) => p.section === activeSection)?.id ?? null
  const activePartId = hoveredPart ?? sectionDefaultPart

  return (
    <div ref={containerRef} className="relative w-full">
      {/* Fixed 3D background */}
      <div className="fixed inset-0 -z-0 grid-bg" aria-hidden>
        <div className="absolute inset-0 bg-gradient-to-b from-brand-bg via-transparent to-brand-bg" />
        <Scene scroll={scroll} activePartId={activePartId} />
      </div>

      {/* Top nav */}
      <header className="fixed top-0 inset-x-0 z-30">
        <div className="max-w-[1400px] mx-auto px-6 md:px-12 py-5 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-lg bg-gradient-to-br from-brand-accent to-brand-accent2 grid place-items-center font-black text-brand-bg">
              A
            </div>
            <span className="font-bold text-lg">AutoParts3D</span>
          </div>
          <nav className="hidden md:flex items-center gap-6 text-sm text-brand-muted">
            {SECTIONS.slice(1, -1).map((s, i) => (
              <a
                key={s.id}
                href={`#${s.id}`}
                className="hover:text-white transition-colors"
              >
                {s.tag}
              </a>
            ))}
          </nav>
          <a
            href="#cta"
            className="text-sm bg-white text-brand-bg px-4 py-2 rounded-full font-semibold hover:bg-brand-accent hover:text-white transition-colors"
          >
            הזמן עכשיו
          </a>
        </div>
      </header>

      {/* Progress dots */}
      <div className="fixed left-6 top-1/2 -translate-y-1/2 z-20 hidden md:flex flex-col gap-3">
        {SECTIONS.map((s, i) => (
          <a
            key={s.id}
            href={`#${s.id}`}
            aria-label={s.title}
            className={`block w-2.5 h-2.5 rounded-full transition-all ${
              i === activeSection
                ? "bg-brand-accent scale-125"
                : "bg-white/20 hover:bg-white/40"
            }`}
          />
        ))}
      </div>

      {/* Scroll hint */}
      <div
        className={`fixed bottom-6 inset-x-0 z-20 flex justify-center transition-opacity duration-500 ${
          scroll > 0.02 ? "opacity-0 pointer-events-none" : "opacity-100"
        }`}
        aria-hidden
      >
        <div className="glass px-4 py-2 rounded-full text-xs text-brand-muted flex items-center gap-2">
          גלול למטה כדי לחקור את הרכב
          <span className="inline-block animate-bounce">↓</span>
        </div>
      </div>

      {/* Anchored sections (text content on top of the canvas) */}
      <div className="relative z-10">
        {SECTIONS.map((s) => (
          <span
            key={s.id}
            id={s.id}
            className="block h-0 w-0 pointer-events-none"
            aria-hidden
          />
        ))}
        <Sections
          activeSection={activeSection}
          activePartId={activePartId}
          onSelectPart={setHoveredPart}
        />
      </div>

      {/* Footer */}
      <footer className="relative z-10 border-t border-white/5 py-10 text-center text-sm text-brand-muted">
        © AutoParts3D · חלקי חילוף מקוריים · משלוח ארצי תוך 48 שעות
      </footer>
    </div>
  )
}
