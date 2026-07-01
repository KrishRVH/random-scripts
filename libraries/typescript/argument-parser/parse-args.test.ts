import { parseArgs } from './parse-args';
export function runTests(): void {
  const tests: Array<{ name: string; fn: () => void }> = [
    {
      name: 'Basic flag parsing with mutation',
      fn: () => {
        const args = ['file.txt', '--verbose', '-d', 'output.txt'];
        const result = parseArgs(args);
        assertDeepEqual(result.flags, { verbose: true, d: true });
        assertDeepEqual(args, ['file.txt', 'output.txt']); // Mutated
        assertEqual(result.positionals === args, true); // Same reference
      },
    },
    {
      name: 'Long flag with equals sign',
      fn: () => {
        const args = ['--output=test.txt', '--port=3000', 'file.txt'];
        const result = parseArgs(args);
        assertDeepEqual(result.flags, { output: 'test.txt', port: '3000' });
        assertDeepEqual(args, ['file.txt']);
      },
    },
    {
      name: 'Short flag expansion',
      fn: () => {
        const args = ['-abc', 'file.txt'];
        const result = parseArgs(args);
        assertDeepEqual(result.flags, { a: true, b: true, c: true });
        assertDeepEqual(args, ['file.txt']);
      },
    },
    {
      name: 'Short flag with value consumption',
      fn: () => {
        const args = ['start', '-p', '3000', '-o', 'output.txt', 'end'];
        const result = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['p', 'o']),
        });
        assertDeepEqual(result.flags, { p: '3000', o: 'output.txt' });
        assertDeepEqual(args, ['start', 'end']);
      },
    },
    {
      name: 'Basic long flag',
      fn: () => {
        const args = ['--verbose'];
        const result = parseArgs(args);
        assertDeepEqual(result.flags, { verbose: true });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Basic short flag',
      fn: () => {
        const args = ['-v'];
        const result = parseArgs(args);
        assertDeepEqual(result.flags, { v: true });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Positionals only',
      fn: () => {
        const args = ['arg1', 'arg2', 'arg3'];
        const result = parseArgs(args);
        assertDeepEqual(result.flags, {});
        assertDeepEqual(result.positionals, ['arg1', 'arg2', 'arg3']);
        assertDeepEqual(args, ['arg1', 'arg2', 'arg3']);
      },
    },
    {
      name: 'Raw args after double-dash',
      fn: () => {
        const args = ['--flag', '--', 'raw1', 'raw2'];
        const result = parseArgs(args);
        assertDeepEqual(result.flags, { flag: true });
        assertDeepEqual(result.raw, ['raw1', 'raw2']);
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Mixed positionals and flags',
      fn: () => {
        const args = ['pos1', '--flag', 'pos2', '-x', 'pos3'];
        const result = parseArgs(args);
        assertDeepEqual(result.flags, { flag: true, x: true });
        assertDeepEqual(result.positionals, ['pos1', 'pos2', 'pos3']);
        assertDeepEqual(args, ['pos1', 'pos2', 'pos3']);
      },
    },
    {
      name: 'Empty string value',
      fn: () => {
        const args = ['--flag='];
        const result = parseArgs(args);
        assertDeepEqual(result.flags, { flag: '' });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Boolean flag parsing true values',
      fn: () => {
        const args = ['--a=true', '--b=1', '--c=yes', '--d=on'];
        const result = parseArgs(args, {
          booleanFlags: new Set(['a', 'b', 'c', 'd']),
        });
        assertDeepEqual(result.flags, { a: true, b: true, c: true, d: true });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Boolean flag parsing false values',
      fn: () => {
        const args = ['--a=false', '--b=0', '--c=no', '--d=off'];
        const result = parseArgs(args, {
          booleanFlags: new Set(['a', 'b', 'c', 'd']),
        });
        assertDeepEqual(result.flags, { a: false, b: false, c: false, d: false });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Short group without values',
      fn: () => {
        const args = ['-abc'];
        const result = parseArgs(args);
        assertDeepEqual(result.flags, { a: true, b: true, c: true });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Negative number consumed as value',
      fn: () => {
        const args = ['--port', '-8080'];
        const result = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['port']),
          numericFlags: new Set(['port']),
        });
        assertDeepEqual(result.flags, { port: -8080 });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'No scientific notation for numeric flags (values remain strings)',
      fn: () => {
        const args = ['--val=1e3', '--val2', '2.5e-2'];
        const result = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['val2']),
          numericFlags: new Set(['val', 'val2']),
        });
        assertDeepEqual(result.flags, { val: '1e3', val2: '2.5e-2' });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Unknown flags in non-strict mode are accepted',
      fn: () => {
        const args = ['--unknown', '--other=value', '-x'];
        const result = parseArgs(args, { strict: false });
        assertDeepEqual(result.flags, { unknown: true, other: 'value', x: true });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Long flag with value separated by space',
      fn: () => {
        const args = ['--name', 'John'];
        const result = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['name']),
        });
        assertDeepEqual(result.flags, { name: 'John' });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Short flag with value separated by space',
      fn: () => {
        const args = ['-n', 'John'];
        const result = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['n']),
        });
        assertDeepEqual(result.flags, { n: 'John' });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Double dash separator extracts raw',
      fn: () => {
        const args = ['--flag', 'pos', '--', '--not-a-flag', 'raw'];
        const result = parseArgs(args);
        assertDeepEqual(result.flags, { flag: true });
        assertDeepEqual(args, ['pos']); // Only positionals remain
        assertDeepEqual(result.raw, ['--not-a-flag', 'raw']);
      },
    },
    {
      name: 'Numeric flag parsing',
      fn: () => {
        const args = ['--port=3000', '--timeout', '5000', 'file.txt'];
        const result = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['timeout']),
          numericFlags: new Set(['port', 'timeout']),
        });
        assertDeepEqual(result.flags, { port: 3000, timeout: 5000 });
        assertDeepEqual(args, ['file.txt']);
      },
    },
    {
      name: 'Boolean flag parsing',
      fn: () => {
        const args = ['--enabled=true', '--disabled=false', '--flag=yes'];
        const result = parseArgs(args, {
          booleanFlags: new Set(['enabled', 'disabled', 'flag']),
        });
        assertDeepEqual(result.flags, {
          enabled: true,
          disabled: false,
          flag: true,
        });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Array flags accumulate values',
      fn: () => {
        const args = ['--file', 'a.txt', '--file', 'b.txt', '--file=c.txt'];
        const result = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['file']),
          arrayFlags: new Set(['file']),
        });
        assertDeepEqual(result.flags, { file: ['a.txt', 'b.txt', 'c.txt'] });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Flag aliases',
      fn: () => {
        const args = ['-v', 'file.txt', '--version'];
        const result = parseArgs(args, { aliases: { v: 'verbose' } });
        assertDeepEqual(result.flags, { verbose: true, version: true });
        assertDeepEqual(args, ['file.txt']);
      },
    },
    {
      name: 'Complex mixed parsing',
      fn: () => {
        const args = ['cmd', '--verbose', 'input.txt', '-o', 'output.txt', '--flag', 'final.txt'];
        const result = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['o']),
        });
        assertDeepEqual(result.flags, {
          verbose: true,
          o: 'output.txt',
          flag: true,
        });
        assertDeepEqual(args, ['cmd', 'input.txt', 'final.txt']);
      },
    },
    {
      name: 'Empty value after equals',
      fn: () => {
        const args = ['before', '--message=', '--text=', 'after'];
        const result = parseArgs(args);
        assertDeepEqual(result.flags, { message: '', text: '' });
        assertDeepEqual(args, ['before', 'after']);
      },
    },
    {
      name: 'Handles standalone dash as positional',
      fn: () => {
        const args = ['-', 'file.txt', '-'];
        const result = parseArgs(args);
        assertDeepEqual(result.flags, {});
        assertDeepEqual(args, ['-', 'file.txt', '-']);
      },
    },
    {
      name: 'Strict mode throws on unknown flags',
      fn: () => {
        let thrown = false;
        try {
          parseArgs(['--unknown'], {
            strict: true,
            flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['known']),
          });
        } catch (e) {
          thrown = true;
          assertEqual((e as Error).message, 'Unknown flag: --unknown');
        }
        assertEqual(thrown, true);
      },
    },
    {
      name: 'Unknown flags in non-strict mode are accepted as booleans',
      fn: () => {
        const args = ['--x', 'pos'];
        const result = parseArgs(args, { strict: false });
        assertDeepEqual(result.flags, { x: true });
        assertDeepEqual(args, ['pos']);
      },
    },
    {
      name: 'Mutation preserves array identity',
      fn: () => {
        const originalArray = ['--flag', 'value', 'positional'];
        const arrayReference = originalArray;
        const result = parseArgs(originalArray, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['flag']),
        });
        assertEqual(originalArray === arrayReference, true); // Same object
        assertEqual(result.positionals === originalArray, true); // Same ref
        assertDeepEqual(originalArray, ['positional']); // Content changed
        assertDeepEqual(result.flags, { flag: 'value' });
      },
    },
    {
      name: 'Complex real-world example with mutation',
      fn: () => {
        const args = [
          'deploy',
          '--env=production',
          '--region',
          'us-west-2',
          '-vdf',
          '--port',
          '8080',
          '--tag',
          'v1.0.0',
          '--tag',
          'latest',
          'app.js',
          '--',
          '--no-flag',
          'raw-arg',
        ];
        const result = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['region', 'port', 'tag']),
          numericFlags: new Set(['port']),
          arrayFlags: new Set(['tag']),
          aliases: { v: 'verbose', d: 'debug', f: 'force' },
        });
        assertDeepEqual(result.flags, {
          env: 'production',
          region: 'us-west-2',
          verbose: true,
          debug: true,
          force: true,
          port: 8080,
          tag: ['v1.0.0', 'latest'],
        });
        assertDeepEqual(args, ['deploy', 'app.js']); // Only positionals
        assertDeepEqual(result.raw, ['--no-flag', 'raw-arg']);
      },
    },
    {
      name: 'Negative numbers as values',
      fn: () => {
        const args = ['--offset', '-10', 'file.txt', '--threshold=-5'];
        const result = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['offset']),
          numericFlags: new Set(['offset', 'threshold']),
        });
        assertDeepEqual(result.flags, { offset: -10, threshold: -5 });
        assertDeepEqual(args, ['file.txt']);
      },
    },
    {
      name: 'Negative decimals and edge cases',
      fn: () => {
        const args = ['--value', '-3.14', '--temp', '-0', '-a', 'end'];
        const result = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['value', 'temp']),
          numericFlags: new Set(['value', 'temp']),
        });
        assertDeepEqual(result.flags, {
          value: -3.14,
          temp: -0,
          a: true, // -a is still treated as a flag
        });
        assertDeepEqual(args, ['end']);
      },
    },
    {
      name: 'Sparse array handling',
      fn: () => {
        const args: string[] = ['--flag'];
        args[2] = 'value'; // creates a hole at index 1 (sparse array)
        const result = parseArgs(args);
        assertDeepEqual(result.flags, { flag: true });
        const compactArgs: Array<string | undefined> = Array.from(args);
        assertDeepEqual(
          compactArgs.filter((x): x is string => x !== undefined),
          ['value'],
        );
      },
    },
    {
      name: 'Long flag with value consumption',
      fn: () => {
        const args = ['--config', 'app.json', '--port', '3000', 'file.txt'];
        const result = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['config', 'port']),
        });
        assertDeepEqual(result.flags, { config: 'app.json', port: '3000' });
        assertDeepEqual(args, ['file.txt']);
      },
    },
    {
      name: 'Short flag equals: -p=3000',
      fn: () => {
        const args = ['start', '-p=3000', 'end'];
        const result = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['p']),
          numericFlags: new Set(['p']),
        });
        assertDeepEqual(result.flags, { p: 3000 });
        assertDeepEqual(args, ['start', 'end']);
      },
    },
    {
      name: 'Short flag group with equals on last: -abp=3000',
      fn: () => {
        const args = ['-abp=3000', 'x'];
        const result = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['p']),
          numericFlags: new Set(['p']),
        });
        assertDeepEqual(result.flags, { a: true, b: true, p: 3000 });
        assertDeepEqual(args, ['x']);
      },
    },
    {
      name:
        'Short flag group with equals where last does not accept value: ' + 'non-strict preserves value as positional',
      fn: () => {
        const args = ['-ab=value', 'x'];
        const result = parseArgs(args, {
          // No flags accept values here
          strict: false,
        });
        assertDeepEqual(result.flags, { a: true, b: true });
        // "-ab=value" replaced with "value" as positional
        assertDeepEqual(args, ['value', 'x']);
        assertDeepEqual(result.positionals, args);
      },
    },
    {
      name: 'Short flag group with equals where last does not accept value: ' + 'strict throws (last unknown)',
      fn: () => {
        let thrown = false;
        try {
          parseArgs(['-ab=value'], { strict: true });
        } catch (e) {
          thrown = true;
          // Last-char semantics
          assertEqual((e as Error).message, 'Unknown flag: -b');
        }
        assertEqual(thrown, true);
      },
    },
    {
      name: 'Short flag consumes negative numeric from next arg',
      fn: () => {
        const args = ['-p', '-.5', 'ok'];
        const result = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['p']),
          numericFlags: new Set(['p']),
        });
        assertDeepEqual(result.flags, { p: -0.5 });
        assertDeepEqual(args, ['ok']);
      },
    },
    {
      name: 'Numeric empty value (long) coerces to 0',
      fn: () => {
        const args = ['--n='];
        const result = parseArgs(args, { numericFlags: new Set(['n']) });
        assertDeepEqual(result.flags, { n: 0 });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Numeric empty value on short equals coerces to 0',
      fn: () => {
        const args = ['-p=', 'x'];
        const result = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['p']),
          numericFlags: new Set(['p']),
        });
        assertDeepEqual(result.flags, { p: 0 });
        assertDeepEqual(args, ['x']);
      },
    },
    {
      name: 'Boolean literals are case-insensitive and support 1/0',
      fn: () => {
        const args = ['--a=ON', '--b=off', '--c=YES', '--d=No', '--e=1', '--f=0'];
        const result = parseArgs(args, {
          booleanFlags: new Set(['a', 'b', 'c', 'd', 'e', 'f']),
        });
        assertDeepEqual(result.flags, {
          a: true,
          b: false,
          c: true,
          d: false,
          e: true,
          f: false,
        });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Unknown long with equals accepted in non-strict mode',
      fn: () => {
        const args = ['--foo=bar', 'x'];
        const result = parseArgs(args);
        assertDeepEqual(result.flags, { foo: 'bar' });
        assertDeepEqual(args, ['x']);
      },
    },
    {
      name: 'Duplicate non-array flags: last wins (string)',
      fn: () => {
        const args = ['--x=1', '--x=2'];
        const result = parseArgs(args);
        assertDeepEqual(result.flags, { x: '2' });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Duplicate non-array numeric flags: last wins (number)',
      fn: () => {
        const args = ['--y=1', '--y=2'];
        const result = parseArgs(args, { numericFlags: new Set(['y']) });
        assertDeepEqual(result.flags, { y: 2 });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Strict + alias requires canonical to be known',
      fn: () => {
        let thrown = false;
        try {
          parseArgs(['-v'], {
            strict: true,
            aliases: { v: 'verbose' },
          });
        } catch (e) {
          thrown = true;
          assertEqual((e as Error).message, 'Unknown flag: -v');
        }
        assertEqual(thrown, true);
      },
    },
    {
      name: 'Alias with value and numeric coercion (short and long)',
      fn: () => {
        const args = ['-p=3000', '--p', '4000', 'z'];
        const result = parseArgs(args, {
          strict: true,
          aliases: { p: 'port' },
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['port']),
          numericFlags: new Set(['port']),
        });
        assertDeepEqual(result.flags, { port: 4000 });
        assertDeepEqual(args, ['z']);
      },
    },
    {
      name: 'Aliased long flag resolves under strict mode',
      fn: () => {
        const args = ['--v'];
        const result = parseArgs(args, {
          strict: true,
          aliases: { v: 'verbose' },
          booleanFlags: new Set(['verbose']),
        });
        assertDeepEqual(result.flags, { verbose: true });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Value after "=" can contain "=" characters',
      fn: () => {
        const args = ['--data=a=b=c', 'x'];
        const result = parseArgs(args);
        assertDeepEqual(result.flags, { data: 'a=b=c' });
        assertDeepEqual(args, ['x']);
      },
    },
    {
      name: 'Array flag mixing booleans and values',
      fn: () => {
        const args = ['--tag', '--tag=a', '--tag', 'b'];
        const result = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['tag']),
          arrayFlags: new Set(['tag']),
        });
        assertDeepEqual(result.flags, { tag: [true, 'a', 'b'] });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Array numeric flag accumulates and coerces values',
      fn: () => {
        const args = ['--n', '1', '--n=2', '--n', '-3'];
        const result = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['n']),
          arrayFlags: new Set(['n']),
          numericFlags: new Set(['n']),
        });
        assertDeepEqual(result.flags, { n: [1, 2, -3] });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Short expects value but next is a flag: do not consume',
      fn: () => {
        const args = ['-p', '-x'];
        const result = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['p']),
        });
        assertDeepEqual(result.flags, { p: true, x: true });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Only double-dash with nothing after',
      fn: () => {
        const args = ['--'];
        const result = parseArgs(args);
        assertDeepEqual(result.flags, {});
        assertDeepEqual(result.raw, []);
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Dangerous key via alias is ignored (even with value)',
      fn: () => {
        const args = ['--p=x', '--p', 'y'];
        const result = parseArgs(args, {
          aliases: { p: '__proto__' },
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['__proto__']),
        });
        assertDeepEqual(result.flags, {});
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Dangerous key ignored even when declared as array flag',
      fn: () => {
        const args = ['--__proto__=x', '--__proto__=y'];
        const result = parseArgs(args, {
          arrayFlags: new Set(['__proto__']),
        });
        assertDeepEqual(result.flags, {});
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Value starting with "--" is treated as data, not a flag',
      fn: () => {
        const args = ['--msg=--value'];
        const result = parseArgs(args);
        assertDeepEqual(result.flags, { msg: '--value' });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Short group: last consumes next value',
      fn: () => {
        const args = ['-abp', '3000', 'x'];
        const result = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['p']),
          numericFlags: new Set(['p']),
        });
        assertDeepEqual(result.flags, { a: true, b: true, p: 3000 });
        assertDeepEqual(args, ['x']);
      },
    },
    {
      name: 'Numeric vs boolean precedence keeps string when NaN',
      fn: () => {
        const args = ['--x=false', '--n=NaN'];
        const result = parseArgs(args, {
          numericFlags: new Set(['x', 'n']),
          booleanFlags: new Set(['x']),
        });
        assertDeepEqual(result.flags, { x: 'false', n: 'NaN' });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Strict mode: unknown in short group throws for first char',
      fn: () => {
        let thrown = false;
        try {
          parseArgs(['-xz'], { strict: true });
        } catch (e) {
          thrown = true;
          assertEqual((e as Error).message, 'Unknown flag: -x');
        }
        assertEqual(thrown, true);
      },
    },
    {
      name: 'Strict: unknown long with equals throws',
      fn: () => {
        let thrown = false;
        try {
          parseArgs(['--x=5'], { strict: true });
        } catch (e) {
          thrown = true;
          assertEqual((e as Error).message, 'Unknown flag: --x');
        }
        assertEqual(thrown, true);
      },
    },
    {
      name: 'Long expects value but next starts with "--": do not consume',
      fn: () => {
        const args = ['--msg', '--value', 'pos'];
        const result = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['msg']),
        });
        assertDeepEqual(result.flags, { msg: true, value: true });
        assertDeepEqual(args, ['pos']);
      },
    },
    {
      name: 'Long expects value but next is "-" (standalone): do not consume',
      fn: () => {
        const args = ['--name', '-', 'file'];
        const result = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['name']),
        });
        assertDeepEqual(result.flags, { name: true });
        // '-' remains positional
        assertDeepEqual(args, ['-', 'file']);
      },
    },
    {
      name: 'Unsupported "-p3000" is treated as short group (documented behavior)',
      fn: () => {
        const args = ['-p3000', 'x'];
        const result = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['p']),
          numericFlags: new Set(['p']),
        });
        // p is boolean, digits become short flags '3','0','0','0'
        assertDeepEqual(result.flags, { p: true, 3: true, 0: true });
        assertDeepEqual(args, ['x']);
      },
    },
    {
      name: 'Hyphenated long flag name and alias',
      fn: () => {
        const args = ['--max-retries=3', '-m', '4'];
        const result = parseArgs(args, {
          aliases: { m: 'max-retries' },
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['max-retries']),
          numericFlags: new Set(['max-retries']),
        });
        assertDeepEqual(result.flags, { 'max-retries': 4 });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Empty long flag name "--=value": accepted in non-strict, thrown in strict',
      fn: () => {
        // non-strict: produces key ""
        const a1 = ['--=v'];
        const r1 = parseArgs(a1);
        assertDeepEqual(r1.flags, { '': 'v' });
        assertDeepEqual(a1, []);
        // strict: throws
        let thrown = false;
        try {
          parseArgs(['--=v'], { strict: true });
        } catch (e) {
          thrown = true;
          assertEqual((e as Error).message, 'Unknown flag: --');
        }
        assertEqual(thrown, true);
      },
    },
    {
      name: 'Array flags accumulate via alias',
      fn: () => {
        const args = ['-f', 'a.txt', '--f=b.txt', '--f', 'c.txt', 'pos'];
        const result = parseArgs(args, {
          aliases: { f: 'file' },
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['file']),
          arrayFlags: new Set(['file']),
        });
        assertDeepEqual(result.flags, { file: ['a.txt', 'b.txt', 'c.txt'] });
        assertDeepEqual(args, ['pos']);
      },
    },
    {
      name: 'Numeric flags reject Infinity/-Infinity under strict decimal',
      fn: () => {
        const args = ['--n=Infinity', '--m=-Infinity'];
        const result = parseArgs(args, { numericFlags: new Set(['n', 'm']) });
        assertDeepEqual(result.flags, { n: 'Infinity', m: '-Infinity' });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Numeric vs boolean precedence when numeric succeeds',
      fn: () => {
        const args = ['--f=1'];
        const result = parseArgs(args, {
          numericFlags: new Set(['f']),
          booleanFlags: new Set(['f']),
        });
        assertDeepEqual(result.flags, { f: 1 });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Long expects value but next is short group: do not consume',
      fn: () => {
        const args = ['--name', '-ab', 'rest'];
        const result = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['name']),
        });
        assertDeepEqual(result.flags, { name: true, a: true, b: true });
        assertDeepEqual(args, ['rest']);
      },
    },
    {
      name: 'Short group with invalid first char "=" becomes positional (edge)',
      fn: () => {
        const args = ['-=value', 'x'];
        const result = parseArgs(args);
        // Replaced with 'value' at same index
        assertDeepEqual(result.flags, {});
        assertDeepEqual(args, ['value', 'x']);
      },
    },
    {
      name: 'Multiple "--" separators: only the first terminates parsing',
      fn: () => {
        const args = ['a', '--x', '--', '--y', '--', 'z'];
        const result = parseArgs(args);
        assertDeepEqual(result.flags, { x: true });
        assertDeepEqual(result.raw, ['--y', '--', 'z']);
        assertDeepEqual(args, ['a']);
      },
    },
    {
      name: 'Strict + short with equals unknown throws unknown',
      fn: () => {
        let thrown = false;
        try {
          parseArgs(['-x=1'], { strict: true });
        } catch (e) {
          thrown = true;
          assertEqual((e as Error).message, 'Unknown flag: -x');
        }
        assertEqual(thrown, true);
      },
    },
    {
      name: 'Strict: known short with equals but no value-acceptance throws',
      fn: () => {
        let thrown = false;
        try {
          parseArgs(['-v=1'], {
            strict: true,
            // v is known as boolean-only, not in value-accepting set
            booleanFlags: new Set(['v']),
          });
        } catch (e) {
          thrown = true;
          assertEqual((e as Error).message, 'Flag -v does not accept a value (got "=...")');
        }
        assertEqual(thrown, true);
      },
    },
    {
      name: 'Aliased long with equals resolves under strict',
      fn: () => {
        const args = ['--m=5'];
        const result = parseArgs(args, {
          strict: true,
          aliases: { m: 'max-retries' },
          numericFlags: new Set(['max-retries']),
        });
        assertDeepEqual(result.flags, { 'max-retries': 5 });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Alias short consumes next value (strict + numeric)',
      fn: () => {
        const args = ['-p', '3001', 'end'];
        const result = parseArgs(args, {
          strict: true,
          aliases: { p: 'port' },
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['port']),
          numericFlags: new Set(['port']),
        });
        assertDeepEqual(result.flags, { port: 3001 });
        assertDeepEqual(args, ['end']);
      },
    },
    {
      name: 'Negative number without -- is parsed as short flags (documented)',
      fn: () => {
        const args = ['-10', 'x'];
        const result = parseArgs(args);
        assertDeepEqual(result.flags, { 1: true, 0: true });
        assertDeepEqual(args, ['x']);
      },
    },
    {
      name: 'Array flag via alias accumulates with equals and next (strict)',
      fn: () => {
        const args = ['-f=a.txt', '--f', 'b.txt', 'end'];
        const result = parseArgs(args, {
          strict: true,
          aliases: { f: 'file' },
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['file']),
          arrayFlags: new Set(['file']),
        });
        assertDeepEqual(result.flags, { file: ['a.txt', 'b.txt'] });
        assertDeepEqual(args, ['end']);
      },
    },
    {
      name: 'Boolean empty value stays empty string',
      fn: () => {
        const args = ['--b='];
        const result = parseArgs(args, { booleanFlags: new Set(['b']) });
        assertDeepEqual(result.flags, { b: '' });
        assertDeepEqual(args, []);
      },
    },
    {
      name:
        'Short group with equals: last does not accept; attached negative ' + 'preserved as positional (not re-parsed)',
      fn: () => {
        const args = ['-ab=-10', 'x'];
        const result = parseArgs(args);
        // a,b are booleans; '-10' should remain positional, not turned into flags 1,0
        assertDeepEqual(result.flags, { a: true, b: true });
        assertDeepEqual(result.positionals, ['-10', 'x']);
        assertDeepEqual(args, ['-10', 'x']);
      },
    },
    {
      name:
        'Short group with equals: last does not accept; attached value ' +
        'starting with "--" is preserved as positional (not re-parsed)',
      fn: () => {
        const args = ['-ab=--not-a-flag', 'x'];
        const result = parseArgs(args);
        // a,b are booleans; '--not-a-flag' must remain positional, not parsed as a flag
        assertDeepEqual(result.flags, { a: true, b: true });
        assertDeepEqual(result.positionals, ['--not-a-flag', 'x']);
        assertDeepEqual(args, ['--not-a-flag', 'x']);
      },
    },
    {
      name: 'Strict: short group with equals; last is known but not value-accepting ' + 'throws the correct error',
      fn: () => {
        let thrown = false;
        try {
          parseArgs(['-ab=value'], {
            strict: true,
            // Make 'b' known as boolean so it is known-but-not-value-accepting
            booleanFlags: new Set(['b']),
          });
        } catch (e) {
          thrown = true;
          assertEqual((e as Error).message, 'Flag -b does not accept a value (got "=...")');
        }
        assertEqual(thrown, true);
      },
    },
    {
      name: 'Aliased long with equals resolves under strict for boolean flags',
      fn: () => {
        const args = ['--v=false', 'rest'];
        const result = parseArgs(args, {
          strict: true,
          aliases: { v: 'verbose' },
          booleanFlags: new Set(['verbose']),
        });
        assertDeepEqual(result.flags, { verbose: false });
        assertDeepEqual(args, ['rest']);
      },
    },
    {
      name: 'Short with equals: value can contain "=" characters',
      fn: () => {
        const args = ['-p=a=b=c', 'x'];
        const result = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['p']),
        });
        assertDeepEqual(result.flags, { p: 'a=b=c' });
        assertDeepEqual(args, ['x']);
      },
    },
    {
      name: 'Strict: short group with invalid first char "=" becomes positional (edge)',
      fn: () => {
        const args = ['-=value', 'x'];
        const result = parseArgs(args, { strict: true });
        assertDeepEqual(result.flags, {});
        assertDeepEqual(args, ['value', 'x']);
        assertDeepEqual(result.positionals, args);
      },
    },
    {
      name: 'Short edge: "-=" with no value becomes empty-string positional',
      fn: () => {
        const args = ['-=', 'x'];
        const result = parseArgs(args);
        assertDeepEqual(result.flags, {});
        assertDeepEqual(result.positionals, ['', 'x']);
        assertDeepEqual(args, ['', 'x']);
      },
    },
    {
      name: 'Short expects value but next is "-" (standalone): do not consume',
      fn: () => {
        const args = ['-p', '-', 'rest'];
        const result = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['p']),
        });
        assertDeepEqual(result.flags, { p: true });
        assertDeepEqual(args, ['-', 'rest']);
        assertDeepEqual(result.positionals, args);
      },
    },
    {
      name: 'Long expects value; next "-Infinity" is not consumed',
      fn: () => {
        const args = ['--n', '-Infinity', 'pos'];
        const result = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['n']),
          numericFlags: new Set(['n']),
        });
        // n stays boolean true; "-Infinity" is interpreted as short flags in non-strict.
        // To avoid over-specifying that side effect, just assert the essentials:
        assertDeepEqual(result.flags['n'], true);
        assertDeepEqual(args, ['pos']);
      },
    },
    {
      name: 'Alias and canonical both present; last assignment wins',
      fn: () => {
        const args = ['--port=2000', '-p=3000', '--p', '4000'];
        const result = parseArgs(args, {
          strict: true,
          aliases: { p: 'port' },
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['port']),
          numericFlags: new Set(['port']),
        });
        assertDeepEqual(result.flags, { port: 4000 });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Array flag not value-accepting accumulates booleans',
      fn: () => {
        const args = ['--tag', '--tag', '--tag'];
        const result = parseArgs(args, {
          arrayFlags: new Set(['tag']),
        });
        assertDeepEqual(result.flags, { tag: [true, true, true] });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Double-dash first: all following collected as raw',
      fn: () => {
        const args = ['--', '-x', '--y', 'pos'];
        const result = parseArgs(args);
        assertDeepEqual(result.flags, {});
        assertDeepEqual(result.raw, ['-x', '--y', 'pos']);
        assertDeepEqual(args, []);
      },
    },
    // Plus-signed numbers
    {
      name: 'Numeric long equals with plus sign',
      fn: () => {
        const args = ['--n=+3'];
        const r = parseArgs(args, { numericFlags: new Set(['n']) });
        assertDeepEqual(r.flags, { n: 3 });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Numeric long consumes +3 as value',
      fn: () => {
        const args = ['--n', '+3', 'x'];
        const r = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['n']),
          numericFlags: new Set(['n']),
        });
        assertDeepEqual(r.flags, { n: 3 });
        assertDeepEqual(args, ['x']);
      },
    },
    // Space-separated scientific notation (document current behavior)
    {
      name: 'Numeric long expects value: space-separated scientific notation consumed as string',
      fn: () => {
        const args = ['--n', '1e3'];
        const r = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['n']),
          numericFlags: new Set(['n']),
        });
        assertDeepEqual(r.flags, { n: '1e3' });
        assertDeepEqual(args, []);
      },
    },
    // Case-sensitive aliasing
    {
      name: 'Aliases are case-sensitive',
      fn: () => {
        let thrown = false;
        try {
          parseArgs(['-v', '--V'], {
            strict: true,
            aliases: { V: 'verbose' },
            booleanFlags: new Set(['verbose']),
          });
        } catch (e) {
          thrown = true;
          assertEqual((e as Error).message, 'Unknown flag: -v');
        }
        assertEqual(thrown, true);
      },
    },
    {
      name: 'Dangerous accessor keys dropped',
      fn: () => {
        const args = ['--__defineGetter__=x', '--__defineSetter__=y', '--__lookupGetter__=z', '--__lookupSetter__=w'];
        const r = parseArgs(args);
        assertDeepEqual(r.flags, {});
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Short boolean with equals empty value stays empty string',
      fn: () => {
        const args = ['-b='];
        const r = parseArgs(args, {
          booleanFlags: new Set(['b']),
          // Required for short flags to accept "=..."
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['b']),
        });
        assertDeepEqual(r.flags, { b: '' });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Numeric long equals with plus sign coerces to number',
      fn: () => {
        const args = ['--n=+3'];
        const result = parseArgs(args, { numericFlags: new Set(['n']) });
        assertDeepEqual(result.flags, { n: 3 });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Numeric long consumes +3 as value',
      fn: () => {
        const args = ['--n', '+3', 'x'];
        const result = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['n']),
          numericFlags: new Set(['n']),
        });
        assertDeepEqual(result.flags, { n: 3 });
        assertDeepEqual(args, ['x']);
      },
    },
    {
      name: 'Numeric long expects value: scientific notation consumed as string',
      fn: () => {
        const args = ['--n', '1e3'];
        const result = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['n']),
          numericFlags: new Set(['n']),
        });
        assertDeepEqual(result.flags, { n: '1e3' });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Numeric long expects value: hex literal consumed as string',
      fn: () => {
        const args = ['--n', '0x10'];
        const result = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['n']),
          numericFlags: new Set(['n']),
        });
        assertDeepEqual(result.flags, { n: '0x10' });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Aliases are single-hop (non-transitive)',
      fn: () => {
        let thrown = false;
        try {
          parseArgs(['-a'], {
            strict: true,
            aliases: { a: 'b', b: 'c' },
            booleanFlags: new Set(['c']),
          });
        } catch (e) {
          thrown = true;
          assertEqual((e as Error).message, 'Unknown flag: -a');
        }
        assertEqual(thrown, true);
      },
    },
    {
      name: 'Aliases are case-sensitive',
      fn: () => {
        let thrown = false;
        try {
          parseArgs(['-v'], {
            strict: true,
            aliases: { V: 'verbose' },
            booleanFlags: new Set(['verbose']),
          });
        } catch (e) {
          thrown = true;
          assertEqual((e as Error).message, 'Unknown flag: -v');
        }
        assertEqual(thrown, true);
        const args2 = ['--V'];
        const r2 = parseArgs(args2, {
          strict: true,
          aliases: { V: 'verbose' },
          booleanFlags: new Set(['verbose']),
        });
        assertDeepEqual(r2.flags, { verbose: true });
        assertDeepEqual(args2, []);
      },
    },
    {
      name: 'Dangerous accessor keys dropped (accessors and property methods)',
      fn: () => {
        const args = [
          '--__defineGetter__=x',
          '--__defineSetter__=y',
          '--__lookupGetter__=z',
          '--__lookupSetter__=w',
          '--hasOwnProperty=1',
          '--isPrototypeOf=1',
          '--propertyIsEnumerable=1',
        ];
        const r = parseArgs(args, {
          booleanFlags: new Set(['hasOwnProperty', 'isPrototypeOf', 'propertyIsEnumerable']),
        });
        assertDeepEqual(r.flags, {});
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Long expects value; next token is "--=v": do not consume; parse as separate flag',
      fn: () => {
        const args = ['--name', '--=v', 'rest'];
        const r = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['name']),
        });
        assertDeepEqual(r.flags, { name: true, '': 'v' });
        assertDeepEqual(args, ['rest']);
      },
    },
    {
      name: 'Alias cycles do not resolve transitively; unknown if canonical not known',
      fn: () => {
        let thrown = false;
        try {
          parseArgs(['--a'], {
            strict: true,
            aliases: { a: 'b', b: 'a' },
          });
        } catch (e) {
          thrown = true;
          assertEqual((e as Error).message, 'Unknown flag: --a');
        }
        assertEqual(thrown, true);
      },
    },
    {
      name: 'Long expects value; next -1e3 not consumed -> parsed as short flags ' + '(documented quirk)',
      fn: () => {
        const args = ['--n', '-1e3', 'pos'];
        const r = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['n']),
          numericFlags: new Set(['n']),
        });
        assertDeepEqual(r.flags, { n: true, 1: true, e: true, 3: true });
        assertDeepEqual(args, ['pos']);
      },
    },
    {
      name: 'Long expects value; next -0x10 not consumed -> parsed as short flags ' + '(documented quirk)',
      fn: () => {
        const args = ['--n', '-0x10', 'pos'];
        const r = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['n']),
          numericFlags: new Set(['n']),
        });
        assertDeepEqual(r.flags, { n: true, 0: true, x: true, 1: true });
        assertDeepEqual(args, ['pos']);
      },
    },
    {
      name: 'Strict: long expects value; next -1e3 causes short-flag parsing and ' + 'throws on first unknown',
      fn: () => {
        let thrown = false;
        try {
          parseArgs(['--n', '-1e3'], {
            strict: true,
            flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['n']),
            numericFlags: new Set(['n']),
          });
        } catch (e) {
          thrown = true;
          assertEqual((e as Error).message, 'Unknown flag: -1');
        }
        assertEqual(thrown, true);
      },
    },
    {
      name: 'Numeric: "0." and "-0." are rejected and remain strings',
      fn: () => {
        const args = ['--n=0.', '--m=-0.'];
        const r = parseArgs(args, { numericFlags: new Set(['n', 'm']) });
        assertDeepEqual(r.flags, { n: '0.', m: '-0.' });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Boolean long consumes next token and coerces (space-separated)',
      fn: () => {
        const args = ['--enabled', 'true', '--disabled', '0'];
        const r = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['enabled', 'disabled']),
          booleanFlags: new Set(['enabled', 'disabled']),
        });
        assertDeepEqual(r.flags, { enabled: true, disabled: false });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Boolean short consumes next token and coerces (space-separated)',
      fn: () => {
        const args = ['-e', 'false', '-f', '1'];
        const r = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['e', 'f']),
          booleanFlags: new Set(['e', 'f']),
        });
        assertDeepEqual(r.flags, { e: false, f: true });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Strict + alias to dangerous key: assignments are dropped without ' + 'throwing',
      fn: () => {
        const args = ['--p=x', '--p', 'y'];
        const r = parseArgs(args, {
          strict: true,
          aliases: { p: '__proto__' },
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['__proto__']),
        });
        assertDeepEqual(r.flags, {});
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Long expects value; "+abc" is consumed as a string value (not numeric)',
      fn: () => {
        const args = ['--name', '+abc', 'pos'];
        const r = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['name']),
        });
        assertDeepEqual(r.flags, { name: '+abc' });
        assertDeepEqual(args, ['pos']);
      },
    },
    {
      name: 'Short with equals: value that looks like flags is not re-parsed ' + '(data only)',
      fn: () => {
        const args = ['-p=--looks-like-flag', 'end'];
        const r = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['p']),
        });
        assertDeepEqual(r.flags, { p: '--looks-like-flag' });
        assertDeepEqual(args, ['end']);
      },
    },
    {
      name: 'Sparse argv with multiple holes is preserved (holes ignored)',
      fn: () => {
        const args: string[] = [];
        args[0] = '--flag';
        args[3] = 'pos';
        const r = parseArgs(args);
        assertDeepEqual(r.flags, { flag: true });
        const compactArgs: Array<string | undefined> = Array.from(args);
        assertDeepEqual(
          compactArgs.filter((x): x is string => x !== undefined),
          ['pos'],
        );
      },
    },
    {
      name: 'Duplicate non-array boolean flags: last assignment wins',
      fn: () => {
        const args = ['--x', '--x=false'];
        const r = parseArgs(args, { booleanFlags: new Set(['x']) });
        assertDeepEqual(r.flags, { x: false });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Long expects value; next "-0." not consumed -> parsed as short flags ' + '(documented quirk)',
      fn: () => {
        const args = ['--n', '-0.', 'pos'];
        const r = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['n']),
          numericFlags: new Set(['n']),
        });
        // "-0." is not a valid negative decimal; it becomes short flags: "0" and "."
        assertDeepEqual(r.flags, { n: true, 0: true, '.': true });
        assertDeepEqual(args, ['pos']);
      },
    },
    {
      name: 'Boolean long equals with surrounding whitespace is not trimmed ' + '(remains string)',
      fn: () => {
        const args = ['--b= true '];
        const r = parseArgs(args, { booleanFlags: new Set(['b']) });
        // Boolean parser does not trim; remains the original string
        assertDeepEqual(r.flags, { b: ' true ' });
        assertDeepEqual(args, []);
      },
    },
    {
      name:
        'Boolean long space-separated with surrounding whitespace is coerced ' +
        '(since token is separate, no trimming needed)',
      fn: () => {
        const args = ['--b', ' true '];
        const r = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['b']),
          booleanFlags: new Set(['b']),
        });
        // The token is " true ", but coercion checks tokens case-insensitively;
        // no trimming occurs, so this remains a string (documenting the policy).
        assertDeepEqual(r.flags, { b: ' true ' });
        assertDeepEqual(args, []);
      },
    },
    {
      name: 'Short expects value; next "-Infinity" is not consumed and becomes ' + 'short flags (documented quirk)',
      fn: () => {
        const args = ['-n', '-Infinity', 'rest'];
        const r = parseArgs(args, {
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid: new Set(['n']),
          numericFlags: new Set(['n']),
        });
        // n remains boolean true; "-Infinity" becomes short flags "I","n","f",...
        // Don't over-specify all chars; assert essentials:
        assertEqual(r.flags['n'], true);
        assertDeepEqual(args, ['rest']);
      },
    },
    {
      name: 'Strict: unknown long without equals throws (baseline sanity for strict)',
      fn: () => {
        let thrown = false;
        try {
          parseArgs(['--zz'], { strict: true });
        } catch (e) {
          thrown = true;
          assertEqual((e as Error).message, 'Unknown flag: --zz');
        }
        assertEqual(thrown, true);
      },
    },
    {
      name: 'Strict: "-p3000" is treated as short-group; first unknown throws on p',
      fn: () => {
        let thrown = false;
        try {
          parseArgs(['-p3000'], { strict: true });
        } catch (e) {
          thrown = true;
          assertEqual((e as Error).message, 'Unknown flag: -p');
        }
        assertEqual(thrown, true);
      },
    },
    {
      name: 'Prototype pollution safety drops "__proto__", "constructor", etc.',
      fn: () => {
        const args = ['--__proto__=polluted', '--constructor=true'];
        const result = parseArgs(args, {
          booleanFlags: new Set(['constructor']),
        });
        assertEqual(Object.getPrototypeOf(result.flags) === null, true);
        assertEqual(Object.prototype.hasOwnProperty.call(result.flags, '__proto__'), false);
        assertEqual(Object.prototype.hasOwnProperty.call(result.flags, 'constructor'), false);
        assertDeepEqual(result.flags, {});
        assertEqual('polluted' in {}, false);
      },
    },
  ];
  let passed = 0;
  let failed = 0;
  for (const test of tests) {
    try {
      test.fn();
      console.log(`✓ ${test.name}`);
      passed++;
    } catch (error) {
      console.error(`✗ ${test.name}`);
      console.error(`  ${String(error)}`);
      failed++;
    }
  }
  console.log(`\n${passed} passed, ${failed} failed`);
  if (failed > 0) {
    process.exit(1);
  }
}
function assertEqual<T>(actual: T, expected: T): void {
  if (actual !== expected) {
    throw new Error(`Expected ${String(expected)}, got ${String(actual)}`);
  }
}
function assertDeepEqual<T>(actual: T, expected: T): void {
  // JSON.stringify prints string "-0" as numeric 0, which is okay here but can be surprising
  const actualStr = JSON.stringify(actual, null, 2);
  const expectedStr = JSON.stringify(expected, null, 2);
  if (actualStr !== expectedStr) {
    throw new Error(`Objects not equal:\nActual:\n${actualStr}\nExpected:\n${expectedStr}`);
  }
}
runTests();
