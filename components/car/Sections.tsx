"use client"

import { CAR_PARTS, SECTIONS } from "./parts"
import { cn } from "@/lib/utils"

type SectionsProps = {
  activeSection: number
  activePartId: string | null
  onSelectPart: (id: string | null) => void
}

export default function Sections({
  activeSection,
  activePartId,
  onSelectPart,
}: SectionsProps) {
  return (
    <div className="relative z-10">
      {SECTIONS.map((section, index) => {
        const sectionParts = CAR_PARTS.filter((p) => p.section === index)
        const isActive = index === activeSection
        return (
          <section
            key={section.id}
            data-section={index}
            className="min-h-screen w-full flex items-center px-6 md:px-12"
          >
            <div className="w-full max-w-[1400px] mx-auto grid grid-cols-1 md:grid-cols-12 gap-8 items-center">
              <div
                className={cn(
                  "md:col-span-5 md:col-start-1 transition-all duration-700",
                  isActive ? "opacity-100 translate-y-0" : "opacity-30 translate-y-3"
                )}
              >
                <div className="inline-flex items-center gap-2 text-xs uppercase tracking-[0.25em] text-brand-accent mb-4">
                  <span className="w-2 h-2 rounded-full bg-brand-accent animate-pulse-ring" />
                  {section.tag}
                </div>
                <h2 className="text-4xl md:text-6xl font-bold leading-[1.05] mb-5">
                  {index === 0 ? (
                    <>
                      <span className="gradient-text">כל חלק.</span>{" "}
                      <span>במקום הנכון.</span>
                    </>
                  ) : (
                    section.title
                  )}
                </h2>
                <p className="text-brand-muted text-lg md:text-xl max-w-xl leading-relaxed">
                  {section.subtitle}
                </p>

                {sectionParts.length > 0 && (
                  <ul className="mt-8 space-y-2">
                    {sectionParts.map((part) => {
                      const selected = part.id === activePartId
                      return (
                        <li key={part.id}>
                          <button
                            onMouseEnter={() => onSelectPart(part.id)}
                            onMouseLeave={() => onSelectPart(null)}
                            onClick={() =>
                              onSelectPart(selected ? null : part.id)
                            }
                            className={cn(
                              "group w-full text-right glass rounded-xl px-4 py-3 flex items-center justify-between gap-4 transition-all",
                              selected
                                ? "border-brand-accent/60 shadow-[0_0_30px_-10px_rgba(240,78,35,0.7)]"
                                : "hover:border-white/15"
                            )}
                          >
                            <span className="flex items-center gap-3">
                              <span
                                className={cn(
                                  "w-1.5 h-6 rounded-full transition-colors",
                                  selected ? "bg-brand-accent" : "bg-white/15"
                                )}
                              />
                              <span>
                                <span className="block font-semibold">
                                  {part.hebrewName}
                                </span>
                                <span className="block text-xs text-brand-muted">
                                  {part.category} · {part.warranty}
                                </span>
                              </span>
                            </span>
                            <span className="text-brand-accent2 font-mono text-sm">
                              {part.price}
                            </span>
                          </button>
                        </li>
                      )
                    })}
                  </ul>
                )}

                {index === 0 && (
                  <div className="mt-10 flex flex-wrap gap-3">
                    <a
                      href="#drivetrain"
                      className="inline-flex items-center gap-2 bg-brand-accent text-white px-6 py-3 rounded-full font-semibold hover:scale-[1.03] transition-transform"
                    >
                      התחל בסיור
                      <span aria-hidden>←</span>
                    </a>
                    <a
                      href="#cta"
                      className="inline-flex items-center gap-2 glass px-6 py-3 rounded-full font-semibold hover:border-white/25 transition-colors"
                    >
                      דלג לתצורה
                    </a>
                  </div>
                )}

                {index === SECTIONS.length - 1 && (
                  <div className="mt-8">
                    <a
                      href="#"
                      className="inline-flex items-center gap-2 bg-brand-accent text-white px-6 py-3 rounded-full font-semibold hover:scale-[1.03] transition-transform"
                    >
                      להתחלת ההזמנה
                      <span aria-hidden>←</span>
                    </a>
                  </div>
                )}
              </div>

              {/* Right side reserved for the 3D canvas behind */}
              <div className="hidden md:block md:col-span-7" />
            </div>
          </section>
        )
      })}
    </div>
  )
}
