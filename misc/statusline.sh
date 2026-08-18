#!/bin/sh
#
# Claude Code statusline — one line, Codex-CLI style.
#
#   [PT] Opus 5 med · myrepo · main · +2 ~1 · ████░░░░░░ 42% · 5h 82% · 7d 93% · 1.2M in · 45K out · $1.23
#   \__/ \_________/  \____/   \__/  \____/   \____________/   \_____/   \_____/   \_______________/   \___/
#   badge   model      dir    branch  dirty     context         5h left   7d left    session tokens     cost
#
# Claude Code pipes a JSON payload on stdin and renders whatever this prints.
# Every segment is independent: any whose data is missing (fresh session,
# non-git directory, plugin not installed) is simply omitted.
#
# Note: the 5h and 7d numbers are percent REMAINING; the context bar is
# percent USED. That asymmetry is deliberate — you want to know how much
# budget is left, but how much context is spent.
#
# The token counts are SESSION CUMULATIVE, not the current context window.
# The payload's .context_window.total_*_tokens describe only what is resident
# in the window right now, which shrinks on compaction and never reflects what
# the session as a whole has consumed. So they are summed out of the session's
# own transcript instead — see session_tokens() below.
#
# ---------------------------------------------------------------------------
# Install (per machine)
#   1. cp statusline.sh ~/.claude/statusline.sh && chmod +x ~/.claude/statusline.sh
#   2. Add to ~/.claude/settings.json:
#        "statusLine": { "type": "command", "command": "~/.claude/statusline.sh" }
#   3. Restart Claude Code.
#
# Requires: POSIX sh + core utilities, jq, awk. Optional: git (branch/dirty).
# Also needs a UTF-8 terminal with a font covering U+2588/U+2591 and U+00B7;
# without it the bar and separators render as tofu boxes. Set SL_ASCII=1 to
# fall back to ASCII-only glyphs.
#
# Portability: written for /bin/sh (tested under dash), no bashisms, no GNU-only
# flags. Machine-specific paths are confined to the Configuration block below.
# ---------------------------------------------------------------------------

# --- Configuration ---------------------------------------------------------

# Claude Code's config dir. Honour CLAUDE_CONFIG_DIR so non-default installs
# and multi-profile setups keep working without editing this script.
CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

# Scratch space for the memoised session token totals. Kept out of CONFIG_DIR
# so nothing here ever pollutes synced/versioned config.
CACHE_DIR="${TMPDIR:-/tmp}/claude-statusline-${USER:-$LOGNAME}"

BAR_WIDTH=10          # cells in the context meter
CTX_WARN=70           # context % at which the bar turns amber
CTX_CRIT=90           # context % at which the bar turns red

if [ "${SL_ASCII:-0}" = 1 ]; then
  GLYPH_FILL='#'; GLYPH_EMPTY='.'; GLYPH_SEP='|'
else
  GLYPH_FILL='█'; GLYPH_EMPTY='░'; GLYPH_SEP='·'
fi

# --- Theme -----------------------------------------------------------------
# 256-colour, deliberately desaturated. Retheming means editing only this block.

sgr()   { printf '\033[%sm' "$1"; }        # raw SGR sequence
fg()    { sgr "38;5;$1"; }                 # 256-colour foreground

C_BADGE=$(fg 108)              # sage
C_MODEL=$(fg 173)              # soft orange
C_PATH=$(fg 149)               # lime
C_BRANCH=$(fg 74)              # steel blue
C_ADD=$(fg 71)                 # sage green
C_MOD=$(fg 143)                # olive amber
C_DEL=$(fg 167)                # soft brick red
C_5H=$(fg 181)                 # pale rose (paler sibling of C_7D)
C_7D=$(fg 167)                 # soft brick red
C_IN=$(fg 173)                 # soft orange
C_OUT=$(sgr '1;38;5;216')      # bold light orange ("neon")
C_COST=$(fg 108)               # dollar-bill green
C_ERR=$(fg 203)                # alarm red, for degraded-mode warnings
C_OK=$(fg 76)                  # context bar, healthy
C_MID=$(fg 178)                # context bar, warning
C_HI=$(fg 203)                 # context bar, critical
C_DIM=$(sgr 2)                 # separators
RST=$(sgr 0)                   # closes any of the above

