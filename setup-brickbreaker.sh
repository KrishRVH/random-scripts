#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Brickbreaker DX Scaffold (Bun + Phaser + Vite + Biome + PWA + Capacitor + Electron + Go levelgen)
# =============================================================================
#
# GOAL
# - Maximize developer experience (DX) for a Phaser game, from zero to fun,
#   with the fastest edit-run loop possible and minimal ceremony.
# - "Write once, run everywhere": Browser (Web), Android, iOS, Desktop.
# - Use Bun instead of npm/pnpm. Use Biome instead of ESLint/Prettier.
# - No heavy test stack or e2e frameworks—we ship fast.
# - Add a tiny Go tool to learn Go without impacting the DX.
#
# WHY THESE CHOICES
# - Bun: Very fast install and script runner. No-lock DX friction.
# - Vite: Best-in-class HMR and simplicity for frontend dev.
# - Phaser: Battle-tested 2D game engine with Arcade physics; familiar APIs.
# - Biome: Single tool for lint+format with sane defaults and speed.
# - PWA: Instant "installable" web app + offline testing with one plugin.
# - Capacitor (Android/iOS): Wraps your Vite app with native shells; live
#   reload over LAN; no native build logic needed until release.
# - Electron (Desktop): On Windows/macOS/Linux, dev is trivial—no Rust toolchain;
#   click-and-go desktop shell using the same Vite app. Tauri is great but adds
#   toolchain friction. You can swap to Tauri later without changing game code.
# - Runtime-generated textures: No asset pipeline; prototype immediately.
# - Optional Go: Small CLI to generate level JSON—just enough to practice Go.
#
# STRUCTURE
# - src/: TypeScript game code with JSDoc so AI tools can reason about intent.
# - tools/go/levelgen: Go CLI; writes src/levels/level1.json
# - Capacitor config for mobile, Electron plugin for desktop dev
# - PWA via vite-plugin-pwa
#
# PREREQS
# - bun installed: https://bun.sh
# - git (optional but recommended)
# - go (optional; only needed to run the level generator)
# - Android Studio/Xcode for platform-specific device builds when you’re ready
#
# RUN MODES
# - Web dev: bun run dev (Vite HMR)
# - Android/iOS live reload: bun run dev:android / bun run dev:ios
# - Desktop dev (Electron): bun run dev:desktop
# - PWA preview: bun run build && bun run preview
#
# NOTES
# - Keep everything as simple as possible: one codebase, unified config.
# - You can add art/audio assets later in public/assets/ and load via /assets/...
# - The Go tool simply overwrites a JSON level—zero runtime coupling.
#
# =============================================================================

# Detect Bun
if ! command -v bun >/dev/null 2>&1; then
  echo "Bun is required. Install from https://bun.sh"
  exit 1
fi

# Args:
#   --here               scaffold into current directory (no new folder)
#   --force              overwrite existing files if present
#   --id <appId>         Capacitor app id (default: com.example.brickbreaker)
#   --name <appName>     Capacitor app name (default: Brickbreaker)
#   <project-name>       optional; if omitted and not --here, uses current dir
APP_ID_DEFAULT="com.example.brickbreaker"
APP_NAME_DEFAULT="Brickbreaker"
FORCE=0
HERE=0
TARGET_DIR=""
APP_ID="$APP_ID_DEFAULT"
APP_NAME="$APP_NAME_DEFAULT"
while [ $# -gt 0 ]; do
  case "$1" in
    --here) HERE=1; shift ;;
    --force) FORCE=1; shift ;;
    --id) APP_ID="$2"; shift 2 ;;
    --name) APP_NAME="$2"; shift 2 ;;
    *) TARGET_DIR="${TARGET_DIR:-$1}"; shift ;;
  esac
done
if [ "$HERE" -eq 1 ] || [ -z "${TARGET_DIR}" ]; then
  TARGET_DIR="."
  PROJECT_NAME="$(basename "$PWD")"
