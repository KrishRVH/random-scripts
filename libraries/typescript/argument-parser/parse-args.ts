/**
 * Security policy: dangerous keys
 * We intentionally ignore keys that are known to participate in prototype
 * manipulation or surprising object behavior when flag objects are merged into
 * plain objects (e.g., Object.assign({}, flags) or object spread).
 *
 * Ignored keys (conservative list):
 * - "__proto__", "prototype", "constructor"
 * - "toString", "valueOf"
 * - "__defineGetter__", "__defineSetter__", "__lookupGetter__", "__lookupSetter__"
 * - "hasOwnProperty", "isPrototypeOf", "propertyIsEnumerable"
 *
 * Notes:
 * - The returned flags object uses a null prototype to mitigate pollution via
 *   special keys, but downstream merges into plain objects may still be risky.
 *   These keys are therefore dropped entirely at parse time, even if configured
 *   as array/numeric/boolean flags or reachable via alias.
 */
const DANGEROUS_FLAG_KEYS = new Set([
  '__proto__',
  'prototype',
  'constructor',
  'toString',
  'valueOf',
  '__defineGetter__',
  '__defineSetter__',
  '__lookupGetter__',
  '__lookupSetter__',
  'hasOwnProperty',
  'isPrototypeOf',
  'propertyIsEnumerable',
]);
export interface ParsedArgs {
  /**
   * Parsed flags with their values. Uses a null-prototype object to avoid
   * prototype pollution via "__proto__", "constructor", etc.
   */
  flags: Record<string, string | boolean | number | (string | number | boolean)[]>;
  /** Remaining positional arguments in the mutated array (same reference) */
  positionals: string[];
  /** Raw unparsed arguments collected after a standalone "--" separator */
  raw: string[];
}
export interface ParserOptions {
  /**
   * Flags that accept the next argument as a value when it's "valid".
   * Valid means:
   * - For "--flag": the next token is either not "-" prefixed OR a negative
   *   decimal number (e.g., -10, -.5, -0). Otherwise, the flag remains boolean
   *   true (fallback).
   * - For grouped short flags "-abc": only the last short flag may take a
   *   value; it may come from "=value" (e.g., "-c=value") or from the next
   *   token under the same rule as above.
   *
   * Note: this parser does NOT support "-p3000" (value stuck to the flag
   * without "="). Use "-p=3000" or "-p 3000".
   */
  flagsThatAcceptTheNextArgumentAsAValueIfItsValid?: Set<string>;
  /**
   * Flags that can be repeated to accumulate values into an array.
   * If a flag is in arrayFlags but NOT in
   * flagsThatAcceptTheNextArgumentAsAValueIfItsValid, repeats will accumulate
   * booleans (e.g., "--tag --tag" => { tag: [true, true] }). This is allowed
   * but uncommon; prefer listing such flags in the value-accepting set.
   */
  arrayFlags?: Set<string>;
  /**
   * Numeric flags (strict decimal parsing)
   * - Accepted: optional sign "+" or "-", integers "123", or decimals "123.45"
   *   and ".5" (and "-.5"). "-0" is preserved as negative zero.
   * - Rejected (value remains a string): scientific/exponent notation ("1e3",
   *   "-1e3"), non-decimal bases ("0x10", "0o10", "0b10"), "Infinity",
   *   "-Infinity", "NaN", and forms like "0." or "-0.".
   * - Trimming: numeric values are trimmed of surrounding whitespace before
   *   validation and parsing (e.g., "--n=  +3  " -> 3).
   * - Empty value via equals ("--n=") coerces to 0.
   * - Precedence: if a flag is both numeric and boolean, numeric parsing runs
   *   first; on failure, the original string is kept (no boolean coercion).
   * - Assignment: for non-array numeric flags, last assignment wins.
   */
  numericFlags?: Set<string>;
  /**
   * Flags that should be parsed as booleans.
   * True: "true", "1", "yes", "on". False: "false", "0", "no", "off".
   * Case-insensitive. Unrecognized literals remain strings.
   * - Note: Boolean parsing does not trim whitespace. The entire next token is checked literally.
   *  For equals-form values,
   *   "--b= true " stays the string " true ". For space-separated values,
   *   the entire next token is checked literally.
   *
   * Precedence: numeric parsing (if configured) runs before boolean parsing.
   */
  booleanFlags?: Set<string>;
  /**
   * Short flag aliases (e.g., { v: 'verbose' }).
   * Aliases apply to both short (-v) and long (--v) spellings. Values are
   * stored under the resolved (canonical) name.
   */
  aliases?: Record<string, string>;
  /**
   * Unknown flags policy:
   * - strict === false (default): unknown flags are accepted, parsed as
   *   boolean true or strings (if a value is attached/consumed), and
   *   removed from argv.
   * - strict === true: unknown flags throw.
   *
   * Aliases in strict mode:
   * - The resolved (canonical) name must be present in at least one of the
   *   known sets (value-accepting, array, numeric, boolean). An alias
   *   mapping alone is not sufficient for a flag to be considered known.
   *
   * "Unknown" means not present in any of:
   * - flagsThatAcceptTheNextArgumentAsAValueIfItsValid
   * - arrayFlags
   * - numericFlags
   * - booleanFlags
   */
  strict?: boolean;
}
/**
 * Parse and MUTATE a command-line arguments array into flags, positionals, and
 * raw extras. In-place mutation keeps a single authoritative argv instance for
 * callers that pass positionals onward after flag extraction.
 *
 * Behavior highlights:
 * - Mutates the passed-in argv, removing parsed flags and any consumed values.
 * - positionals is the exact same array reference as argv (post-mutation).
 * - "--" stops flag parsing; everything after is collected into "raw".
 *
 * Long flags:
 * - "--flag" => boolean true (unless a value is valid and consumed)
 * - "--flag=value" => attached value is always used (including empty "")
 *   Note: This is accepted even if the flag is not in the
 *   flagsThatAcceptTheNextArgumentAsAValueIfItsValid set. In strict mode, the
 *   flag must still be "known" (by canonical name) or it throws.
 *
 * Short flags:
 * - "-abc" => "-a", "-b", "-c" set to true
 * - Only the last short flag can take a value:
 *   - "-c=value" => value for "c" (in strict mode, "c" must be known AND
 *     value-accepting)
 *   - "-c value" => consumes the next token if valid (same rule as long)
 * - If "-abc=value" is used but "c" does not accept a value:
 *   - strict === true: throws "does not accept a value"
 *   - strict === false: parses "-a", "-b", "-c" and preserves "value" as a
 *     positional token at the same index (not re-parsed)
 * - Unsupported "-p3000" is treated as a short group per policy; use "-p=3000"
 *   or "-p 3000".
 *
 * Value consumption heuristics (when a flag is in
 * flagsThatAcceptTheNextArgumentAsAValueIfItsValid):
 * - For a long flag "--flag":
 *   - The next token is consumed as the value if:
 *     - it does NOT start with "-" (e.g., "foo", "+3", "1e3", "0x10"), OR
 *     - it is a valid negative decimal per isNegativeNumber (e.g., "-10", "-.5", "-0")
 *   - Otherwise, the flag remains boolean true and the next token is parsed
 *     normally at its position. This means tokens like "-1e3" or "-0x10"
 *     are not consumed and will be interpreted as short-flag groups in
 *     non-strict mode (e.g., "-1e3" -> "-1", "-e", "-3"), or will throw on
 *     the first unknown short in strict mode.
 *
 * - For grouped short flags "-xyz":
 *   - Only the last short may take a value.
 *   - With "-z=value": the attached value is used. In strict mode, the last
 *     short must be known and value-accepting; otherwise an error is thrown.
 *   - With "-z value": the next token is consumed under the same rule as long
 *     flags (see above).
 *   - If an attached value is provided for a last short that does NOT accept
 *     a value, the token is replaced with that value as a positional and is
 *     not re-parsed.
 *
 * - Values provided via "=..." (long or short) are never re-parsed, even if
 *   they look like flags (e.g., "--msg=--help" is stored as the string "--help").
 *
 * - A lone "-" is always treated as a positional token.
 *
 * - Unsupported "-p3000" is treated as a grouped short sequence; use "-p=3000"
 *   or "-p 3000" instead.
 *
 * Unknown flags policy:
 * - strict === false (default): unknown flags are accepted, parsed as boolean
 *   true or strings (if a value is attached/consumed), and removed from argv.
 * - strict === true: unknown flags throw. An alias mapping alone is not
 *   sufficient; the resolved canonical name must appear in at least one known
 *   set (value-accepting, array, numeric, boolean).
 *
 * Aliases
 * - Single-hop only: aliases[flag] is used if present; alias chains are not
 *   followed (e.g., { a: 'b', b: 'c' } resolves 'a' -> 'b').
 * - Case-sensitive.
 * - In strict mode, the resolved (canonical) name must appear in at least one
 *   of the known sets (value-accepting, array, numeric, boolean). An alias
 *   mapping alone does not make a flag "known".
 *
 * Sparse argv
 * - The parser skips undefined entries (sparse arrays) during scanning but does
 *   not compact them. After parsing, the mutated argv (returned as "positionals")
 *   may still contain holes. Callers who rely on dense arrays can compact via
 *   argv.filter(x => x !== undefined) after parsing.
 *
 * Dangerous keys policy
 * - The following keys are dropped entirely (not stored) to mitigate prototype
 *   pollution when flags objects are merged into plain objects:
 *   "__proto__", "prototype", "constructor", "toString", "valueOf",
 *   "__defineGetter__", "__defineSetter__", "__lookupGetter__",
 *   "__lookupSetter__", "hasOwnProperty", "isPrototypeOf",
 *   "propertyIsEnumerable".
 * - Dropping applies even if the key is:
 *   - configured as array/numeric/boolean,
 *   - or reached via an alias,
 *   - and in both strict and non-strict modes.
 * - In strict mode this does not throw; the assignment is silently dropped.
 *
 * Security hardening:
 * - The returned flags object has a null prototype to avoid prototype pollution
 *   via special keys like "__proto__" or "constructor".
 *
 * Note on tokens starting with "-":
 * - After a value-accepting flag, a next token starting with "-" is consumed
 *   as a value only if it is a valid negative decimal per isNegativeNumber.
 *   Otherwise it is not consumed and is parsed normally at its position.
 *   In non-strict mode this often means the token becomes a short-flag group
 *   (e.g., "-1e3" -> flags "1", "e", "3"). In strict mode it throws at the
 *   first unknown short.
 */
