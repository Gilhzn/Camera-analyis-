"use client"

import { Suspense, useEffect, useRef, useState } from "react"
import { Canvas, useThree, useFrame } from "@react-three/fiber"
import {
  Environment,
  ContactShadows,
  PerspectiveCamera,
} from "@react-three/drei"
import * as THREE from "three"
import CarModel from "./CarModel"
import { SECTIONS } from "./parts"
import { lerp } from "@/lib/utils"

function CameraRig({ scroll }: { scroll: number }) {
  const { camera } = useThree()
  const target = useRef(new THREE.Vector3(0, 0.4, 0))

  useFrame(() => {
    // Camera arcs around as you scroll
    const radius = 9.5
    const angle = scroll * Math.PI * 1.4 - Math.PI * 0.4
    const tx = Math.sin(angle) * radius
    const tz = Math.cos(angle) * radius
    const ty = lerp(3.2, 1.2, scroll) + Math.sin(scroll * Math.PI) * 1.2

    camera.position.x = lerp(camera.position.x, tx, 0.08)
    camera.position.y = lerp(camera.position.y, ty, 0.08)
    camera.position.z = lerp(camera.position.z, tz, 0.08)
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
      <fog attach="fog" args={["#06070b", 14, 30]} />

      <PerspectiveCamera makeDefault position={[0, 4, 10]} fov={38} />
      <CameraRig scroll={scroll} />

      <ambientLight intensity={0.4} />
      <directionalLight
        position={[6, 9, 4]}
        intensity={1.6}
        castShadow
        shadow-mapSize-width={1024}
        shadow-mapSize-height={1024}
      />
      <directionalLight position={[-6, 4, -3]} intensity={0.6} color="#22d3ee" />
      <pointLight position={[0, 5, 5]} intensity={0.6} color="#f04e23" />

      <Suspense fallback={null}>
        <CarModel
          scroll={scroll}
          totalSections={SECTIONS.length}
          activePartId={activePartId}
        />
        <Environment preset="city" />
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