else
  PROJECT_NAME="$TARGET_DIR"
fi
# Safety: refuse to overwrite common files unless --force
if [ "$TARGET_DIR" = "." ] && [ "$FORCE" -ne 1 ]; then
  for p in package.json tsconfig.json vite.config.ts index.html biome.json capacitor.config.ts src electron; do
    if [ -e "$p" ]; then
      echo "Refusing to overwrite existing '$p'. Use --force to override."
      exit 1
    fi
  done
fi
if [ "$TARGET_DIR" != "." ]; then
  mkdir -p "$TARGET_DIR"
  cd "$TARGET_DIR"
fi

# Initialize git only if not already a repo
if command -v git >/dev/null 2>&1 && [ ! -d .git ]; then
  git init -q
fi

# -----------------------------------------------------------------------------
# package.json - minimal scripts using Bun, Vite HMR, Biome checks
# -----------------------------------------------------------------------------
cat > package.json <<EOF
{
  "name": "$PROJECT_NAME",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "bunx vite",
    "dev:web": "bunx vite",
    "dev:desktop": "bunx vite",
    "dev:android": "bunx concurrently -k -n vite,android -c green,cyan \\"bun run dev:web\\" \\"bunx cap run android -l --external\\"",
    "dev:ios": "bunx concurrently -k -n vite,ios -c green,magenta \\"bun run dev:web\\" \\"bunx cap run ios -l --external\\"",
    "build": "tsc && bunx vite build",
    "preview": "bunx vite preview",
    "type-check": "tsc --noEmit",
    "format": "biome format --write .",
    "check": "biome check --apply .",
    "cap:add:android": "bunx cap add android",
    "cap:add:ios": "bunx cap add ios",
    "cap:sync": "bunx cap sync",
    "levels:generate": "go run ./tools/go/levelgen --rows 6 --cols 10 --width 75 --height 30 --padding 5 --offsetx 0 --offsety 90"
  },
  "engines": {
    "bun": ">=1.1.0"
  }
}
EOF

# -----------------------------------------------------------------------------
# Dependencies - runtime and dev
# -----------------------------------------------------------------------------
# Runtime deps: phaser + dev HUD toys
bun add phaser stats.js tweakpane @capacitor/core
# Dev deps: types, bundler, pwa, checker, paths, electron, capacitor cli, biome
bun add -d typescript vite vite-plugin-checker vite-tsconfig-paths vite-plugin-pwa vite-plugin-electron @biomejs/biome @tsconfig/strictest @types/node @types/stats.js concurrently @capacitor/cli

# -----------------------------------------------------------------------------
# TypeScript config - strict, path aliases, JSON modules, bundler resolution
# -----------------------------------------------------------------------------
cat > tsconfig.json <<'EOF'
{
  "extends": "@tsconfig/strictest/tsconfig.json",
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "noEmit": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noPropertyAccessFromIndexSignature": true,
    "verbatimModuleSyntax": true,
    "isolatedModules": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"]
    },
    "types": ["node"],
    "skipLibCheck": true
  },
  "include": ["src/**/*"]
}
EOF

# -----------------------------------------------------------------------------
# Vite config - DX-first: TS checker, tsconfig paths, PWA, Electron dev
# -----------------------------------------------------------------------------
# - PWA: lets you "install" the app and test offline quickly
# - Electron: runs desktop shell in dev with a single command
# -----------------------------------------------------------------------------
cat > vite.config.ts <<'EOF'
import { defineConfig } from "vite";
import checker from "vite-plugin-checker";
import tsconfigPaths from "vite-tsconfig-paths";
import { VitePWA } from "vite-plugin-pwa";
import electron from "vite-plugin-electron/simple";

