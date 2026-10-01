#!/bin/sh
#
# Claude Code statusline — one line, Codex-CLI style.
#
#   [PT] Opus 5.5 xhigh · myrepo · main · +2 ~1 · ████░░░░░░ 42% · 5h 82% · 7d 93% · 1.2M in · 45K out · $1.23
#
# Claude Code pipes a JSON payload on stdin and renders whatever this prints.
# Payload schema: https://code.claude.com/docs/en/statusline#available-data
# Every segment is independent: one whose data is missing (fresh session,
# non-git directory, plugin not installed) is simply omitted.
#
# The units are mixed on purpose:
#   ████░░ 42%   context window USED      — you want to know how much is spent
#   5h / 7d      rate-limit budget LEFT   — you want to know how much remains
#   cache cold   prompt cache expired; the next message re-writes the whole
#                context at cache-write prices (shown only when cold)
#   in / out     session-cumulative tokens, main transcript plus subagents
#   $            Claude Code's own estimate of the session's cost
#
# The session cost is shown as Claude Code reports it rather than priced here.
# Claude Code already carries current list prices for every model, cache-write
# TTLs included, and its ledger also counts requests that never reach the
# transcript. Pricing the in/out counts locally would duplicate that table and
# still read low. The one local price list, input_price below, exists only for
# the re-cache estimate, which Claude Code does not price.
#
# ---------------------------------------------------------------------------
# Install
#   1. cp statusline.sh ~/.claude/statusline.sh && chmod +x ~/.claude/statusline.sh
#   2. In ~/.claude/settings.json:
#        "statusLine": { "type": "command", "command": "~/.claude/statusline.sh" }
#
# Requires POSIX sh, jq and awk; git is optional. Written for /bin/sh (tested
# under dash), with no bashisms or GNU-only flags. The default glyphs need a
# UTF-8 terminal and a font covering U+2588, U+2591 and U+00B7; set SL_ASCII=1
# for ASCII-only output.
# ---------------------------------------------------------------------------

# Format numbers with a "." decimal point whatever the user's locale.
export LC_ALL=C

# --- Configuration ---------------------------------------------------------

# Honour CLAUDE_CONFIG_DIR so non-default installs and multi-profile setups
# work without editing this script.
CONFIG_DIR=${CLAUDE_CONFIG_DIR:-$HOME/.claude}

# Memoised token totals. Kept out of CONFIG_DIR so synced config stays clean.
CACHE_DIR=${TMPDIR:-/tmp}/claude-statusline-${USER:-$LOGNAME}

BAR_WIDTH=10    # cells in the context meter
CTX_WARN=70     # context % at which the meter turns amber
CTX_CRIT=90     # context % at which the meter turns red

# Base input price in $/MTok, by model id. Used only to estimate what a cold
# cache costs to rebuild: cache writes bill at 1.25x this on the 5-minute TTL
# and 2x on the 1-hour TTL. A model missing here still gets the "cache cold"
# warning, just without the dollar figure.
# Prices: https://platform.claude.com/docs/en/about-claude/pricing
input_price() {
  case ${1%%\[*} in    # drop any "[1m]" context-size suffix
    claude-fable-5|claude-fable-5-1|claude-mythos-5|claude-mythos-5-1) echo 10 ;;
    claude-opus-5|claude-opus-4-8|claude-opus-4-7|claude-opus-4-6)     echo 5 ;;
    claude-opus-5-5)                                                   echo 4 ;;
    claude-sonnet-4-6)                                                 echo 3 ;;
    claude-sonnet-5|claude-sonnet-5-5)                                 echo 2 ;;
    claude-haiku-4-5*)                                                 echo 1 ;;
  esac
}

if [ "${SL_ASCII:-0}" = 1 ]; then
  GLYPH_FILL='#' GLYPH_EMPTY='.' GLYPH_SEP='|'
else
  GLYPH_FILL='█' GLYPH_EMPTY='░' GLYPH_SEP='·'
fi

# --- Theme -----------------------------------------------------------------
# 256-colour, deliberately desaturated. Retheming means editing only this block.

sgr() { printf '\033[%sm' "$1"; }    # raw SGR sequence
fg()  { sgr "38;5;$1"; }             # 256-colour foreground

