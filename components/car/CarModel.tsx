"use client"

import { useMemo, useRef } from "react"
import { useFrame } from "@react-three/fiber"
import * as THREE from "three"
import { CAR_PARTS, type CarPart } from "./parts"
import { lerp, smoothstep } from "@/lib/utils"

type PartProps = {
  part: CarPart
  progress: number
  active: boolean
  children: React.ReactNode
}

function Part({ part, progress, active, children }: PartProps) {
  const ref = useRef<THREE.Group>(null!)
  const t = smoothstep(0, 1, progress)
  const target = useMemo(
    () =>
      new THREE.Vector3(part.explode[0], part.explode[1], part.explode[2]),
    [part]
  )

  useFrame(() => {
    if (!ref.current) return
    ref.current.position.x = lerp(ref.current.position.x, target.x * t, 0.12)
    ref.current.position.y = lerp(ref.current.position.y, target.y * t, 0.12)
    ref.current.position.z = lerp(ref.current.position.z, target.z * t, 0.12)
    const scale = active ? 1.05 : 1
    ref.current.scale.x = lerp(ref.current.scale.x, scale, 0.15)
    ref.current.scale.y = lerp(ref.current.scale.y, scale, 0.15)
    ref.current.scale.z = lerp(ref.current.scale.z, scale, 0.15)
  })

  return <group ref={ref}>{children}</group>
}

const bodyPaint = (
  <meshStandardMaterial color="#d72b1f" metalness={0.45} roughness={0.42} />
)

const darkMetal = (
  <meshStandardMaterial color="#1a1d24" metalness={0.85} roughness={0.45} />
)

const glass = (
  <meshStandardMaterial
    color="#0a1018"
    metalness={0.4}
    roughness={0.15}
    transparent
    opacity={0.55}
  />
)

const tireMat = (
  <meshStandardMaterial color="#0c0d10" roughness={0.95} metalness={0.05} />
)

const rimMat = (
  <meshStandardMaterial color="#c9ced6" metalness={0.95} roughness={0.25} />
)

const lightMat = (
  <meshStandardMaterial
    color="#fff7cf"
    emissive="#ffe07a"
    emissiveIntensity={1.4}
    roughness={0.2}
    metalness={0.1}
  />
)

const brakeMat = (
  <meshStandardMaterial color="#f04e23" metalness={0.6} roughness={0.4} />
)

function Wheel() {
  return (
    <group rotation={[0, 0, Math.PI / 2]}>
      <mesh castShadow receiveShadow>
        <cylinderGeometry args={[0.55, 0.55, 0.4, 32]} />
        {tireMat}
      </mesh>
      <mesh position={[0, 0.01, 0]} castShadow>
        <cylinderGeometry args={[0.34, 0.34, 0.42, 24]} />
        {rimMat}
      </mesh>
      <mesh position={[0, 0.02, 0]}>
        <cylinderGeometry args={[0.18, 0.18, 0.44, 16]} />
        {brakeMat}
      </mesh>
    </group>
  )
}

function getProgressFor(part: CarPart, scroll: number, totalSections: number) {
  const start = (part.section - 0.4) / totalSections
  const end = (part.section + 0.6) / totalSections
  if (scroll <= start) return 0
  if (scroll >= end) return 1
  return (scroll - start) / (end - start)
}

type CarModelProps = {
  scroll: number
  totalSections: number
  activePartId: string | null
}

