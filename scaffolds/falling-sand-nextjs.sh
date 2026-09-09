#!/usr/bin/env bash

# Falling Sand Next.js Scaffold
# Works with Next.js 15.4.4 and src/ directory structure.

set -e

echo "Scaffolding Falling Sand Simulation..."

# Detect if we're using src/ structure
if [ -d "src/app" ]; then
    echo "✓ Detected src/ directory structure"
    BASE_DIR="src"
else
    echo "✓ Using root directory structure"
    BASE_DIR="."
fi

# Create directory structure
mkdir -p $BASE_DIR/components/falling-sand/{typescript,zig,webgl,shared}
mkdir -p $BASE_DIR/app/falling-sand
mkdir -p public/wasm

# ==============================================================================
# Shared Types and Constants
# ==============================================================================

cat > $BASE_DIR/components/falling-sand/shared/types.ts << 'EOF'
export enum ParticleType {
  Empty = 0,
  Sand = 1,
  Water = 2,
  Stone = 3,
}

export interface SimulationConfig {
  width: number
  height: number
  scale: number
}

export const COLORS: Record<number, number> = {
  [ParticleType.Empty]: 0x00000000,
  [ParticleType.Sand]: 0xFFC9A76A,
  [ParticleType.Water]: 0xFF3B82F6,
  [ParticleType.Stone]: 0xFF6B7280,
} as const

export const DEFAULT_CONFIG: SimulationConfig = {
  width: 200,
  height: 150,
  scale: 4
}
EOF

# ==============================================================================
# TypeScript Canvas Implementation
# ==============================================================================

cat > $BASE_DIR/components/falling-sand/typescript/CanvasSimulation.tsx << 'EOF'
'use client'
import { useRef, useEffect, useCallback, useState } from 'react'
import { ParticleType, COLORS, DEFAULT_CONFIG } from '../shared/types'

