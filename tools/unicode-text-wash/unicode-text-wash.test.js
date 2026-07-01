const assert = require('assert');
const { spawnSync } = require('child_process');
const fs = require('fs/promises');
const os = require('os');
const path = require('path');
const test = require('node:test');

const { CharacterReplacerTransform, REPLACEMENTS, processFile } = require('./unicode-text-wash.js');

const scriptPath = path.join(__dirname, 'unicode-text-wash.js');

async function withTempDir(fn) {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), 'wash-test-'));
  try {
    return await fn(dir);
  } finally {
    await fs.rm(dir, { recursive: true, force: true });
  }
}

function runCli(args) {
  return spawnSync(process.execPath, [scriptPath, ...args], {
    encoding: 'utf8',
  });
}

function runTransform(chunks) {
  return new Promise((resolve, reject) => {
    const transform = new CharacterReplacerTransform();
    let output = '';

    transform.on('data', (chunk) => {
      output += chunk.toString();
    });
    transform.on('error', reject);
    transform.on('end', () => resolve(output));

    for (const chunk of chunks) {
      transform.write(chunk);
    }
    transform.end();
  });
}

test('replacement map targets the intended Unicode spaces only', () => {
  assert.equal(REPLACEMENTS.has(' '), false);
  assert.equal(REPLACEMENTS.has(''), false);

  for (const char of [
    '\u00A0',
    '\u1680',
    '\u2000',
    '\u2001',
    '\u2002',
    '\u2003',
    '\u2004',
    '\u2005',
    '\u2006',
    '\u2007',
    '\u2008',
    '\u2009',
    '\u200A',
    '\u202F',
    '\u205F',
    '\u3000',
  ]) {
    assert.equal(REPLACEMENTS.get(char), ' ');
  }

  for (const char of ['\u00AD', '\u200B', '\u200C', '\u200D', '\u2060', '\uFEFF']) {
    assert.equal(REPLACEMENTS.get(char), '');
  }
});

test('replacement map includes LLM and Apple text cleanup cases', () => {
  const expected = new Map([
    ['\u2012', '-'],
    ['\u2015', '--'],
    ['\u0060', "'"],
    ['\u00B4', "'"],
    ['\u2039', "'"],
    ['\u203A', "'"],
    ['\u02BB', "'"],
    ['\u02BC', "'"],
    ['\u00A9', '(c)'],
    ['\u00AE', '(R)'],
    ['\u2122', 'TM'],
    ['\u2713', 'OK'],
    ['\u2714', 'OK'],
    ['\u2717', 'x'],
    ['\u2718', 'x'],
    ['\u00D7', 'x'],
    ['\u00F7', '/'],
    ['\u2264', '<='],
    ['\u2265', '>='],
    ['\u2260', '!='],
    ['\u2248', '~='],
  ]);

  for (const [char, replacement] of expected) {
    assert.equal(REPLACEMENTS.get(char), replacement);
  }
});

test('transform handles split UTF-8 characters and empty replacements', async () => {
  const output = await runTransform([
    Buffer.from([0xe2]),
    Buffer.from([0x80, 0x94]),
    Buffer.from('x\u200By', 'utf8'),
    Buffer.from(' a', 'utf8'),
    Buffer.from('😀b', 'utf8').subarray(0, 3),
    Buffer.from('😀b', 'utf8').subarray(3),
  ]);

  assert.equal(output, '--xy a😀b');
});

test('processFile replaces intended characters without changing ASCII spaces', async () => {
  await withTempDir(async (dir) => {
    const file = path.join(dir, 'input.txt');
    await fs.writeFile(file, 'A B\u00A0C\u2009D\u200BE\u2014F', 'utf8');

    const result = await processFile(file, { quiet: true });

    assert.equal(result.success, true);
    assert.equal(result.stats.replacements, 4);
    assert.equal(await fs.readFile(file, 'utf8'), 'A B C DE--F');
  });
});

test('processFile removes invisible formatting characters', async () => {
  await withTempDir(async (dir) => {
    const file = path.join(dir, 'invisible.txt');
    await fs.writeFile(file, '\uFEFFsoft\u00ADword\u2060zero\u200Cwidth\u200Djoiner', 'utf8');

    const result = await processFile(file, { quiet: true });

    assert.equal(result.success, true);
    assert.equal(result.stats.replacements, 5);
    assert.equal(await fs.readFile(file, 'utf8'), 'softwordzerowidthjoiner');
  });
});

