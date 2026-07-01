#!/usr/bin/env node

const crypto = require("crypto");
const fs = require("fs");
const path = require("path");
const { Transform } = require("stream");
const { pipeline } = require("stream/promises");
const { TextDecoder } = require("util");

const QUOTE = String.fromCharCode(34);
const APOS = String.fromCharCode(39);

const REPLACEMENTS = new Map([
  // Dashes and hyphens.
  ["\u2212", "-"], // U+2212 MINUS SIGN
  ["\u2013", "-"], // U+2013 EN DASH
  ["\u2014", "--"], // U+2014 EM DASH
  ["\u2012", "-"], // U+2012 FIGURE DASH
  ["\u2015", "--"], // U+2015 HORIZONTAL BAR
  ["\u2010", "-"], // U+2010 HYPHEN
  ["\u2011", "-"], // U+2011 NON-BREAKING HYPHEN

  // Quotes.
  ["\u0060", APOS], // U+0060 GRAVE ACCENT
  ["\u00B4", APOS], // U+00B4 ACUTE ACCENT
  ["\u201C", QUOTE], // U+201C LEFT DOUBLE QUOTATION MARK
  ["\u201D", QUOTE], // U+201D RIGHT DOUBLE QUOTATION MARK
  ["\u2018", APOS], // U+2018 LEFT SINGLE QUOTATION MARK
  ["\u2019", APOS], // U+2019 RIGHT SINGLE QUOTATION MARK
  ["\u201E", QUOTE], // U+201E DOUBLE LOW-9 QUOTATION MARK
  ["\u201A", APOS], // U+201A SINGLE LOW-9 QUOTATION MARK
  ["\u00AB", QUOTE], // U+00AB LEFT-POINTING DOUBLE ANGLE QUOTATION MARK
  ["\u00BB", QUOTE], // U+00BB RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK
  ["\u2039", APOS], // U+2039 SINGLE LEFT-POINTING ANGLE QUOTATION MARK
  ["\u203A", APOS], // U+203A SINGLE RIGHT-POINTING ANGLE QUOTATION MARK
  ["\u02BB", APOS], // U+02BB MODIFIER LETTER TURNED COMMA
  ["\u02BC", APOS], // U+02BC MODIFIER LETTER APOSTROPHE

  // Prime marks.
  ["\u2032", APOS], // U+2032 PRIME
  ["\u2033", QUOTE], // U+2033 DOUBLE PRIME
  ["\u2034", APOS + APOS + APOS], // U+2034 TRIPLE PRIME

  // Spaces.
  ["\u00A0", " "], // U+00A0 NO-BREAK SPACE
  ["\u1680", " "], // U+1680 OGHAM SPACE MARK
  ["\u2000", " "], // U+2000 EN QUAD
  ["\u2001", " "], // U+2001 EM QUAD
  ["\u2002", " "], // U+2002 EN SPACE
  ["\u2003", " "], // U+2003 EM SPACE
  ["\u2004", " "], // U+2004 THREE-PER-EM SPACE
  ["\u2005", " "], // U+2005 FOUR-PER-EM SPACE
  ["\u2006", " "], // U+2006 SIX-PER-EM SPACE
  ["\u2007", " "], // U+2007 FIGURE SPACE
  ["\u2008", " "], // U+2008 PUNCTUATION SPACE
  ["\u2009", " "], // U+2009 THIN SPACE
  ["\u200A", " "], // U+200A HAIR SPACE
  ["\u202F", " "], // U+202F NARROW NO-BREAK SPACE
  ["\u205F", " "], // U+205F MEDIUM MATHEMATICAL SPACE
  ["\u3000", " "], // U+3000 IDEOGRAPHIC SPACE

  // Invisible format characters.
  ["\u00AD", ""], // U+00AD SOFT HYPHEN
  ["\u200B", ""], // U+200B ZERO WIDTH SPACE
  ["\u200C", ""], // U+200C ZERO WIDTH NON-JOINER
  ["\u200D", ""], // U+200D ZERO WIDTH JOINER
  ["\u2060", ""], // U+2060 WORD JOINER
  ["\uFEFF", ""], // U+FEFF ZERO WIDTH NO-BREAK SPACE / BOM

  // Other punctuation.
  ["\u2026", "..."], // U+2026 HORIZONTAL ELLIPSIS
  ["\u2022", "*"], // U+2022 BULLET
  ["\u00B7", "-"], // U+00B7 MIDDLE DOT
  ["\u00B0", " deg"], // U+00B0 DEGREE SIGN
  ["\u00A9", "(c)"], // U+00A9 COPYRIGHT SIGN
  ["\u00AE", "(R)"], // U+00AE REGISTERED SIGN
  ["\u2122", "TM"], // U+2122 TRADE MARK SIGN

  // Status and math symbols.
  ["\u2713", "OK"], // U+2713 CHECK MARK
  ["\u2714", "OK"], // U+2714 HEAVY CHECK MARK
  ["\u2717", "x"], // U+2717 BALLOT X
  ["\u2718", "x"], // U+2718 HEAVY BALLOT X
  ["\u00D7", "x"], // U+00D7 MULTIPLICATION SIGN
  ["\u00F7", "/"], // U+00F7 DIVISION SIGN
  ["\u2264", "<="], // U+2264 LESS-THAN OR EQUAL TO
  ["\u2265", ">="], // U+2265 GREATER-THAN OR EQUAL TO
  ["\u2260", "!="], // U+2260 NOT EQUAL TO
  ["\u2248", "~="], // U+2248 ALMOST EQUAL TO

  // Arrows.
  ["\u2192", "->"], // U+2192 RIGHTWARDS ARROW
  ["\u2190", "<-"], // U+2190 LEFTWARDS ARROW
  ["\u21D2", "=>"], // U+21D2 RIGHTWARDS DOUBLE ARROW
  ["\u21D0", "<="], // U+21D0 LEFTWARDS DOUBLE ARROW
]);

