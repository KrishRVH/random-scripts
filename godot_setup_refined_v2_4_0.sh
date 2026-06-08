#!/usr/bin/env bash
# Godot 2D Game Project Setup for WSL2 (and Linux)
# Reliability-first: atomic writes, idempotency, best-effort execution,
# graceful failures, and non-interactive-safe operation.
#
# Version 2.4.0

set +e
set -o pipefail
set -u
umask 022

# -----------------------------------------------------------------------------
# Script metadata
# -----------------------------------------------------------------------------
SCRIPT_VERSION="2.4.0"
SCRIPT_NAME="Godot 2D Project Setup"

# -----------------------------------------------------------------------------
# Default configuration
# -----------------------------------------------------------------------------
PROJECT_NAME=""
PROJECT_DIR=""
TEMPLATE_TYPE="platformer"
GITINIT=false
RESOLUTION="1152x648"
PIXEL_ART=false
DRY_RUN=false
GODOT_VERSION="4.2.2"
FORCE_REINSTALL=false
SKIP_GODOT_INSTALL=false
ASSUME_YES=false
FORCE_DIR=false
INSTALL_DEPS=false
INSTALL_SCOPE="auto" # auto | system | user
RUN_DIAGNOSTICS=true

MAIN_SCENE_PATH=""

# -----------------------------------------------------------------------------
# Output styling
# -----------------------------------------------------------------------------
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  PURPLE='\033[0;35m'
  CYAN='\033[0;36m'
  NC='\033[0m'
else
  RED='' ; GREEN='' ; YELLOW='' ; BLUE='' ; PURPLE='' ; CYAN='' ; NC=''
fi

SUCCESS="✅"
ERROR="❌"
INFO="ℹ️"
WARNING="⚠️"
ROCKET="🚀"
GAME="🎮"

declare -a failed_steps=()
declare -A failed_step_set=()
declare -a warnings=()
declare -A warning_set=()
declare -a temp_dirs=()

# -----------------------------------------------------------------------------
# Utility / logging
# -----------------------------------------------------------------------------
print_status()  { echo -e "${GREEN}${SUCCESS} $1${NC}"; }
print_error()   { echo -e "${RED}${ERROR} $1${NC}"; }
add_warning() {
  local msg="$1"
  if [ -z "${warning_set[$msg]-}" ]; then
    warning_set["$msg"]=1
    warnings+=("$msg")
  fi
}

print_warning() { echo -e "${YELLOW}${WARNING} $1${NC}"; add_warning "$1"; }
print_info()    { echo -e "${CYAN}${INFO} $1${NC}"; }

print_section() {
  echo ""
  echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}▶ $1${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
}

print_subsection() { echo -e "${PURPLE}──── $1${NC}"; }

command_exists() { command -v "$1" >/dev/null 2>&1; }
is_interactive() { [ -t 0 ] && [ -t 1 ]; }

confirm() {
  # confirm "Prompt" "Y"|"N"
  local prompt="$1"
  local default="${2:-N}"
  local reply=""

  if [ "$ASSUME_YES" = true ]; then
    return 0
  fi

  if ! is_interactive; then
    if [ "$default" = "Y" ]; then return 0; else return 1; fi
  fi

  if [ "$default" = "Y" ]; then
    read -r -p "$prompt (Y/n) " reply
    [ -z "$reply" ] && reply="y"
  else
    read -r -p "$prompt (y/N) " reply
    [ -z "$reply" ] && reply="n"
  fi

  case "$reply" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

add_failed_step() {
  local key="$1"
  if [ -z "${failed_step_set[$key]-}" ]; then
    failed_step_set["$key"]=1
    failed_steps+=("$key")
  fi
}

run_step() {
  # run_step <step_id> <fn> [args...]
  local step_id="$1"
  shift
  "$@"
  local rc=$?
  if [ $rc -ne 0 ]; then
    add_failed_step "$step_id"
  fi
  return 0
}

run_command() {
  if [ "$DRY_RUN" = true ]; then
    print_info "[DRY RUN] Would run: $*"
    return 0
  fi
  "$@"
}

make_directory() {
  local dir="$1"
  if [ "$DRY_RUN" = true ]; then
    print_info "[DRY RUN] Would create directory: $dir"
    return 0
  fi
  mkdir -p "$dir"
}

mktemp_dir() {
  local d
  d="$(mktemp -d 2>/dev/null)"
  if [ -z "$d" ] || [ ! -d "$d" ]; then
    print_error "Failed to create temporary directory (mktemp -d)"
    return 1
  fi
  temp_dirs+=("$d")
  echo "$d"
  return 0
}

cleanup() {
  if [ "$DRY_RUN" = true ]; then
    return 0
  fi
  for d in "${temp_dirs[@]}"; do
    [ -n "$d" ] && [ -d "$d" ] && rm -rf "$d" >/dev/null 2>&1
  done
}
trap cleanup EXIT

# Atomic write with idempotency + backup on changes.
# - Writes to a temp file in the same directory, then moves into place (atomic).
# - Skips writing (and avoids backups) if content is unchanged.
# - When content changes, creates a timestamped backup of the previous file.
files_equal() {
  local a="$1"
  local b="$2"
  if command_exists cmp; then
    cmp -s "$a" "$b"
    return $?
  fi
  if command_exists diff; then
    diff -q "$a" "$b" >/dev/null 2>&1
    return $?
  fi
  if command_exists sha256sum; then
    local ha hb
    ha="$(sha256sum "$a" 2>/dev/null | awk '{print $1}')"
    hb="$(sha256sum "$b" 2>/dev/null | awk '{print $1}')"
    [ -n "$ha" ] && [ "$ha" = "$hb" ]
    return $?
  fi
  if command_exists md5sum; then
    local ha2 hb2
    ha2="$(md5sum "$a" 2>/dev/null | awk '{print $1}')"
    hb2="$(md5sum "$b" 2>/dev/null | awk '{print $1}')"
    [ -n "$ha2" ] && [ "$ha2" = "$hb2" ]
    return $?
  fi
  return 1
}

write_file() {
  # write_file <path> <mode-octal>
  local path="$1"
  local mode="${2:-0644}"
  local dir
  dir="$(dirname "$path")"

  if [ "$DRY_RUN" = true ]; then
    print_info "[DRY RUN] Would write: $path"
    cat >/dev/null 2>&1 || true
    return 0
  fi

  mkdir -p "$dir" || return 1

  local tmp
  tmp="$(mktemp "${dir}/.tmp.$(basename "$path").XXXXXX" 2>/dev/null)" || return 1
  cat >"$tmp" || { rm -f "$tmp"; return 1; }
  chmod "$mode" "$tmp" >/dev/null 2>&1 || true

  if [ -f "$path" ] && files_equal "$path" "$tmp"; then
    rm -f "$tmp"
    return 0
  fi

  if [ -f "$path" ]; then
    local backup="${path}.backup.$(date +%Y%m%d_%H%M%S)"
    cp -p "$path" "$backup" >/dev/null 2>&1 || true
  fi

  mv -f "$tmp" "$path" || { rm -f "$tmp"; return 1; }
  return 0
}

# -----------------------------------------------------------------------------
# Usage
# -----------------------------------------------------------------------------
show_usage() {
  cat << EOF
${GAME} ${SCRIPT_NAME} v${SCRIPT_VERSION}

Usage:
  $0 --name <project_name> --dir <directory> [options]

Required:
  --name <name>          Project name (letters, numbers, hyphens, underscores)
  --dir <path>           Project directory path

Options:
  --type <type>          platformer | topdown | puzzle | empty (default: platformer)
  --resolution <WxH>     Default: 1152x648
  --pixel-art            Enable pixel-art friendly settings
  --git                  Initialize a git repo
  --godot-version <v>    Default: 4.2.2
  --skip-godot           Skip Godot install/check (still generates project)
  --force-reinstall      Reinstall Godot even if present
  --install-deps         Try to install missing deps via apt (best-effort)
  --install-scope <s>    auto | system | user (default: auto)
  --force-dir            Proceed even if project dir is non-empty
  --no-diagnostics       Skip post-run diagnostics
  --yes, -y              Assume "yes" to prompts
  --dry-run, -n          Preview actions without writing anything
  --help, -h             Show help
EOF
}

# -----------------------------------------------------------------------------
# Argument parsing / validation
# -----------------------------------------------------------------------------
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --name)
        shift
        [ $# -lt 1 ] && { print_error "--name requires a value"; return 1; }
        PROJECT_NAME="$1"
        shift
        ;;
      --dir)
        shift
        [ $# -lt 1 ] && { print_error "--dir requires a value"; return 1; }
        PROJECT_DIR="$1"
        shift
        ;;
      --type)
        shift
        [ $# -lt 1 ] && { print_error "--type requires a value"; return 1; }
        TEMPLATE_TYPE="$1"
        shift
        ;;
      --git)
        GITINIT=true
        shift
        ;;
      --resolution)
        shift
        [ $# -lt 1 ] && { print_error "--resolution requires a value"; return 1; }
        RESOLUTION="$1"
        shift
        ;;
      --pixel-art)
        PIXEL_ART=true
        shift
        ;;
      --godot-version)
        shift
        [ $# -lt 1 ] && { print_error "--godot-version requires a value"; return 1; }
        GODOT_VERSION="$1"
        shift
        ;;
      --skip-godot)
        SKIP_GODOT_INSTALL=true
        shift
        ;;
      --force-reinstall)
        FORCE_REINSTALL=true
        shift
        ;;
      --install-deps)
        INSTALL_DEPS=true
        shift
        ;;
      --install-scope)
        shift
        [ $# -lt 1 ] && { print_error "--install-scope requires a value"; return 1; }
        INSTALL_SCOPE="$1"
        shift
        ;;
      --force-dir)
        FORCE_DIR=true
        shift
        ;;
      --no-diagnostics)
        RUN_DIAGNOSTICS=false
        shift
        ;;
      --yes|-y)
        ASSUME_YES=true
        shift
        ;;
      --dry-run|-n)
        DRY_RUN=true
        shift
        ;;
      --help|-h)
        show_usage
        exit 0
        ;;
      *)
        print_error "Unknown option: $1"
        show_usage
        return 1
        ;;
    esac
  done

  return 0
}