export function parseArgs(argv: string[], options: ParserOptions = {}): ParsedArgs {
  const {
    flagsThatAcceptTheNextArgumentAsAValueIfItsValid = new Set<string>(),
    arrayFlags = new Set<string>(),
    numericFlags = new Set<string>(),
    booleanFlags = new Set<string>(),
    aliases = {},
    strict = false,
  } = options;
  const flags = Object.create(null) as Record<string, string | boolean | number | (string | number | boolean)[]>;
  const raw: string[] = [];
  let i = 0;
  while (i < argv.length) {
    const arg = argv[i];
    // Safety check for sparse arrays
    if (arg === undefined) {
      i++;
      continue;
    }
    // Double dash stops flag parsing; collect rest as raw
    if (arg === '--') {
      raw.push(...argv.splice(i + 1));
      argv.splice(i, 1); // remove the '--' itself
      break;
    }
    // Long flag: --flag or --flag=value
    if (arg.startsWith('--') && arg.length > 2) {
      const equalIndex = arg.indexOf('=');
      let flagName: string;
      let resolvedName: string;
      let value: string | boolean | number = true;
      let consumeNext = false;
      if (equalIndex !== -1) {
        // --flag=value format (value can be empty "")
        flagName = arg.slice(2, equalIndex);
        resolvedName = resolveAlias(flagName, aliases);
        value = arg.slice(equalIndex + 1);
      } else {
        // --flag format
        flagName = arg.slice(2);
        resolvedName = resolveAlias(flagName, aliases);
        if (flagsThatAcceptTheNextArgumentAsAValueIfItsValid.has(resolvedName) && i + 1 < argv.length) {
          const nextArg = argv[i + 1];
          if (nextArg !== undefined) {
            // Accept negative numbers or any non-flag token
            if (!nextArg.startsWith('-') || isNegativeNumber(nextArg)) {
              value = nextArg;
              consumeNext = true;
            }
          }
        }
      }
      if (
        strict &&
        !isKnownFlag(
          resolvedName,
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid,
          arrayFlags,
          numericFlags,
          booleanFlags,
        )
      ) {
        throw new Error(`Unknown flag: --${flagName}`);
      }
      // Parse value based on flag type
      value = parseValue(value, resolvedName, numericFlags, booleanFlags);
      // Store the flag value
      storeFlag(flags, resolvedName, value, arrayFlags);
      // Remove from argv
      if (consumeNext) {
        argv.splice(i, 2); // flag and its value
      } else {
        argv.splice(i, 1); // just the flag
      }
      continue; // don't increment i; elements shifted
    }
    // Short flag(s): -a or -abc or -p value or "-c=value"
    if (arg.startsWith('-') && arg.length > 1 && arg[1] !== '-') {
      let shortFlags = arg.slice(1);
      // Support "-p=3000" or "-abc=value" (value applies to last short flag)
      let attachedValue: string | null = null;
      const eqIdx = shortFlags.indexOf('=');
      if (eqIdx !== -1) {
        attachedValue = shortFlags.slice(eqIdx + 1);
        shortFlags = shortFlags.slice(0, eqIdx);
      }
      // Edge: "-=value" or "-=" -> no actual short flags; treat as positional.
      // Policy:
      // - "-=value" => replace token with "value" (not re-parsed)
      // - "-="      => replace token with "" (empty string, not re-parsed)
      if (shortFlags.length === 0) {
        if (attachedValue !== null) {
          argv.splice(i, 1, attachedValue);
          i++;
          continue;
        } else {
          argv.splice(i, 1, '');
          i++;
          continue;
        }
      }
      // With an attached "=value", in strict mode ensure:
      // 1) the last short is known; otherwise throw unknown first
      // 2) if known but not value-accepting, throw "does not accept a value"
      if (attachedValue !== null) {
        const lastShort = shortFlags[shortFlags.length - 1];
        if (lastShort === undefined) {
          throw new Error('Missing short flag before attached value');
        }
        const lastResolved = resolveAlias(lastShort, aliases);
        const lastIsKnown = isKnownFlag(
          lastResolved,
          flagsThatAcceptTheNextArgumentAsAValueIfItsValid,
          arrayFlags,
          numericFlags,
          booleanFlags,
        );
        const lastExpects = flagsThatAcceptTheNextArgumentAsAValueIfItsValid.has(lastResolved);
        if (strict && !lastIsKnown) {
          throw new Error(`Unknown flag: -${lastShort}`);
        }
        if (strict && !lastExpects) {
          throw new Error(`Flag -${lastShort} does not accept a value (got "=...")`);
        }
      }
      let consumeNext = false;
      let consumedByEquals = false;
      for (let j = 0; j < shortFlags.length; j++) {
        const ch = shortFlags[j];
        if (ch === undefined || ch === '') {
          continue;
        }
        const resolvedName = resolveAlias(ch, aliases);
        if (
          strict &&
          !isKnownFlag(
            resolvedName,
            flagsThatAcceptTheNextArgumentAsAValueIfItsValid,
            arrayFlags,
            numericFlags,
            booleanFlags,
          )
        ) {
          throw new Error(`Unknown flag: -${ch}`);
        }
        let value: string | boolean | number = true;
        const isLast = j === shortFlags.length - 1;
        const expectsValue = flagsThatAcceptTheNextArgumentAsAValueIfItsValid.has(resolvedName);
        if (isLast && expectsValue) {
          if (attachedValue !== null) {
            value = attachedValue;
            consumedByEquals = true;
          } else if (i + 1 < argv.length) {
            const nextArg = argv[i + 1];
            if (nextArg !== undefined) {
              if (!nextArg.startsWith('-') || isNegativeNumber(nextArg)) {
                value = nextArg;
                consumeNext = true;
              }
            }
          }
        }
        value = parseValue(value, resolvedName, numericFlags, booleanFlags);
        storeFlag(flags, resolvedName, value, arrayFlags);
      }
      // If there was an attached value (e.g., "-abc=value") but the last short
      // flag does not accept a value, preserve it as positional.
      if (attachedValue !== null && !consumedByEquals) {
        argv.splice(i, 1, attachedValue);
        i++; // ensure it is not re-interpreted as a flag in this pass
        continue;
      }
      // Remove the flag token and optionally the consumed next arg
      if (consumeNext) {
        argv.splice(i, 2);
      } else {
        argv.splice(i, 1);
      }
      continue;
    }
    // Not a flag, move to next argument
    i++;
  }
  // The mutated argv now contains only positionals
  return { flags, positionals: argv, raw };
}