export default defineConfig({
  plugins: [
    tsconfigPaths(),
    checker({ typescript: true }),
    VitePWA({
      registerType: "autoUpdate",
      includeAssets: [],
      manifest: {
        name: "Brickbreaker",
        short_name: "Brickbreaker",
        start_url: "/",
        display: "standalone",
        background_color: "#1a1a2e",
        theme_color: "#1a1a2e",
        icons: []
      }
    }),
    electron({
      main: {
        entry: "electron/main.ts",
        onstart: ({ startup }) => startup()
      },
      preload: {
        input: { preload: "electron/preload.ts" }
      },
      renderer: {}
    })
  ],
  server: {
    host: true,
    port: 5173,
    open: false
  },
  build: {
    target: "es2022",
    sourcemap: true
  }
});
EOF

# -----------------------------------------------------------------------------
# index.html - minimal frame; Vite dev server injects HMR client
# -----------------------------------------------------------------------------
cat > index.html <<'EOF'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta
      name="viewport"
      content="width=device-width, initial-scale=1.0, maximum-scale=1"
    />
    <title>Brickbreaker</title>
    <style>
      html, body { height: 100%; }
      body {
        margin: 0;
        background: #0f1020;
        display: grid;
        place-items: center;
        font-family: system-ui, -apple-system, Segoe UI, Roboto, Ubuntu,
          Cantarell, Noto Sans, Helvetica, Arial, "Apple Color Emoji",
          "Segoe UI Emoji";
      }
      #game-container {
        border-radius: 8px;
        box-shadow: 0 10px 40px rgba(0, 0, 0, 0.35);
        overflow: hidden;
      }
    </style>
  </head>
  <body>
    <div id="game-container"></div>
    <script type="module" src="/src/main.ts"></script>
  </body>
</html>
EOF

# -----------------------------------------------------------------------------
# Electron minimal setup for desktop dev
# -----------------------------------------------------------------------------
mkdir -p electron
cat > electron/main.ts <<'EOF'
/**
 * Electron "main" process entry.
 * - DX: In dev, loads the Vite dev server URL (HMR inside desktop shell).
 * - Prod: Loads dist/index.html after `bun run build`.
 */
import { app, BrowserWindow } from "electron";
import path from "node:path";
import process from "node:process";

const isDev =
  !!process.env.VITE_DEV_SERVER_URL || !!process.env.ELECTRON_START_URL;

let win: BrowserWindow | null = null;

async function createWindow() {
  win = new BrowserWindow({
    width: 900,
    height: 700,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, "preload.js")
    }
  });

  const devUrl = process.env.VITE_DEV_SERVER_URL || "http://localhost:5173";
  if (isDev) {
    await win.loadURL(devUrl);
    win.webContents.openDevTools({ mode: "detach" });
  } else {
    await win.loadFile(path.join(__dirname, "../dist/index.html"));
  }

  win.on("closed", () => {
    win = null;
  });
}

app.whenReady().then(createWindow);
app.on("window-all-closed", () => {
  if (process.platform !== "darwin") app.quit();
});
app.on("activate", () => {
  if (BrowserWindow.getAllWindows().length === 0) createWindow();
});
EOF

cat > electron/preload.ts <<'EOF'
/**
 * Electron "preload" script.
 * Keep empty or expose safe APIs via contextBridge later.
 */
export {};
EOF

# -----------------------------------------------------------------------------
# Capacitor config for mobile shells (Android/iOS)
# -----------------------------------------------------------------------------
cat > capacitor.config.ts <<EOF
import type { CapacitorConfig } from "@capacitor/cli";

/**
 * Capacitor wraps the built Vite app for Android/iOS.
 * - For live reload during dev: uncomment server.url and set your LAN IP.
 * - For release: ensure server.url is removed and build with webDir: "dist".
 */
const config: CapacitorConfig = {
  appId: "$APP_ID",
  appName: "$APP_NAME",
  webDir: "dist",
  server: {
    // url: "http://YOUR-LAN-IP:5173",
    // cleartext: true,
    androidScheme: "http"
  }
};

export default config;
EOF