export default function CanvasSimulation() {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const gridRef = useRef<Uint8Array | null>(null)
  const animationRef = useRef<number | null>(null)
  const mouseDownRef = useRef(false)
  const [selectedType, setSelectedType] = useState(ParticleType.Sand)

  const initGrid = useCallback(() => {
    const size = DEFAULT_CONFIG.width * DEFAULT_CONFIG.height
    gridRef.current = new Uint8Array(size)
  }, [])

  const getIndex = (x: number, y: number) => y * DEFAULT_CONFIG.width + x
  
  const updateParticles = useCallback(() => {
    if (!gridRef.current) return
    const grid = gridRef.current
    const width = DEFAULT_CONFIG.width
    const height = DEFAULT_CONFIG.height
    const newGrid = new Uint8Array(grid)
    
    // Process bottom to top
    for (let y = height - 2; y >= 0; y--) {
      // Alternate left/right each row for more natural flow
      const xStart = y % 2 === 0 ? 0 : width - 1
      const xEnd = y % 2 === 0 ? width : -1
      const xStep = y % 2 === 0 ? 1 : -1
      
      for (let x = xStart; x !== xEnd; x += xStep) {
        const idx = getIndex(x, y)
        const particle = grid[idx]
        
        if (particle === ParticleType.Sand) {
          const below = getIndex(x, y + 1)
          const belowLeft = x > 0 ? getIndex(x - 1, y + 1) : -1
          const belowRight = x < width - 1 ? getIndex(x + 1, y + 1) : -1
          
          if (grid[below] === ParticleType.Empty || grid[below] === ParticleType.Water) {
            // Sand falls through water
            const temp = grid[below]
            newGrid[below] = particle
            newGrid[idx] = temp
          } else if (belowLeft !== -1 && (grid[belowLeft] === ParticleType.Empty || grid[belowLeft] === ParticleType.Water)) {
            const temp = grid[belowLeft]
            newGrid[belowLeft] = particle
            newGrid[idx] = temp
          } else if (belowRight !== -1 && (grid[belowRight] === ParticleType.Empty || grid[belowRight] === ParticleType.Water)) {
            const temp = grid[belowRight]
            newGrid[belowRight] = particle
            newGrid[idx] = temp
          }
        } else if (particle === ParticleType.Water) {
          const below = getIndex(x, y + 1)
          const left = x > 0 ? getIndex(x - 1, y) : -1
          const right = x < width - 1 ? getIndex(x + 1, y) : -1
          
          if (grid[below] === ParticleType.Empty) {
            newGrid[below] = particle
            newGrid[idx] = ParticleType.Empty
          } else {
            // Water flows sideways
            const canLeft = left !== -1 && grid[left] === ParticleType.Empty
            const canRight = right !== -1 && grid[right] === ParticleType.Empty
            
            if (canLeft && canRight) {
              // Random direction
              if (Math.random() > 0.5) {
                newGrid[left] = particle
                newGrid[idx] = ParticleType.Empty
              } else {
                newGrid[right] = particle
                newGrid[idx] = ParticleType.Empty
              }
            } else if (canLeft) {
              newGrid[left] = particle
              newGrid[idx] = ParticleType.Empty
            } else if (canRight) {
              newGrid[right] = particle
              newGrid[idx] = ParticleType.Empty
            }
          }
        }
        // Stone doesn't move
      }
    }
    
    gridRef.current = newGrid
  }, [])

  const render = useCallback(() => {
    const canvas = canvasRef.current
    if (!canvas || !gridRef.current) return
    
    const ctx = canvas.getContext('2d', { alpha: false })!
    const imageData = ctx.createImageData(DEFAULT_CONFIG.width, DEFAULT_CONFIG.height)
    const data32 = new Uint32Array(imageData.data.buffer)
    
    for (let i = 0; i < gridRef.current.length; i++) {
      data32[i] = COLORS[gridRef.current[i]] || 0xFF000000
    }
    
    ctx.putImageData(imageData, 0, 0)
  }, [])

  const gameLoop = useCallback(() => {
    updateParticles()
    render()
    animationRef.current = requestAnimationFrame(gameLoop)
  }, [updateParticles, render])

  const handlePointer = useCallback((e: React.PointerEvent) => {
    if (!mouseDownRef.current || !gridRef.current) return
    
    const rect = canvasRef.current!.getBoundingClientRect()
    const x = Math.floor((e.clientX - rect.left) / DEFAULT_CONFIG.scale)
    const y = Math.floor((e.clientY - rect.top) / DEFAULT_CONFIG.scale)
    
    // Draw in a 3x3 area
    for (let dy = -1; dy <= 1; dy++) {
      for (let dx = -1; dx <= 1; dx++) {
        const px = x + dx
        const py = y + dy
        if (px >= 0 && px < DEFAULT_CONFIG.width && py >= 0 && py < DEFAULT_CONFIG.height) {
          gridRef.current[getIndex(px, py)] = selectedType
        }
      }
    }
  }, [selectedType])

  useEffect(() => {
    initGrid()
    animationRef.current = requestAnimationFrame(gameLoop)
    
    return () => {
      if (animationRef.current !== null) {
        cancelAnimationFrame(animationRef.current)
      }
    }
  }, [initGrid, gameLoop])

  return (
    <div className="flex flex-col gap-4">
      <div className="flex gap-2">
        <button 
          onClick={() => setSelectedType(ParticleType.Sand)}
          className={`px-4 py-2 rounded transition-colors ${
            selectedType === ParticleType.Sand 
              ? 'bg-yellow-600 text-white' 
              : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
          }`}
        >
          Sand
        </button>
        <button 
          onClick={() => setSelectedType(ParticleType.Water)}
          className={`px-4 py-2 rounded transition-colors ${
            selectedType === ParticleType.Water 
              ? 'bg-blue-600 text-white' 
              : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
          }`}
        >
          Water
        </button>
        <button 
          onClick={() => setSelectedType(ParticleType.Stone)}
          className={`px-4 py-2 rounded transition-colors ${
            selectedType === ParticleType.Stone 
              ? 'bg-gray-600 text-white' 
              : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
          }`}
        >
          Stone
        </button>
      </div>
      <canvas
        ref={canvasRef}
        width={DEFAULT_CONFIG.width}
        height={DEFAULT_CONFIG.height}
        style={{
          width: DEFAULT_CONFIG.width * DEFAULT_CONFIG.scale,
          height: DEFAULT_CONFIG.height * DEFAULT_CONFIG.scale,
          imageRendering: 'pixelated',
          cursor: 'crosshair',
          touchAction: 'none'
        }}
        className="border border-gray-600 bg-black rounded"
        onPointerDown={() => mouseDownRef.current = true}
        onPointerUp={() => mouseDownRef.current = false}
        onPointerLeave={() => mouseDownRef.current = false}
        onPointerMove={handlePointer}
      />
    </div>
  )
}
EOF

