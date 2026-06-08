#!/usr/bin/env node

const fs = require(`fs`);
const { pipeline } = require(`stream/promises`);
const { Transform } = require(`stream`);
const path = require(`path`);

// Define quote characters using char codes to prevent any auto-conversion
const QUOTE = String.fromCharCode(34); // "
const APOS = String.fromCharCode(39); // '

// Character replacement map - all problematic characters
const REPLACEMENTS = new Map([
  // Smart dashes and hyphens
  [`−`, `-`], // U+2212 minus sign → hyphen-minus
  [`–`, `--`], // U+2013 en dash → double hyphen-minus should this be single?
  [`—`, `--`], // U+2014 em dash → double hyphen-minus
  [`‐`, `-`], // U+2010 hyphen → hyphen-minus
  [`‑`, `-`], // U+2011 non-breaking hyphen → hyphen-minus

  // Smart quotes
  [`“`, QUOTE], // U+201C left double quotation mark
  [`”`, QUOTE], // U+201D right double quotation mark
  [`‘`, APOS], // U+2018 left single quotation mark
  [`’`, APOS], // U+2019 right single quotation mark
  [`„`, QUOTE], // U+201E double low-9 quotation mark
  [`‚`, APOS], // U+201A single low-9 quotation mark
  [`«`, QUOTE], // U+00AB left guillemet
  [`»`, QUOTE], // U+00BB right guillemet

  // Prime marks
  [`′`, APOS], // U+2032 prime
  [`″`, QUOTE], // U+2033 double prime
  [`‴`, APOS + APOS + APOS], // U+2034 triple prime

  // Spaces
  [` `, ` `], // U+00A0 non-breaking space
  [` `, ` `], // U+2009 thin space
  [` `, ` `], // U+200A hair space
  [``, ``], // U+200B zero-width space (remove entirely)
  [` `, ` `], // U+202F narrow no-break space
  [` `, ` `], // U+2003 em space
  [` `, ` `], // U+2002 en space

  // Other punctuation
  [`…`, `...`], // U+2026 horizontal ellipsis
  [`•`, `*`], // U+2022 bullet
  [`·`, `-`], // U+00B7 middle dot
  [`°`, `o`], // U+00B0 degree sign (context dependent, using 'o')

  // Arrows (common in code/docs)
  [`→`, `->`], // U+2192 rightwards arrow
  [`←`, `<-`], // U+2190 leftwards arrow
  [`⇒`, `=>`], // U+21D2 rightwards double arrow
  [`⇐`, `<=`], // U+21D0 leftwards double arrow
]);

// Create regex pattern from all characters that need replacement
const createReplacementRegex = () => {
  const chars = Array.from(REPLACEMENTS.keys()).map(
    (char) => char.replace(/[.*+?^${}()|[\]\\]/g, `\\$&`), // Escape regex special chars
  );
  return new RegExp(`[${chars.join(``)}]`, `g`);
};

const REPLACEMENT_REGEX = createReplacementRegex();

// High-performance transform stream
class CharacterReplacerTransform extends Transform {
  constructor(options = {}) {
    super(options);
    this.buffer = ``;
    this.stats = { replacements: 0, bytes: 0 };
  }

  _transform(chunk, encoding, callback) {
    this.stats.bytes += chunk.length;

    // Work with string data
    const str = this.buffer + chunk.toString(`utf8`);

    // Keep last few chars in buffer to handle multi-byte UTF8 sequences
    const safeLength = Math.max(0, str.length - 4);
    const toProcess = str.substring(0, safeLength);
    this.buffer = str.substring(safeLength);

    // Perform replacements
    const replaced = toProcess.replace(REPLACEMENT_REGEX, (match) => {
      this.stats.replacements++;
      return REPLACEMENTS.get(match) || match;
    });

    callback(null, replaced);
  }

  _flush(callback) {
    // Process remaining buffer
    if (this.buffer) {
      const replaced = this.buffer.replace(REPLACEMENT_REGEX, (match) => {
        this.stats.replacements++;
        return REPLACEMENTS.get(match) || match;
      });
      this.push(replaced);
    }
    callback();
  }
}

// Process a single file
async function processFile(filePath, options = {}) {
  const stats = { replacements: 0, bytes: 0, time: Date.now() };

  try {
    // Check file exists and is readable
    await fs.promises.access(filePath, fs.constants.R_OK | fs.constants.W_OK);

    // Get file stats
    const fileStats = await fs.promises.stat(filePath);
    if (!fileStats.isFile()) {
      throw new Error(`Not a regular file: ${filePath}`);
    }

    // Create temp file path
    const tempPath = `${filePath}.tmp${process.pid}`;

    // Set up streams
    const readStream = fs.createReadStream(filePath, { encoding: null });
    const writeStream = fs.createWriteStream(tempPath, { encoding: null });
    const transformer = new CharacterReplacerTransform();

    // Process file
    if (options.verbose) {
      console.log(`Processing: ${filePath} (${(fileStats.size / 1024).toFixed(1)} KB)`);
    }

    await pipeline(readStream, transformer, writeStream);

    // Get stats
    stats.replacements = transformer.stats.replacements;
    stats.bytes = transformer.stats.bytes;

    // Replace original file atomically
    await fs.promises.rename(tempPath, filePath);

    stats.time = Date.now() - stats.time;

    if (options.verbose || stats.replacements > 0) {
      console.log(`✓ ${filePath}: ${stats.replacements} replacements in ${stats.time}ms`);
    }

    return { success: true, stats, path: filePath };
  } catch (error) {
    // Clean up temp file if it exists
    try {
      await fs.promises.unlink(`${filePath}.tmp${process.pid}`);
    } catch {} // Ignore cleanup errors

    return { success: false, error: error.message, path: filePath };
  }
}