# Capacitor init is optional (we generate capacitor.config.ts).
# Run only if the config is missing; Capacitor 7 syntax (no --npm-client).
if [ ! -f capacitor.config.ts ]; then
  bunx cap init "$APP_NAME" "$APP_ID" --web-dir=dist --yes >/dev/null || true
fi

# -----------------------------------------------------------------------------
# Source files with rich JSDoc for AI assistance
# -----------------------------------------------------------------------------
mkdir -p src/{config,devtools,levels,scenes,types}
# Game configuration
cat > src/config/game.config.ts <<'EOF'
import type { Types } from "phaser";

/**
 * Global Phaser game configuration.
 * - DX choices:
 *   - Scale FIT: preserves aspect and centers the canvas on any screen.
 *   - Arcade physics with no gravity: standard for brickbreaker.
 *   - FPS 60 with requestAnimationFrame.
 */
export const GAME_CONFIG: Types.Core.GameConfig = {
  type: Phaser.AUTO,
  width: 800,
  height: 600,
  parent: "game-container",
  backgroundColor: "#1a1a2e",
  fps: { target: 60, forceSetTimeOut: false },
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH
  },
  render: {
    antialias: true,
    pixelArt: false,
    roundPixels: false
  },
  physics: {
    default: "arcade",
    arcade: {
      gravity: { x: 0, y: 0 },
      debug: false
    }
  },
  audio: { disableWebAudio: false },
  input: { keyboard: true, mouse: true, touch: true }
};
EOF

# Dev HUD tools
cat > src/devtools/devhud.ts <<'EOF'
import Stats from "stats.js";
import type Phaser from "phaser";
import { Pane } from "tweakpane";

/**
 * Installs a developer HUD:
 * - FPS panel (toggle with F)
 * - Mute and Pause toggles
 * - This is intentionally lightweight: visual knobs beat over-testing for game feel.
 */
export function installDevHud(game: Phaser.Game): void {
  const stats = new Stats();
  stats.showPanel(0);
  stats.dom.style.cssText =
    "position:fixed;left:8px;top:8px;z-index:9999;opacity:0.9";
  document.body.appendChild(stats.dom);

  let statsOn = true;

  // Drive Stats.js on RAF for stable readings irrespective of Phaser events.
  const raf = () => {
    if (statsOn) stats.update();
    requestAnimationFrame(raf);
  };
  requestAnimationFrame(raf);

  const pane = new Pane({ title: "Dev", expanded: false });
  pane.element.style.position = "fixed";
  pane.element.style.right = "8px";
  pane.element.style.top = "8px";
  pane.element.style.zIndex = "9999";

  const toggles = { fps: true, mute: false, pause: false };
  const f = pane.addFolder({ title: "Toggles" });
  f.addBinding(toggles, "fps").on("change", (ev) => {
    statsOn = !!ev.value;
    stats.dom.style.display = statsOn ? "block" : "none";
  });
  f.addBinding(toggles, "mute").on("change", (ev) => {
    game.sound.mute = !!ev.value;
  });
  f.addBinding(toggles, "pause").on("change", (ev) => {
    const active = game.scene.getScenes(true);
    if (ev.value) active.forEach((s) => s.scene.pause());
    else active.forEach((s) => s.scene.resume());
  });

  // Keyboard: F toggles FPS panel quickly.
  window.addEventListener("keydown", (e) => {
    if (e.key.toLowerCase() === "f") {
      statsOn = !statsOn;
      stats.dom.style.display = statsOn ? "block" : "none";
    }
  });
}
EOF

# Level types
cat > src/types/level.ts <<'EOF'
/**
 * LevelSpec describes a brick layout grid.
 * - rows x cols grid
 * - brick metrics control sizing and placement
 * - mask is optional: if omitted, renders a full grid
 */
export interface LevelSpec {
  rows: number;
  cols: number;
  brick: {
    width: number;
    height: number;
    padding: number;
    offsetX: number;
    offsetY: number;
  };
  mask?: number[][]; // 0 or 1; 1 = place a brick
}
EOF