# ==============================================================================
# Zig Implementation (Vertical Sand Motion)
# ==============================================================================

cat > $BASE_DIR/components/falling-sand/zig/main.zig << 'EOF'
const WIDTH: u32 = 200;
const HEIGHT: u32 = 150;
const GRID_SIZE: u32 = WIDTH * HEIGHT;

var grid: [GRID_SIZE]u8 align(16) = [_]u8{0} ** GRID_SIZE;

export fn getGridPointer() [*]u8 {
    return &grid;
}

export fn getWidth() u32 {
    return WIDTH;
}

export fn getHeight() u32 {
    return HEIGHT;
}

export fn setParticle(x: u32, y: u32, particle_type: u8) void {
    if (x >= WIDTH or y >= HEIGHT) return;
    grid[y * WIDTH + x] = particle_type;
}

export fn step() void {
    var temp: [GRID_SIZE]u8 = grid;
    
    var y: i32 = @intCast(HEIGHT - 2);
    while (y >= 0) : (y -= 1) {
        var x: u32 = 0;
        while (x < WIDTH) : (x += 1) {
            const yu: u32 = @intCast(y);
            const idx = yu * WIDTH + x;
            const particle = grid[idx];
            
            if (particle == 1) { // Sand
                const below = (yu + 1) * WIDTH + x;
                if (below < GRID_SIZE and grid[below] == 0) {
                    temp[below] = particle;
                    temp[idx] = 0;
                }
            }
        }
    }
    
    grid = temp;
}
EOF

cat > $BASE_DIR/components/falling-sand/zig/ZigSimulation.tsx << 'EOF'
'use client'
import { useRef, useEffect, useState, useCallback } from 'react'
import { ParticleType, COLORS } from '../shared/types'

interface ZigWASM {
  memory: WebAssembly.Memory
  getGridPointer(): number
  getWidth(): number
  getHeight(): number
  setParticle(x: number, y: number, type: number): void
  step(): void
}