const CHARACTER_NAMES = new Map([
  ["\u2212", "MINUS SIGN"],
  ["\u2013", "EN DASH"],
  ["\u2014", "EM DASH"],
  ["\u2012", "FIGURE DASH"],
  ["\u2015", "HORIZONTAL BAR"],
  ["\u2010", "HYPHEN"],
  ["\u2011", "NON-BREAKING HYPHEN"],
  ["\u0060", "GRAVE ACCENT"],
  ["\u00B4", "ACUTE ACCENT"],
  ["\u201C", "LEFT DOUBLE QUOTATION MARK"],
  ["\u201D", "RIGHT DOUBLE QUOTATION MARK"],
  ["\u2018", "LEFT SINGLE QUOTATION MARK"],
  ["\u2019", "RIGHT SINGLE QUOTATION MARK"],
  ["\u201E", "DOUBLE LOW-9 QUOTATION MARK"],
  ["\u201A", "SINGLE LOW-9 QUOTATION MARK"],
  ["\u00AB", "LEFT-POINTING DOUBLE ANGLE QUOTATION MARK"],
  ["\u00BB", "RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK"],
  ["\u2039", "SINGLE LEFT-POINTING ANGLE QUOTATION MARK"],
  ["\u203A", "SINGLE RIGHT-POINTING ANGLE QUOTATION MARK"],
  ["\u02BB", "MODIFIER LETTER TURNED COMMA"],
  ["\u02BC", "MODIFIER LETTER APOSTROPHE"],
  ["\u2032", "PRIME"],
  ["\u2033", "DOUBLE PRIME"],
  ["\u2034", "TRIPLE PRIME"],
  ["\u00A0", "NO-BREAK SPACE"],
  ["\u1680", "OGHAM SPACE MARK"],
  ["\u2000", "EN QUAD"],
  ["\u2001", "EM QUAD"],
  ["\u2002", "EN SPACE"],
  ["\u2003", "EM SPACE"],
  ["\u2004", "THREE-PER-EM SPACE"],
  ["\u2005", "FOUR-PER-EM SPACE"],
  ["\u2006", "SIX-PER-EM SPACE"],
  ["\u2007", "FIGURE SPACE"],
  ["\u2008", "PUNCTUATION SPACE"],
  ["\u2009", "THIN SPACE"],
  ["\u200A", "HAIR SPACE"],
  ["\u202F", "NARROW NO-BREAK SPACE"],
  ["\u205F", "MEDIUM MATHEMATICAL SPACE"],
  ["\u3000", "IDEOGRAPHIC SPACE"],
  ["\u00AD", "SOFT HYPHEN"],
  ["\u200B", "ZERO WIDTH SPACE"],
  ["\u200C", "ZERO WIDTH NON-JOINER"],
  ["\u200D", "ZERO WIDTH JOINER"],
  ["\u2060", "WORD JOINER"],
  ["\uFEFF", "ZERO WIDTH NO-BREAK SPACE"],
  ["\u2026", "HORIZONTAL ELLIPSIS"],
  ["\u2022", "BULLET"],
  ["\u00B7", "MIDDLE DOT"],
  ["\u00B0", "DEGREE SIGN"],
  ["\u00A9", "COPYRIGHT SIGN"],
  ["\u00AE", "REGISTERED SIGN"],
  ["\u2122", "TRADE MARK SIGN"],
  ["\u2713", "CHECK MARK"],
  ["\u2714", "HEAVY CHECK MARK"],
  ["\u2717", "BALLOT X"],
  ["\u2718", "HEAVY BALLOT X"],
  ["\u00D7", "MULTIPLICATION SIGN"],
  ["\u00F7", "DIVISION SIGN"],
  ["\u2264", "LESS-THAN OR EQUAL TO"],
  ["\u2265", "GREATER-THAN OR EQUAL TO"],
  ["\u2260", "NOT EQUAL TO"],
  ["\u2248", "ALMOST EQUAL TO"],
  ["\u2192", "RIGHTWARDS ARROW"],
  ["\u2190", "LEFTWARDS ARROW"],
  ["\u21D2", "RIGHTWARDS DOUBLE ARROW"],
  ["\u21D0", "LEFTWARDS DOUBLE ARROW"],
]);

