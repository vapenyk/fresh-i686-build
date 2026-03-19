#!/bin/sh
# fresh-install.sh — install/update/remove fresh i686 builds
# POSIX sh compatible

set -e

REPO="vapenyk/fresh-i686-build"
BINARY_NAME="fresh"
DEFAULT_INSTALL_DIR="$HOME/.local/bin"
META_FILE="$HOME/.local/share/fresh-installer/install.meta"

# ---- helpers ----------------------------------------------------------------

die() { printf 'Error: %s\n' "$1" >&2; exit 1; }

info()    { printf '  \033[1;34m::\033[0m %s\n' "$1"; }
success() { printf '  \033[1;32m✓\033[0m  %s\n' "$1"; }
warn()    { printf '  \033[1;33m!\033[0m  %s\n' "$1"; }
prompt()  { printf '  \033[1;37m??\033[0m %s ' "$1"; }

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

download() {
    url="$1"; dest="$2"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$dest"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$url" -O "$dest"
    else
        die "Neither curl nor wget found. Install one of them."
    fi
}

# ---- metadata ---------------------------------------------------------------

meta_save() {
    mkdir -p "$(dirname "$META_FILE")"
    printf 'VARIANT=%s\nVERSION=%s\nINSTALL_DIR=%s\n' \
        "$1" "$2" "$3" > "$META_FILE"
}

meta_load() {
    if [ -f "$META_FILE" ]; then
        # shellcheck disable=SC1090
        . "$META_FILE"
    fi
}

# ---- CPU detection ----------------------------------------------------------

detect_variant() {
    if [ -f /proc/cpuinfo ]; then
        if grep -qw 'pni' /proc/cpuinfo 2>/dev/null; then
            printf 'k8-sse3'
            return
        fi
    fi
    printf 'pentium4'
}

# ---- GitHub API -------------------------------------------------------------

latest_version() {
    tmp=$(mktemp)
    download "https://api.github.com/repos/$REPO/releases/latest" "$tmp"
    tag=$(grep '"tag_name"' "$tmp" | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
    rm -f "$tmp"
    printf '%s' "$tag"
}

download_url() {
    version="$1"; variant="$2"
    printf 'https://github.com/%s/releases/download/%s/fresh-%s' \
        "$REPO" "$version" "$variant"
}

# ---- PATH check -------------------------------------------------------------

check_path() {
    install_dir="$1"
    case ":$PATH:" in
        *":$install_dir:"*) return 0 ;;
    esac
    return 1
}

offer_path() {
    install_dir="$1"
    check_path "$install_dir" && return

    warn "$install_dir is not in your PATH."
    info "Binary installed at: $install_dir/$BINARY_NAME"
    info "Add this to your shell config:"
    printf '\n    export PATH="%s:$PATH"\n\n' "$install_dir"
}

# ---- choose variant ---------------------------------------------------------

choose_variant() {
    auto=$(detect_variant)

    printf '\n  Available builds:\n'
    printf '    1) k8-sse3   — AMD K8 / Sempron with SSE3\n'
    printf '    2) pentium4  — SSE2 only (broader compatibility)\n'
    printf '\n'
    info "Auto-detected: $auto"
    prompt "Choose variant [1/2] or press Enter to use detected:"
    read -r choice

    case "$choice" in
        1) printf 'k8-sse3' ;;
        2) printf 'pentium4' ;;
        *) printf '%s' "$auto" ;;
    esac
}

# ---- choose install dir -----------------------------------------------------

choose_install_dir() {
    prompt "Install directory [default: $DEFAULT_INSTALL_DIR]:"
    read -r dir
    if [ -z "$dir" ]; then
        printf '%s' "$DEFAULT_INSTALL_DIR"
    else
        printf '%s' "$dir"
    fi
}

# ---- actions ----------------------------------------------------------------