/**
 * Checks if the next token is a negative number eligible to be consumed as a
 * value by a flag. Strict decimal only; scientific notation is NOT allowed.
 * Infinity/-Infinity are excluded and must be provided via equals.
 */
function isNegativeNumber(str: string): boolean {
  // Accept "-123", "-123.45", "-.5", "-0"
  return /^-(?:\d+(?:\.\d+)?|\.\d+)$/.test(str);
}

/**
 * Storage semantics
 * - For flags not listed in arrayFlags, the last assignment wins:
 *   e.g., "--x=1 --x=2" -> { x: "2" } (or number 2 if numeric).
 * - For flags listed in arrayFlags, values accumulate in order of appearance:
 *   e.g., "--tag a --tag=b --tag c" -> { tag: ["a", "b", "c"] }.
 */
function storeFlag(
  flags: Record<string, string | boolean | number | (string | number | boolean)[]>,
  name: string,
  value: string | boolean | number,
  arrayFlags: Set<string>,
): void {
  // Do not persist dangerous keys; they’re discarded for safety.
  if (DANGEROUS_FLAG_KEYS.has(name)) {
    return;
  }
  if (arrayFlags.has(name)) {
    const existing = flags[name];
    if (Array.isArray(existing)) {
      existing.push(value);
    } else if (existing !== undefined) {
      flags[name] = [existing, value];
    } else {
      flags[name] = [value];
    }
  } else {
    flags[name] = value;
  }
}

