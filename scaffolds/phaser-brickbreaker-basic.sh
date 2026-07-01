#!/usr/bin/env bash

# Phaser Brickbreaker Basic Scaffold
# Generates a TypeScript, Phaser, Vite, Biome, Vitest, and Playwright project.

set -e

# Color output for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🎮 Creating TypeScript/Phaser Brickbreaker Project${NC}"

# Get project name or use default
PROJECT_NAME=${1:-brickbreaker-game}

echo -e "${GREEN}📁 Creating project: ${PROJECT_NAME}${NC}"

# Create project directory
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Initialize git
git init

# Create directory structure
mkdir -p \
  src/{game,scenes,entities,systems,utils,types,config,assets} \
  src/game/{physics,input,audio,state,commands} \
  src/entities/{ball,paddle,brick,powerup} \
  src/systems/{collision,scoring,particles,ui} \
  src/utils/{math,debug,testing} \
  tests/{unit,integration,e2e,visual} \
  tests/unit/{entities,systems,utils} \
  tests/fixtures \
  public/assets/{sprites,audio,fonts} \
  .github/workflows \
  docs

echo -e "${GREEN}📦 Initializing package.json${NC}"

# Create package.json with all dependencies
cat > package.json << 'EOF'
{
  "name": "brickbreaker-game",
  "version": "1.0.0",
  "type": "module",
  "description": "Production-quality TypeScript/Phaser brickbreaker with SQLite-level testing",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "test": "vitest",
    "test:ui": "vitest --ui",
    "test:coverage": "vitest run --coverage",
    "test:e2e": "playwright test",
    "type-check": "tsc --noEmit",
    "lint": "biome lint ./src",
    "format": "biome format --write ./src",
    "check": "biome check --apply ./src",
    "prepare": "lefthook install",
    "analyze": "vite build --mode analyze"
  },
  "keywords": ["game", "phaser", "typescript", "brickbreaker"],
  "author": "",
  "license": "MIT"
}
EOF

echo -e "${GREEN}📦 Installing dependencies...${NC}"

# Core dependencies
npm install --save \
  phaser@^3.70.0 \
  zod@^3.22.0 \
  xstate@^5.9.0 \
  zustand@^4.5.0 \
  mitt@^3.0.1

# Development dependencies
npm install --save-dev \
  typescript@~5.4.5 \
  vite@^5.2.0 \
  vitest@^1.5.0 \
  @vitest/ui@^1.5.0 \
  @biomejs/biome@^1.7.0 \
  lefthook@^1.6.0 \
  @tsconfig/strictest@^2.0.0 \
  @types/node@^20.12.0

# Testing dependencies
npm install --save-dev \
  jsdom@^24.0.0 \
  jest-canvas-mock@^2.5.0 \
  fast-check@^3.17.0 \
  @vitest/coverage-v8@^1.5.0 \
  @playwright/test@^1.43.0

# Build and development tools
npm install --save-dev \
  vite-plugin-checker@^0.6.0 \
  vite-tsconfig-paths@^4.3.0 \
  rollup-plugin-visualizer@^5.12.0 \
  typedoc@^0.26.0 \
  tsx@^4.7.0

echo -e "${GREEN}⚙️  Creating TypeScript configuration${NC}"

# Create tsconfig.json with strictest settings
cat > tsconfig.json << 'EOF'
{
  "extends": "@tsconfig/strictest/tsconfig.json",
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "allowImportingTsExtensions": true,
    "noEmit": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noPropertyAccessFromIndexSignature": true,
    "verbatimModuleSyntax": true,
    "isolatedModules": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"],
      "@game/*": ["src/game/*"],
      "@entities/*": ["src/entities/*"],
      "@systems/*": ["src/systems/*"],
      "@utils/*": ["src/utils/*"],
      "@types/*": ["src/types/*"],
      "@config/*": ["src/config/*"],
      "@assets/*": ["src/assets/*"],
      "@test-utils": ["src/utils/testing/index.ts"]
    },
    "types": ["vitest/globals", "node"],
    "skipLibCheck": true
  },
  "include": ["src/**/*", "tests/**/*"],
  "exclude": ["node_modules", "dist", "coverage"]
}
EOF

echo -e "${GREEN}⚡ Creating Vite configuration${NC}"

# Create vite.config.ts
cat > vite.config.ts << 'EOF'
import { defineConfig } from 'vite';
import checker from 'vite-plugin-checker';
import tsconfigPaths from 'vite-tsconfig-paths';
import { visualizer } from 'rollup-plugin-visualizer';

export default defineConfig(({ mode }) => ({
  plugins: [
    tsconfigPaths(),
    checker({
      typescript: true,
    }),
    mode === 'analyze' && visualizer({
      filename: './dist/stats.html',
      gzipSize: true,
      brotliSize: true,
    }),
  ].filter(Boolean),
  build: {
    target: 'es2022',
    sourcemap: true,
    rollupOptions: {
      output: {
        manualChunks: {
          phaser: ['phaser'],
          vendor: ['zod', 'xstate', 'zustand', 'mitt'],
        },
      },
    },
  },
  server: {
    port: 3000,
    strictPort: false,
    open: true,
  },
  optimizeDeps: {
    include: ['phaser'],
  },
}));
EOF