# Default level JSON (Go tool can overwrite this file)
mkdir -p src/levels
cat > src/levels/level1.json <<'EOF'
{
  "rows": 6,
  "cols": 10,
  "brick": { "width": 75, "height": 30, "padding": 5, "offsetX": 0, "offsetY": 90 }
}
EOF

# BootScene: runtime-generated textures (no asset pipeline)
cat > src/scenes/BootScene.ts <<'EOF'
import { Scene } from "phaser";

/**
 * BootScene pre-generates simple textures so we can iterate without an asset pipeline.
 * Replace these with real art later when needed.
 */
export class BootScene extends Scene {
  constructor() {
    super("BootScene");
  }

  create(): void {
    this.makeBallTexture();
    this.makePaddleTexture();
    this.makeBrickTexture();
    this.scene.start("GameScene");
  }

  /** Creates a circular "ball" texture. */
  private makeBallTexture(): void {
    const size = 16;
    const g = this.add.graphics();
    g.fillStyle(0xffffff, 1);
    g.fillCircle(size / 2, size / 2, size / 2);
    g.generateTexture("ball", size, size);
    g.destroy();
  }

  /** Creates a rounded-rect "paddle" texture. */
  private makePaddleTexture(): void {
    const w = 100;
    const h = 20;
    const g = this.add.graphics();
    g.fillStyle(0x4ade80, 1);
    g.fillRoundedRect(0, 0, w, h, 6);
    g.generateTexture("paddle", w, h);
    g.destroy();
  }

  /** Creates a bordered "brick" texture. */
  private makeBrickTexture(): void {
    const w = 75;
    const h = 30;
    const g = this.add.graphics();
    g.fillStyle(0x60a5fa, 1);
    g.fillRoundedRect(0, 0, w, h, 4);
    g.lineStyle(2, 0x1e293b, 1);
    g.strokeRoundedRect(1, 1, w - 2, h - 2, 4);
    g.generateTexture("brick", w, h);
    g.destroy();
  }
}
EOF

# GameScene: playable core with bricks from JSON level
cat > src/scenes/GameScene.ts <<'EOF'
import Phaser, { Scene, Types } from "phaser";
import type { LevelSpec } from "@/types/level";
import level1 from "@/levels/level1.json" assert { type: "json" };

/**
 * GameScene: Minimal but fun brickbreaker loop.
 * DX features:
 * - Keyboard & mouse/touch input
 * - Dev shortcuts: R (restart), P (pause), M (mute), F (FPS)
 * - Level driven by JSON (overwritable by Go tool)
 */
export class GameScene extends Scene {
  private paddle!: Phaser.Physics.Arcade.Image;
  private ball!: Phaser.Physics.Arcade.Image;
  private bricks!: Phaser.Physics.Arcade.StaticGroup;
  private cursors!: Types.Input.Keyboard.CursorKeys;
  private lives = 3;
  private score = 0;
  private scoreText!: Phaser.GameObjects.Text;

  constructor() {
    super("GameScene");
  }