function escapeRegex(text) {
  return text.replace(/[\\^$.*+?()[\]{}|]/g, "\\$&");
}

function createReplacementRegex() {
  const alternatives = Array.from(REPLACEMENTS.keys())
    .filter((char) => char.length > 0)
    .sort((left, right) => right.length - left.length)
    .map(escapeRegex);

  return new RegExp(alternatives.join("|"), "gu");
}

const REPLACEMENT_REGEX = createReplacementRegex();

function replacementFor(match) {
  return REPLACEMENTS.has(match) ? REPLACEMENTS.get(match) : match;
}

function replaceText(text, stats) {
  return text.replace(REPLACEMENT_REGEX, (match) => {
    const replacement = replacementFor(match);
    if (replacement !== match) {
      stats.replacements += 1;
    }
    return replacement;
  });
}

function makeSkippedError(code, message) {
  const error = new Error(message);
  error.code = code;
  error.skipped = true;
  return error;
}

function decodeUtf8(buffer) {
  if (buffer.includes(0)) {
    throw makeSkippedError("BINARY_FILE", "file appears to be binary (contains NUL byte)");
  }

  try {
    return new TextDecoder("utf-8", { fatal: true, ignoreBOM: true }).decode(buffer);
  } catch {
    throw makeSkippedError("INVALID_UTF8", "file is not valid UTF-8");
  }
}

class CharacterReplacerTransform extends Transform {
  constructor(options = {}) {
    super(options);
    this.decoder = new TextDecoder("utf-8", { fatal: true, ignoreBOM: true });
    this.stats = { replacements: 0, bytes: 0 };
  }

  _transform(chunk, encoding, callback) {
    const buffer = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk, encoding);
    this.stats.bytes += buffer.length;

    if (buffer.includes(0)) {
      callback(makeSkippedError("BINARY_FILE", "file appears to be binary (contains NUL byte)"));
      return;
    }