export default function ZigSimulation() {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const [wasm, setWasm] = useState<ZigWASM | null>(null)
  const [loadError, setLoadError] = useState(false)
  const animationRef = useRef<number | null>(null)
  const mouseDownRef = useRef(false)
  const [selectedType, setSelectedType] = useState(ParticleType.Sand)

  useEffect(() => {
    async function loadWasm() {
      try {
        const response = await fetch('/wasm/falling_sand.wasm')
        if (!response.ok) throw new Error(`WASM request failed: ${response.status}`)
        const bytes = await response.arrayBuffer()
        const { instance } = await WebAssembly.instantiate(bytes)
        setWasm(instance.exports as unknown as ZigWASM)
      } catch (error) {
        console.error('Failed to load Zig WASM:', error)
        setLoadError(true)
      }
    }
    
    loadWasm()
  }, [])

  const gameLoop = useCallback(() => {
    if (!wasm || !canvasRef.current) return
    
    const canvas = canvasRef.current
    const ctx = canvas.getContext('2d', { alpha: false })!
    
    wasm.step()
    
    const gridPtr = wasm.getGridPointer()
    const width = wasm.getWidth()
    const height = wasm.getHeight()
    const gridData = new Uint8Array(wasm.memory.buffer, gridPtr, width * height)
    
    const imageData = ctx.createImageData(width, height)
    const data32 = new Uint32Array(imageData.data.buffer)
    
    for (let i = 0; i < gridData.length; i++) {
      data32[i] = COLORS[gridData[i]] || 0xFF000000
    }
    
    ctx.putImageData(imageData, 0, 0)
    animationRef.current = requestAnimationFrame(gameLoop)
  }, [wasm])

  useEffect(() => {
    if (wasm) {
      animationRef.current = requestAnimationFrame(gameLoop)
    }
    
    return () => {
      if (animationRef.current !== null) {
        cancelAnimationFrame(animationRef.current)
      }
    }
  }, [wasm, gameLoop])

  const handlePointer = useCallback((e: React.PointerEvent) => {
    if (!mouseDownRef.current || !wasm) return
    
    const rect = canvasRef.current!.getBoundingClientRect()
    const scale = 4
    const x = Math.floor((e.clientX - rect.left) / scale)
    const y = Math.floor((e.clientY - rect.top) / scale)
    
    for (let dy = -1; dy <= 1; dy++) {
      for (let dx = -1; dx <= 1; dx++) {
        wasm.setParticle(x + dx, y + dy, selectedType)
      }
    }
  }, [wasm, selectedType])

  if (!wasm) {
    return (
      <div className="flex items-center justify-center h-[600px] text-gray-400">
        {loadError ? 'Zig simulation unavailable. Run npm run build:simulations with Zig installed.' : 'Loading Zig WASM...'}
      </div>
    )
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="flex gap-2">
        <button 
          onClick={() => setSelectedType(ParticleType.Sand)}
          className={`px-4 py-2 rounded transition-colors ${
            selectedType === ParticleType.Sand 
              ? 'bg-yellow-600 text-white' 
              : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
          }`}
        >
          Sand
        </button>
        <button 
          onClick={() => setSelectedType(ParticleType.Water)}
          className={`px-4 py-2 rounded transition-colors ${
            selectedType === ParticleType.Water 
              ? 'bg-blue-600 text-white' 
              : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
          }`}
        >
          Water
        </button>
        <button 
          onClick={() => setSelectedType(ParticleType.Stone)}
          className={`px-4 py-2 rounded transition-colors ${
            selectedType === ParticleType.Stone 
              ? 'bg-gray-600 text-white' 
              : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
          }`}
        >
          Stone
        </button>
      </div>
      <canvas
        ref={canvasRef}
        width={200}
        height={150}
        style={{
          width: 800,
          height: 600,
          imageRendering: 'pixelated',
          cursor: 'crosshair',
          touchAction: 'none'
        }}
        className="border border-gray-600 bg-black rounded"
        onPointerDown={() => mouseDownRef.current = true}
        onPointerUp={() => mouseDownRef.current = false}
        onPointerLeave={() => mouseDownRef.current = false}
        onPointerMove={handlePointer}
      />
    </div>
  )
}
EOF

# ==============================================================================
# WebGL Implementation
# ==============================================================================

cat > $BASE_DIR/components/falling-sand/webgl/WebGLSimulation.tsx << 'EOF'
'use client'
import { useRef, useEffect, useCallback, useState } from 'react'
import { ParticleType } from '../shared/types'

const vertexShader = `
attribute vec2 a_position;
void main() {
  gl_Position = vec4(a_position, 0.0, 1.0);
}
`

const fragmentShader = `
precision mediump float;
uniform sampler2D u_grid;
uniform vec2 u_resolution;

void main() {
  vec2 coord = gl_FragCoord.xy / u_resolution;
  coord.y = 1.0 - coord.y; // Flip Y
  float value = texture2D(u_grid, coord).r;
  
  vec3 color = vec3(0.0);
  if (value > 0.6) { // Sand
    color = vec3(0.79, 0.65, 0.41);
  } else if (value > 0.3 && value < 0.6) { // Water
    color = vec3(0.23, 0.51, 0.96);
  } else if (value > 0.1 && value < 0.3) { // Stone
    color = vec3(0.42, 0.45, 0.50);
  }
  
  gl_FragColor = vec4(color, 1.0);
}
`