test('processFile applies every configured replacement', async () => {
  await withTempDir(async (dir) => {
    const file = path.join(dir, 'all.txt');
    const input = Array.from(REPLACEMENTS.keys()).join('|');
    const expected = Array.from(REPLACEMENTS.values()).join('|');
    await fs.writeFile(file, input, 'utf8');

    const result = await processFile(file, { quiet: true });

    assert.equal(result.success, true);
    assert.equal(result.stats.replacements, REPLACEMENTS.size);
    assert.equal(await fs.readFile(file, 'utf8'), expected);
  });
});

test('processFile does not rewrite files with no replacements', async () => {
  await withTempDir(async (dir) => {
    const file = path.join(dir, 'plain.txt');
    await fs.writeFile(file, 'plain ascii\n', 'utf8');
    const oldDate = new Date('2001-01-01T00:00:00Z');
    await fs.utimes(file, oldDate, oldDate);
    const before = await fs.stat(file);

    const result = await processFile(file, { quiet: true });
    const after = await fs.stat(file);

    assert.equal(result.success, true);
    assert.equal(result.stats.replacements, 0);
    assert.equal(after.mtimeMs, before.mtimeMs);
  });
});

test('dry-run prints every occurrence with line, column, code point, and replacement', async () => {
  await withTempDir(async (dir) => {
    const file = path.join(dir, 'dry.txt');
    const input = 'A \u201Cx\u201D\u00A0B\u200BZ\u2014\n';
    await fs.writeFile(file, input, 'utf8');

    const result = runCli(['--dry-run', file]);

    assert.equal(result.status, 0, result.stderr);
    assert.equal(await fs.readFile(file, 'utf8'), input);
    assert.match(result.stdout, /1:3\s+U\+201C\s+LEFT DOUBLE QUOTATION MARK\s+.+ -> "/);
    assert.match(result.stdout, /1:5\s+U\+201D\s+RIGHT DOUBLE QUOTATION MARK\s+.+ -> "/);
    assert.match(result.stdout, /1:6\s+U\+00A0\s+NO-BREAK SPACE\s+.+ -> SPACE/);
    assert.match(result.stdout, /1:8\s+U\+200B\s+ZERO WIDTH SPACE\s+.+ -> <delete>/);
    assert.match(result.stdout, /1:10\s+U\+2014\s+EM DASH\s+.+ -> --/);
    assert.match(result.stdout, /Total replacements:\s+5/);
  });
});

test('dry-run occurrence details still print with quiet', async () => {
  await withTempDir(async (dir) => {
    const file = path.join(dir, 'quiet-dry.txt');
    await fs.writeFile(file, 'quiet\u2014dry', 'utf8');

    const result = runCli(['--quiet', '--dry-run', file]);

    assert.equal(result.status, 0, result.stderr);
    assert.doesNotMatch(result.stdout, /Processing/);
    assert.match(result.stdout, /quiet-dry\.txt:1:6\s+U\+2014\s+EM DASH\s+.+ -> --/);
  });
});

test('binary-looking files are skipped without modification', async () => {
  await withTempDir(async (dir) => {
    const file = path.join(dir, 'binary.bin');
    const input = Buffer.from([0, 0xe2, 0x80, 0x94, 1, 2, 3]);
    await fs.writeFile(file, input);

    const result = await processFile(file, { quiet: true });

    assert.equal(result.success, true);
    assert.equal(result.skipped, true);
    assert.deepEqual(await fs.readFile(file), input);
  });
});

test('replacement preserves file mode', async () => {
  await withTempDir(async (dir) => {
    const file = path.join(dir, 'mode.txt');
    await fs.writeFile(file, 'mode\u2014test', { encoding: 'utf8', mode: 0o600 });
    await fs.chmod(file, 0o600);

    const result = await processFile(file, { quiet: true });
    const stats = await fs.stat(file);

    assert.equal(result.success, true);
    assert.equal(stats.mode & 0o777, 0o600);
    assert.equal(await fs.readFile(file, 'utf8'), 'mode--test');
  });
});

test('recursive dry-run honors the pattern', async () => {
  await withTempDir(async (dir) => {
    await fs.mkdir(path.join(dir, 'nested'));
    const md = path.join(dir, 'nested', 'doc.md');
    const txt = path.join(dir, 'note.txt');
    await fs.writeFile(md, 'md\u2014file', 'utf8');
    await fs.writeFile(txt, 'txt\u2014file', 'utf8');

    const result = runCli(['--dry-run', '-r', '-p', '*.md', dir]);

    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, /doc\.md/);
    assert.doesNotMatch(result.stdout, /note\.txt/);
    assert.match(result.stdout, /Total replacements:\s+1/);
  });
});
