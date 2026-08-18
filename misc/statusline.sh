#!/bin/sh
#
# Claude Code statusline — one line, Codex-CLI style.
#
#   [PT] Opus 5 med · myrepo · main · +2 ~1 · ████░░░░░░ 42% · 5h 82% · weekly 93% · 12345 in · 678 out · 🪙  💰 $1.23
#   \__/ \_________/  \____/   \__/  \____/   \____________/   \_____/   \________/   \_______________/   \_________/
#   badge   model      dir    branch  dirty     context         5h left   week left      token counts       cost
#
# Claude Code pipes a JSON payload on stdin and renders whatever this prints.
# Every segment is independent: any whose data is missing (fresh session,
# non-git directory, plugin not installed) is simply omitted.
#
# Note: the 5h and weekly numbers are percent REMAINING; the context bar is
# percent USED. That asymmetry is deliberate — you want to know how much
# budget is left, but how much context is spent.
#
# ---------------------------------------------------------------------------
# Install (per machine)
#   1. cp statusline.sh ~/.claude/statusline.sh && chmod +x ~/.claude/statusline.sh
#   2. Add to ~/.claude/settings.json:
#        "statusLine": { "type": "command", "command": "~/.claude/statusline.sh" }
#   3. Restart Claude Code.
#
# Requires: POSIX sh, jq, awk. Optional: git (branch/dirty segment).
# Also needs a UTF-8 terminal with a font covering U+2588/U+2591 and emoji;
# without it the bar and coin render as tofu boxes. Set SL_ASCII=1 to
# fall back to ASCII-only glyphs.
#
# Portability: written for /bin/sh (tested under dash), no bashisms, no GNU-only
# flags. Machine-specific paths are confined to the Configuration block below.
# ---------------------------------------------------------------------------

# --- Configuration ---------------------------------------------------------

# Claude Code's config dir. Honour CLAUDE_CONFIG_DIR so non-default installs
# and multi-profile setups keep working without editing this script.
CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

# Scratch space for the coin's per-session frame counter. Kept out of
# CONFIG_DIR so nothing here ever pollutes synced/versioned config.
CACHE_DIR="${TMPDIR:-/tmp}/claude-statusline-${USER:-$LOGNAME}"

BAR_WIDTH=10          # cells in the context meter
CTX_WARN=70           # context % at which the bar turns amber
CTX_CRIT=90           # context % at which the bar turns red

if [ "${SL_ASCII:-0}" = 1 ]; then
  GLYPH_FILL='#'; GLYPH_EMPTY='.'; GLYPH_SEP='|'
  COIN_0='o   $'; COIN_1=' o  $'; COIN_2='  o $'; COIN_3='    $'
else
  GLYPH_FILL='█'; GLYPH_EMPTY='░'; GLYPH_SEP='·'
  # Coin drifts right into the money bag. All four frames are the same display
  # width so the rest of the line never shifts as it animates.
  COIN_0='🪙  💰'; COIN_1=' 🪙 💰'; COIN_2='  🪙💰'; COIN_3='    💰'
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
C_5H=$(fg 181)                 # pale rose (paler sibling of C_WEEK)
C_WEEK=$(fg 167)               # soft brick red
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

# --- Payload ---------------------------------------------------------------

input=$(cat)

# One jq pass over the payload; absent fields become empty strings. Fields are
# joined on the ASCII unit separator (0x1f): unlike tab or space, a
# non-whitespace IFS character makes `read` preserve empty fields rather than
# collapsing runs of them, so field positions stay aligned when some are absent.
US=$(printf '\037')

if command -v jq >/dev/null 2>&1; then
  has_jq=1
else
  has_jq=0
fi

model=''; effort=''; cwd=''; ctx_used=''; tokens_in=''
tokens_out=''; used_5h=''; used_7d=''; cost=''; session=''

if [ "$has_jq" = 1 ]; then
  IFS=$US read -r model effort cwd ctx_used tokens_in tokens_out \
                  used_5h used_7d cost session <<EOF
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
  (.session_id                     // "")
] | map(tostring) | join("")')
EOF
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
[ -n "$used_7d" ] && add "${C_WEEK}weekly $(pct_left "$used_7d")%$RST"

# Token counts.
if [ -n "$tokens_in" ] && [ -n "$tokens_out" ]; then
  add "$C_IN$tokens_in in$RST"
  add "$C_OUT$tokens_out out$RST"
fi

# Cost, with the coin animation.
#
# Claude Code re-runs this script on conversation state changes, not on a timer:
# measured cadence is one render every 1-6s, with 60s+ gaps during long thinking.
# So the frame index is advanced once per render rather than derived from the
# wall clock — a clock-derived index gets sampled at random phases and reads as
# jitter, whereas a counter steps 0,1,2,3 in order. The coin therefore doubles
# as an activity indicator: it moves while work happens, and holds still when
# nothing is going on.
if [ -n "$cost" ]; then
  if [ ! -d "$CACHE_DIR" ]; then
    mkdir -p "$CACHE_DIR" 2>/dev/null && chmod 700 "$CACHE_DIR" 2>/dev/null
  fi
  frame_file="$CACHE_DIR/coin-${session:-default}"

  frame=$(cat "$frame_file" 2>/dev/null)
  case $frame in ''|*[!0-9]*) frame=0 ;; esac       # first render, or clobbered
  printf '%s' $(( (frame + 1) % 4 )) > "$frame_file" 2>/dev/null

  case $frame in
    0) coin=$COIN_0 ;;
    1) coin=$COIN_1 ;;
    2) coin=$COIN_2 ;;
    *) coin=$COIN_3 ;;
  esac
  add "$coin $C_COST$(awk -v c="$cost" 'BEGIN { printf "$%.2f", c }')$RST"
fi

# Degraded mode is loud rather than silent: without jq every payload-derived
# segment vanishes, and a bare "Claude · dir" line looks like a config error
# with no hint as to the cause.
[ "$has_jq" = 1 ] || add "${C_ERR}jq not found$RST"

printf '%s' "$line"