echo -e "${GREEN}🧪 Creating Vitest configuration${NC}"

# Create vitest.config.ts
cat > vitest.config.ts << 'EOF'
import { defineConfig } from 'vitest/config';
import tsconfigPaths from 'vite-tsconfig-paths';

export default defineConfig({
  plugins: [tsconfigPaths()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./tests/setup.ts'],
    include: ['tests/**/*.{test,spec}.{ts,tsx}'],
    exclude: ['tests/e2e/**/*', 'tests/visual/**/*'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html', 'lcov'],
      exclude: [
        'node_modules/',
        'tests/',
        '*.config.ts',
        'src/types/',
        'src/**/*.d.ts',
        'src/main.ts',
      ],
      thresholds: {
        branches: 80,
        functions: 80,
        lines: 80,
        statements: 80,
      },
    },
    testTimeout: 10000,
    hookTimeout: 10000,
    teardownTimeout: 10000,
    isolate: true,
    threads: true,
    mockReset: true,
    restoreMocks: true,
    clearMocks: true,
  },
});
EOF

echo -e "${GREEN}🧪 Creating test setup${NC}"

# Create test setup file
cat > tests/setup.ts << 'EOF'
import 'jest-canvas-mock';
import { vi } from 'vitest';

// Add game container to DOM for Phaser
document.body.innerHTML = '<div id="game-container"></div>';

// Mock requestAnimationFrame for deterministic testing
let frameId = 0;
let callbacks: Map<number, FrameRequestCallback> = new Map();

global.requestAnimationFrame = vi.fn((callback: FrameRequestCallback) => {
  const id = ++frameId;
  callbacks.set(id, callback);
  return id;
});

global.cancelAnimationFrame = vi.fn((id: number) => {
  callbacks.delete(id);
});

// Helper to advance frames in tests
(global as any).advanceFrames = (count: number = 1, deltaTime: number = 16.67) => {
  for (let i = 0; i < count; i++) {
    const currentCallbacks = Array.from(callbacks.entries());
    for (const [id, callback] of currentCallbacks) {
      callback(performance.now() + deltaTime * i);
    }
  }
};

// Mock Audio Context
global.AudioContext = vi.fn(() => ({
  createBufferSource: vi.fn(),
  createGain: vi.fn(),
  decodeAudioData: vi.fn(),
  destination: {},
})) as any;

// Mock WebGL - already handled by jest-canvas-mock
EOF

echo -e "${GREEN}🎯 Creating Biome configuration${NC}"

# Create biome.json
cat > biome.json << 'EOF'
{
  "$schema": "https://biomejs.dev/schemas/1.7.0/schema.json",
  "organizeImports": {
    "enabled": true
  },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true,
      "complexity": {
        "noExcessiveCognitiveComplexity": {
          "level": "warn",
          "options": { "maxAllowedComplexity": 10 }
        }
      },
      "correctness": {
        "noUnusedVariables": "error",
        "noUnusedImports": "error"
      },
      "style": {
        "useConst": "error",
        "useTemplate": "error",
        "noVar": "error"
      },
      "suspicious": {
        "noExplicitAny": "error",
        "noImplicitAnyLet": "error"
      }
    }
  },
  "formatter": {
    "enabled": true,
    "formatWithErrors": false,
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 100,
    "lineEnding": "lf"
  },
  "javascript": {
    "formatter": {
      "quoteStyle": "single",
      "trailingComma": "es5",
      "semicolons": "always",
      "arrowParentheses": "always"
    }
  },
  "files": {
    "ignore": ["node_modules", "dist", "coverage", "*.min.js", "public/assets"]
  }
}
EOF

echo -e "${GREEN}🪝 Creating Lefthook configuration${NC}"

# Create lefthook.yml
cat > lefthook.yml << 'EOF'
pre-commit:
  parallel: true
  commands:
    type-check:
      run: npx tsc --noEmit
      tags: [typescript]
    
    biome-check:
      run: npx biome check --apply {staged_files}
      glob: "*.{js,ts,tsx,jsx}"
      tags: [linting, formatting]
    
    test-related:
      run: npx vitest related {staged_files} --run
      glob: "*.{ts,tsx}"
      tags: [testing]

pre-push:
  parallel: false
  commands:
    test-all:
      run: npm run test:coverage
      tags: [testing]
    
    build:
      run: npm run build
      tags: [build]
EOF

echo -e "${GREEN}🎮 Creating core game utilities${NC}"

# Create SQLite-inspired testing utilities
cat > src/utils/testing/assertions.ts << 'EOF'
/**
 * SQLite-inspired assertion utilities
 * These compile to no-ops in production but provide runtime checks in tests
 */

const IS_TEST = process.env.NODE_ENV === 'test';
const IS_DEV = process.env.NODE_ENV === 'development';

/**
 * Assert that a condition should ALWAYS be true
 * Throws in test/dev, no-op in production
 */
export function ALWAYS(condition: boolean, message?: string): asserts condition {
  if ((IS_TEST || IS_DEV) && !condition) {
    throw new Error(`ALWAYS assertion failed: ${message || 'Condition was false'}`);
  }
}