    try {
      const text = this.decoder.decode(buffer, { stream: true });
      callback(null, replaceText(text, this.stats));
    } catch {
      callback(makeSkippedError("INVALID_UTF8", "file is not valid UTF-8"));
    }
  }

  _flush(callback) {
    try {
      const text = this.decoder.decode();
      if (text) {
        this.push(replaceText(text, this.stats));
      }
      callback();
    } catch {
      callback(makeSkippedError("INVALID_UTF8", "file is not valid UTF-8"));
    }
  }
}

function plural(count, singular, pluralForm = `${singular}s`) {
  return count === 1 ? singular : pluralForm;
}

function codePointLabel(char) {
  return `U+${char.codePointAt(0).toString(16).toUpperCase().padStart(4, "0")}`;
}

function charName(char) {
  return CHARACTER_NAMES.get(char) || "UNKNOWN CHARACTER";
}

function displayChar(char) {
  switch (char) {
    case "\u00AD":
      return "<soft-hyphen>";
    case "\u00A0":
      return "<NBSP>";
    case "\u1680":
      return "<ogham-space>";
    case "\u2000":
      return "<en-quad>";
    case "\u2001":
      return "<em-quad>";
    case "\u2002":
      return "<en-space>";
    case "\u2003":
      return "<em-space>";
    case "\u2004":
      return "<three-per-em-space>";
    case "\u2005":
      return "<four-per-em-space>";
    case "\u2006":
      return "<six-per-em-space>";
    case "\u2007":
      return "<figure-space>";
    case "\u2008":
      return "<punctuation-space>";
    case "\u2009":
      return "<thin-space>";
    case "\u200A":
      return "<hair-space>";
    case "\u200B":
      return "<ZWSP>";
    case "\u200C":
      return "<ZWNJ>";
    case "\u200D":
      return "<ZWJ>";
    case "\u202F":
      return "<narrow-NBSP>";
    case "\u205F":
      return "<medium-math-space>";
    case "\u2060":
      return "<word-joiner>";
    case "\u3000":
      return "<ideographic-space>";
    case "\uFEFF":
      return "<BOM>";
    case "\n":
      return "\\n";
    case "\r":
      return "\\r";
    case "\t":
      return "\\t";
    default:
      return char;
  }
}

function displayReplacement(replacement) {
  if (replacement === "") {
    return "<delete>";
  }
  if (replacement === " ") {
    return "SPACE";
  }
  return replacement;
}

function advancePosition(position, text) {
  for (const char of text) {
    if (char === "\n") {
      position.line += 1;
      position.column = 1;
    } else {
      position.column += 1;
    }
  }
}

function visibleContextSegment(text) {
  let result = "";
  for (const char of text) {
    result += displayChar(char);
  }
  return result;
}

function clipStart(text, maxLength) {
  const chars = Array.from(text);
  if (chars.length <= maxLength) {
    return text;
  }
  return `...${chars.slice(chars.length - maxLength).join("")}`;
}

function clipEnd(text, maxLength) {
  const chars = Array.from(text);
  if (chars.length <= maxLength) {
    return text;
  }
  return `${chars.slice(0, maxLength).join("")}...`;
}

function formatContext(content, index, match, radius = 32) {
  const lineStart = content.lastIndexOf("\n", Math.max(0, index - 1)) + 1;
  const lineEndIndex = content.indexOf("\n", index);
  const lineEnd = lineEndIndex === -1 ? content.length : lineEndIndex;
  const before = clipStart(content.slice(lineStart, index), radius);
  const after = clipEnd(content.slice(index + match.length, lineEnd), radius);

  return `${visibleContextSegment(before)}[${displayChar(match)}]${visibleContextSegment(after)}`;
}

function findReplacementOccurrences(content) {
  const occurrences = [];
  const regex = createReplacementRegex();
  const position = { line: 1, column: 1 };
  let cursor = 0;

  for (let match = regex.exec(content); match !== null; match = regex.exec(content)) {
    const char = match[0];
    const index = match.index;
    advancePosition(position, content.slice(cursor, index));

    const replacement = replacementFor(char);
    if (replacement !== char) {
      occurrences.push({
        char,
        column: position.column,
        context: formatContext(content, index, char),
        index,
        line: position.line,
        name: charName(char),
        replacement,
      });
    }

    advancePosition(position, char);
    cursor = index + char.length;
  }

  return occurrences;
}