  create(): void {
    const { width, height } = this.scale;

    // Paddle
    this.paddle = this.physics.add
      .image(width / 2, height - 50, "paddle")
      .setImmovable(true)
      .setCollideWorldBounds(true);

    // Ball
    this.ball = this.physics.add
      .image(width / 2, height - 80, "ball")
      .setCollideWorldBounds(true)
      .setBounce(1, 1)
      .setVelocity(240, -240);

    // Bricks from LevelSpec
    this.bricks = this.physics.add.staticGroup();
    this.buildBricks(level1 as LevelSpec);

    // Collisions
    this.physics.add.collider(this.ball, this.paddle, (ball, paddle) => {
      const diff = ball.x - (paddle as Phaser.Physics.Arcade.Image).x;
      // Nudge X velocity based on hit position to keep gameplay lively
      ball.body.velocity.x += Phaser.Math.Clamp(diff * 3, -200, 200);
    });

    this.physics.add.collider(this.ball, this.bricks, (ball, brickObj) => {
      const b = brickObj as Phaser.Physics.Arcade.Image;
      // Remove brick
      b.destroy();
      // Score and speed clamp
      this.score += 100;
      this.updateHud();
      const v = this.ball.body.velocity;
      const max = 500;
      v.x = Phaser.Math.Clamp(v.x, -max, max);
      v.y = Phaser.Math.Clamp(v.y, -max, max);

      // Win condition: all gone
      if (this.bricks.countActive() === 0) {
        this.time.delayedCall(500, () => this.resetLevel(level1 as LevelSpec));
      }
    });

    // Keyboard + cursors
    this.cursors = this.input.keyboard!.createCursorKeys();

    // Mouse/touch follow
    this.input.on("pointermove", (p: Phaser.Input.Pointer) => {
      this.paddle.x = Phaser.Math.Clamp(p.x, 50, width - 50);
    });

    // World bounds (no bottom)
    this.physics.world.setBounds(0, 0, width, height, true, true, true, false);

    // HUD
    this.add
      .text(12, 8, "R: restart  P: pause  M: mute  F: FPS", {
        fontSize: "14px",
        color: "#94a3b8"
      })
      .setDepth(1000)
      .setScrollFactor(0);
    this.scoreText = this.add
      .text(width - 12, 8, "", {
        fontSize: "14px",
        color: "#e2e8f0",
        align: "right"
      })
      .setOrigin(1, 0)
      .setDepth(1000);
    this.updateHud();

    // Dev shortcuts
    this.input.keyboard?.on("keydown-R", () => this.scene.restart());
    this.input.keyboard?.on("keydown-P", () => this.togglePause());
    this.input.keyboard?.on("keydown-M", () => (this.sound.mute = !this.sound.mute));
  }

  update(): void {
    // Keyboard paddle movement
    const speed = 520;
    if (this.cursors.left?.isDown) {
      this.paddle.setVelocityX(-speed);
    } else if (this.cursors.right?.isDown) {
      this.paddle.setVelocityX(speed);
    } else {
      this.paddle.setVelocityX(0);
    }

    this.handleOutOfBounds();
  }

  /** Rebuilds bricks from the supplied LevelSpec. */
  private buildBricks(level: LevelSpec): void {
    const { width } = this.scale;
    const totalWidth =
      level.cols * level.brick.width + (level.cols - 1) * level.brick.padding;
    const startX = (width - totalWidth) / 2 + level.brick.offsetX;

    for (let r = 0; r < level.rows; r++) {
      for (let c = 0; c < level.cols; c++) {
        if (level.mask && level.mask[r] && level.mask[r][c] === 0) continue;
        const x = startX + c * (level.brick.width + level.brick.padding);
        const y =
          level.brick.offsetY +
          r * (level.brick.height + level.brick.padding);
        const brick = this.add.image(x, y, "brick");
        this.bricks.add(brick, true);
      }
    }
  }

  /** Updates score/lives HUD text. */
  private updateHud(): void {
    this.scoreText.setText(`Score: ${this.score}   Lives: ${this.lives}`);
  }

  /** Handles ball missing the paddle (life lost). */
  private handleOutOfBounds(): void {
    const { height } = this.scale;
    if (this.ball.y > height + 20) {
      this.lives -= 1;
      if (this.lives <= 0) {
        this.lives = 3;
        this.score = 0;
        this.scene.restart();
      } else {
        this.resetBall();
      }
      this.updateHud();
    }
  }

  /** Resets the ball to a starting position and velocity. */
  private resetBall(): void {
    const { width, height } = this.scale;
    this.ball.setPosition(width / 2, height - 80);
    this.ball.setVelocity(240, -240);
  }