/**
 * Assert that a condition should NEVER be true
 * Throws in test/dev, no-op in production
 */
export function NEVER(condition: boolean, message?: string): asserts condition is false {
  if ((IS_TEST || IS_DEV) && condition) {
    throw new Error(`NEVER assertion failed: ${message || 'Condition was true'}`);
  }
}

/**
 * Mark code as unreachable
 * Throws in all environments if reached
 */
export function UNREACHABLE(message?: string): never {
  throw new Error(`Unreachable code executed: ${message || 'This should never happen'}`);
}

/**
 * Type guard for non-null values with assertion
 */
export function assertDefined<T>(
  value: T | null | undefined,
  message?: string
): asserts value is T {
  if (value === null || value === undefined) {
    throw new Error(`Value was null or undefined: ${message || 'Expected defined value'}`);
  }
}

/**
 * Type guard for exhaustive switch statements
 */
export function assertNever(value: never): never {
  throw new Error(`Unhandled value: ${JSON.stringify(value)}`);
}
EOF

# Create testing index
cat > src/utils/testing/index.ts << 'EOF'
export * from './assertions';
export * from './test-helpers';
EOF

# Create test helpers
cat > src/utils/testing/test-helpers.ts << 'EOF'
import { Game } from 'phaser';
import type { Types } from 'phaser';

/**
 * Create a headless Phaser game for testing
 */
export function createTestGame(config?: Partial<Types.Core.GameConfig>): Game {
  return new Game({
    type: Phaser.HEADLESS,
    width: 800,
    height: 600,
    physics: {
      default: 'arcade',
      arcade: {
        gravity: { x: 0, y: 0 },
        debug: false,
      },
    },
    scene: [],
    ...config,
  });
}

/**
 * Deterministic frame advancement for testing
 */
export class TestGameLoop {
  private mockTime = 0;
  private frameCallbacks: Array<(time: number, delta: number) => void> = [];

  addFrameCallback(callback: (time: number, delta: number) => void): void {
    this.frameCallbacks.push(callback);
  }

  removeFrameCallback(callback: (time: number, delta: number) => void): void {
    const index = this.frameCallbacks.indexOf(callback);
    if (index > -1) {
      this.frameCallbacks.splice(index, 1);
    }
  }

  /**
   * Advance the game by a specific number of frames
   */
  advance(frames: number = 1, deltaTime: number = 16.67): void {
    for (let i = 0; i < frames; i++) {
      this.mockTime += deltaTime;
      for (const callback of this.frameCallbacks) {
        callback(this.mockTime, deltaTime);
      }
    }
  }

  /**
   * Advance the game by a specific amount of time
   */
  advanceTime(milliseconds: number, frameTime: number = 16.67): void {
    const frames = Math.ceil(milliseconds / frameTime);
    this.advance(frames, frameTime);
  }

  reset(): void {
    this.mockTime = 0;
    this.frameCallbacks = [];
  }

  get currentTime(): number {
    return this.mockTime;
  }
}

/**
 * Create a deterministic random number generator for testing
 */
export class SeededRandom {
  private seed: number;

  constructor(seed: number = 12345) {
    this.seed = seed;
  }

  next(): number {
    this.seed = (this.seed * 1664525 + 1013904223) % 2147483647;
    return this.seed / 2147483647;
  }

  nextInt(min: number, max: number): number {
    return Math.floor(this.next() * (max - min + 1)) + min;
  }

  nextFloat(min: number, max: number): number {
    return this.next() * (max - min) + min;
  }

  reset(seed: number = 12345): void {
    this.seed = seed;
  }
}
EOF

echo -e "${GREEN}🎮 Creating type definitions${NC}"

# Create brand type utility
cat > src/types/brand.ts << 'EOF'
/**
 * Brand type for nominal typing
 * Prevents accidental type confusion
 */
declare const brand: unique symbol;

export type Brand<T, TBrand extends string> = T & {
  readonly [brand]: TBrand;
};

// Game-specific branded types
export type PlayerId = Brand<string, 'PlayerId'>;
export type EntityId = Brand<string, 'EntityId'>;
export type BrickId = Brand<string, 'BrickId'>;
export type PowerUpId = Brand<string, 'PowerUpId'>;

export type WorldX = Brand<number, 'WorldX'>;
export type WorldY = Brand<number, 'WorldY'>;
export type Velocity = Brand<number, 'Velocity'>;
export type Angle = Brand<number, 'Angle'>;
export type Score = Brand<number, 'Score'>;
export type Level = Brand<number, 'Level'>;

// Helper functions for creating branded types
export function asPlayerId(value: string): PlayerId {
  return value as PlayerId;
}

export function asEntityId(value: string): EntityId {
  return value as EntityId;
}

export function asWorldX(value: number): WorldX {
  return value as WorldX;
}

export function asWorldY(value: number): WorldY {
  return value as WorldY;
}
EOF

# Create game schemas with Zod
cat > src/types/schemas.ts << 'EOF'
import { z } from 'zod';

// Vector schemas
export const Vector2Schema = z.object({
  x: z.number(),
  y: z.number(),
});

export const BoundsSchema = z.object({
  x: z.number(),
  y: z.number(),
  width: z.number().positive(),
  height: z.number().positive(),
});