compute_main_scene() {
  case "$TEMPLATE_TYPE" in
    platformer) MAIN_SCENE_PATH="res://scenes/levels/test_level.tscn" ;;
    topdown)    MAIN_SCENE_PATH="res://scenes/levels/topdown_level.tscn" ;;
    puzzle)     MAIN_SCENE_PATH="res://scenes/main/puzzle_main.tscn" ;;
    empty)      MAIN_SCENE_PATH="res://scenes/main/main.tscn" ;;
    *)          MAIN_SCENE_PATH="res://scenes/main/main.tscn" ;;
  esac
}

validate_inputs() {
  local has_error=false

  if [ -z "$PROJECT_NAME" ]; then
    print_error "Project name is required (--name)"
    has_error=true
  elif ! [[ "$PROJECT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    print_error "Project name must contain only letters, numbers, hyphens, and underscores"
    has_error=true
  fi

  if [ -z "$PROJECT_DIR" ]; then
    print_error "Project directory is required (--dir)"
    has_error=true
  fi

  case "$TEMPLATE_TYPE" in
    platformer|topdown|puzzle|empty) ;;
    *)
      print_error "Invalid template type: $TEMPLATE_TYPE"
      has_error=true
      ;;
  esac

  if ! [[ "$RESOLUTION" =~ ^[0-9]+x[0-9]+$ ]]; then
    print_error "Invalid resolution format: $RESOLUTION (expected WIDTHxHEIGHT)"
    has_error=true
  fi

  case "$INSTALL_SCOPE" in
    auto|system|user) ;;
    *)
      print_error "Invalid --install-scope: $INSTALL_SCOPE (expected auto|system|user)"
      has_error=true
      ;;
  esac

  if [ "$has_error" = true ]; then
    echo ""
    show_usage
    return 1
  fi

  # Normalize project directory (best effort)
  if command_exists realpath; then
    PROJECT_DIR="$(realpath -m "$PROJECT_DIR" 2>/dev/null || echo "$PROJECT_DIR")"
  fi

  if [ -d "$PROJECT_DIR" ] && [ "$(ls -A "$PROJECT_DIR" 2>/dev/null)" ]; then
    if [ "$FORCE_DIR" = true ]; then
      print_warning "Directory exists and is not empty, but --force-dir was provided: $PROJECT_DIR"
    else
      print_warning "Directory exists and is not empty: $PROJECT_DIR"
      if ! confirm "Continue and potentially overwrite files in this directory?" "N"; then
        print_info "Cancelled."
        return 1
      fi
    fi
  fi

  compute_main_scene
  return 0
}

# -----------------------------------------------------------------------------
# Environment / preflight
# -----------------------------------------------------------------------------
check_wsl_environment() {
  if grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
    if grep -qi wsl2 /proc/sys/kernel/osrelease 2>/dev/null; then
      print_info "WSL2 detected"
      return 0
    fi
    print_warning "WSL detected (version unclear)"
    return 1
  fi
  print_info "Not running under WSL (continuing)"
  return 2
}

install_deps_if_needed() {
  # install_deps_if_needed <apt-package>...
  # Best-effort. Returns 0 if install was successful, 1 otherwise.
  [ "$INSTALL_DEPS" = true ] || return 1

  if ! command_exists sudo; then
    print_warning "sudo not available; cannot install missing dependencies automatically"
    return 1
  fi

  local apt_bin=""
  if command_exists apt-get; then
    apt_bin="apt-get"
  elif command_exists apt; then
    apt_bin="apt"
  else
    print_warning "No apt/apt-get found; cannot install missing dependencies automatically"
    return 1
  fi

  # Dedupe packages
  local -A seen=()
  local pkgs=()
  local p
  for p in "$@"; do
    [ -n "$p" ] || continue
    if [ -z "${seen[$p]-}" ]; then
      seen["$p"]=1
      pkgs+=("$p")
    fi
  done

  [ "${#pkgs[@]}" -gt 0 ] || return 0

  if [ "$DRY_RUN" = true ]; then
    print_info "[DRY RUN] Would install packages: ${pkgs[*]}"
    return 0
  fi

  # Non-interactive safety: if no TTY, require passwordless sudo.
  if ! is_interactive; then
    if ! sudo -n true 2>/dev/null; then
      print_warning "Non-interactive session and sudo requires a password; skipping dependency install"
      return 1
    fi
  fi

  print_info "Installing missing packages via ${apt_bin}: ${pkgs[*]}"
  local ok=true

  # apt-get is preferred for scripts.
  if [ "$apt_bin" = "apt-get" ]; then
    sudo DEBIAN_FRONTEND=noninteractive apt-get update -y >/dev/null 2>&1 || ok=false
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkgs[@]}" >/dev/null 2>&1 || ok=false
  else
    # apt can be a bit noisier but works.
    sudo DEBIAN_FRONTEND=noninteractive apt update -y >/dev/null 2>&1 || ok=false
    sudo DEBIAN_FRONTEND=noninteractive apt install -y "${pkgs[@]}" >/dev/null 2>&1 || ok=false
  fi

  if [ "$ok" = true ]; then
    print_status "Dependencies installed"
    return 0
  fi

  print_warning "Failed to install one or more dependencies (continuing)"
  return 1
}

run_preflight_checks() {
  print_section "Pre-flight Checks"

  local core_cmds=(
    mkdir mktemp chmod cp mv date df awk grep sed tr cut dirname basename cat
  )

  local missing_core=()
  local c
  for c in "${core_cmds[@]}"; do
    command_exists "$c" || missing_core+=("$c")
  done

  if [ "${#missing_core[@]}" -gt 0 ]; then
    print_error "Missing core commands required to generate the project: ${missing_core[*]}"
    print_info "This environment is missing standard GNU utilities."

    # Best-effort attempt to fix on Debian/Ubuntu.
    install_deps_if_needed coreutils util-linux gawk grep sed >/dev/null 2>&1 || true

    # Re-check core commands
    missing_core=()
    for c in "${core_cmds[@]}"; do
      command_exists "$c" || missing_core+=("$c")
    done
    if [ "${#missing_core[@]}" -gt 0 ]; then
      print_error "Still missing core commands after attempting installs: ${missing_core[*]}"
      return 1
    fi
  fi
  print_status "Core command set available"

  # Disk space (best-effort)
  local df_target="$PROJECT_DIR"
  [ -e "$df_target" ] || df_target="$(dirname "$df_target")"
  if command_exists df; then
    local available_kb=""
    available_kb="$(df -Pk "$df_target" 2>/dev/null | awk 'NR==2 {print $4}')"
    if [[ "$available_kb" =~ ^[0-9]+$ ]]; then
      local required_kb=2097152  # 2GB
      if [ "$available_kb" -lt "$required_kb" ]; then
        print_warning "Low disk space: need ~2GB free for Godot + templates"
      else
        print_status "Disk space OK (~$(( available_kb / 1024 / 1024 ))GB free)"
      fi
    else
      print_info "Disk space check skipped (df output unavailable)"
    fi
  fi

  # Internet connectivity (best-effort)
  # Only warn; downloads will fail later with clear errors.
  if command_exists curl; then
    curl -fsSLI --max-time 5 https://github.com >/dev/null 2>&1 || print_warning "Internet check failed (curl); downloads may fail"
  elif command_exists wget; then
    wget -q --spider --timeout=5 https://github.com >/dev/null 2>&1 || print_warning "Internet check failed (wget); downloads may fail"
  else
    print_info "No curl/wget for connectivity check (ok)"
  fi

  # Tools needed for Godot installation.
  local have_downloader=false
  command_exists wget && have_downloader=true
  command_exists curl && have_downloader=true

  local have_extractor=false
  command_exists unzip && have_extractor=true
  command_exists python3 && have_extractor=true

  if [ "$SKIP_GODOT_INSTALL" != true ]; then
    local pkgs=()
    if [ "$have_downloader" = false ]; then
      print_warning "Neither wget nor curl found; Godot install will be skipped unless deps can be installed"
      pkgs+=(wget curl ca-certificates)
    fi
    if [ "$have_extractor" = false ]; then
      print_warning "Neither unzip nor python3 found; Godot install will be skipped unless deps can be installed"
      pkgs+=(unzip python3)
    fi

    if [ "${#pkgs[@]}" -gt 0 ]; then
      install_deps_if_needed "${pkgs[@]}" >/dev/null 2>&1 || true
    fi

    # Re-evaluate install capability
    have_downloader=false; have_extractor=false
    command_exists wget && have_downloader=true
    command_exists curl && have_downloader=true
    command_exists unzip && have_extractor=true
    command_exists python3 && have_extractor=true

    if [ "$have_downloader" = false ] || [ "$have_extractor" = false ]; then
      print_warning "Godot install prerequisites still missing; enabling --skip-godot behavior"
      SKIP_GODOT_INSTALL=true
    else
      print_status "Godot install prerequisites available"
    fi
  else
    print_info "Skipping Godot installation checks (--skip-godot)"
  fi

  # Git (only if requested)
  if [ "$GITINIT" = true ] && ! command_exists git; then
    print_warning "git not found; will skip git initialization"
    install_deps_if_needed git >/dev/null 2>&1 || true
    if ! command_exists git; then
      GITINIT=false
    fi
  fi

  # Optional niceties
  command_exists cmp || print_info "cmp not available; idempotent writes will use fallback comparisons"
  command_exists timeout || print_info "timeout not available; import generation may run longer"

  return 0
}