C_BADGE=$(fg 108)              # sage
C_MODEL=$(fg 173)              # soft orange
C_FAST=$(sgr '1;38;5;214')     # bold amber: fast mode bills at a premium
C_PATH=$(fg 149)               # lime
C_BRANCH=$(fg 74)              # steel blue
C_ADD=$(fg 71)                 # sage green
C_MOD=$(fg 143)                # olive amber
C_DEL=$(fg 167)                # soft brick red
C_5H=$(fg 181)                 # pale rose (paler sibling of C_7D)
C_7D=$(fg 167)                 # soft brick red
C_COLD=$(sgr '1;38;5;203')     # bold alarm red: the next message costs extra
C_IN=$(fg 173)                 # soft orange
C_OUT=$(sgr '1;38;5;216')      # bold light orange ("neon")
C_COST=$(fg 108)               # dollar-bill green
C_ERR=$(fg 203)                # alarm red, for degraded-mode warnings
C_OK=$(fg 76)                  # context meter, healthy
C_MID=$(fg 178)                # context meter, warning
C_HI=$(fg 203)                 # context meter, critical
C_DIM=$(sgr 2)                 # separators
RST=$(sgr 0)                   # closes any of the above

SEP="$C_DIM $GLYPH_SEP $RST"

# --- Helpers ---------------------------------------------------------------

# Append a segment, with a separator only between segments (never leading).
# This is what makes every segment independently omittable.
line=''
add() { line=${line:+$line$SEP}$1; }

# Draw a BAR_WIDTH-cell meter for a whole-number percentage. Any non-zero
# percentage fills at least one cell, so an empty meter means exactly zero.
meter() {
  _filled=$(( $1 * BAR_WIDTH / 100 ))
  [ "$_filled" -gt "$BAR_WIDTH" ] && _filled=$BAR_WIDTH
  [ "$_filled" -eq 0 ] && [ "$1" -gt 0 ] && _filled=1
  _i=0
  while [ "$_i" -lt "$BAR_WIDTH" ]; do
    if [ "$_i" -lt "$_filled" ]; then printf '%s' "$GLYPH_FILL"
    else                              printf '%s' "$GLYPH_EMPTY"
    fi
    _i=$((_i + 1))
  done
}

# Print "<branch> <dirty>" for the work tree at $1, or nothing outside one.
# Branch names cannot contain spaces, so the first space is the split point.
#
# One `git status` supplies both the branch and the counts. The
# --no-optional-locks flag keeps a statusline from ever taking the index lock
# out from under a concurrent interactive git command.
#
# The counts are a heuristic by design: untracked counts as added, and a file
# with mixed index/worktree states lands in the first matching class instead
# of being counted twice. Exact accounting is not worth the width.
git_info() {
  git --no-optional-locks -C "$1" status --porcelain=v2 --branch 2>/dev/null |
  awk -v A="$C_ADD" -v M="$C_MOD" -v D="$C_DEL" -v X="$RST" '
    $1 == "#" && $2 == "branch.oid"  { oid  = substr($3, 1, 7) }
    $1 == "#" && $2 == "branch.head" { head = $3 }
    $1 == "?"                        { a++ }
    $1 ~ /^[12u]$/ { if ($2 ~ /A/) a++; else if ($2 ~ /D/) d++; else m++ }
    END {
      if (head == "") exit
      if (head == "(detached)") head = oid
      if (a) dirty = dirty " " A "+" a X
      if (m) dirty = dirty " " M "~" m X
      if (d) dirty = dirty " " D "-" d X
      printf "%s %s", head, substr(dirty, 2)
    }'
}