export default function WebGLSimulation() {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const [selectedType, setSelectedType] = useState(ParticleType.Sand)
  const glRef = useRef<WebGLRenderingContext | null>(null)
  const gridRef = useRef<Float32Array | null>(null)
  const textureRef = useRef<WebGLTexture | null>(null)
  const mouseDownRef = useRef(false)
  const animationRef = useRef<number | null>(null)
  
  const initWebGL = useCallback(() => {
    const canvas = canvasRef.current
    if (!canvas) return false
    
    const gl = canvas.getContext('webgl', { alpha: false, antialias: false })
    if (!gl) return false
    if (!gl.getExtension('OES_texture_float')) {
      console.error('Floating-point WebGL textures are unavailable')
      return false
    }
    
    glRef.current = gl
    
    // Initialize grid
    gridRef.current = new Float32Array(200 * 150)
    
    // Create texture
    const texture = gl.createTexture()!
    gl.bindTexture(gl.TEXTURE_2D, texture)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    textureRef.current = texture
    
    // Compile shaders
    const vs = gl.createShader(gl.VERTEX_SHADER)!
    gl.shaderSource(vs, vertexShader)
    gl.compileShader(vs)
    
    const fs = gl.createShader(gl.FRAGMENT_SHADER)!
    gl.shaderSource(fs, fragmentShader)
    gl.compileShader(fs)
    
    const program = gl.createProgram()!
    gl.attachShader(program, vs)
    gl.attachShader(program, fs)
    gl.linkProgram(program)
    gl.useProgram(program)
    
    // Setup geometry
    const vertices = new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1])
    const buffer = gl.createBuffer()
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer)
    gl.bufferData(gl.ARRAY_BUFFER, vertices, gl.STATIC_DRAW)
    
    const posLoc = gl.getAttribLocation(program, 'a_position')
    gl.enableVertexAttribArray(posLoc)
    gl.vertexAttribPointer(posLoc, 2, gl.FLOAT, false, 0, 0)
    
    // Set uniforms
    const resLoc = gl.getUniformLocation(program, 'u_resolution')
    gl.uniform2f(resLoc, 200, 150)
    
    return true
  }, [])
  
  const updateSimulation = useCallback(() => {
    if (!gridRef.current) return
    
    const grid = gridRef.current
    const width = 200
    const height = 150
    const newGrid = new Float32Array(grid)
    
    // Simple falling sand physics
    for (let y = height - 2; y >= 0; y--) {
      for (let x = 0; x < width; x++) {
        const idx = y * width + x
        const value = grid[idx]
        
        if (value > 0.6) { // Sand
          const below = (y + 1) * width + x
          if (grid[below] < 0.01) {
            newGrid[below] = value
            newGrid[idx] = 0
          }
        } else if (value > 0.3 && value < 0.6) { // Water
          const below = (y + 1) * width + x
          if (grid[below] < 0.01) {
            newGrid[below] = value
            newGrid[idx] = 0
          } else {
            // Spread sideways
            if (x > 0 && grid[idx - 1] < 0.01 && Math.random() > 0.5) {
              newGrid[idx - 1] = value
              newGrid[idx] = 0
            } else if (x < width - 1 && grid[idx + 1] < 0.01) {
              newGrid[idx + 1] = value
              newGrid[idx] = 0
            }
          }
        }
      }
    }
    
    gridRef.current = newGrid
  }, [])
  
  const render = useCallback(() => {
    const gl = glRef.current
    if (!gl || !gridRef.current || !textureRef.current) return
    
    updateSimulation()
    
    // Update texture
    gl.bindTexture(gl.TEXTURE_2D, textureRef.current)
    gl.texImage2D(
      gl.TEXTURE_2D, 0, gl.LUMINANCE,
      200, 150, 0,
      gl.LUMINANCE, gl.FLOAT, gridRef.current
    )
    
    // Draw
    gl.viewport(0, 0, 200, 150)
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4)
    
    animationRef.current = requestAnimationFrame(render)
  }, [updateSimulation])
  
  const handlePointer = useCallback((e: React.PointerEvent) => {
    if (!mouseDownRef.current || !gridRef.current) return
    
    const rect = canvasRef.current!.getBoundingClientRect()
    const x = Math.floor((e.clientX - rect.left) / 4)
    const y = Math.floor((e.clientY - rect.top) / 4)
    
    if (x >= 0 && x < 200 && y >= 0 && y < 150) {
      const value = selectedType === ParticleType.Sand ? 0.8
                  : selectedType === ParticleType.Water ? 0.5
                  : selectedType === ParticleType.Stone ? 0.2 : 0
      
      // Draw 3x3 area
      for (let dy = -1; dy <= 1; dy++) {
        for (let dx = -1; dx <= 1; dx++) {
          const px = x + dx
          const py = y + dy
          if (px >= 0 && px < 200 && py >= 0 && py < 150) {
            gridRef.current[py * 200 + px] = value
          }
        }
      }
    }
  }, [selectedType])
  
  useEffect(() => {
    if (initWebGL()) {
      animationRef.current = requestAnimationFrame(render)
    }
    
    return () => {
      if (animationRef.current !== null) {
        cancelAnimationFrame(animationRef.current)
      }
    }
  }, [initWebGL, render])
  
  return (
    <div className="flex flex-col gap-4">
      <div className="flex gap-2">
        <button 
          onClick={() => setSelectedType(ParticleType.Sand)}
          className={`px-4 py-2 rounded transition-colors ${
            selectedType === ParticleType.Sand 
              ? 'bg-yellow-600 text-white' 
              : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
          }`}
        >
          Sand
        </button>
        <button 
          onClick={() => setSelectedType(ParticleType.Water)}
          className={`px-4 py-2 rounded transition-colors ${
            selectedType === ParticleType.Water 
              ? 'bg-blue-600 text-white' 
              : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
          }`}
        >
          Water
        </button>
        <button 
          onClick={() => setSelectedType(ParticleType.Stone)}
          className={`px-4 py-2 rounded transition-colors ${
            selectedType === ParticleType.Stone 
              ? 'bg-gray-600 text-white' 
              : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
          }`}
        >
          Stone
        </button>
      </div>
      <canvas
        ref={canvasRef}
        width={200}
        height={150}
        style={{
          width: 800,
          height: 600,
          imageRendering: 'pixelated',
          cursor: 'crosshair',
          touchAction: 'none'
        }}
        className="border border-gray-600 bg-black rounded"
        onPointerDown={() => mouseDownRef.current = true}
        onPointerUp={() => mouseDownRef.current = false}
        onPointerLeave={() => mouseDownRef.current = false}
        onPointerMove={handlePointer}
      />
    </div>
  )
}
EOF

