/**
 * Drop object/prototype keys because callers may merge flags into plain objects.
 * A null-prototype result alone does not protect those downstream merges.
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
   * Boolean parsing does not trim whitespace: both "--b= true " and a separate
   * " true " token keep the original string.
   *
   * Precedence: numeric parsing (if configured) runs before boolean parsing.
   */
  booleanFlags?: Set<string>;
  /**
   * Short flag aliases (e.g., { v: 'verbose' }).
   * Aliases apply to both short (-v) and long (--v) spellings. Values are
   * stored under the resolved (canonical) name. Resolution is case-sensitive
   * and single-hop: { a: 'b', b: 'c' } resolves 'a' to 'b'. Only own properties
   * participate; the prototype chain is ignored.
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
 * Parse flags in place. The returned positionals array is the same object as
 * argv, with flags and consumed values removed. A standalone "--" ends parsing
 * and moves everything after it to raw; a lone "-" stays positional.
 *
 * Long flags:
 * - "--flag" sets true unless the flag accepts and consumes the next value.
 * - "--flag=value" always uses the attached value, including an empty string.
 *   The flag need not be value-accepting, but strict mode still requires a
 *   known canonical name (see ParserOptions.strict).
 *
 * Short flags:
 * - "-abc" sets "a", "b", and "c" to true. Only the last flag may take a value.
 * - "-c=value" uses the attached value if "c" is value-accepting. In strict
 *   mode, an unknown last flag throws before any earlier group member is parsed;
 *   a known last flag that does not accept values throws "does not accept a value".
 * - In non-strict mode, an attached value on a non-value-accepting last flag
 *   replaces the group token as a positional at the same index.
 * - "-=value" becomes positional "value"; "-=" becomes positional "" in both modes.
 * - "-p3000" is a group of short flags. Use "-p=3000" or "-p 3000" for a value.
 *
 * Value consumption:
 * - A value-accepting flag consumes the next token if it does not start with
 *   "-", or if it is a negative decimal such as "-10", "-.5", or "-0".
 * - Other tokens stay in the parsing stream. For example, "-1e3" and "-0x10"
 *   become short-flag groups in non-strict mode and may throw in strict mode.
 * - Attached values are never re-parsed, even when they look like flags.
 *
 * Sparse argv entries are skipped without compaction. Callers that need a
 * dense positional array can use argv.filter(x => x !== undefined).
 *
 * Flags use a null-prototype object. DANGEROUS_FLAG_KEYS are never stored,
 * including through aliases or when configured as array, numeric, or boolean
 * flags. Strict-mode name and value-acceptance checks still apply before storage.
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
        argv.splice(i, 1, attachedValue ?? '');
        i++;
        continue;
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
  const decimalPattern = /^[+-]?(?:\d+(?:\.\d+)?|\.\d+)$/;
  if (!decimalPattern.test(s)) {
    return null;
  }
  return parseFloat(s);
}