# -----------------------------------------------------------------------------
# Godot installation
# -----------------------------------------------------------------------------
get_arch_suffix() {
  local arch
  arch="$(uname -m 2>/dev/null)"
  case "$arch" in
    x86_64|amd64) echo "x86_64" ;;
    aarch64|arm64) echo "arm64" ;;
    *) echo "" ; return 1 ;;
  esac
  return 0
}

check_godot_installed() {
  if command_exists godot; then
    local installed_version
    installed_version="$(godot --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
    if [ -n "$installed_version" ]; then
      print_info "Found Godot $installed_version at: $(command -v godot)"
      if [ "$installed_version" = "$GODOT_VERSION" ] && [ "$FORCE_REINSTALL" != true ]; then
        print_status "Godot version matches requested version"
        return 0
      fi

      if [ "$FORCE_REINSTALL" = true ]; then
        print_info "Force reinstall requested"
        return 1
      fi

      if confirm "Installed Godot ($installed_version) differs from requested ($GODOT_VERSION). Use installed version?" "Y"; then
        return 0
      fi
      return 1
    fi
  fi
  return 1
}

install_godot() {
  print_section "Godot Installation"

  if [ "$SKIP_GODOT_INSTALL" = true ]; then
    print_info "Skipping Godot installation (--skip-godot)"
    return 0
  fi

  if check_godot_installed; then
    return 0
  fi

  local arch_suffix
  arch_suffix="$(get_arch_suffix)"
  if [ -z "$arch_suffix" ]; then
    print_error "Unsupported architecture: $(uname -m). Cannot auto-install Godot."
    return 1
  fi

  local temp_dir
  temp_dir="$(mktemp_dir)" || return 1

  local godot_zip="Godot_v${GODOT_VERSION}-stable_linux.${arch_suffix}.zip"
  local godot_bin="Godot_v${GODOT_VERSION}-stable_linux.${arch_suffix}"
  local templates_tpz="Godot_v${GODOT_VERSION}-stable_export_templates.tpz"

  local godot_url="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/${godot_zip}"
  local templates_url="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/${templates_tpz}"

  print_subsection "Downloading Godot"
  local zip_path="${temp_dir}/${godot_zip}"

  local attempt ok=false
  for attempt in 1 2 3; do
    print_info "Downloading Godot (attempt $attempt/3): $godot_url"
    if run_command wget -q --show-progress -O "$zip_path" "$godot_url"; then
      ok=true
      break
    fi
    print_warning "Download failed (attempt $attempt)"
    sleep 2
  done

  if [ "$ok" != true ]; then
    print_error "Failed to download Godot after 3 attempts"
    print_info "URL: $godot_url"
    return 1
  fi

  print_subsection "Extracting Godot"
  if ! run_command unzip -q "$zip_path" -d "$temp_dir"; then
    print_error "Failed to extract Godot zip"
    return 1
  fi

  local extracted="${temp_dir}/${godot_bin}"
  if [ "$DRY_RUN" != true ] && [ ! -f "$extracted" ]; then
    print_error "Extracted Godot binary not found: $extracted"
    return 1
  fi

  local install_path=""
  case "$INSTALL_SCOPE" in
    system) install_path="/usr/local/bin/godot" ;;
    user)   install_path="${HOME}/.local/bin/godot" ;;
    auto)
      if command_exists sudo && sudo -n true 2>/dev/null; then
        install_path="/usr/local/bin/godot"
      else
        install_path="${HOME}/.local/bin/godot"
        print_warning "No passwordless sudo; installing to user bin: $install_path"
      fi
      ;;
  esac

  make_directory "$(dirname "$install_path")" || return 1

  if [ "$DRY_RUN" != true ] && [ -f "$install_path" ]; then
    local backup="${install_path}.backup.$(date +%Y%m%d_%H%M%S)"
    print_info "Backing up existing Godot to: $backup"
    if [[ "$install_path" == /usr/* ]]; then
      run_command sudo cp -p "$install_path" "$backup" || true
    else
      cp -p "$install_path" "$backup" >/dev/null 2>&1 || true
    fi
  fi

  print_subsection "Installing Godot to: $install_path"
  if [[ "$install_path" == /usr/* ]]; then
    if ! command_exists sudo; then
      print_error "sudo required for system install but not found"
      return 1
    fi
    run_command sudo mv -f "$extracted" "$install_path" || return 1
    run_command sudo chmod +x "$install_path" || return 1
  else
    run_command mv -f "$extracted" "$install_path" || return 1
    run_command chmod +x "$install_path" || return 1
    export PATH="${HOME}/.local/bin:${PATH}"
  fi

  if ! command_exists godot; then
    export PATH="$(dirname "$install_path"):${PATH}"
  fi

  if command_exists godot; then
    print_status "Godot installed: $(godot --version 2>/dev/null | head -1)"
  else
    print_error "Godot install completed but 'godot' is not in PATH"
    print_info "Installed at: $install_path"
    if [[ "$install_path" == "${HOME}/.local/bin/godot" ]]; then
      print_info "Add this to your shell profile:"
      print_info "  export PATH=\"$HOME/.local/bin:\$PATH\""
    fi
    return 1
  fi

  print_subsection "Installing export templates (best-effort)"
  local tpz_path="${temp_dir}/${templates_tpz}"
  ok=false
  for attempt in 1 2 3; do
    print_info "Downloading templates (attempt $attempt/3): $templates_url"
    if run_command wget -q --show-progress -O "$tpz_path" "$templates_url"; then
      ok=true
      break
    fi
    print_warning "Templates download failed (attempt $attempt)"
    sleep 2
  done

  if [ "$ok" = true ]; then
    local template_dir="${HOME}/.local/share/godot/export_templates"
    make_directory "$template_dir" || true

    if [ "$DRY_RUN" != true ]; then
      local target="${template_dir}/${GODOT_VERSION}.stable"
      if [ -d "$target" ]; then
        local b="${target}.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Backing up existing templates to: $b"
        mv "$target" "$b" >/dev/null 2>&1 || true
      fi
      if unzip -q "$tpz_path" -d "$template_dir" >/dev/null 2>&1; then
        if [ -d "${template_dir}/templates" ]; then
          mv "${template_dir}/templates" "$target" >/dev/null 2>&1 || true
        fi
        print_status "Export templates installed"
      else
        print_warning "Failed to extract export templates (continuing)"
      fi
    else
      print_info "[DRY RUN] Would extract templates to: ${template_dir}/${GODOT_VERSION}.stable"
    fi
  else
    print_warning "Could not download export templates (continuing)"
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Project creation
# -----------------------------------------------------------------------------
create_project_structure() {
  print_section "Creating Project Structure"

  local ok=true
  make_directory "$PROJECT_DIR" || ok=false

  local dirs=(
    "scenes/main"
    "scenes/player"
    "scenes/enemies"
    "scenes/levels"
    "scenes/ui"
    "scenes/common"
    "scripts/autoload"
    "scripts/components"
    "scripts/systems"
    "assets/textures/sprites"
    "assets/textures/tiles"
    "assets/textures/ui"
    "assets/audio/music"
    "assets/audio/sfx"
    "assets/fonts"
    "assets/shaders"
    "resources/themes"
    "resources/materials"
    "addons"
    "exports"
    "docs"
    "tools"
  )

  local d
  for d in "${dirs[@]}"; do
    make_directory "${PROJECT_DIR}/${d}" || ok=false
  done

  if [ "$ok" = true ]; then
    print_status "Project directories created"
    return 0
  fi

  print_warning "One or more directories could not be created"
  return 1
}

create_project_godot() {
  print_subsection "Creating project.godot"

  IFS='x' read -r WIDTH HEIGHT <<< "$RESOLUTION"

  local ok=true
  {
    cat << EOF
; Engine configuration file.
; It's best edited using the editor UI and not directly.

[application]

config/name="${PROJECT_NAME}"
config/description="2D game project created via automation script"
config/version="0.1.0"
run/main_scene="${MAIN_SCENE_PATH}"
config/features=PackedStringArray("4.2", "GL Compatibility")
config/icon="res://icon.svg"

[autoload]

Events="*res://scripts/autoload/events.gd"
SaveManager="*res://scripts/autoload/save_manager.gd"
AudioManager="*res://scripts/autoload/audio_manager.gd"
SceneManager="*res://scripts/autoload/scene_manager.gd"
GameManager="*res://scripts/autoload/game_manager.gd"

[debug]

settings/stdout/print_fps=true
settings/stdout/verbose_stdout=true

[display]

window/size/viewport_width=${WIDTH}
window/size/viewport_height=${HEIGHT}
window/size/resizable=true
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"
window/vsync/vsync_mode=1

[input]

ui_accept={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194309,"physical_keycode":0,"key_label":0,"unicode":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194310,"physical_keycode":0,"key_label":0,"unicode":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":32,"physical_keycode":0,"key_label":0,"unicode":32,"echo":false,"script":null)
]
}
ui_cancel={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194305,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}
move_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":65,"key_label":0,"unicode":97,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194319,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}
move_right={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":68,"key_label":0,"unicode":100,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194321,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}
move_up={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":87,"key_label":0,"unicode":119,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194320,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}
move_down={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":83,"key_label":0,"unicode":115,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194322,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}
jump={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":32,"key_label":0,"unicode":32,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":90,"key_label":0,"unicode":122,"echo":false,"script":null)
]
}
action={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":88,"key_label":0,"unicode":120,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":69,"key_label":0,"unicode":101,"echo":false,"script":null)
]
}
pause={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194305,"key_label":0,"unicode":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":80,"key_label":0,"unicode":112,"echo":false,"script":null)
]
}

[layer_names]

2d_physics/layer_1="World"
2d_physics/layer_2="Player"
2d_physics/layer_3="Enemies"
2d_physics/layer_4="PlayerHurtbox"
2d_physics/layer_5="EnemyHurtbox"
2d_physics/layer_6="Pickups"
2d_physics/layer_7="Triggers"
2d_physics/layer_8="Platforms"

[physics]

common/physics_ticks_per_second=60
2d/default_gravity=980.0
2d/default_gravity_vector=Vector2(0, 1)
2d/default_linear_damp=0.1
2d/default_angular_damp=1.0

[rendering]

renderer/rendering_method="gl_compatibility"
anti_aliasing/quality/msaa_2d=2
environment/defaults/default_clear_color=Color(0.2, 0.2, 0.3, 1)
EOF

    if [ "$PIXEL_ART" = true ]; then
      cat << 'EOF'
textures/canvas_textures/default_texture_filter=0
anti_aliasing/quality/msaa_2d=0
2d/snap/snap_2d_transforms_to_pixel=true
2d/snap/snap_2d_vertices_to_pixel=true

[gui]
common/snap_controls_to_pixels=true
EOF
    fi
  } | write_file "${PROJECT_DIR}/project.godot" 0644 || ok=false

  if [ "$ok" = true ]; then
    print_status "Created project.godot"
    return 0
  fi

  print_error "Failed to create project.godot"
  return 1
}

create_autoload_scripts() {
  print_subsection "Creating autoload scripts"
  local ok=true

  write_file "${PROJECT_DIR}/scripts/autoload/events.gd" 0644 << 'EVENTS_EOF' || ok=false
extends Node
## Global event bus singleton for decoupled communication between systems.

signal player_spawned(player: Node2D)
signal player_died(player: Node2D)
signal player_health_changed(current: int, maximum: int)
signal player_state_changed(new_state: String)

signal enemy_spawned(enemy: Node2D)
signal enemy_died(enemy: Node2D, killer: Node2D)

signal level_started(level_name: String)
signal level_completed()

signal ui_show_message(text: String, duration: float)

signal request_sfx(sound_name: String, position: Vector2)
signal request_music(music_name: String)

func _ready() -> void:
	print("Events initialized")
EVENTS_EOF

  write_file "${PROJECT_DIR}/scripts/autoload/save_manager.gd" 0644 << 'SAVE_MANAGER_EOF' || ok=false
extends Node
## Save/settings management singleton.

signal save_completed(slot: int)
signal save_failed(reason: String)
signal load_completed(slot: int)
signal load_failed(reason: String)

const SAVE_DIR := "user://saves/"
const SETTINGS_FILE := "user://settings.cfg"
const SAVE_VERSION := 1

var current_save_slot: int = -1

func _ready() -> void:
	_ensure_save_dir()
	print("SaveManager initialized")

func _ensure_save_dir() -> void:
	var dir := DirAccess.open("user://")
	if dir == null:
		push_error("SaveManager: Failed to open user://")
		return
	if not dir.dir_exists("saves"):
		var err := dir.make_dir("saves")
		if err != OK:
			push_error("SaveManager: Failed to create saves dir (err=%s)" % err)

func save_game(slot: int) -> bool:
	_ensure_save_dir()
	var save_path := SAVE_DIR + ("save_slot_%d.sav" % slot)
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f == null:
		save_failed.emit("Could not create save file")
		return false

	var save_data := {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"game_data": _collect_game_data()
	}

	f.store_string(JSON.stringify(save_data))
	f.close()

	current_save_slot = slot
	save_completed.emit(slot)
	return true

func load_game(slot: int) -> bool:
	var save_path := SAVE_DIR + ("save_slot_%d.sav" % slot)
	if not FileAccess.file_exists(save_path):
		load_failed.emit("Save file does not exist")
		return false

	var f := FileAccess.open(save_path, FileAccess.READ)
	if f == null:
		load_failed.emit("Could not open save file")
		return false

	var json_string := f.get_as_text()
	f.close()

	var json := JSON.new()
	var err := json.parse(json_string)
	if err != OK:
		load_failed.emit("Save file is corrupted")
		return false

	var data: Dictionary = json.data
	if data.get("version", 0) != SAVE_VERSION:
		load_failed.emit("Save version mismatch")
		return false

	_apply_game_data(data.get("game_data", {}))
	current_save_slot = slot
	load_completed.emit(slot)
	return true

func save_settings(settings: Dictionary) -> void:
	var config := ConfigFile.new()
	for key in settings.keys():
		config.set_value("settings", str(key), settings[key])
	var err := config.save(SETTINGS_FILE)
	if err != OK:
		push_warning("SaveManager: Failed to save settings (err=%s)" % err)

func load_settings() -> Dictionary:
	var defaults := _get_default_settings()
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_FILE)
	if err != OK:
		return defaults

	var out := {}
	if config.has_section("settings"):
		for key in config.get_section_keys("settings"):
			out[key] = config.get_value("settings", key)

	for k in defaults.keys():
		if not out.has(k):
			out[k] = defaults[k]
	return out

func save_high_score(score: int) -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_FILE)
	config.set_value("game", "high_score", score)
	config.save(SETTINGS_FILE)

func _collect_game_data() -> Dictionary:
	var gm := get_node_or_null("/root/GameManager")
	if gm == null:
		return {}
	return {
		"current_level": gm.current_level,
		"score": gm.current_score,
		"lives": gm.player_lives,
		"play_time": gm.game_time
	}

func _apply_game_data(data: Dictionary) -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm == null:
		return
	if data.has("current_level"):
		gm.current_level = int(data["current_level"])
	if data.has("score"):
		gm.current_score = int(data["score"])
	if data.has("lives"):
		gm.player_lives = int(data["lives"])
	if data.has("play_time"):
		gm.game_time = float(data["play_time"])

func _get_default_settings() -> Dictionary:
	return {
		"master_volume": 1.0,
		"sfx_volume": 1.0,
		"music_volume": 1.0,
		"fullscreen": false,
		"vsync": true,
		"resolution": "1152x648",
		"high_score": 0
	}
SAVE_MANAGER_EOF

  write_file "${PROJECT_DIR}/scripts/autoload/audio_manager.gd" 0644 << 'AUDIO_MANAGER_EOF' || ok=false
extends Node
## Audio management singleton (music + SFX pools).

signal bus_volume_changed(bus_name: String, volume: float)

const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"

const MUSIC_POOL_SIZE := 2
const SFX_POOL_SIZE := 16

var _music_players: Array[AudioStreamPlayer] = []
var _sfx_players: Array[AudioStreamPlayer] = []
var _current_music: AudioStreamPlayer = null
var _fade_tween: Tween = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_buses()
	_create_pools()

func _setup_audio_buses() -> void:
	if AudioServer.get_bus_index(BUS_MASTER) < 0:
		push_warning("AudioManager: Master bus missing; audio routing may be off")

	if AudioServer.get_bus_index(BUS_MUSIC) < 0:
		AudioServer.add_bus()
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, BUS_MUSIC)
		AudioServer.set_bus_send(idx, BUS_MASTER)

	if AudioServer.get_bus_index(BUS_SFX) < 0:
		AudioServer.add_bus()
		var idx2 := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx2, BUS_SFX)
		AudioServer.set_bus_send(idx2, BUS_MASTER)

func _create_pools() -> void:
	for i in range(MUSIC_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = BUS_MUSIC
		p.name = "MusicPlayer_%d" % i
		add_child(p)
		_music_players.append(p)

	for i in range(SFX_POOL_SIZE):
		var p2 := AudioStreamPlayer.new()
		p2.bus = BUS_SFX
		p2.name = "SFXPlayer_%d" % i
		add_child(p2)
		_sfx_players.append(p2)

func play_music(stream: AudioStream, fade_in: bool = true) -> void:
	if stream == null:
		push_error("AudioManager: play_music called with null stream")
		return

	if _current_music and _current_music.playing:
		if fade_in:
			fade_out_music(0.4)
			await get_tree().create_timer(0.4).timeout
		else:
			stop_music()

	for p in _music_players:
		if not p.playing:
			_current_music = p
			p.stream = stream
			p.volume_db = -80.0 if fade_in else 0.0
			p.play()
			if fade_in:
				var t := create_tween()
				t.tween_property(p, "volume_db", 0.0, 0.4)
			return

	push_warning("AudioManager: No available music players")

func stop_music() -> void:
	if _current_music:
		_current_music.stop()
		_current_music = null

func fade_out_music(duration: float = 0.4) -> void:
	if _current_music == null or not _current_music.playing:
		return
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_current_music, "volume_db", -80.0, duration)
	_fade_tween.tween_callback(stop_music)

func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> AudioStreamPlayer:
	if stream == null:
		push_error("AudioManager: play_sfx called with null stream")
		return null

	for p in _sfx_players:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.pitch_scale = pitch_scale
			p.play()
			return p

	var oldest := _sfx_players[0]
	oldest.stop()
	oldest.stream = stream
	oldest.volume_db = volume_db
	oldest.pitch_scale = pitch_scale
	oldest.play()
	return oldest

func set_master_volume(linear_value: float) -> void:
	var idx := AudioServer.get_bus_index(BUS_MASTER)
	if idx < 0:
		return
	var db := linear_to_db(clamp(linear_value, 0.0, 1.0))
	AudioServer.set_bus_volume_db(idx, db)
	bus_volume_changed.emit(BUS_MASTER, linear_value)

func set_music_volume(linear_value: float) -> void:
	var idx := AudioServer.get_bus_index(BUS_MUSIC)
	if idx < 0:
		return
	var db := linear_to_db(clamp(linear_value, 0.0, 1.0))
	AudioServer.set_bus_volume_db(idx, db)
	bus_volume_changed.emit(BUS_MUSIC, linear_value)

func set_sfx_volume(linear_value: float) -> void:
	var idx := AudioServer.get_bus_index(BUS_SFX)
	if idx < 0:
		return
	var db := linear_to_db(clamp(linear_value, 0.0, 1.0))
	AudioServer.set_bus_volume_db(idx, db)
	bus_volume_changed.emit(BUS_SFX, linear_value)
AUDIO_MANAGER_EOF

  write_file "${PROJECT_DIR}/scripts/autoload/scene_manager.gd" 0644 << 'SCENE_MANAGER_EOF' || ok=false
extends Node
## Scene transition management singleton (fade-only).

signal scene_changing(to_scene: String)
signal scene_changed(scene_path: String)
signal transition_finished

var current_scene: Node = null
var is_transitioning: bool = false

var _overlay: ColorRect = null
var _layer: CanvasLayer = null

enum TransitionType { NONE, FADE_BLACK, FADE_WHITE }

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	current_scene = get_tree().current_scene
	_create_overlay()

func goto_scene(path: String, transition: TransitionType = TransitionType.FADE_BLACK) -> void:
	if is_transitioning:
		push_warning("SceneManager: transition already in progress")
		return
	if not ResourceLoader.exists(path):
		push_error("SceneManager: scene does not exist: " + path)
		return

	is_transitioning = true
	scene_changing.emit(path)

	match transition:
		TransitionType.NONE:
			if _change_scene(path):
				_finish_transition()
		TransitionType.FADE_WHITE:
			await _fade_to(path, Color.WHITE)
		_:
			await _fade_to(path, Color.BLACK)

func _fade_to(path: String, color: Color) -> void:
	if _overlay == null:
		if _change_scene(path):
			_finish_transition()
		return

	_overlay.color = color
	_overlay.modulate.a = 0.0
	_overlay.show()

	var t := create_tween()
	t.tween_property(_overlay, "modulate:a", 1.0, 0.25)
	await t.finished

	_change_scene(path)

	var t2 := create_tween()
	t2.tween_property(_overlay, "modulate:a", 0.0, 0.25)
	await t2.finished

	_overlay.hide()
	_finish_transition()

func _change_scene(path: String) -> bool:
	if current_scene:
		current_scene.queue_free()

	var packed := load(path) as PackedScene
	if packed == null:
		push_error("SceneManager: failed to load scene: " + path)
		return false

	current_scene = packed.instantiate()
	get_tree().root.add_child(current_scene)
	get_tree().current_scene = current_scene

	scene_changed.emit(path)
	return true

func _finish_transition() -> void:
	is_transitioning = false
	transition_finished.emit()

func _create_overlay() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 128
	_layer.name = "TransitionLayer"
	add_child(_layer)

	_overlay = ColorRect.new()
	_overlay.name = "TransitionOverlay"
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.hide()

	_layer.add_child(_overlay)
SCENE_MANAGER_EOF

  write_file "${PROJECT_DIR}/scripts/autoload/game_manager.gd" 0644 << 'GAME_MANAGER_EOF' || ok=false
extends Node
## Central game state singleton.

signal game_started
signal game_paused
signal game_resumed
signal game_over
signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal level_changed(level: int)

enum GameState { MENU, PLAYING, PAUSED, GAME_OVER, LOADING }

var current_state: GameState = GameState.MENU
var current_score: int = 0
var high_score: int = 0
var player_lives: int = 3
var current_level: int = 1
var game_time: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_settings_best_effort()

func _process(delta: float) -> void:
	if current_state == GameState.PLAYING:
		game_time += delta

func start_game() -> void:
	current_state = GameState.PLAYING
	current_score = 0
	player_lives = 3
	current_level = 1
	game_time = 0.0
	game_started.emit()
	score_changed.emit(current_score)
	lives_changed.emit(player_lives)
	level_changed.emit(current_level)

func toggle_pause() -> void:
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		get_tree().paused = true
		game_paused.emit()
	elif current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		get_tree().paused = false
		game_resumed.emit()

func end_game() -> void:
	current_state = GameState.GAME_OVER
	get_tree().paused = true

	if current_score > high_score:
		high_score = current_score
		var sm := get_node_or_null("/root/SaveManager")
		if sm and sm.has_method("save_high_score"):
			sm.save_high_score(high_score)

	game_over.emit()

func add_score(points: int) -> void:
	current_score += points
	score_changed.emit(current_score)

func lose_life() -> void:
	player_lives -= 1
	lives_changed.emit(player_lives)
	if player_lives <= 0:
		end_game()

func _load_settings_best_effort() -> void:
	var sm := get_node_or_null("/root/SaveManager")
	var am := get_node_or_null("/root/AudioManager")
	if sm and sm.has_method("load_settings"):
		var settings: Dictionary = sm.load_settings()
		high_score = int(settings.get("high_score", 0))
		if am:
			if am.has_method("set_master_volume"):
				am.set_master_volume(float(settings.get("master_volume", 1.0)))
			if am.has_method("set_music_volume"):
				am.set_music_volume(float(settings.get("music_volume", 1.0)))
			if am.has_method("set_sfx_volume"):
				am.set_sfx_volume(float(settings.get("sfx_volume", 1.0)))
GAME_MANAGER_EOF

  if [ "$ok" = true ]; then
    print_status "Autoload scripts created"
    return 0
  fi

  print_error "One or more autoload scripts failed to write"
  return 1
}

create_common_components() {
  print_subsection "Creating common components"
  local ok=true

  write_file "${PROJECT_DIR}/scripts/components/health_component.gd" 0644 << 'HEALTH_EOF' || ok=false
extends Node
class_name HealthComponent

signal health_changed(current: int, maximum: int)
signal died

@export var max_health: int = 100
@export var start_health: int = -1

var current_health: int = 0

func _ready() -> void:
	current_health = max_health if start_health < 0 else start_health
	current_health = clamp(current_health, 0, max_health)
	health_changed.emit(current_health, max_health)

func take_damage(amount: int) -> void:
	if current_health <= 0:
		return
	current_health = max(0, current_health - max(0, amount))
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		died.emit()

func heal(amount: int) -> void:
	if current_health <= 0:
		return
	current_health = min(max_health, current_health + max(0, amount))
	health_changed.emit(current_health, max_health)
HEALTH_EOF

  write_file "${PROJECT_DIR}/scripts/systems/state.gd" 0644 << 'STATE_EOF' || ok=false
extends Node
class_name State

signal transitioned(new_state_name: String)

var state_machine: StateMachine

func enter() -> void: pass
func exit() -> void: pass
func update(_delta: float) -> void: pass
func physics_update(_delta: float) -> void: pass
func handle_input(_event: InputEvent) -> void: pass
STATE_EOF

  write_file "${PROJECT_DIR}/scripts/systems/state_machine.gd" 0644 << 'SM_EOF' || ok=false
extends Node
class_name StateMachine

@export var initial_state: NodePath
var current_state: State = null
var states: Dictionary = {}

func _ready() -> void:
	for child in get_children():
		if child is State:
			states[child.name] = child
			child.state_machine = self
			child.transitioned.connect(_on_state_transitioned)

	if initial_state != NodePath():
		var s := get_node_or_null(initial_state)
		if s is State:
			current_state = s
			current_state.enter()

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func _on_state_transitioned(state_name: String) -> void:
	transition_to(state_name)

func transition_to(state_name: String) -> void:
	if not states.has(state_name):
		push_warning("StateMachine: state not found: " + state_name)
		return
	if current_state:
		current_state.exit()
	current_state = states[state_name]
	current_state.enter()
SM_EOF

  if [ "$ok" = true ]; then
    print_status "Common components created"
    return 0
  fi
  print_error "One or more common components failed to write"
  return 1
}

create_supporting_files() {
  print_subsection "Creating supporting files"
  local ok=true

  write_file "${PROJECT_DIR}/README.md" 0644 << EOF || ok=false
# ${PROJECT_NAME}

Godot ${GODOT_VERSION} starter project.

## Quick start

\`\`\`bash
cd "${PROJECT_DIR}"
godot --editor --path .
# or run:
godot --path .
\`\`\`
EOF

  write_file "${PROJECT_DIR}/.gitignore" 0644 << 'GITIGNORE_EOF' || ok=false
# Godot
.godot/
.import/
export_presets.cfg
export.cfg
*.tmp
*.translation

# Mono
.mono/
mono_crash.*.json

# IDEs
.vscode/
.idea/

# OS junk
.DS_Store
Thumbs.db

# Builds/exports
exports/
build/
dist/
GITIGNORE_EOF

  write_file "${PROJECT_DIR}/.editorconfig" 0644 << 'EDITORCONFIG_EOF' || ok=false
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
indent_style = tab
indent_size = 4

[*.{yml,yaml,json}]
indent_style = space
indent_size = 2

[*.md]
trim_trailing_whitespace = false

[*.{tscn,tres,godot,import}]
indent_style = space
indent_size = 4
EDITORCONFIG_EOF

  write_file "${PROJECT_DIR}/icon.svg" 0644 << 'ICON_EOF' || ok=false
<svg height="128" width="128" xmlns="http://www.w3.org/2000/svg">
  <rect width="128" height="128" fill="#1a1a2e"/>
  <circle cx="64" cy="64" r="48" fill="#16213e"/>
  <path d="M 64 32 L 80 64 L 64 96 L 48 64 Z" fill="#0f3460"/>
  <circle cx="64" cy="64" r="24" fill="#e94560"/>
</svg>
ICON_EOF

  if [ "$ok" = true ]; then
    print_status "Supporting files created"
    return 0
  fi
  print_error "One or more supporting files failed to write"
  return 1
}

# -----------------------------------------------------------------------------
# Templates
# -----------------------------------------------------------------------------
create_template_content() {
  print_subsection "Creating template content: $TEMPLATE_TYPE"
  case "$TEMPLATE_TYPE" in
    platformer) create_platformer_template ;;
    topdown)    create_topdown_template ;;
    puzzle)     create_puzzle_template ;;
    empty)      create_empty_template ;;
  esac
  return $?
}

create_platformer_template() {
  print_info "Creating platformer template"
  local ok=true

  write_file "${PROJECT_DIR}/scenes/player/ball_player.gd" 0644 << 'BALL_PLAYER_EOF' || ok=false
extends CharacterBody2D
class_name BallPlayer

@export_group("Movement")
@export var move_speed: float = 350.0
@export var acceleration: float = 2500.0
@export var friction: float = 2000.0
@export var air_acceleration: float = 1500.0
@export var air_friction: float = 500.0

@export_group("Jumping")
@export var jump_velocity: float = -450.0
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.1

@export_group("Visuals")
@export var squash_stretch_amount: float = 0.2
@export var rotation_speed: float = 360.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var time_since_on_floor: float = 0.0
var jump_buffer_timer: float = 0.0
var _was_on_floor: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	add_to_group("player")
	var ev := get_node_or_null("/root/Events")
	if ev:
		ev.player_spawned.emit(self)
	_was_on_floor = is_on_floor()

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_apply_gravity(delta)
	_handle_horizontal(delta)
	_handle_jump()
	move_and_slide()
	_update_visuals(delta)
	_was_on_floor = is_on_floor()

func _update_timers(delta: float) -> void:
	if is_on_floor():
		time_since_on_floor = 0.0
	else:
		time_since_on_floor += delta
	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

func _handle_horizontal(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		var target := dir * move_speed
		var accel := acceleration if is_on_floor() else air_acceleration
		velocity.x = move_toward(velocity.x, target, accel * delta)
	else:
		var fric := friction if is_on_floor() else air_friction
		velocity.x = move_toward(velocity.x, 0.0, fric * delta)

func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time

	var can_jump := is_on_floor() or time_since_on_floor < coyote_time
	if can_jump and jump_buffer_timer > 0.0:
		jump_buffer_timer = 0.0
		velocity.y = jump_velocity
		if animation_player and animation_player.has_animation("jump"):
			animation_player.play("jump")

func _update_visuals(delta: float) -> void:
	if sprite == null:
		return

	if abs(velocity.x) > 10.0:
		sprite.rotation_degrees += sign(velocity.x) * rotation_speed * delta

	if is_on_floor() and not _was_on_floor:
		_apply_squash(1.0 + squash_stretch_amount, 1.0 - squash_stretch_amount)
	elif (not is_on_floor()) and _was_on_floor:
		_apply_squash(1.0 - squash_stretch_amount, 1.0 + squash_stretch_amount)

func _apply_squash(x_scale: float, y_scale: float) -> void:
	if sprite == null:
		return
	var t := create_tween()
	t.set_trans(Tween.TRANS_ELASTIC)
	t.set_ease(Tween.EASE_OUT)
	t.tween_property(sprite, "scale", Vector2(x_scale, y_scale), 0.1)
	t.tween_property(sprite, "scale", Vector2.ONE, 0.2)
BALL_PLAYER_EOF

  write_file "${PROJECT_DIR}/scenes/player/ball_player.tscn" 0644 << 'BALL_PLAYER_SCENE_EOF' || ok=false
[gd_scene load_steps=6 format=3 uid="uid://b1234567890"]

[ext_resource type="Script" path="res://scenes/player/ball_player.gd" id="1_player"]

[sub_resource type="CircleShape2D" id="CircleShape2D_1"]
radius = 16.0

[sub_resource type="Gradient" id="Gradient_1"]
offsets = PackedFloat32Array(0, 0.5, 1)
colors = PackedColorArray(0.2, 0.6, 1, 1, 0.4, 0.8, 1, 1, 0.6, 0.9, 1, 1)

[sub_resource type="GradientTexture2D" id="GradientTexture2D_1"]
gradient = SubResource("Gradient_1")
width = 32
height = 32
fill = 1
fill_from = Vector2(0.5, 0.5)
fill_to = Vector2(1, 0.5)

[sub_resource type="Animation" id="Animation_jump"]
resource_name = "jump"
length = 0.3
tracks/0/type = "value"
tracks/0/enabled = true
tracks/0/path = NodePath("Sprite2D:scale")
tracks/0/interp = 2
tracks/0/keys = {"times": PackedFloat32Array(0, 0.1, 0.3), "transitions": PackedFloat32Array(0.5, 2, 1), "update": 0, "values": [Vector2(1, 1), Vector2(0.8, 1.2), Vector2(1, 1)]}

[sub_resource type="AnimationLibrary" id="AnimationLibrary_1"]
_data = {"jump": SubResource("Animation_jump")}

[node name="BallPlayer" type="CharacterBody2D"]
collision_layer = 2
collision_mask = 1
script = ExtResource("1_player")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = SubResource("GradientTexture2D_1")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_1")

[node name="AnimationPlayer" type="AnimationPlayer" parent="."]
libraries = { "": SubResource("AnimationLibrary_1") }
BALL_PLAYER_SCENE_EOF

  write_file "${PROJECT_DIR}/scenes/common/platform.tscn" 0644 << 'PLATFORM_SCENE_EOF' || ok=false
[gd_scene load_steps=3 format=3 uid="uid://bplatform12345"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_1"]
size = Vector2(200, 20)

[sub_resource type="Gradient" id="Gradient_1"]
colors = PackedColorArray(0.3, 0.3, 0.3, 1, 0.5, 0.5, 0.5, 1)

[sub_resource type="GradientTexture2D" id="GradientTexture2D_1"]
gradient = SubResource("Gradient_1")
width = 200
height = 20

[node name="Platform" type="StaticBody2D"]
collision_layer = 1
collision_mask = 0

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = SubResource("GradientTexture2D_1")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_1")
PLATFORM_SCENE_EOF

  write_file "${PROJECT_DIR}/scenes/ui/game_ui.gd" 0644 << 'GAME_UI_GD_EOF' || ok=false
extends CanvasLayer

@onready var score_label: Label = $Control/ScoreLabel

func _ready() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm:
		gm.score_changed.connect(_on_score_changed)
		_on_score_changed(gm.current_score)

func _on_score_changed(new_score: int) -> void:
	if score_label:
		score_label.text = "Score: %d" % new_score
GAME_UI_GD_EOF

  write_file "${PROJECT_DIR}/scenes/ui/game_ui.tscn" 0644 << 'GAME_UI_TSCN_EOF' || ok=false
[gd_scene load_steps=2 format=3 uid="uid://bgameui12345"]

[ext_resource type="Script" path="res://scenes/ui/game_ui.gd" id="1_ui"]

[node name="GameUI" type="CanvasLayer"]
script = ExtResource("1_ui")

[node name="Control" type="Control" parent="."]
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2

[node name="ScoreLabel" type="Label" parent="Control"]
offset_left = 10.0
offset_top = 10.0
offset_right = 200.0
offset_bottom = 50.0
text = "Score: 0"
theme_override_font_sizes/font_size = 24

[node name="Instructions" type="Label" parent="Control"]
anchor_top = 1.0
anchor_bottom = 1.0
offset_left = 10.0
offset_top = -100.0
offset_right = 420.0
offset_bottom = -10.0
text = "Arrow Keys / A,D - Move\\nSpace - Jump\\nEsc - Pause"
theme_override_colors/font_color = Color(0.8, 0.8, 0.8, 0.7)
GAME_UI_TSCN_EOF

  write_file "${PROJECT_DIR}/scenes/levels/test_level.gd" 0644 << 'TEST_LEVEL_GD_EOF' || ok=false
extends Node2D

@export var level_name: String = "Test Level"

@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var camera: Camera2D = $Camera2D

const PLAYER_SCENE := preload("res://scenes/player/ball_player.tscn")
const UI_SCENE := preload("res://scenes/ui/game_ui.tscn")

func _ready() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm:
		gm.start_game()

	add_child(UI_SCENE.instantiate())

	var ev := get_node_or_null("/root/Events")
	if ev:
		ev.level_started.emit(level_name)

	_spawn_player()

func _spawn_player() -> void:
	if player_spawn == null:
		push_error("TestLevel: PlayerSpawn missing")
		return

	var p := PLAYER_SCENE.instantiate()
	p.global_position = player_spawn.global_position
	add_child(p)

	if camera:
		camera.position = p.position
		camera.current = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		var gm := get_node_or_null("/root/GameManager")
		if gm:
			gm.toggle_pause()
TEST_LEVEL_GD_EOF

  write_file "${PROJECT_DIR}/scenes/levels/test_level.tscn" 0644 << 'TEST_LEVEL_TSCN_EOF' || ok=false
[gd_scene load_steps=5 format=3 uid="uid://btestlevel1234"]

[ext_resource type="Script" path="res://scenes/levels/test_level.gd" id="1_level"]
[ext_resource type="PackedScene" uid="uid://bplatform12345" path="res://scenes/common/platform.tscn" id="2_platform"]

[sub_resource type="Gradient" id="Gradient_bg"]
offsets = PackedFloat32Array(0, 1)
colors = PackedColorArray(0.1, 0.1, 0.2, 1, 0.2, 0.2, 0.3, 1)

[sub_resource type="GradientTexture2D" id="GradientTexture2D_bg"]
gradient = SubResource("Gradient_bg")
width = 1152
height = 648
fill = 1
fill_from = Vector2(0.5, 0)
fill_to = Vector2(0.5, 1)

[node name="TestLevel" type="Node2D"]
script = ExtResource("1_level")
level_name = "Ball Jump Test"

[node name="Background" type="Sprite2D" parent="."]
z_index = -10
position = Vector2(576, 324)
texture = SubResource("GradientTexture2D_bg")

[node name="Camera2D" type="Camera2D" parent="."]
position = Vector2(576, 324)

[node name="PlayerSpawn" type="Marker2D" parent="."]
position = Vector2(576, 200)

[node name="Platforms" type="Node2D" parent="."]

[node name="Ground" parent="Platforms" instance=ExtResource("2_platform")]
position = Vector2(576, 520)
scale = Vector2(3, 1)

[node name="Platform1" parent="Platforms" instance=ExtResource("2_platform")]
position = Vector2(400, 420)

[node name="Platform2" parent="Platforms" instance=ExtResource("2_platform")]
position = Vector2(760, 370)

[node name="Platform3" parent="Platforms" instance=ExtResource("2_platform")]
position = Vector2(576, 270)
scale = Vector2(0.6, 1)

[node name="Instructions" type="Label" parent="."]
offset_left = 10.0
offset_top = 10.0
offset_right = 520.0
offset_bottom = 120.0
text = "Arrow Keys / A,D - Move\\nSpace - Jump\\nEsc - Pause"
TEST_LEVEL_TSCN_EOF

  if [ "$ok" = true ]; then
    print_status "Platformer template created"
    return 0
  fi
  print_error "Platformer template had write failures"
  return 1
}

create_topdown_template() {
  print_info "Creating top-down template"
  local ok=true

  write_file "${PROJECT_DIR}/scenes/player/player_topdown.gd" 0644 << 'TOPDOWN_GD_EOF' || ok=false
extends CharacterBody2D
class_name PlayerTopDown

@export var move_speed: float = 220.0
@export var acceleration: float = 1200.0
@export var friction: float = 1200.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("player")
	var ev := get_node_or_null("/root/Events")
	if ev:
		ev.player_spawned.emit(self)

func _physics_process(delta: float) -> void:
	var input_vec := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vec != Vector2.ZERO:
		velocity = velocity.move_toward(input_vec * move_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	move_and_slide()

	if Input.is_action_just_pressed("pause"):
		var gm := get_node_or_null("/root/GameManager")
		if gm:
			gm.toggle_pause()
TOPDOWN_GD_EOF

  write_file "${PROJECT_DIR}/scenes/player/player_topdown.tscn" 0644 << 'TOPDOWN_TSCN_EOF' || ok=false
[gd_scene load_steps=4 format=3 uid="uid://btopdownplayer1"]

[ext_resource type="Script" path="res://scenes/player/player_topdown.gd" id="1_player"]

[sub_resource type="CircleShape2D" id="CircleShape2D_1"]
radius = 14.0

[sub_resource type="Gradient" id="Gradient_1"]
offsets = PackedFloat32Array(0, 1)
colors = PackedColorArray(0.2, 1, 0.4, 1, 0.1, 0.6, 0.2, 1)

[sub_resource type="GradientTexture2D" id="GradientTexture2D_1"]
gradient = SubResource("Gradient_1")
width = 32
height = 32
fill = 1
fill_from = Vector2(0.5, 0.5)
fill_to = Vector2(1, 0.5)

[node name="PlayerTopDown" type="CharacterBody2D"]
collision_layer = 2
collision_mask = 1
script = ExtResource("1_player")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = SubResource("GradientTexture2D_1")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_1")
TOPDOWN_TSCN_EOF

  write_file "${PROJECT_DIR}/scenes/levels/topdown_level.gd" 0644 << 'TOPDOWN_LEVEL_GD_EOF' || ok=false
extends Node2D

@export var level_name: String = "TopDown Level"
@onready var spawn: Marker2D = $PlayerSpawn
const PLAYER := preload("res://scenes/player/player_topdown.tscn")

func _ready() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm:
		gm.start_game()

	var ev := get_node_or_null("/root/Events")
	if ev:
		ev.level_started.emit(level_name)

	if spawn:
		var p := PLAYER.instantiate()
		p.global_position = spawn.global_position
		add_child(p)
TOPDOWN_LEVEL_GD_EOF

  write_file "${PROJECT_DIR}/scenes/levels/topdown_level.tscn" 0644 << 'TOPDOWN_LEVEL_TSCN_EOF' || ok=false
[gd_scene load_steps=2 format=3 uid="uid://btopdownlevel1"]

[ext_resource type="Script" path="res://scenes/levels/topdown_level.gd" id="1_level"]

[node name="TopDownLevel" type="Node2D"]
script = ExtResource("1_level")
level_name = "TopDown Test"

[node name="PlayerSpawn" type="Marker2D" parent="."]
position = Vector2(576, 324)

[node name="Instructions" type="Label" parent="."]
offset_left = 10.0
offset_top = 10.0
offset_right = 520.0
offset_bottom = 120.0
text = "WASD/Arrows - Move\\nEsc/P - Pause"
TOPDOWN_LEVEL_TSCN_EOF

  if [ "$ok" = true ]; then
    print_status "Top-down template created"
    return 0
  fi
  print_error "Top-down template had write failures"
  return 1
}

create_puzzle_template() {
  print_info "Creating puzzle template"
  local ok=true

  write_file "${PROJECT_DIR}/scripts/components/grid_movement.gd" 0644 << 'GRID_EOF' || ok=false
extends Node2D
class_name GridMovement

@export var grid_size: int = 32
@export var move_duration: float = 0.15

var is_moving: bool = false
var target_position: Vector2

func _ready() -> void:
	position = position.snapped(Vector2.ONE * grid_size)
	target_position = position

func _input(event: InputEvent) -> void:
	if is_moving:
		return

	var dir := Vector2.ZERO
	if event.is_action_pressed("move_left"):
		dir = Vector2.LEFT
	elif event.is_action_pressed("move_right"):
		dir = Vector2.RIGHT
	elif event.is_action_pressed("move_up"):
		dir = Vector2.UP
	elif event.is_action_pressed("move_down"):
		dir = Vector2.DOWN

	if dir != Vector2.ZERO:
		_try_move(dir)

func _try_move(dir: Vector2) -> void:
	var new_pos := position + dir * grid_size
	_move_to(new_pos)

func _move_to(new_pos: Vector2) -> void:
	is_moving = true
	target_position = new_pos
	var t := create_tween()
	t.tween_property(self, "position", target_position, move_duration)
	t.tween_callback(func(): is_moving = false)
GRID_EOF

  write_file "${PROJECT_DIR}/scenes/main/puzzle_main.gd" 0644 << 'PUZZLE_MAIN_GD_EOF' || ok=false
extends Node2D

const PAWN := preload("res://scenes/main/puzzle_pawn.tscn")

func _ready() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm:
		gm.start_game()
	add_child(PAWN.instantiate())
PUZZLE_MAIN_GD_EOF

  write_file "${PROJECT_DIR}/scenes/main/puzzle_pawn.tscn" 0644 << 'PUZZLE_PAWN_TSCN_EOF' || ok=false
[gd_scene load_steps=4 format=3 uid="uid://bpuzzlepawn1"]

[ext_resource type="Script" path="res://scripts/components/grid_movement.gd" id="1_grid"]

[sub_resource type="CircleShape2D" id="CircleShape2D_1"]
radius = 14.0

[sub_resource type="Gradient" id="Gradient_1"]
offsets = PackedFloat32Array(0, 1)
colors = PackedColorArray(1, 0.8, 0.2, 1, 0.9, 0.4, 0.1, 1)

[sub_resource type="GradientTexture2D" id="GradientTexture2D_1"]
gradient = SubResource("Gradient_1")
width = 32
height = 32
fill = 1
fill_from = Vector2(0.5, 0.5)
fill_to = Vector2(1, 0.5)

[node name="PuzzlePawn" type="Node2D"]
script = ExtResource("1_grid")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = SubResource("GradientTexture2D_1")

[node name="Area2D" type="Area2D" parent="."]

[node name="CollisionShape2D" type="CollisionShape2D" parent="Area2D"]
shape = SubResource("CircleShape2D_1")
PUZZLE_PAWN_TSCN_EOF

  write_file "${PROJECT_DIR}/scenes/main/puzzle_main.tscn" 0644 << 'PUZZLE_MAIN_TSCN_EOF' || ok=false
[gd_scene load_steps=2 format=3 uid="uid://bpuzzlemain1"]

[ext_resource type="Script" path="res://scenes/main/puzzle_main.gd" id="1_main"]

[node name="PuzzleMain" type="Node2D"]
script = ExtResource("1_main")

[node name="Instructions" type="Label" parent="."]
offset_left = 10.0
offset_top = 10.0
offset_right = 520.0
offset_bottom = 120.0
text = "Arrow Keys / WASD - Move on grid\\nEsc/P - Pause"
PUZZLE_MAIN_TSCN_EOF

  if [ "$ok" = true ]; then
    print_status "Puzzle template created"
    return 0
  fi
  print_error "Puzzle template had write failures"
  return 1
}

create_empty_template() {
  print_info "Creating empty template"
  local ok=true

  write_file "${PROJECT_DIR}/scenes/main/main.gd" 0644 << 'EMPTY_GD_EOF' || ok=false
extends Node2D

func _ready() -> void:
	print("Game started: %s" % ProjectSettings.get_setting("application/config/name", "Game"))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
EMPTY_GD_EOF

  write_file "${PROJECT_DIR}/scenes/main/main.tscn" 0644 << 'EMPTY_TSCN_EOF' || ok=false
[gd_scene load_steps=2 format=3 uid="uid://bemptymain1"]

[ext_resource type="Script" path="res://scenes/main/main.gd" id="1_main"]

[node name="Main" type="Node2D"]
script = ExtResource("1_main")

[node name="Label" type="Label" parent="."]
offset_left = 10.0
offset_top = 10.0
offset_right = 520.0
offset_bottom = 120.0
text = "Empty template. Press Esc to quit."
EMPTY_TSCN_EOF

  if [ "$ok" = true ]; then
    print_status "Empty template created"
    return 0
  fi
  print_error "Empty template had write failures"
  return 1
}

# -----------------------------------------------------------------------------
# Git / import generation
# -----------------------------------------------------------------------------
setup_git_repository() {
  if [ "$GITINIT" != true ]; then
    return 0
  fi

  print_subsection "Initializing Git repository"
  if [ "$DRY_RUN" = true ]; then
    print_info "[DRY RUN] Would initialize git repo in: $PROJECT_DIR"
    return 0
  fi

  if [ -d "${PROJECT_DIR}/.git" ]; then
    print_info "Git repo already exists; skipping git init"
    return 0
  fi

  (cd "$PROJECT_DIR" && git init) || return 1

  local email name
  email="$(git -C "$PROJECT_DIR" config --get user.email 2>/dev/null)"
  name="$(git -C "$PROJECT_DIR" config --get user.name 2>/dev/null)"
  if [ -z "$email" ] || [ -z "$name" ]; then
    print_warning "Git user.name/user.email not set; skipping initial commit"
    print_info "Set them with:"
    print_info "  git config --global user.name \"Your Name\""
    print_info "  git config --global user.email \"you@example.com\""
    return 0
  fi

  (cd "$PROJECT_DIR" && git add . && git commit -m "Initial commit: ${PROJECT_NAME}") || {
    print_warning "Git commit failed (repo still initialized)"
    return 0
  }

  print_status "Git repository initialized"
  return 0
}

generate_import_files() {
  print_subsection "Generating initial import files"
  if [ "$DRY_RUN" = true ]; then
    print_info "[DRY RUN] Would run Godot headless to generate imports"
    return 0
  fi

  if ! command_exists godot; then
    print_warning "Godot not found; skipping import generation"
    return 0
  fi

  if command_exists timeout; then
    timeout 8s godot --headless --path "$PROJECT_DIR" >/dev/null 2>&1 || true
  else
    print_warning "timeout not available; running Godot headless briefly (may take longer)"
    godot --headless --path "$PROJECT_DIR" >/dev/null 2>&1 || true
  fi
  print_status "Import generation attempted"
  return 0
}

# -----------------------------------------------------------------------------
# Diagnostics
# -----------------------------------------------------------------------------
diagnose_godot_setup() {
  [ "$RUN_DIAGNOSTICS" = true ] || return 0

  print_section "Diagnostics"

  if [ "$DRY_RUN" = true ]; then
    print_info "Dry-run enabled: skipping file existence validation"
    if command_exists godot; then
      print_status "Godot available: $(godot --version 2>/dev/null | head -1)"
    else
      print_info "Godot not in PATH (dry-run)"
    fi
    return 0
  fi

  if command_exists godot; then
    print_status "Godot: $(godot --version 2>/dev/null | head -1)"
    print_info "Path: $(command -v godot)"
  else
    print_warning "Godot: not found in PATH"
  fi

  local template_dir="${HOME}/.local/share/godot/export_templates"
  if [ -d "$template_dir" ]; then
    local count
    count="$(ls -1 "$template_dir" 2>/dev/null | wc -l | tr -d ' ')"
    [ "$count" -gt 0 ] && print_status "Export templates dir present: $template_dir" || print_warning "Export templates dir empty: $template_dir"
  else
    print_warning "Export templates dir not found (ok if you don't export yet)"
  fi

  if [ -n "${DISPLAY-}" ] || [ -n "${WAYLAND_DISPLAY-}" ] || [ -d "/mnt/wslg" ]; then
    print_status "Display appears configured (GUI should work)"
  else
    print_warning "No DISPLAY/WAYLAND_DISPLAY detected. Godot may require WSLg or an X server for GUI."
  fi

  if [ -f "${PROJECT_DIR}/project.godot" ]; then
    print_status "project.godot present"
  else
    print_warning "project.godot missing"
  fi

  if [ -n "$MAIN_SCENE_PATH" ] && [ -f "${PROJECT_DIR}/${MAIN_SCENE_PATH#res://}" ]; then
    print_status "Main scene present: $MAIN_SCENE_PATH"
  else
    print_warning "Main scene missing: $MAIN_SCENE_PATH"
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
print_final_summary() {
  print_section "${ROCKET} Setup Complete"

  echo ""
  echo "Project:"
  echo "  Name:       $PROJECT_NAME"
  echo "  Location:   $PROJECT_DIR"
  echo "  Template:   $TEMPLATE_TYPE"
  echo "  Resolution: $RESOLUTION"
  echo "  Pixel Art:  $PIXEL_ART"
  echo "  Godot:      $GODOT_VERSION"
  echo "  Main Scene: $MAIN_SCENE_PATH"
  echo ""

  if [ "$DRY_RUN" = true ]; then
    echo -e "${CYAN}Note:${NC} Dry-run was enabled; no files were written."
    echo ""
  fi

  if [ "${#warnings[@]}" -gt 0 ]; then
    echo -e "${YELLOW}Warnings:${NC}"
    for w in "${warnings[@]}"; do
      echo "  - $w"
    done
    echo ""
  fi

  if [ "${#failed_steps[@]}" -gt 0 ]; then
    echo -e "${RED}Failed Steps:${NC}"
    for s in "${failed_steps[@]}"; do
      echo "  - $s"
    done
    echo ""
    echo "You can re-run the script safely; writes are atomic and backups are created when content changes."
    echo ""
  fi

  echo "Next:"
  echo "  cd \"$PROJECT_DIR\""
  echo "  godot --editor --path ."
  echo ""
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {

  parse_arguments "$@" || { failed_steps+=("parse_arguments"); show_usage; exit 1; }
  validate_inputs || { failed_steps+=("validate_inputs"); exit 1; }
  echo ""
  echo "${GAME} ${SCRIPT_NAME} v${SCRIPT_VERSION}"
  echo "════════════════════════════════════════════"

  check_wsl_environment || true

  if ! run_preflight_checks; then
    failed_steps+=("preflight")
    print_error "Pre-flight checks failed (missing required tooling)."
    print_final_summary
    exit 1
  fi

  if [ "$DRY_RUN" = true ]; then
    print_info "DRY RUN MODE - No changes will be made"
  fi

  echo ""
  print_info "Configuration:"
  echo "  Project:     $PROJECT_NAME"
  echo "  Directory:   $PROJECT_DIR"
  echo "  Template:    $TEMPLATE_TYPE"
  echo "  Main scene:  $MAIN_SCENE_PATH"
  echo "  Resolution:  $RESOLUTION"
  echo "  Pixel Art:   $PIXEL_ART"
  echo "  Godot:       $GODOT_VERSION"
  echo ""

  if [ "$DRY_RUN" != true ]; then
    if ! confirm "Proceed with setup?" "Y"; then
      print_info "Cancelled."
      exit 0
    fi
  fi
run_step install_godot install_godot

run_step create_project_structure create_project_structure

# If the project dir isn't available, don't spam follow-on failures.
if [ "$DRY_RUN" != true ] && { [ ! -d "$PROJECT_DIR" ] || [ ! -w "$PROJECT_DIR" ]; }; then
  print_error "Project directory is not available/writable: $PROJECT_DIR"
  add_failed_step "project_directory"
else
  run_step create_project_godot create_project_godot
  run_step create_autoload_scripts create_autoload_scripts
  run_step create_common_components create_common_components
  run_step create_template_content create_template_content
  run_step create_supporting_files create_supporting_files

  run_step generate_import_files generate_import_files
  run_step setup_git_repository setup_git_repository
fi


diagnose_godot_setup || true
  print_final_summary

  if [ "${#failed_steps[@]}" -gt 0 ]; then
    exit 1
  fi
  exit 0
}

main "$@"