# Print session-cumulative "<in> <out>" token counts, human-formatted, summed
# over the given transcript files. Prints nothing if no turn has landed yet.
#
# Input counts fresh, cache-write and cache-read tokens together: all three are
# model input and all three are billed, so leaving out cache reads would make a
# long session look an order of magnitude smaller than it was.
#
# An assistant turn is written as several transcript lines (one per content
# block) sharing a message id, so rows are deduped on .message.id, and the
# LAST row per id wins: an earlier one can carry a partial, mid-stream output
# count. (.uuid stands in for a missing id, so such a row is counted once
# rather than merged with unrelated ones.)
#
# jq streams one row per usage-bearing line and awk aggregates. Slurping
# (jq -s) would be shorter but holds every parsed line in memory at once:
# 34MB peak on a 5MB transcript against 4MB streaming.
sum_tokens() {
  jq -r 'select(.message.usage)
    | .message.usage as $u
    | [ .message.id // .uuid // "?",
        ($u.input_tokens // 0) + ($u.cache_creation_input_tokens // 0)
                               + ($u.cache_read_input_tokens    // 0),
        $u.output_tokens // 0 ]
    | @tsv' -- "$@" 2>/dev/null |
  awk -F'\t' '
    # 812 · 4.2K · 45K · 1.2M · 3.4B. One decimal only below 10 of a unit,
    # which caps the width at four cells so the line does not keep reflowing
    # as a session grows. Thresholds sit on the .5 rounding boundaries, so
    # 999,600 reads "1.0M" rather than "1000K".
    function human(n,   v, s) {
      if (n < 999.5) return sprintf("%.0f", n)
      if      (n >= 999.5e6) { v = n / 1e9; s = "B" }
      else if (n >= 999.5e3) { v = n / 1e6; s = "M" }
      else                   { v = n / 1e3; s = "K" }
      return sprintf(v < 9.95 ? "%.1f%s" : "%.0f%s", v, s)
    }
    !($1 in tin) { n++ }
    { tin[$1] = $2; tout[$1] = $3 }
    END {
      if (!n) exit
      for (id in tin) { i += tin[id]; o += tout[id] }
      printf "%s %s", human(i), human(o)
    }'
}

# sum_tokens over every transcript of this session: the main one at $1 plus
# one per subagent (in a sibling <session-id>/subagents/ directory; their usage
# is billed to this session too). $2 names the cache entry.
#
# Re-parsing a busy transcript costs ~50ms, and this runs on every update, so
# the result is memoised against the files' sizes. Transcripts are append-only,
# so any new turn changes the key, while updates that add nothing (mode
# toggles, directory changes) reuse the cached line.
session_tokens() {
  [ -f "$1" ] || return
  _cache=$CACHE_DIR/$2.tokens

  set -- "$1"
  for _f in "${1%.jsonl}"/subagents/*.jsonl; do
    [ -f "$_f" ] && set -- "$@" "$_f"
  done

  _key=$(wc -c -- "$@" 2>/dev/null | awk '{ printf "%s:", $1 }')
  _cached=''
  { read -r _cached < "$_cache"; } 2>/dev/null
  case $_cached in
    "$_key "*) printf '%s' "${_cached#* }"; return ;;
  esac

  _totals=$(sum_tokens "$@")
  [ -n "$_totals" ] || return
  mkdir -m 700 "$CACHE_DIR" 2>/dev/null
  printf '%s %s\n' "$_key" "$_totals" > "$_cache" 2>/dev/null
  printf '%s' "$_totals"
}

# --- Payload ---------------------------------------------------------------

# Degraded mode is loud rather than silent: without jq every segment would
# vanish, and a bare line looks like a config error with no hint as to why.
if ! command -v jq >/dev/null 2>&1; then
  cat >/dev/null    # drain stdin so Claude Code never writes into a closed pipe
  add "${C_MODEL}Claude$RST"
  add "${C_ERR}statusline needs jq$RST"
  printf '%s' "$line"
  exit 0
fi

# One jq pass turns the payload into shell assignments; @sh quotes every value,
# so the eval is safe whatever the payload contains. Absent fields become
# empty strings, and percentages arrive pre-rounded for integer comparison.
#
# The cache counts as cold once its expires_at has passed, judged against the
# clock rather than trusting .warm alone. Claude Code re-runs this script when
# a warm cache reaches expires_at, so the warning appears on time even while
# the session sits idle.
eval "$(jq -r '
  def int:  if type == "number" then round           else "" end;
  def left: if type == "number" then 100 - . | round else "" end;
  def cold: .caching_observed == true
            and (.warm != true or (.expires_at // 0) <= now);
  @sh "
    model=\(.model.display_name // "")
    model_id=\(.model.id // "")
    effort=\(.effort.level // "")
    fast=\(if .fast_mode then "fast" else "" end)
    cwd=\(.workspace.current_dir // .cwd // "")
    ctx_pct=\(.context_window.used_percentage | int)
    left_5h=\(.rate_limits.five_hour.used_percentage | left)
    left_7d=\(.rate_limits.seven_day.used_percentage | left)
    cache_cold=\(if .prompt_cache | cold then "cold" else "" end)
    cache_ttl=\(.prompt_cache.ttl // "")
    recache=\(.prompt_cache.recache_tokens_if_cold // "")
    cost=\(.cost.total_cost_usd // "")
    session=\(.session_id // "")
    transcript=\(.transcript_path // "")
  "' 2>/dev/null)"

# Never render a blank line. A malformed payload, or an early render before
# the session is populated, would otherwise read as "the statusline is broken"
# rather than "there is nothing to show yet".
: "${model:=Claude}" "${cwd:=$PWD}"

# --- Segments --------------------------------------------------------------

# Ponytail plugin's lazy-mode badge, read from its flag file. Absent unless
# that plugin is installed, so this costs nothing on machines without it.
ponytail_flag=$CONFIG_DIR/.ponytail-active
if [ -f "$ponytail_flag" ]; then
  mode=''
  read -r mode < "$ponytail_flag"
  mode=$(printf '%s' "${mode:-full}" | tr '[:lower:]' '[:upper:]')
  if [ "$mode" = FULL ]; then add "${C_BADGE}[PT]$RST"
  else                        add "${C_BADGE}[PT:$mode]$RST"
  fi
fi

# Model and effort, with any "(1M context)" suffix trimmed for width, and a
# flag when fast mode is on since it changes what the session costs.
model=${model% (*}
[ "$effort" = medium ] && effort=med
if [ -n "$fast" ]; then
  add "$C_MODEL$model${effort:+ $effort}$RST $C_FAST$fast$RST"
else
  add "$C_MODEL$model${effort:+ $effort}$RST"
fi

# Current directory, basename only.
add "$C_PATH${cwd##*/}$RST"

# Branch and working-tree status, when inside a work tree.
git=$(git_info "$cwd")
if [ -n "$git" ]; then
  add "$C_BRANCH${git%% *}$RST"
  dirty=${git#* }
  add "${dirty:-No changes}"
fi

# Context window meter.
if [ -n "$ctx_pct" ]; then
  if   [ "$ctx_pct" -ge "$CTX_CRIT" ]; then color=$C_HI
  elif [ "$ctx_pct" -ge "$CTX_WARN" ]; then color=$C_MID
  else                                      color=$C_OK
  fi
  add "$color$(meter "$ctx_pct") $ctx_pct%$RST"
fi

# Cold prompt cache. Silent while warm; once expired, the next message
# re-writes the whole context at the cache-write rate (125% of input on the
# 5-minute TTL, 200% on the 1-hour), so estimate that cost in whole cents.
# SC2154: model_id and cache_ttl are assigned by the payload eval above.
# shellcheck disable=SC2154
if [ -n "$cache_cold" ]; then
  price=$(input_price "$model_id")
  if [ -n "$price" ] && [ -n "$recache" ]; then
    case $cache_ttl in 1h) rate=200 ;; *) rate=125 ;; esac
    cents=$(( (recache * price * rate + 500000) / 1000000 ))
    add "${C_COLD}cache cold $(printf '~$%d.%02d' $((cents / 100)) $((cents % 100)))$RST"
  else
    add "${C_COLD}cache cold$RST"
  fi
fi

# Rate limits, shown as budget remaining.
[ -n "$left_5h" ] && add "${C_5H}5h $left_5h%$RST"
[ -n "$left_7d" ] && add "${C_7D}7d $left_7d%$RST"

# Session-cumulative token counts.
if [ -n "$transcript" ]; then
  tokens=$(session_tokens "$transcript" "${session:-default}")
  if [ -n "$tokens" ]; then
    add "$C_IN${tokens% *} in$RST"
    add "$C_OUT${tokens#* } out$RST"
  fi
fi

# Session cost.
[ -n "$cost" ] && add "$C_COST$(printf '$%.2f' "$cost")$RST"

printf '%s' "$line"