SEP="$C_DIM $GLYPH_SEP $RST"

# --- Helpers ---------------------------------------------------------------

# Append a segment, inserting the separator only between segments (never
# leading). This is what makes every segment independently omittable.
line=''
add() {
  [ -n "$line" ] && line="$line$SEP"
  line="$line$1"
}

# Round to a whole number. Tolerates empty/garbage input by yielding 0.
round() { awk -v v="$1" 'BEGIN { printf "%.0f", v }'; }

# Percentage remaining, given percentage used.
pct_left() { awk -v u="$1" 'BEGIN { printf "%.0f", 100 - u }'; }

# Abbreviate a token count: 812 · 4.2K · 45K · 1.2M · 3.4B.
# One decimal only below 10 of a unit, which caps every result at four cells —
# the segment must not keep resizing the line as a session grows. Thresholds
# are the .5 rounding boundaries rather than flat powers of ten, so 999_600
# reads "1.0M" instead of "1000K".
human() {
  awk -v n="$1" 'BEGIN {
    if (n < 999.5)          { printf "%.0f", n; exit }
    if      (n >= 999.5e6)  { v = n / 1e9; s = "B" }
    else if (n >= 999.5e3)  { v = n / 1e6; s = "M" }
    else                    { v = n / 1e3; s = "K" }
    printf (v < 9.95 ? "%.1f%s" : "%.0f%s"), v, s
  }'
}

# Threshold colour for a context percentage.
ctx_color() {
  if   [ "$1" -ge "$CTX_CRIT" ]; then printf '%s' "$C_HI"
  elif [ "$1" -ge "$CTX_WARN" ]; then printf '%s' "$C_MID"
  else                                printf '%s' "$C_OK"
  fi
}

# Render an N-of-BAR_WIDTH meter for a percentage.
# Any non-zero percentage fills at least one cell: an entirely empty bar
# should mean "nothing used", not merely "used a little".
meter() {
  awk -v pct="$1" -v width="$BAR_WIDTH" -v on="$GLYPH_FILL" -v off="$GLYPH_EMPTY" 'BEGIN {
    n = int(pct * width / 100)
    if (n > width)        n = width
    if (n < 1 && pct > 0) n = 1
    for (i = 0; i < width; i++) printf "%s", (i < n ? on : off)
  }'
}

# git, configured to never take a lock or touch the index — a statusline must
# not interfere with a concurrent interactive git session. Reads the global
# $cwd, which the Payload section below resolves before any segment runs.
git_ro() { git --no-optional-locks -C "$cwd" "$@" 2>/dev/null; }