# ==============================================================================
# Main Next.js Page Component (Dark Mode, No Fake Stats)
# ==============================================================================

cat > $BASE_DIR/app/falling-sand/page.tsx << 'EOF'
'use client'
import dynamic from 'next/dynamic'
import { Suspense } from 'react'

const CanvasSimulation = dynamic(
  () => import('@/components/falling-sand/typescript/CanvasSimulation'),
  { ssr: false, loading: () => <SimulationSkeleton /> }
)

const ZigSimulation = dynamic(
  () => import('@/components/falling-sand/zig/ZigSimulation'),
  { ssr: false, loading: () => <SimulationSkeleton /> }
)

const WebGLSimulation = dynamic(
  () => import('@/components/falling-sand/webgl/WebGLSimulation'),
  { ssr: false, loading: () => <SimulationSkeleton /> }
)

function SimulationSkeleton() {
  return (
    <div className="w-[800px] h-[600px] bg-gray-900 animate-pulse rounded" />
  )
}

export default function FallingSandPage() {
  return (
    <div className="min-h-screen p-8 bg-gray-950 text-white">
      <h1 className="text-4xl font-bold mb-8 text-center text-gray-100">
        Falling Sand Simulation
      </h1>
      
      <div className="max-w-7xl mx-auto grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div className="bg-gray-900 rounded-lg shadow-xl p-6 border border-gray-800">
          <h2 className="text-2xl font-semibold mb-4 text-blue-400">
            TypeScript Canvas
          </h2>
          <div className="mb-4 space-y-2 text-sm text-gray-400">
            <p>• Direct canvas manipulation</p>
            <p>• Immediate mode rendering</p>
            <p>• CPU-based physics</p>
          </div>
          <Suspense fallback={<SimulationSkeleton />}>
            <CanvasSimulation />
          </Suspense>
        </div>
        
        <div className="bg-gray-900 rounded-lg shadow-xl p-6 border border-gray-800">
          <h2 className="text-2xl font-semibold mb-4 text-orange-400">
            Zig WASM
          </h2>
          <div className="mb-4 space-y-2 text-sm text-gray-400">
            <p>• Compiled to WebAssembly</p>
            <p>• Fixed-size particle grid</p>
            <p>• Vertical sand motion</p>
          </div>
          <Suspense fallback={<SimulationSkeleton />}>
            <ZigSimulation />
          </Suspense>
        </div>
        
        <div className="bg-gray-900 rounded-lg shadow-xl p-6 border border-gray-800">
          <h2 className="text-2xl font-semibold mb-4 text-green-400">
            WebGL GPU
          </h2>
          <div className="mb-4 space-y-2 text-sm text-gray-400">
            <p>• GPU-accelerated rendering</p>
            <p>• Shader-based processing</p>
            <p>• Texture-based storage</p>
          </div>
          <Suspense fallback={<SimulationSkeleton />}>
            <WebGLSimulation />
          </Suspense>
        </div>
      </div>
      
      <div className="max-w-4xl mx-auto mt-12 bg-gray-900 rounded-lg shadow-xl p-8 border border-gray-800">
        <h2 className="text-2xl font-bold mb-4 text-gray-100">How to Use</h2>
        <div className="space-y-2 text-gray-300">
          <p>• Click and drag to draw particles</p>
          <p>• Sand falls and forms piles</p>
          <p>• Water flows and spreads</p>
          <p>• Stone creates barriers</p>
        </div>
      </div>
    </div>
  )
}
EOF