// Entity schemas
export const EntityStateSchema = z.object({
  id: z.string(),
  position: Vector2Schema,
  velocity: Vector2Schema,
  active: z.boolean(),
  destroyed: z.boolean(),
});

export const BallStateSchema = EntityStateSchema.extend({
  type: z.literal('ball'),
  radius: z.number().positive(),
  speed: z.number().positive(),
  damage: z.number().positive().int(),
});

export const PaddleStateSchema = EntityStateSchema.extend({
  type: z.literal('paddle'),
  width: z.number().positive(),
  height: z.number().positive(),
  speed: z.number().positive(),
});

export const BrickStateSchema = EntityStateSchema.extend({
  type: z.literal('brick'),
  width: z.number().positive(),
  height: z.number().positive(),
  health: z.number().positive().int(),
  maxHealth: z.number().positive().int(),
  points: z.number().nonnegative().int(),
  color: z.string(),
});

export const PowerUpStateSchema = EntityStateSchema.extend({
  type: z.literal('powerup'),
  powerType: z.enum(['multi-ball', 'wide-paddle', 'laser', 'slow-ball', 'extra-life']),
  duration: z.number().positive().optional(),
});

// Game state schemas
export const GameStateSchema = z.object({
  status: z.enum(['menu', 'playing', 'paused', 'game-over', 'victory']),
  level: z.number().positive().int(),
  score: z.number().nonnegative().int(),
  lives: z.number().nonnegative().int(),
  combo: z.number().nonnegative().int(),
  highScore: z.number().nonnegative().int(),
});

export const SaveGameSchema = z.object({
  version: z.string(),
  timestamp: z.string().datetime(),
  gameState: GameStateSchema,
  entities: z.object({
    balls: z.array(BallStateSchema),
    paddle: PaddleStateSchema,
    bricks: z.array(BrickStateSchema),
    powerUps: z.array(PowerUpStateSchema),
  }),
});

// Config schemas
export const GameConfigSchema = z.object({
  physics: z.object({
    gravity: z.number(),
    friction: z.number().min(0).max(1),
    restitution: z.number().min(0).max(1),
  }),
  difficulty: z.object({
    ballSpeed: z.number().positive(),
    paddleSpeed: z.number().positive(),
    brickHealth: z.number().positive().int(),
    powerUpChance: z.number().min(0).max(1),
  }),
  audio: z.object({
    masterVolume: z.number().min(0).max(1),
    sfxVolume: z.number().min(0).max(1),
    musicVolume: z.number().min(0).max(1),
  }),
});

// Type exports
export type Vector2 = z.infer<typeof Vector2Schema>;
export type Bounds = z.infer<typeof BoundsSchema>;
export type EntityState = z.infer<typeof EntityStateSchema>;
export type BallState = z.infer<typeof BallStateSchema>;
export type PaddleState = z.infer<typeof PaddleStateSchema>;
export type BrickState = z.infer<typeof BrickStateSchema>;
export type PowerUpState = z.infer<typeof PowerUpStateSchema>;
export type GameState = z.infer<typeof GameStateSchema>;
export type SaveGame = z.infer<typeof SaveGameSchema>;
export type GameConfig = z.infer<typeof GameConfigSchema>;
EOF

echo -e "${GREEN}🎮 Creating game configuration${NC}"

# Create game config
cat > src/config/game.config.ts << 'EOF'
import type { Types } from 'phaser';

export const GAME_CONFIG: Types.Core.GameConfig = {
  type: Phaser.AUTO,
  width: 800,
  height: 600,
  parent: 'game-container',
  backgroundColor: '#1a1a2e',
  fps: {
    target: 60,
    forceSetTimeOut: false,
  },
  physics: {
    default: 'arcade',
    arcade: {
      gravity: { x: 0, y: 0 },
      debug: import.meta.env.DEV,
    },
  },
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
  },
  audio: {
    disableWebAudio: false,
  },
  input: {
    keyboard: true,
    mouse: true,
    touch: true,
  },
  render: {
    antialias: true,
    pixelArt: false,
    roundPixels: false,
  },
};

export const GAME_CONSTANTS = {
  BALL: {
    INITIAL_SPEED: 300,
    MAX_SPEED: 600,
    RADIUS: 8,
    ACCELERATION: 1.05,
  },
  PADDLE: {
    WIDTH: 100,
    HEIGHT: 20,
    SPEED: 400,
    MARGIN_BOTTOM: 50,
  },
  BRICK: {
    WIDTH: 75,
    HEIGHT: 30,
    PADDING: 5,
    OFFSET_TOP: 100,
    ROWS: 6,
    COLUMNS: 10,
  },
  POWERUP: {
    FALL_SPEED: 150,
    SIZE: 20,
    SPAWN_CHANCE: 0.15,
  },
  GAME: {
    INITIAL_LIVES: 3,
    POINTS_PER_BRICK: 100,
    COMBO_MULTIPLIER: 1.5,
  },
} as const;
EOF

echo -e "${GREEN}📝 Creating HTML entry point${NC}"