function createTempPath(filePath) {
  const dir = path.dirname(filePath);
  const base = path.basename(filePath);
  const suffix = crypto.randomBytes(8).toString("hex");
  return path.join(dir, `.${base}.${process.pid}.${suffix}.tmp`);
}

async function preserveFileModeAndOwner(tempPath, fileStats) {
  await fs.promises.chmod(tempPath, fileStats.mode & 0o7777);

  if (typeof fileStats.uid === "number" && typeof fileStats.gid === "number") {
    try {
      await fs.promises.chown(tempPath, fileStats.uid, fileStats.gid);
    } catch (error) {
      if (!["EPERM", "EINVAL"].includes(error.code)) {
        throw error;
      }
    }
  }
}

async function processFile(filePath, options = {}) {
  const stats = { replacements: 0, bytes: 0, time: Date.now() };
  let tempPath = null;

  try {
    const fileStats = await fs.promises.lstat(filePath);
    if (fileStats.isSymbolicLink()) {
      return {
        path: filePath,
        reason: "symbolic links are skipped",
        skipped: true,
        stats,
        success: true,
      };
    }
    if (!fileStats.isFile()) {
      throw new Error(`not a regular file: ${filePath}`);
    }

    await fs.promises.access(filePath, fs.constants.R_OK);

    tempPath = createTempPath(filePath);
    const readStream = fs.createReadStream(filePath);
    const writeStream = fs.createWriteStream(tempPath, {
      flags: "wx",
      mode: fileStats.mode & 0o7777,
    });
    const transformer = new CharacterReplacerTransform();

    if (options.verbose && !options.quiet) {
      console.log(`Processing: ${filePath} (${(fileStats.size / 1024).toFixed(1)} KB)`);
    }

    await pipeline(readStream, transformer, writeStream);

    stats.replacements = transformer.stats.replacements;
    stats.bytes = transformer.stats.bytes;
    stats.time = Date.now() - stats.time;

    if (stats.replacements === 0) {
      await fs.promises.unlink(tempPath);
      tempPath = null;
      if (options.verbose && !options.quiet) {
        console.log(`OK ${filePath}: 0 replacements in ${stats.time}ms`);
      }
      return { changed: false, path: filePath, stats, success: true };
    }

    await preserveFileModeAndOwner(tempPath, fileStats);
    await fs.promises.rename(tempPath, filePath);
    tempPath = null;

    if (!options.quiet) {
      console.log(`OK ${filePath}: ${stats.replacements} ${plural(stats.replacements, "replacement")} in ${stats.time}ms`);
    }

    return { changed: true, path: filePath, stats, success: true };
  } catch (error) {
    if (tempPath) {
      try {
        await fs.promises.unlink(tempPath);
      } catch {}
    }

    stats.time = Date.now() - stats.time;

    if (error.skipped) {
      return {
        path: filePath,
        reason: error.message,
        skipped: true,
        stats,
        success: true,
      };
    }

    return { error: error.message, path: filePath, stats, success: false };
  }
}

async function inspectFile(filePath) {
  const stats = { replacements: 0, bytes: 0, time: Date.now() };

  try {
    const fileStats = await fs.promises.lstat(filePath);
    if (fileStats.isSymbolicLink()) {
      return {
        occurrences: [],
        path: filePath,
        reason: "symbolic links are skipped",
        skipped: true,
        stats,
        success: true,
      };
    }
    if (!fileStats.isFile()) {
      throw new Error(`not a regular file: ${filePath}`);
    }

    const buffer = await fs.promises.readFile(filePath);
    stats.bytes = buffer.length;
    const content = decodeUtf8(buffer);
    const occurrences = findReplacementOccurrences(content);
    stats.replacements = occurrences.length;
    stats.time = Date.now() - stats.time;

    return { occurrences, path: filePath, stats, success: true };
  } catch (error) {
    stats.time = Date.now() - stats.time;

    if (error.skipped) {
      return {
        occurrences: [],
        path: filePath,
        reason: error.message,
        skipped: true,
        stats,
        success: true,
      };
    }

    return { error: error.message, occurrences: [], path: filePath, stats, success: false };
  }
}