  /** Restarts the level layout and resets the ball. */
  private resetLevel(level: LevelSpec): void {
    this.bricks.clear(true, true);
    this.buildBricks(level);
    this.resetBall();
  }

  /** Toggles scene pause/resume. */
  private togglePause(): void {
    if (this.scene.isPaused()) this.scene.resume();
    else this.scene.pause();
  }
}
EOF

# Main entry
cat > src/main.ts <<'EOF'
import Phaser from "phaser";
import { GAME_CONFIG } from "./config/game.config";
import { BootScene } from "./scenes/BootScene";
import { GameScene } from "./scenes/GameScene";
import { installDevHud } from "./devtools/devhud";

/**
 * Application bootstrap:
 * - Combines global config with scene list
 * - Installs dev HUD (FPS + toggles)
 * - Handles tab visibility for polite audio/CPU behavior
 */
const config: Phaser.Types.Core.GameConfig = {
  ...GAME_CONFIG,
  scene: [BootScene, GameScene]
};

const game = new Phaser.Game(config);
installDevHud(game);

// Mute/pause on tab hidden to avoid surprise sounds on multitask.
document.addEventListener("visibilitychange", () => {
  const active = game.scene.getScenes(true);
  if (document.hidden) {
    game.sound.mute = true;
    active.forEach((s) => s.scene.pause());
  } else {
    game.sound.mute = false;
    active.forEach((s) => s.scene.resume());
  }
});

// Developer convenience: access game from devtools
if (import.meta.env.DEV) {
  (window as any).game = game;
}
EOF

# -----------------------------------------------------------------------------
# Biome config - single-tool lint/format
# -----------------------------------------------------------------------------
cat > biome.json <<'EOF'
{
  "$schema": "https://biomejs.dev/schemas/1.8.0/schema.json",
  "linter": {
    "enabled": true,
    "rules": { "recommended": true }
  },
  "formatter": {
    "enabled": true,
    "lineWidth": 80
  }
}
EOF

# -----------------------------------------------------------------------------
# Go level generator - optional, small, instructive
# -----------------------------------------------------------------------------
# - Writes src/levels/level1.json (overwrites default)
# - Lets you experiment with masks and parameters
# -----------------------------------------------------------------------------
mkdir -p tools/go/levelgen
cat > tools/go/levelgen/go.mod <<EOF
module levelgen

go 1.22
EOF

cat > tools/go/levelgen/main.go <<'EOF'
// levelgen: tiny Go tool to generate a brick layout JSON.
// Rationale: a small, useful Go piece that doesn't harm DX.
// Usage example:
//   go run ./tools/go/levelgen --rows 6 --cols 10 --width 75 --height 30 --padding 5 --offsetx 0 --offsety 90
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"math/rand"
	"os"
	"time"
)

type BrickSpec struct {
	Width   int `json:"width"`
	Height  int `json:"height"`
	Padding int `json:"padding"`
	OffsetX int `json:"offsetX"`
	OffsetY int `json:"offsetY"`
}

type LevelSpec struct {
	Rows  int        `json:"rows"`
	Cols  int        `json:"cols"`
	Brick BrickSpec  `json:"brick"`
	Mask  [][]int    `json:"mask,omitempty"`
}