# ==============================================================================
# Build Script
# ==============================================================================

cat > build-simulations.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

if [ -d "src/app" ]; then
    ZIG_DIR="src/components/falling-sand/zig"
else
    ZIG_DIR="components/falling-sand/zig"
fi

if ! command -v zig >/dev/null 2>&1; then
    echo "Zig is unavailable; Canvas and WebGL can run without the Zig demo."
    echo "Install Zig, then run npm run build:simulations."
    exit 0
fi

mkdir -p public/wasm
zig build-exe "$ZIG_DIR/main.zig" \
  -target wasm32-freestanding \
  -O ReleaseSmall \
  -fno-entry \
  --export=getGridPointer \
  --export=getWidth \
  --export=getHeight \
  --export=setParticle \
  --export=step \
  --export-memory \
  -femit-bin=public/wasm/falling_sand.wasm

echo "Built public/wasm/falling_sand.wasm"
EOF

chmod +x build-simulations.sh

# ==============================================================================
# Update package.json
# ==============================================================================

node --input-type=commonjs << 'EOF'
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
if (!pkg.scripts) pkg.scripts = {};
pkg.scripts['build:simulations'] = './build-simulations.sh';
pkg.scripts['dev:sand'] = 'npm run build:simulations && next dev';
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
console.log('✅ package.json updated');
EOF

# ==============================================================================
# Initial build
# ==============================================================================

echo "🏗️ Running initial build..."
./build-simulations.sh

echo ""
echo "🎉 Falling Sand Scaffold Complete!"
echo ""
echo "Features:"
echo "  Canvas: sand and water motion, with stationary stone"
echo "  Zig: vertical sand motion; water and stone stay fixed"
echo "  WebGL: simple sand and water motion, with stationary stone"
echo "  Touch and mouse drawing"
echo "  These are experimental particle rules, ready for further development."
echo ""
echo "Quick Start:"
echo "  npm run dev:sand"
echo "  Visit: http://localhost:3000/falling-sand"
echo ""
echo "Build Zig WASM with npm run build:simulations when Zig is installed."