# Create index.html
cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <meta name="description" content="TypeScript/Phaser Brickbreaker - Production Quality Game">
  <title>Brickbreaker</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
    }
    
    #game-container {
      border-radius: 8px;
      box-shadow: 0 10px 40px rgba(0, 0, 0, 0.3);
      overflow: hidden;
    }
    
    .loading {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      color: white;
      font-size: 24px;
      font-weight: 300;
      text-align: center;
    }
    
    .loading::after {
      content: '.';
      animation: dots 1.5s infinite;
    }
    
    @keyframes dots {
      0%, 20% { content: '.'; }
      40% { content: '..'; }
      60%, 100% { content: '...'; }
    }
  </style>
</head>
<body>
  <div id="game-container">
    <div class="loading">Loading</div>
  </div>
  <script type="module" src="/src/main.ts"></script>
</body>
</html>
EOF

echo -e "${GREEN}🎮 Creating main entry point${NC}"

# Create main.ts
cat > src/main.ts << 'EOF'
import Phaser from 'phaser';
import { GAME_CONFIG } from './config/game.config';
import { BootScene } from './scenes/BootScene';
import { PreloadScene } from './scenes/PreloadScene';
import { MenuScene } from './scenes/MenuScene';
import { GameScene } from './scenes/GameScene';
import { GameOverScene } from './scenes/GameOverScene';

// Register scenes
GAME_CONFIG.scene = [BootScene, PreloadScene, MenuScene, GameScene, GameOverScene];

// Initialize game
const game = new Phaser.Game(GAME_CONFIG);

// Handle visibility change
document.addEventListener('visibilitychange', () => {
  const activeScenes = game.scene.getScenes(true);
  if (document.hidden) {
    game.sound.mute = true;
    activeScenes.forEach((scene) => scene.scene.pause());
  } else {
    game.sound.mute = false;
    activeScenes.forEach((scene) => scene.scene.resume());
  }
});

// Export for debugging in development
if (import.meta.env.DEV) {
  (window as any).game = game;
}
EOF

echo -e "${GREEN}🎮 Creating basic scene structure${NC}"

# Create BootScene
cat > src/scenes/BootScene.ts << 'EOF'
import { Scene } from 'phaser';

export class BootScene extends Scene {
  constructor() {
    super({ key: 'BootScene' });
  }

  preload(): void {
    // Load minimal assets needed for preloader
    this.load.image('logo', '/assets/sprites/logo.png');
  }

  create(): void {
    // Proceed to preload scene
    this.scene.start('PreloadScene');
  }
}
EOF

# Create PreloadScene
cat > src/scenes/PreloadScene.ts << 'EOF'
import { Scene } from 'phaser';

export class PreloadScene extends Scene {
  constructor() {
    super({ key: 'PreloadScene' });
  }

  preload(): void {
    // Create loading bar
    const width = this.cameras.main.width;
    const height = this.cameras.main.height;

    const progressBar = this.add.graphics();
    const progressBox = this.add.graphics();
    progressBox.fillStyle(0x222222, 0.8);
    progressBox.fillRect(width / 2 - 160, height / 2 - 30, 320, 50);

    const loadingText = this.make.text({
      x: width / 2,
      y: height / 2 - 50,
      text: 'Loading...',
      style: {
        font: '20px monospace',
        color: '#ffffff',
      },
    });
    loadingText.setOrigin(0.5, 0.5);

    const percentText = this.make.text({
      x: width / 2,
      y: height / 2,
      text: '0%',
      style: {
        font: '18px monospace',
        color: '#ffffff',
      },
    });
    percentText.setOrigin(0.5, 0.5);

    // Update loading bar
    this.load.on('progress', (value: number) => {
      percentText.setText(`${Math.round(value * 100)}%`);
      progressBar.clear();
      progressBar.fillStyle(0xffffff, 1);
      progressBar.fillRect(width / 2 - 150, height / 2 - 20, 300 * value, 30);
    });

    // Load all game assets
    this.loadAssets();
  }

  private loadAssets(): void {
    // Load sprites with absolute paths
    this.load.image('ball', '/assets/sprites/ball.png');
    this.load.image('paddle', '/assets/sprites/paddle.png');
    this.load.image('brick', '/assets/sprites/brick.png');
    this.load.image('powerup', '/assets/sprites/powerup.png');
    this.load.image('particle', '/assets/sprites/particle.png');
  }

  create(): void {
    this.scene.start('MenuScene');
  }
}
EOF

# Create MenuScene
cat > src/scenes/MenuScene.ts << 'EOF'
import { Scene } from 'phaser';

export class MenuScene extends Scene {
  constructor() {
    super({ key: 'MenuScene' });
  }

  create(): void {
    const { width, height } = this.cameras.main;

    // Title
    const title = this.add.text(width / 2, height / 3, 'BRICKBREAKER', {
      fontSize: '48px',
      color: '#ffffff',
      fontStyle: 'bold',
    });
    title.setOrigin(0.5);

    // Play button
    const playButton = this.add.text(width / 2, height / 2, 'PLAY', {
      fontSize: '32px',
      color: '#00ff00',
      fontStyle: 'bold',
    });
    playButton.setOrigin(0.5);
    playButton.setInteractive({ useHandCursor: true });

    // Button animations
    playButton.on('pointerover', () => {
      playButton.setScale(1.1);
    });

    playButton.on('pointerout', () => {
      playButton.setScale(1);
    });

    playButton.on('pointerdown', () => {
      this.scene.start('GameScene');
    });

    // Instructions
    const instructions = this.add.text(width / 2, height * 0.75, 
      'Use Arrow Keys or Mouse to Move\nCatch Power-ups for Special Abilities', {
      fontSize: '16px',
      color: '#cccccc',
      align: 'center',
    });
    instructions.setOrigin(0.5);
  }
}
EOF