function printDryRunOccurrences(result) {
  if (result.occurrences.length === 0) {
    return;
  }

  console.log(`${result.path} (${result.occurrences.length} ${plural(result.occurrences.length, "replacement")})`);
  for (const occurrence of result.occurrences) {
    console.log(
      `  ${result.path}:${occurrence.line}:${occurrence.column} ` +
        `${codePointLabel(occurrence.char)} ${occurrence.name} ` +
        `${displayChar(occurrence.char)} -> ${displayReplacement(occurrence.replacement)} | ` +
        occurrence.context,
    );
  }
}

async function collectFiles(inputPaths, options) {
  const files = [];
  let failed = 0;

  async function addPath(inputPath) {
    try {
      const stats = await fs.promises.lstat(inputPath);

      if (stats.isSymbolicLink()) {
        if (!options.quiet) {
          console.error(`Warning: Skipping ${inputPath} (symbolic link)`);
        }
        return;
      }

      if (stats.isDirectory()) {
        if (!options.recursive) {
          if (!options.quiet) {
            console.error(`Warning: Skipping ${inputPath} (directory; use --recursive)`);
          }
          return;
        }
        await findFiles(inputPath);
        return;
      }

      if (stats.isFile()) {
        if (!options.pattern || minimatch(path.basename(inputPath), options.pattern)) {
          files.push(inputPath);
        }
        return;
      }

      if (!options.quiet) {
        console.error(`Warning: Skipping ${inputPath} (not a regular file)`);
      }
    } catch (error) {
      failed += 1;
      console.error(`Error accessing ${inputPath}: ${error.message}`);
    }
  }

  async function findFiles(dir) {
    let entries;
    try {
      entries = await fs.promises.readdir(dir, { withFileTypes: true });
    } catch (error) {
      failed += 1;
      console.error(`Error reading ${dir}: ${error.message}`);
      return;
    }

    entries.sort((left, right) => left.name.localeCompare(right.name));

    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      if (entry.isSymbolicLink()) {
        if (options.verbose && !options.quiet) {
          console.error(`Warning: Skipping ${fullPath} (symbolic link)`);
        }
      } else if (entry.isDirectory()) {
        await findFiles(fullPath);
      } else if (entry.isFile()) {
        if (!options.pattern || minimatch(entry.name, options.pattern)) {
          files.push(fullPath);
        }
      }
    }
  }

  for (const inputPath of inputPaths) {
    await addPath(inputPath);
  }

  return { failed, files };
}

function parseArgs(args) {
  const options = {
    dryRun: false,
    pattern: null,
    quiet: false,
    recursive: false,
    verbose: false,
  };
  const files = [];

  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index];

    switch (arg) {
      case "-v":
      case "--verbose":
        options.verbose = true;
        break;
      case "-q":
      case "--quiet":
        options.quiet = true;
        break;
      case "-r":
      case "--recursive":
        options.recursive = true;
        break;
      case "--dry-run":
        options.dryRun = true;
        break;
      case "-p":
      case "--pattern":
        index += 1;
        if (index >= args.length) {
          throw new Error(`${arg} requires a pattern`);
        }
        options.pattern = args[index];
        break;
      default:
        if (arg.startsWith("-")) {
          throw new Error(`unknown option: ${arg}`);
        }
        files.push(arg);
        break;
    }
  }

  return { files, options };
}

