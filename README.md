# Random Scripts

Personal scaffolds, small utilities, and learning examples.

## Layout

- `examples/c/` - C learning and demonstration programs.
- `examples/cobol/` - COBOL learning and demonstration programs.
- `libraries/typescript/argument-parser/` - Small TypeScript argument parser with self-contained tests.
- `scaffolds/` - Project generator scripts.
- `tools/unicode-text-wash/` - Prose-oriented Unicode-to-ASCII text cleanup CLI and tests.

## Examples

- `examples/c/c-programming-essentials.c` - Beginner-oriented C walkthrough.
- `examples/c/cgol.c` - Freestanding ANSI C cellular automaton example.
- `examples/c/ultimate-hello-world.c` - Maximal C feature demonstration.
- `examples/cobol/snake.cob` - Portable line-mode Snake in ANSI COBOL-85.

The standards gate compiles the portable C examples. `ultimate-hello-world.c` is
kept as an unsafe/platform-specific demonstration and is not part of the default
compile gate.

## Libraries

The TypeScript argument parser lives in:

```text
libraries/typescript/argument-parser/parse-args.ts
```

Its test file is self-contained and runs through Bun:

```sh
bun libraries/typescript/argument-parser/parse-args.test.ts
```

## Scaffolds

- `scaffolds/datastar-php-sapi.sh` - Datastar, Bulma, PHTML, FastRoute, Diactoros, and SQLite PHP scaffold.
- `scaffolds/falling-sand-nextjs.sh` - Falling-sand simulation route/components for a Next.js app.
- `scaffolds/godot-2d-project.sh` - Godot 4 2D project generator and optional installer.
- `scaffolds/phaser-brickbreaker-basic.sh` - npm/Vite/Phaser brickbreaker scaffold with a larger test/tooling setup.
- `scaffolds/phaser-brickbreaker-dx.sh` - Bun/Vite/Phaser brickbreaker scaffold with PWA, Capacitor, Electron, and Go level generation.

## Tools

Run the Unicode text cleaner:

```sh
node tools/unicode-text-wash/unicode-text-wash.js --dry-run README.md
```

It normalizes copied prose and rich text. Do not run it over source code unless you intentionally want backticks and other code-significant characters normalized.

Run its tests:

```sh
node --test tools/unicode-text-wash/unicode-text-wash.test.js
```

## Standards

This repo uses the shared standards baseline with a repo-specific mise command
surface:

```sh
mise run install
mise run standards
mise run standards:check
```