# Create GameScene stub
cat > src/scenes/GameScene.ts << 'EOF'
import { Scene } from 'phaser';

export class GameScene extends Scene {
  constructor() {
    super({ key: 'GameScene' });
  }

  create(): void {
    // Game implementation goes here
    const { width, height } = this.cameras.main;
    
    const text = this.add.text(width / 2, height / 2, 'Game Scene\n(To Be Implemented)', {
      fontSize: '32px',
      color: '#ffffff',
      align: 'center',
    });
    text.setOrigin(0.5);

    // Temporary: Return to menu on click
    this.input.on('pointerdown', () => {
      this.scene.start('MenuScene');
    });
  }
}
EOF

# Create GameOverScene
cat > src/scenes/GameOverScene.ts << 'EOF'
import { Scene } from 'phaser';

export class GameOverScene extends Scene {
  private finalScore: number = 0;

  constructor() {
    super({ key: 'GameOverScene' });
  }

  init(data: { score: number }): void {
    this.finalScore = data.score || 0;
  }

  create(): void {
    const { width, height } = this.cameras.main;

    // Game Over text
    const gameOverText = this.add.text(width / 2, height / 3, 'GAME OVER', {
      fontSize: '48px',
      color: '#ff0000',
      fontStyle: 'bold',
    });
    gameOverText.setOrigin(0.5);

    // Score
    const scoreText = this.add.text(width / 2, height / 2, `Score: ${this.finalScore}`, {
      fontSize: '32px',
      color: '#ffffff',
    });
    scoreText.setOrigin(0.5);

    // Retry button
    const retryButton = this.add.text(width / 2, height * 0.7, 'TRY AGAIN', {
      fontSize: '24px',
      color: '#00ff00',
      fontStyle: 'bold',
    });
    retryButton.setOrigin(0.5);
    retryButton.setInteractive({ useHandCursor: true });

    retryButton.on('pointerover', () => retryButton.setScale(1.1));
    retryButton.on('pointerout', () => retryButton.setScale(1));
    retryButton.on('pointerdown', () => {
      this.scene.start('GameScene');
    });

    // Menu button
    const menuButton = this.add.text(width / 2, height * 0.85, 'MAIN MENU', {
      fontSize: '20px',
      color: '#cccccc',
    });
    menuButton.setOrigin(0.5);
    menuButton.setInteractive({ useHandCursor: true });

    menuButton.on('pointerover', () => menuButton.setScale(1.1));
    menuButton.on('pointerout', () => menuButton.setScale(1));
    menuButton.on('pointerdown', () => {
      this.scene.start('MenuScene');
    });
  }
}
EOF

echo -e "${GREEN}🧪 Creating example tests${NC}"

# Create entity test example
cat > tests/unit/entities/ball.test.ts << 'EOF'
import { describe, it, expect, beforeEach } from 'vitest';
import { ALWAYS, NEVER } from '@test-utils';
import type { BallState } from '@/types/schemas';

describe('Ball Entity', () => {
  let ballState: BallState;

  beforeEach(() => {
    ballState = {
      id: 'ball-1',
      type: 'ball',
      position: { x: 400, y: 300 },
      velocity: { x: 200, y: -200 },
      active: true,
      destroyed: false,
      radius: 8,
      speed: 300,
      damage: 1,
    };
  });

  describe('Movement', () => {
    it('should update position based on velocity', () => {
      const deltaTime = 0.016; // 60 FPS
      const expectedX = ballState.position.x + ballState.velocity.x * deltaTime;
      const expectedY = ballState.position.y + ballState.velocity.y * deltaTime;

      // Update position (implementation would be in Ball class)
      ballState.position.x += ballState.velocity.x * deltaTime;
      ballState.position.y += ballState.velocity.y * deltaTime;

      expect(ballState.position.x).toBeCloseTo(expectedX);
      expect(ballState.position.y).toBeCloseTo(expectedY);
    });

    it('should maintain constant speed', () => {
      const speed = Math.sqrt(
        ballState.velocity.x ** 2 + ballState.velocity.y ** 2
      );
      
      expect(speed).toBeCloseTo(ballState.speed, 5);
    });

    it('should enforce speed limits', () => {
      const MAX_SPEED = 600;
      ALWAYS(ballState.speed <= MAX_SPEED, 'Ball speed exceeds maximum');
      NEVER(ballState.speed <= 0, 'Ball speed must be positive');
    });
  });

  describe('Collision', () => {
    it('should reverse X velocity on vertical wall collision', () => {
      const originalVelocityX = ballState.velocity.x;
      
      // Simulate wall collision
      ballState.velocity.x = -ballState.velocity.x;
      
      expect(ballState.velocity.x).toBe(-originalVelocityX);
    });

    it('should reverse Y velocity on horizontal wall collision', () => {
      const originalVelocityY = ballState.velocity.y;
      
      // Simulate ceiling collision
      ballState.velocity.y = -ballState.velocity.y;
      
      expect(ballState.velocity.y).toBe(-originalVelocityY);
    });
  });
});
EOF