// Main CLI
async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0 || args.includes(`--help`) || args.includes(`-h`)) {
    console.log(`
Smart Character Replacer - High Performance Unicode Fix

Usage: ${path.basename(process.argv[1])} [options] <file1> [file2] ...

Options:
  -v, --verbose    Show detailed progress
  -q, --quiet      Suppress all output except errors
  -r, --recursive Pocess directories recursively
  -p, --pattern    File pattern to match (e.g., ${QUOTE}*.txt${QUOTE})
  --dry-run        Show what would be changed without modifying files
  --help           Show this help

Examples:
  ${path.basename(process.argv[1])} document.txt
  ${path.basename(process.argv[1])} -r -p ${QUOTE}*.md${QUOTE} ./docs
  ${path.basename(process.argv[1])} -v file1.txt file2.txt file3.txt

Replaces smart quotes, dashes, spaces, and other Unicode characters with ASCII equivalents.
    `);
    process.exit(0);
  }
  // Parse options
  const options = {
    verbose: args.includes(`-v`) || args.includes(`--verbose`),
    quiet: args.includes(`-q`) || args.includes(`--quiet`),
    recursive: args.includes(`-r`) || args.includes(`--recursive`),
    dryRun: args.includes(`--dry-run`),
    pattern: null,
  };
  // Get pattern if specified
  const patternIndex = args.findIndex((arg) => arg === `-p` || arg === `--pattern`);
  if (patternIndex !== -1 && args[patternIndex + 1]) {
    options.pattern = args[patternIndex + 1];
  }
  // Filter out option flags and get file paths
  const files = args.filter((arg, index) => {
    if (arg.startsWith(`-`)) return false;
    if (patternIndex !== -1 && index === patternIndex + 1) return false;
    return true;
  });
  if (files.length === 0) {
    console.error(`Error: No files specified`);
    process.exit(1);
  }

  // Collect all files to process
  const filesToProcess = [];
  for (const file of files) {
    try {
      const stats = await fs.promises.stat(file);

      if (stats.isDirectory() && options.recursive) {
        // Recursively find files
        const findFiles = async (dir) => {
          const entries = await fs.promises.readdir(dir, { withFileTypes: true });
          for (const entry of entries) {
            const fullPath = path.join(dir, entry.name);
            if (entry.isDirectory()) {
              await findFiles(fullPath);
            } else if (entry.isFile()) {
              if (!options.pattern || minimatch(entry.name, options.pattern)) {
                filesToProcess.push(fullPath);
              }
            }
          }
        };
        await findFiles(file);
      } else if (stats.isFile()) {
        filesToProcess.push(file);
      } else {
        console.error(`Warning: Skipping ${file} (not a regular file)`);
      }
    } catch (error) {
      console.error(`Error accessing ${file}: ${error.message}`);
    }
  }
  if (filesToProcess.length === 0) {
    console.error(`No files found to process`);
    process.exit(1);
  }
  if (!options.quiet) {
    console.log(`Processing ${filesToProcess.length} file(s)...`);
  }

  const results = {
    success: 0,
    failed: 0,
    totalReplacements: 0,
    totalBytes: 0,
    totalTime: 0,
  };

  for (const filePath of filesToProcess) {
    if (options.dryRun) {
      // Just check what would be replaced
      try {
        const content = await fs.promises.readFile(filePath, `utf8`);
        const matches = content.match(REPLACEMENT_REGEX);
        if (matches && matches.length > 0) {
          console.log(`Would replace ${matches.length} characters in: ${filePath}`);
        }
      } catch (error) {
        console.error(`Error reading ${filePath}: ${error.message}`);
      }
    } else {
      const result = await processFile(filePath, options);

      if (result.success) {
        results.success++;
        results.totalReplacements += result.stats.replacements;
        results.totalBytes += result.stats.bytes;
        results.totalTime += result.stats.time;
      } else {
        results.failed++;
        if (!options.quiet) {
          console.error(`✗ ${result.path}: ${result.error}`);
        }
      }
    }
  }

  // Summary
  if (!options.quiet && !options.dryRun) {
    console.log(`\nSummary:`);
    console.log(`  Files processed: ${results.success}`);
    if (results.failed > 0) {
      console.log(`  Files failed: ${results.failed}`);
    }
    console.log(`  Total replacements: ${results.totalReplacements}`);
    console.log(`  Total data: ${(results.totalBytes / 1024 / 1024).toFixed(2)} MB`);
    console.log(`  Total time: ${results.totalTime}ms`);

    if (results.totalBytes > 0) {
      const throughput = results.totalBytes / 1024 / 1024 / (results.totalTime / 1000);
      console.log(`  Throughput: ${throughput.toFixed(1)} MB/s`);
    }
  }

  process.exit(results.failed > 0 ? 1 : 0);
}

// Simple minimatch alternative (basic glob matching)
function minimatch(filename, pattern) {
  // Convert glob pattern to regex
  const regex = pattern
    .replace(/[.+^${}()|[\]\\]/g, `\\$&`)
    .replace(/\*/g, `.*`)
    .replace(/\?/g, `.`);

  return new RegExp(`^${regex}$`).test(filename);
}

// Run if called directly
if (require.main === module) {
  main().catch((error) => {
    console.error(`Fatal error: ${error.message}`);
    process.exit(1);
  });
}

module.exports = { processFile, CharacterReplacerTransform, REPLACEMENTS };
 