cmd_install() {
    meta_load
    if [ -n "$INSTALL_DIR" ] && [ -f "$INSTALL_DIR/$BINARY_NAME" ]; then
        warn "Already installed at $INSTALL_DIR/$BINARY_NAME (version: $VERSION, variant: $VARIANT)"
        prompt "Reinstall? [y/N]:"
        read -r ans
        case "$ans" in [Yy]*) ;; *) info "Aborted."; exit 0 ;; esac
    fi

    variant=$(choose_variant)
    install_dir=$(choose_install_dir)
    mkdir -p "$install_dir"

    info "Fetching latest version..."
    version=$(latest_version)
    [ -z "$version" ] || [ "$version" = "null" ] && die "Could not fetch latest version."

    info "Downloading fresh-$variant ($version)..."
    tmp=$(mktemp)
    download "$(download_url "$version" "$variant")" "$tmp"
    chmod +x "$tmp"
    mv "$tmp" "$install_dir/$BINARY_NAME"

    meta_save "$variant" "$version" "$install_dir"
    success "Installed fresh $version ($variant) → $install_dir/$BINARY_NAME"
    offer_path "$install_dir"
}

cmd_update() {
    meta_load
    [ -z "$VARIANT" ] && die "No installation metadata found. Run install first."

    info "Installed: version=$VERSION  variant=$VARIANT  dir=$INSTALL_DIR"
    info "Checking for updates..."

    latest=$(latest_version)
    [ -z "$latest" ] || [ "$latest" = "null" ] && die "Could not fetch latest version."

    if [ "$latest" = "$VERSION" ]; then
        success "Already up to date ($VERSION)."
        exit 0
    fi

    info "New version available: $VERSION → $latest"
    prompt "Update now? [Y/n]:"
    read -r ans
    case "$ans" in [Nn]*) info "Aborted."; exit 0 ;; esac

    tmp=$(mktemp)
    download "$(download_url "$latest" "$VARIANT")" "$tmp"
    chmod +x "$tmp"
    mv "$tmp" "$INSTALL_DIR/$BINARY_NAME"

    meta_save "$VARIANT" "$latest" "$INSTALL_DIR"
    success "Updated fresh $VERSION → $latest ($VARIANT)"
}

cmd_remove() {
    meta_load
    [ -z "$INSTALL_DIR" ] && die "No installation metadata found."

    target="$INSTALL_DIR/$BINARY_NAME"
    if [ ! -f "$target" ]; then
        die "Binary not found at $target"
    fi

    warn "This will remove $target and installation metadata."
    prompt "Continue? [y/N]:"
    read -r ans
    case "$ans" in [Yy]*) ;; *) info "Aborted."; exit 0 ;; esac

    rm -f "$target"
    rm -f "$META_FILE"
    success "Removed $target"
    info "Note: PATH entries in your shell rc file (if any) were not touched."
}

cmd_status() {
    meta_load
    if [ -z "$VARIANT" ]; then
        info "fresh is not installed (no metadata)."
        exit 0
    fi

    target="$INSTALL_DIR/$BINARY_NAME"
    if [ -f "$target" ]; then
        success "Installed: $target"
        info "Version : $VERSION"
        info "Variant : $VARIANT"
        check_path "$INSTALL_DIR" \
            && info "PATH    : OK" \
            || warn "PATH    : $INSTALL_DIR is NOT in PATH"
    else
        warn "Metadata exists but binary not found at $target"
    fi
}

# ---- usage ------------------------------------------------------------------

usage() {
    cat <<EOF

Usage: $(basename "$0") <command>

Commands:
  install   Download and install fresh
  update    Update to the latest version
  remove    Uninstall fresh
  status    Show installation info and PATH check

EOF
    exit 1
}

# ---- main -------------------------------------------------------------------

need_cmd grep
need_cmd sed
need_cmd mktemp
need_cmd chmod

case "$1" in
    install) cmd_install ;;
    update)  cmd_update  ;;
    remove)  cmd_remove  ;;
    status)  cmd_status  ;;
    *)       usage       ;;
esac