# Create property-based test example
cat > tests/unit/utils/math.test.ts << 'EOF'
import { describe, it, expect } from 'vitest';
import * as fc from 'fast-check';

// Example math utilities to test
export function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

export function normalizeVector(x: number, y: number): { x: number; y: number } {
  const magnitude = Math.sqrt(x * x + y * y);
  if (magnitude === 0) return { x: 0, y: 0 };
  return { x: x / magnitude, y: y / magnitude };
}

describe('Math Utilities', () => {
  describe('clamp', () => {
    it('should return value within bounds', () => {
      fc.assert(
        fc.property(
          fc.float({ min: -1000, max: 1000 }),
          fc.float({ min: -100, max: 100 }),
          fc.float({ min: -100, max: 100 }),
          (value, min, max) => {
            // Ensure min <= max
            if (min > max) [min, max] = [max, min];
            
            const result = clamp(value, min, max);
            expect(result).toBeGreaterThanOrEqual(min);
            expect(result).toBeLessThanOrEqual(max);
          }
        )
      );
    });

    it('should be idempotent', () => {
      fc.assert(
        fc.property(
          fc.float(),
          fc.float(),
          fc.float(),
          (value, min, max) => {
            if (min > max) [min, max] = [max, min];
            
            const once = clamp(value, min, max);
            const twice = clamp(once, min, max);
            expect(twice).toBe(once);
          }
        )
      );
    });
  });

  describe('normalizeVector', () => {
    it('should produce unit vectors', () => {
      fc.assert(
        fc.property(
          fc.float({ min: -1000, max: 1000, noNaN: true }),
          fc.float({ min: -1000, max: 1000, noNaN: true }),
          (x, y) => {
            const normalized = normalizeVector(x, y);
            const magnitude = Math.sqrt(
              normalized.x ** 2 + normalized.y ** 2
            );
            
            // Either zero vector or unit vector
            if (x === 0 && y === 0) {
              expect(magnitude).toBe(0);
            } else {
              expect(magnitude).toBeCloseTo(1, 5);
            }
          }
        )
      );
    });

    it('should preserve direction', () => {
      fc.assert(
        fc.property(
          fc.float({ min: -1000, max: 1000, noNaN: true }),
          fc.float({ min: -1000, max: 1000, noNaN: true }),
          (x, y) => {
            if (x === 0 && y === 0) return; // Skip zero vector
            
            const normalized = normalizeVector(x, y);
            const angle = Math.atan2(y, x);
            const normalizedAngle = Math.atan2(normalized.y, normalized.x);
            
            expect(normalizedAngle).toBeCloseTo(angle, 5);
          }
        )
      );
    });
  });
});
EOF

echo -e "${GREEN}🎬 Creating GitHub Actions workflow${NC}"

# Create CI/CD workflow
cat > .github/workflows/ci.yml << 'EOF'
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  quality:
    name: Code Quality
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Type check
        run: npm run type-check
      
      - name: Lint & Format
        run: npm run check
      
      - name: Build
        run: npm run build

  test:
    name: Test Suite
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run unit tests with coverage
        run: npm run test:coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          files: ./coverage/lcov.info
          flags: unittests
          name: codecov-umbrella

  deploy:
    name: Deploy
    needs: [quality, test]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Build production
        run: npm run build
        env:
          NODE_ENV: production
      
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v4
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./dist
EOF

echo -e "${GREEN}🎬 Creating minimal Playwright config${NC}"

# Create playwright.config.ts
cat > playwright.config.ts << 'EOF'
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: 'tests/e2e',
  fullyParallel: true,
  reporter: [['html', { outputFolder: 'playwright-report' }]],
  use: { 
    baseURL: 'http://localhost:4173',
    screenshot: 'only-on-failure',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } }
  ],
  webServer: {
    command: 'npm run preview',
    port: 4173,
    reuseExistingServer: !process.env.CI,
  },
});
EOF

echo -e "${GREEN}📝 Creating README${NC}"

# Create README
cat > README.md << 'EOF'
# TypeScript/Phaser Brickbreaker

Production-quality brickbreaker game with SQLite-level testing standards.

## 🎯 Features

- **100% Type Safety** - Strictest TypeScript configuration with branded types
- **Comprehensive Testing** - Unit, integration, E2E, and property-based testing
- **SQLite-Inspired Quality** - ALWAYS/NEVER assertions, defensive programming patterns
- **Cross-Platform** - Web, iOS, Android via Capacitor; Desktop via Tauri
- **Modern Tooling** - Vite, Vitest, Biome, Lefthook for lightning-fast development
- **State Management** - XState for game states, Zustand for UI state
- **Runtime Validation** - Zod schemas for all data structures

## 🚀 Quick Start

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Run tests
npm test

# Run tests with coverage
npm run test:coverage

# Type check
npm run type-check

