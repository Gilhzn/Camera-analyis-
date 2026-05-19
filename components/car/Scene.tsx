"use client"

import { Suspense, useEffect, useRef, useState } from "react"
import { Canvas, useThree, useFrame } from "@react-three/fiber"
import { ContactShadows, PerspectiveCamera } from "@react-three/drei"
import * as THREE from "three"
import CarModel from "./CarModel"
import { SECTIONS } from "./parts"
import { lerp } from "@/lib/utils"

function CameraRig({ scroll }: { scroll: number }) {
  const { camera } = useThree()
  const target = useRef(new THREE.Vector3(0, 0.2, 0))

  useFrame(() => {
    // Stay far enough out that the full exploded car always fits.
    const radius = lerp(15, 17, scroll)
    // Smooth orbit from front-right to rear-right (no full 360 — keeps brand side visible).
    const angle = lerp(Math.PI * 0.18, Math.PI * 0.85, scroll)
    const tx = Math.sin(angle) * radius
    const tz = Math.cos(angle) * radius
    // Subtle vertical arc — high during body explode, lower at the wheels.
    const ty = lerp(4.5, 3.0, scroll) + Math.sin(scroll * Math.PI) * 0.8

    camera.position.x = lerp(camera.position.x, tx, 0.07)
    camera.position.y = lerp(camera.position.y, ty, 0.07)
    camera.position.z = lerp(camera.position.z, tz, 0.07)
    camera.lookAt(target.current)
  })
  return null
}

type SceneProps = {
  scroll: number
  activePartId: string | null
}

export default function Scene({ scroll, activePartId }: SceneProps) {
  const [dpr, setDpr] = useState(1.5)

  useEffect(() => {
    setDpr(Math.min(window.devicePixelRatio || 1, 2))
  }, [])

  return (
    <Canvas
      dpr={dpr}
      shadows
      gl={{ antialias: true, powerPreference: "high-performance" }}
      style={{ width: "100%", height: "100%" }}
    >
      <color attach="background" args={["#06070b"]} />
      <fog attach="fog" args={["#06070b", 22, 40]} />

      <PerspectiveCamera makeDefault position={[3, 5, 14]} fov={42} />
      <CameraRig scroll={scroll} />

      <hemisphereLight args={["#9bb8ff", "#1a1612", 0.55]} />
      <ambientLight intensity={0.25} />
      <directionalLight
        position={[6, 9, 4]}
        intensity={1.8}
        castShadow
        shadow-mapSize-width={1024}
        shadow-mapSize-height={1024}
      />
      <directionalLight position={[-7, 3, -4]} intensity={0.8} color="#22d3ee" />
      <directionalLight position={[0, 6, -8]} intensity={0.5} color="#ffffff" />
      <pointLight position={[0, 3, 6]} intensity={0.9} color="#f04e23" />
      <pointLight position={[4, 1, 2]} intensity={0.4} color="#ffffff" />

      <Suspense fallback={null}>
        <CarModel
          scroll={scroll}
          totalSections={SECTIONS.length}
          activePartId={activePartId}
        />
        <ContactShadows
          position={[0, -1.3, 0]}
          opacity={0.55}
          scale={14}
          blur={2.4}
          far={6}
        />
      </Suspense>
    </Canvas>
  )
}