export default function CarModel({
  scroll,
  totalSections,
  activePartId,
}: CarModelProps) {
  const root = useRef<THREE.Group>(null!)

  useFrame(() => {
    if (!root.current) return
    // Gentle idle rotation only — the camera does the heavy lifting.
    const targetY = scroll * 0.25
    root.current.rotation.y = lerp(root.current.rotation.y, targetY, 0.08)
    const float = Math.sin(performance.now() * 0.0008) * 0.04
    root.current.position.y = lerp(root.current.position.y, float, 0.1)
  })

  const partProgress = (id: string) => {
    const p = CAR_PARTS.find((x) => x.id === id)
    if (!p) return 0
    return getProgressFor(p, scroll, totalSections)
  }

  const renderPart = (id: string, geom: React.ReactNode) => {
    const part = CAR_PARTS.find((x) => x.id === id)
    if (!part) return null
    return (
      <Part
        part={part}
        progress={partProgress(id)}
        active={activePartId === id}
      >
        {geom}
      </Part>
    )
  }

  return (
    <group ref={root}>
      {/* Chassis (does not explode) */}
      <mesh position={[0, -0.7, 0]} castShadow receiveShadow>
        <boxGeometry args={[4.2, 0.4, 7.6]} />
        <meshStandardMaterial
          color="#15171c"
          metalness={0.6}
          roughness={0.6}
        />
      </mesh>

      {/* Main body shell */}
      <mesh position={[0, 0.1, 0]} castShadow receiveShadow>
        <boxGeometry args={[3.9, 0.9, 6.6]} />
        {bodyPaint}
      </mesh>

      {/* Lower side panels */}
      <mesh position={[1.95, -0.35, 0]} castShadow>
        <boxGeometry args={[0.08, 0.5, 6.0]} />
        {darkMetal}
      </mesh>
      <mesh position={[-1.95, -0.35, 0]} castShadow>
        <boxGeometry args={[0.08, 0.5, 6.0]} />
        {darkMetal}
      </mesh>

      {/* Front fascia / grille */}
      <mesh position={[0, 0, 3.4]} castShadow>
        <boxGeometry args={[3.0, 0.5, 0.2]} />
        <meshStandardMaterial
          color="#0a0b0d"
          metalness={0.4}
          roughness={0.7}
        />
      </mesh>

      {/* Engine */}
      {renderPart(
        "engine",
        <group>
          <mesh castShadow>
            <boxGeometry args={[2.0, 0.9, 1.8]} />
            <meshStandardMaterial
              color="#3d4654"
              metalness={0.7}
              roughness={0.4}
            />
          </mesh>
          {[-0.6, -0.2, 0.2, 0.6].map((x) => (
            <mesh key={x} position={[x, 0.55, 0]}>
              <cylinderGeometry args={[0.18, 0.18, 0.35, 16]} />
              <meshStandardMaterial color="#9aa3b1" metalness={0.9} roughness={0.3} />
            </mesh>
          ))}
          <mesh position={[0, 0.8, 0]}>
            <boxGeometry args={[2.1, 0.15, 1.9]} />
            <meshStandardMaterial color="#f04e23" metalness={0.4} roughness={0.5} />
          </mesh>
        </group>
      )}

      {/* Battery */}
      {renderPart(
        "battery",
        <mesh castShadow>
          <boxGeometry args={[0.7, 0.5, 0.5]} />
          <meshStandardMaterial color="#222831" metalness={0.4} roughness={0.7} />
        </mesh>
      )}

      {/* Exhaust */}
      {renderPart(
        "exhaust",
        <group rotation={[Math.PI / 2, 0, 0]}>
          <mesh>
            <cylinderGeometry args={[0.12, 0.12, 1.8, 16]} />
            <meshStandardMaterial color="#9aa3b1" metalness={0.95} roughness={0.2} />
          </mesh>
          <mesh position={[0, 0.95, 0]}>
            <cylinderGeometry args={[0.18, 0.18, 0.3, 16]} />
            <meshStandardMaterial color="#9aa3b1" metalness={0.95} roughness={0.2} />
          </mesh>
        </group>
      )}

      {/* Hood */}
      {renderPart(
        "hood",
        <mesh position={[0, 0.6, 1.8]} castShadow>
          <boxGeometry args={[3.6, 0.12, 2.4]} />
          {bodyPaint}
        </mesh>
      )}

      {/* Roof */}
      {renderPart(
        "roof",
        <group position={[0, 1.05, -0.4]}>
          <mesh castShadow>
            <boxGeometry args={[3.4, 0.12, 3.6]} />
            {bodyPaint}
          </mesh>
          {/* Windshield */}
          <mesh position={[0, -0.3, 1.95]} rotation={[-Math.PI / 7, 0, 0]}>
            <planeGeometry args={[3.0, 1.2]} />
            {glass}
          </mesh>
          {/* Rear window */}
          <mesh position={[0, -0.3, -1.95]} rotation={[Math.PI / 7, 0, 0]}>
            <planeGeometry args={[3.0, 1.2]} />
            {glass}
          </mesh>
        </group>
      )}

      {/* Doors */}
      {renderPart(
        "door-l",
        <mesh position={[1.95, 0.4, -0.3]} castShadow>
          <boxGeometry args={[0.12, 1.2, 2.4]} />
          {bodyPaint}
        </mesh>
      )}
      {renderPart(
        "door-r",
        <mesh position={[-1.95, 0.4, -0.3]} castShadow>
          <boxGeometry args={[0.12, 1.2, 2.4]} />
          {bodyPaint}
        </mesh>
      )}

      {/* Headlights */}
      {renderPart(
        "headlight-l",
        <mesh position={[1.1, 0.15, 3.45]}>
          <boxGeometry args={[0.9, 0.35, 0.2]} />
          {lightMat}
        </mesh>
      )}
      {renderPart(
        "headlight-r",
        <mesh position={[-1.1, 0.15, 3.45]}>
          <boxGeometry args={[0.9, 0.35, 0.2]} />
          {lightMat}
        </mesh>
      )}

      {/* Mirrors */}
      {renderPart(
        "mirror-l",
        <group position={[2.1, 0.85, 1.2]}>
          <mesh>
            <boxGeometry args={[0.18, 0.18, 0.4]} />
            {bodyPaint}
          </mesh>
        </group>
      )}
      {renderPart(
        "mirror-r",
        <group position={[-2.1, 0.85, 1.2]}>
          <mesh>
            <boxGeometry args={[0.18, 0.18, 0.4]} />
            {bodyPaint}
          </mesh>
        </group>
      )}

      {/* Wheels */}
      {renderPart(
        "wheel-fl",
        <group position={[1.85, -0.6, 2.2]}>
          <Wheel />
        </group>
      )}
      {renderPart(
        "wheel-fr",
        <group position={[-1.85, -0.6, 2.2]}>
          <Wheel />
        </group>
      )}
      {renderPart(
        "wheel-rl",
        <group position={[1.85, -0.6, -2.2]}>
          <Wheel />
        </group>
      )}
      {renderPart(
        "wheel-rr",
        <group position={[-1.85, -0.6, -2.2]}>
          <Wheel />
        </group>
      )}
    </group>
  )
}