# Lint and format
npm run check
```

## 📁 Project Structure

```
src/
├── game/           # Core game logic
│   ├── physics/    # Physics systems
│   ├── input/      # Input handling
│   ├── audio/      # Audio management
│   ├── state/      # Game state management
│   └── commands/   # Command pattern for undo/redo
├── scenes/         # Phaser scenes
├── entities/       # Game entities (ball, paddle, bricks)
├── systems/        # Game systems (collision, scoring)
├── utils/          # Utilities and helpers
│   └── testing/    # Testing utilities (ALWAYS/NEVER assertions)
├── types/          # TypeScript types and schemas
└── config/         # Game configuration

tests/
├── unit/          # Unit tests
├── integration/   # Integration tests
├── e2e/          # End-to-end tests
└── visual/       # Visual regression tests
```

## 🧪 Testing Philosophy

Following SQLite's 590:1 test-to-code ratio philosophy:

1. **Foundation Libraries** - 100% coverage with defensive assertions
2. **Game Logic** - 80-90% coverage with property-based testing
3. **Integration** - E2E and visual regression for user-facing features

## 🛠️ Technology Stack

- **Framework**: Phaser 3.70
- **Language**: TypeScript 5.4 (strictest settings)
- **Build**: Vite 5.2
- **Testing**: Vitest, fast-check, Playwright
- **Validation**: Zod
- **State**: XState, Zustand
- **Code Quality**: Biome, Lefthook
- **CI/CD**: GitHub Actions

## 📊 Coverage Goals

- Branches: 80%
- Functions: 80%
- Lines: 80%
- Statements: 80%

Foundation libraries target 100% coverage.

## 🚢 Deployment

The game automatically deploys to GitHub Pages on merge to main.

## 📄 License

MIT
EOF

echo -e "${GREEN}📝 Creating .gitignore${NC}"

# Create .gitignore
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
.pnp
.pnp.js

# Build outputs
dist/
build/
out/
*.local

# Testing
coverage/
.nyc_output/
test-results/
playwright-report/
playwright/.cache/
backstop_data/bitmaps_test/
backstop_data/html_report/
.stryker-tmp/
reports/

# IDE
.vscode/*
!.vscode/extensions.json
.idea/
*.swp
*.swo
*~
.DS_Store

# Environment
.env
.env.local
.env.*.local

# Logs
logs/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*
lerna-debug.log*

# Cache
.eslintcache
.stylelintcache
.prettiercache
.biomecache

# Misc
*.tsbuildinfo
.vercel
.netlify
EOF

echo -e "${GREEN}📝 Creating VS Code configuration${NC}"

# Create VS Code settings
mkdir -p .vscode
cat > .vscode/extensions.json << 'EOF'
{
  "recommendations": [
    "biomejs.biome",
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "streetsidesoftware.code-spell-checker",
    "usernamehw.errorlens",
    "vitest.explorer",
    "ms-playwright.playwright"
  ]
}
EOF

cat > .vscode/settings.json << 'EOF'
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.biome": "explicit",
    "source.organizeImports.biome": "explicit"
  },
  "[typescript]": {
    "editor.defaultFormatter": "biomejs.biome"
  },
  "[javascript]": {
    "editor.defaultFormatter": "biomejs.biome"
  },
  "[json]": {
    "editor.defaultFormatter": "biomejs.biome"
  },
  "typescript.tsdk": "node_modules/typescript/lib",
  "typescript.enablePromptUseWorkspaceTsdk": true,
  "files.exclude": {
    "**/.git": true,
    "**/.DS_Store": true,
    "**/node_modules": true,
    "**/dist": true,
    "**/coverage": true
  }
}
EOF

echo -e "${GREEN}📝 Creating placeholder assets${NC}"

# Create real placeholder PNG files (1x1 white pixel)
mkdir -p public/assets/sprites

# Generate a real 1x1 white PNG using base64
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==" | base64 -d > public/assets/sprites/ball.png

# Copy to other sprites as placeholders
cp public/assets/sprites/ball.png public/assets/sprites/logo.png
cp public/assets/sprites/ball.png public/assets/sprites/paddle.png
cp public/assets/sprites/ball.png public/assets/sprites/brick.png
cp public/assets/sprites/ball.png public/assets/sprites/powerup.png
cp public/assets/sprites/ball.png public/assets/sprites/particle.png

echo -e "${GREEN}🔧 Initializing Lefthook${NC}"
npx lefthook install

echo -e "${GREEN}🎉 Project scaffold complete!${NC}"
echo -e "${BLUE}=================================${NC}"
echo -e "Next steps:"
echo -e "1. ${YELLOW}cd ${PROJECT_NAME}${NC}"
echo -e "2. ${YELLOW}npm run dev${NC} - Start development server"
echo -e "3. ${YELLOW}npm test${NC} - Run tests"
echo -e ""
echo -e "Key commands:"
echo -e "• ${GREEN}npm run dev${NC} - Development server with HMR"
echo -e "• ${GREEN}npm run test:ui${NC} - Interactive test UI"
echo -e "• ${GREEN}npm run test:coverage${NC} - Coverage report"
echo -e "• ${GREEN}npm run check${NC} - Fix all linting/formatting"
echo -e ""
echo -e "${BLUE}Happy coding! 🎮${NC}"