# Session-cumulative input/output tokens over the given transcript files,
# printed as "<in> <out>".
#
# Input counts fresh, cache-write and cache-read tokens together: all three are
# input to the model and all three are billed, so excluding cache reads would
# make a long session look an order of magnitude cheaper than it was.
#
# jq emits one row per usage-bearing line and awk does the dedupe and the
# arithmetic. Slurping instead (jq -s) would be shorter but holds every parsed
# line in memory at once — 34MB peak on a 5MB transcript against 4MB streaming,
# for a process that runs every few seconds.
#
# The dedupe matters: an assistant turn is written as several transcript lines
# (one per content block) all carrying the same final usage object, so summing
# every row double-counts each turn that emitted both thinking and text. Keying
# on .message.id collapses them; the .uuid fallback keeps a row that somehow
# lacks a message id counted once rather than merged with unrelated rows.
#
# Prints nothing at all when no usage row was seen. That is load-bearing: it
# lets the caller tell "no turns yet, or unparseable" apart from a genuine
# zero, and fall back to the payload rather than claiming 0 in / 0 out.
sum_tokens() {
  jq -r '
    select(.message.usage)
    | [ (.message.id // .uuid // "?"),
        (.message.usage
         | .input_tokens + (.cache_creation_input_tokens // 0)
                         + (.cache_read_input_tokens    // 0)),
        .message.usage.output_tokens ]
    | @tsv' -- "$@" 2>/dev/null |
  awk -F'\t' '
    !seen[$1]++ { in_ += $2; out += $3; n++ }
    END         { if (n) printf "%.0f %.0f", in_, out }'
}

# Memoised sum over every transcript file belonging to this session: the main
# one, plus one per subagent (those live in a sibling <session-id>/subagents/
# directory and their usage is billed to this session, so leaving them out
# would under-report any session that fanned work out).
#
# A busy 5MB transcript costs ~50ms to re-parse and this script runs every
# 1-6s, so the result is cached against a signature of the input files' sizes:
# renders that produced no tokens (mode toggles, directory changes) reuse it
# for ~5ms, and any appended byte busts it. Transcripts are append-only, so
# size alone is a sound cache key.
#
# The file list is carried in the positional parameters rather than a
# whitespace-joined string, so a config or project path containing spaces does
# not silently split into bogus filenames.
#
# Locals are _st_-prefixed: POSIX sh has no `local`, and the caller happens to
# use $totals for this function's own result.
session_tokens() {
  _st_cache="$CACHE_DIR/tokens-${2:-default}"
  [ -f "$1" ] || return 1

  set -- "$1"
  for _st_f in "${1%.jsonl}"/subagents/*.jsonl; do
    [ -f "$_st_f" ] && set -- "$@" "$_st_f"
  done

  # `--` matters: Claude Code's project directories are the cwd with slashes
  # turned into dashes, so an absolute-path-less invocation would hand ls and
  # jq a filename that starts with "-" and be parsed as options.
  _st_sig=$(ls -Ldn -- "$@" 2>/dev/null | awk '{ printf "%s:", $5 }')
  [ -n "$_st_sig" ] || return 1

  _st_cached=$(cat "$_st_cache" 2>/dev/null)
  case $_st_cached in
    "$_st_sig "*) printf '%s' "${_st_cached#* }"; return 0 ;;
  esac

  _st_totals=$(sum_tokens "$@")
  [ -n "$_st_totals" ] || return 1

  if [ ! -d "$CACHE_DIR" ]; then
    mkdir -p "$CACHE_DIR" 2>/dev/null && chmod 700 "$CACHE_DIR" 2>/dev/null
  fi
  printf '%s %s' "$_st_sig" "$_st_totals" > "$_st_cache" 2>/dev/null
  printf '%s' "$_st_totals"
}

# --- Payload ---------------------------------------------------------------

# Read stdin unconditionally, before deciding whether jq is even available:
# leaving the pipe undrained risks handing Claude Code an EPIPE on a machine
# where this script degrades.
input=$(cat)

# One jq pass over the payload; absent fields become empty strings. Fields are
# joined on the ASCII unit separator (0x1f): unlike tab or space, a
# non-whitespace IFS character makes `read` preserve empty fields rather than
# collapsing runs of them, so field positions stay aligned when some are absent.
US=$(printf '\037')

command -v jq >/dev/null 2>&1 && has_jq=1 || has_jq=0

model=''; effort=''; cwd=''; ctx_used=''; tokens_in=''
tokens_out=''; used_5h=''; used_7d=''; cost=''; session=''; transcript=''

if [ "$has_jq" = 1 ]; then
  IFS=$US read -r model effort cwd ctx_used tokens_in tokens_out \
                  used_5h used_7d cost session transcript <<EOF
$(printf '%s' "$input" | jq -r 2>/dev/null '[
  (.model.display_name             // ""),
  (.effort.level                   // ""),
  (.workspace.current_dir // .cwd  // ""),
  (.context_window.used_percentage // ""),
  (.context_window.total_input_tokens  // ""),
  (.context_window.total_output_tokens // ""),
  (.rate_limits.five_hour.used_percentage // ""),
  (.rate_limits.seven_day.used_percentage // ""),
  (.cost.total_cost_usd            // ""),
  (.session_id                     // ""),
  (.transcript_path                // "")
] | map(tostring) | join("")')
EOF
fi

# Older Claude Code builds omit .transcript_path. Reconstruct it from the
# session id and the project directory, whose name is the cwd with every
# non-alphanumeric character replaced by a dash.
if [ -z "$transcript" ] && [ -n "$session" ] && [ -n "$cwd" ]; then
  slug=$(printf '%s' "$cwd" | sed 's/[^a-zA-Z0-9]/-/g')
  transcript="$CONFIG_DIR/projects/$slug/$session.jsonl"
fi

# The payload carries no effort level until the first response of a session;
# fall back to the configured default so the segment is not blank at startup.
if [ -z "$effort" ] && [ "$has_jq" = 1 ]; then
  effort=$(jq -r '.effortLevel // empty' "$CONFIG_DIR/settings.json" 2>/dev/null)
fi

# Never render a blank line. A malformed payload or an early render before the
# session is populated would otherwise emit nothing but escape codes, which
# reads as "the statusline is broken" rather than "there is nothing to show".
[ -z "$model" ] && model='Claude'
[ -z "$cwd" ]   && cwd=$PWD

# --- Segments --------------------------------------------------------------

# Ponytail plugin's lazy-mode badge, read from its flag file. Absent unless
# that plugin is installed, so this costs nothing on machines without it.
ponytail_flag="$CONFIG_DIR/.ponytail-active"
if [ -f "$ponytail_flag" ]; then
  mode=$(head -n 1 "$ponytail_flag" | tr -d '[:space:]')
  [ -z "$mode" ] && mode=full
  badge=$(printf '%s' "$mode" | tr '[:lower:]' '[:upper:]')
  if [ "$badge" = FULL ]; then badge=PT; else badge="PT:$badge"; fi
  add "$C_BADGE[$badge]$RST"
fi

# Model, with the parenthesised "(1M context)" suffix trimmed for width.
model=${model% (*}
[ "$effort" = medium ] && effort=med
[ -n "$effort" ] && model="$model $effort"
add "$C_MODEL$model$RST"

# Current directory, basename only.
add "$C_PATH${cwd##*/}$RST"

# Branch and working-tree status, when inside a work tree.
if git_ro rev-parse --is-inside-work-tree >/dev/null; then
  branch=$(git_ro branch --show-current)
  [ -z "$branch" ] && branch=$(git_ro rev-parse --short HEAD)   # detached HEAD
  [ -n "$branch" ] && add "$C_BRANCH$branch$RST"

  # Porcelain XY status -> "+added ~modified -deleted".
  # Heuristic by design: untracked counts as added, and a file with mixed
  # index/worktree states is attributed to the first matching class rather
  # than counted twice. Exact per-file accounting is not worth the width.
  dirty=$(git_ro status --porcelain |
    awk -v A="$C_ADD" -v M="$C_MOD" -v D="$C_DEL" -v X="$RST" '
      { xy = substr($0, 1, 2) }
      xy == "??" || xy ~ /A/ { a++; next }
      xy ~ /D/               { d++; next }
                             { m++ }
      END {
        out = ""
        if (a) out = out " " A "+" a X
        if (m) out = out " " M "~" m X
        if (d) out = out " " D "-" d X
        sub(/^ /, "", out)
        print out
      }')
  add "${dirty:-No changes}"
fi

# Context window meter.
if [ -n "$ctx_used" ]; then
  pct=$(round "$ctx_used")
  color=$(ctx_color "$pct")
  add "$color$(meter "$pct")$RST $color$pct%$RST"
fi

# Rate limits, shown as budget remaining.
[ -n "$used_5h" ] && add "${C_5H}5h $(pct_left "$used_5h")%$RST"
[ -n "$used_7d" ] && add "${C_7D}7d $(pct_left "$used_7d")%$RST"

# Session-cumulative token counts, summed from the transcript. If it cannot be
# read — a session whose first turn has not landed yet, a relocated transcript
# — the payload's context-window figures stand in; they describe only the
# current window, but that beats showing nothing at all.
if [ "$has_jq" = 1 ] && [ -n "$transcript" ]; then
  totals=$(session_tokens "$transcript" "$session")
  case $totals in
    ?*' '?*) tokens_in=${totals% *}; tokens_out=${totals#* } ;;
  esac
fi

if [ -n "$tokens_in" ] && [ -n "$tokens_out" ]; then
  add "$C_IN$(human "$tokens_in") in$RST"
  add "$C_OUT$(human "$tokens_out") out$RST"
fi

# Session cost.
[ -n "$cost" ] && add "$C_COST$(awk -v c="$cost" 'BEGIN { printf "$%.2f", c }')$RST"

# Degraded mode is loud rather than silent: without jq every payload-derived
# segment vanishes, and a bare "Claude · dir" line looks like a config error
# with no hint as to the cause.
[ "$has_jq" = 1 ] || add "${C_ERR}jq not found$RST"

printf '%s' "$line"