function printHelp() {
  console.log(`
Smart Character Replacer - Unicode to ASCII cleanup

Usage: ${path.basename(process.argv[1])} [options] <file1> [file2] ...

Options:
  -v, --verbose     Show detailed progress
  -q, --quiet       Suppress progress and summaries
  -r, --recursive   Process directories recursively
  -p, --pattern     Basename glob to match (e.g., ${QUOTE}*.txt${QUOTE})
  --dry-run         Print every replacement occurrence without modifying files
  --help            Show this help

Examples:
  ${path.basename(process.argv[1])} document.txt
  ${path.basename(process.argv[1])} -r -p ${QUOTE}*.md${QUOTE} ./docs
  ${path.basename(process.argv[1])} --dry-run file1.txt file2.txt

Replaces prose punctuation, weird spaces, invisible format characters, and common symbols with ASCII equivalents.
This is intended for prose and copied rich text, not source code.
  `);
}

async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0 || args.includes("--help") || args.includes("-h")) {
    printHelp();
    process.exit(0);
  }

  let parsed;
  try {
    parsed = parseArgs(args);
  } catch (error) {
    console.error(`Error: ${error.message}`);
    process.exit(1);
  }

  if (parsed.files.length === 0) {
    console.error("Error: No files specified");
    process.exit(1);
  }

  const { files: filesToProcess, failed: collectionFailures } = await collectFiles(parsed.files, parsed.options);

  if (filesToProcess.length === 0) {
    console.error("No files found to process");
    process.exit(collectionFailures > 0 ? 1 : 0);
  }

  if (!parsed.options.quiet) {
    console.log(`Processing ${filesToProcess.length} ${plural(filesToProcess.length, "file")}...`);
  }

  const results = {
    changed: 0,
    failed: collectionFailures,
    skipped: 0,
    success: 0,
    totalBytes: 0,
    totalReplacements: 0,
    totalTime: 0,
  };

  for (const filePath of filesToProcess) {
    const result = parsed.options.dryRun ? await inspectFile(filePath) : await processFile(filePath, parsed.options);

    if (result.success) {
      if (result.skipped) {
        results.skipped += 1;
        if (!parsed.options.quiet) {
          console.error(`Warning: Skipping ${result.path} (${result.reason})`);
        }
        continue;
      }

      results.success += 1;
      results.totalReplacements += result.stats.replacements;
      results.totalBytes += result.stats.bytes;
      results.totalTime += result.stats.time;

      if (parsed.options.dryRun) {
        if (result.stats.replacements > 0) {
          results.changed += 1;
        }
        printDryRunOccurrences(result);
      } else if (result.changed) {
        results.changed += 1;
      }
    } else {
      results.failed += 1;
      console.error(`Error: ${result.path}: ${result.error}`);
    }
  }

  if (!parsed.options.quiet) {
    console.log(parsed.options.dryRun ? "\nDry-run summary:" : "\nSummary:");
    console.log(`  Files scanned: ${results.success}`);
    console.log(`  Files changed: ${results.changed}`);
    if (results.skipped > 0) {
      console.log(`  Files skipped: ${results.skipped}`);
    }
    if (results.failed > 0) {
      console.log(`  Files failed: ${results.failed}`);
    }
    console.log(`  Total replacements: ${results.totalReplacements}`);

    if (!parsed.options.dryRun) {
      console.log(`  Total data: ${(results.totalBytes / 1024 / 1024).toFixed(2)} MB`);
      console.log(`  Total time: ${results.totalTime}ms`);

      if (results.totalBytes > 0 && results.totalTime > 0) {
        const throughput = results.totalBytes / 1024 / 1024 / (results.totalTime / 1000);
        console.log(`  Throughput: ${throughput.toFixed(1)} MB/s`);
      }
    }
  }

  process.exit(results.failed > 0 ? 1 : 0);
}

function minimatch(filename, pattern) {
  const regex = pattern
    .replace(/[.+^${}()|[\]\\]/g, "\\$&")
    .replace(/\*/g, ".*")
    .replace(/\?/g, ".");

  return new RegExp(`^${regex}$`).test(filename);
}

if (require.main === module) {
  main().catch((error) => {
    console.error(`Fatal error: ${error.message}`);
    process.exit(1);
  });
}

module.exports = {
  CharacterReplacerTransform,
  REPLACEMENTS,
  findReplacementOccurrences,
  inspectFile,
  processFile,
  replaceText,
};