func main() {
	var rows, cols, w, h, pad, offx, offy int
	var density float64
	flag.IntVar(&rows, "rows", 6, "number of rows")
	flag.IntVar(&cols, "cols", 10, "number of columns")
	flag.IntVar(&w, "width", 75, "brick width")
	flag.IntVar(&h, "height", 30, "brick height")
	flag.IntVar(&pad, "padding", 5, "brick padding")
	flag.IntVar(&offx, "offsetx", 0, "grid offset X")
	flag.IntVar(&offy, "offsety", 90, "grid offset Y")
	flag.Float64Var(&density, "density", 1.0, "0..1 chance to place each brick")
	flag.Parse()

	rand.Seed(time.Now().UnixNano())

	level := LevelSpec{
		Rows: rows,
		Cols: cols,
		Brick: BrickSpec{
			Width:   w,
			Height:  h,
			Padding: pad,
			OffsetX: offx,
			OffsetY: offy,
		},
	}

	// Optionally sparsify with density < 1.0
	if density < 1.0 {
		level.Mask = make([][]int, rows)
		for r := 0; r < rows; r++ {
			level.Mask[r] = make([]int, cols)
			for c := 0; c < cols; c++ {
				if rand.Float64() <= density {
					level.Mask[r][c] = 1
				} else {
					level.Mask[r][c] = 0
				}
			}
		}
	}

	bytes, err := json.MarshalIndent(level, "", "  ")
	if err != nil {
		fmt.Println("error marshaling json:", err)
		os.Exit(1)
	}

	// Overwrite the default level with generated one for immediate use.
	if err := os.WriteFile("src/levels/level1.json", bytes, 0o644); err != nil {
		fmt.Println("error writing src/levels/level1.json:", err)
		os.Exit(1)
	}

	fmt.Println("Generated src/levels/level1.json")
}
EOF

# -----------------------------------------------------------------------------
# .gitignore
# -----------------------------------------------------------------------------
cat > .gitignore <<'EOF'
node_modules/
dist/
.DS_Store
.idea/
.vscode/
*.log
*.tsbuildinfo
playwright-report/
EOF

# -----------------------------------------------------------------------------
# README - quickstart
# -----------------------------------------------------------------------------
cat > README.md <<EOF
# $APP_NAME

DX-first Phaser + Vite + Bun game scaffold:
- Single codebase: web, Android, iOS, desktop (Electron), PWA
- Bun for speed, Biome for lint+format, no heavy test stack
- Runtime-generated textures (replace with art later)
- Optional Go level generator

## Quick start

bun install
bun run dev

Open http://localhost:5173 (or your LAN IP on device).

## Platform dev

- Desktop (Electron): bun run dev:desktop
- Android live reload:
  - bun run cap:add:android (first time)
  - bun run dev:android
- iOS live reload (on macOS):
  - bun run cap:add:ios (first time)
  - bun run dev:ios

Tip: For devices that cannot auto-discover the dev server, set your LAN IP
in capacitor.config.ts (server.url) and keep \`bun run dev\` running.

## Build

- Web/PWA: bun run build && bun run preview
- Mobile sync (after build): bun run build && bun run cap:sync

## Go level generator

bun run levels:generate

It overwrites src/levels/level1.json with a new layout. Adjust flags to taste.

## Controls

- Left/Right arrows or mouse/touch to move paddle
- R: restart, P: pause, M: mute, F: toggle FPS overlay
EOF

# -----------------------------------------------------------------------------
# Finalize: initial commit and optional first level generation
# -----------------------------------------------------------------------------
if command -v git >/dev/null 2>&1; then
  git add .
  git commit -m "chore: scaffold DX-first Phaser app (bun+vite+biome+PWA+capacitor+electron+go levelgen)" -q
fi

# Optionally generate a level with Go to demonstrate integration
if command -v go >/dev/null 2>&1; then
  echo "Running Go level generator (optional)..."
  bun run levels:generate >/dev/null || true
else
  echo "Go not found; keeping default level (you can run 'bun run levels:generate' later)."
fi

echo
echo "Done!"
echo
echo "Next steps:"
if [ "$TARGET_DIR" != "." ]; then
  echo "  1) cd $PROJECT_NAME"
  echo "  2) bun install"
  echo "  3) bun run dev"
else
  echo "  1) bun install"
  echo "  2) bun run dev"
fi
echo
echo "Mobile:"
echo "  - bun run cap:add:android && bun run dev:android"
echo "  - bun run cap:add:ios     && bun run dev:ios   (macOS)"
echo
echo "Desktop:"
echo "  - bun run dev:desktop"
echo
echo "Optional Go levelgen:"
echo "  - bun run levels:generate  (tweak flags in package.json)"