/**
 * Resolve a flag name through aliases using own-property lookup only.
 * - Single-hop only: returns aliases[flag] if present, otherwise the flag.
 *   Alias chains are NOT followed (e.g., { a: 'b', b: 'c' } resolves 'a' -> 'b').
 * - Prototype chain is ignored for safety and predictability.
 */
function resolveAlias(flag: string, aliases: Record<string, string>): string {
  if (Object.prototype.hasOwnProperty.call(aliases, flag)) {
    return aliases[flag] ?? flag;
  }
  return flag;
}

/** Checks if passed arg was defined in parserOptions */
function isKnownFlag(
  flag: string,
  flagsThatAcceptTheNextArgumentAsAValueIfItsValid: Set<string>,
  arrayFlags: Set<string>,
  numericFlags: Set<string>,
  booleanFlags: Set<string>,
): boolean {
  return (
    flagsThatAcceptTheNextArgumentAsAValueIfItsValid.has(flag) ||
    arrayFlags.has(flag) ||
    numericFlags.has(flag) ||
    booleanFlags.has(flag)
  );
}
function parseValue(
  value: string | boolean | number,
  flagName: string,
  numericFlags: Set<string>,
  booleanFlags: Set<string>,
): string | boolean | number {
  // Already parsed
  if (typeof value === 'boolean' || typeof value === 'number') {
    return value;
  }
  // Numeric (strict decimal only)
  if (numericFlags.has(flagName)) {
    const parsed = parseNumericStrict(value);
    if (parsed !== null) {
      return parsed;
    }
    // Numeric precedence: keep the original string and do NOT parse as boolean
    return value;
  }
  // Boolean (case-insensitive)
  if (booleanFlags.has(flagName)) {
    const lowerValue = value.toLowerCase();
    if (lowerValue === 'true' || lowerValue === '1' || lowerValue === 'yes' || lowerValue === 'on') {
      return true;
    }
    if (lowerValue === 'false' || lowerValue === '0' || lowerValue === 'no' || lowerValue === 'off') {
      return false;
    }
    return value;
  }
  return value;
}
/**
 * Strict decimal parser:
 * - Accepts: optional sign, decimal ints, or decimals with fraction
 *   (e.g., "123", "-0", "123.45", ".5", "-.5")
 * - Rejects: scientific/exponent notation, hex/octal/binary, Infinity/NaN
 * - Special case: empty string ("") coerces to 0 for numeric flags
 * Returns number on success, or null on failure.
 */
function parseNumericStrict(value: string): number | null {
  if (value === '') {
    return 0;
  }
  const s = value.trim();
  if (
    s === 'Infinity' ||
    s === '+Infinity' ||
    s === '-Infinity' ||
    s.toLowerCase() === 'nan' ||
    /^[-+]?0[xob]/i.test(s) || // 0x, 0o, 0b
    /[eE]/.test(s) // disallow scientific/exponent notation
  ) {
    return null;
  }
  const decimalPattern = /^[+-]?(?:\d+(?:\.\d+)?|\.\d+)$/;
  if (!decimalPattern.test(s)) {
    return null;
  }
  const num = parseFloat(s);
  if (Number.isNaN(num)) {
    return null;
  }
  return num;
}
