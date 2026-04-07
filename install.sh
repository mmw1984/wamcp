#!/usr/bin/env bash
set -euo pipefail

# Public installer for wamcp (macOS + Ubuntu)
# Installs:
# - source checkout into ~/.wamcp-src/<ref>
# - symlink ~/.wamcp-src/current -> that checkout
# - wrapper ~/.local/bin/wamcp that sets WAMCP_ROOT and runs scripts/wamcp
#
# Usage:
#   curl -fsSL <url-to-install.sh> | bash
#   curl -fsSL <url-to-install.sh> | bash -s -- --ref v0.1.0
#   curl -fsSL <url-to-install.sh> | bash -s -- --uninstall

# Default to the public distribution repo.
# You can override with WAMCP_REPO_URL or --repo.
REPO_URL_DEFAULT="https://github.com/mmw1984/wamcp"

REF="main"
REPO_URL="${WAMCP_REPO_URL:-$REPO_URL_DEFAULT}"
INSTALL_BIN_DIR="${WAMCP_BIN_DIR:-$HOME/.local/bin}"
SRC_BASE_DIR="${WAMCP_SRC_DIR:-$HOME/.wamcp-src}"

print() { printf "[wamcp-install] %s\n" "$*"; }
err() { printf "[wamcp-install] ERROR: %s\n" "$*" >&2; }

usage() {
  cat <<EOF
wamcp installer

Options:
  --ref <ref>         Git ref (tag/branch/commit). Default: ${REF}
  --repo <url>        Git repo URL. Default: ${REPO_URL}
  --uninstall         Remove ~/.local/bin/wamcp, ~/.wamcp, and source checkout (${SRC_BASE_DIR})
  --purge             Keep compatibility flag (currently same as --uninstall)
EOF
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { err "missing command: $1"; return 1; }
}

download_and_extract_tarball() {
  local url="$1"
  local dest_dir="$2"

  need_cmd curl
  need_cmd tar

  mkdir -p "${dest_dir}"

  # Expect tarball with top-level folder, extract into dest_dir
  curl -fsSL "${url}" | tar -xz -C "${dest_dir}" --strip-components=1
}

ensure_path_hint() {
  if [[ ":$PATH:" != *":${INSTALL_BIN_DIR}:"* ]]; then
    print "NOTE: ${INSTALL_BIN_DIR} is not on PATH."
    if [[ -n "${SHELL:-}" && "${SHELL}" == *"zsh"* ]]; then
      print "Add this to ~/.zshrc:"
    else
      print "Add this to ~/.bashrc (or your shell rc):"
    fi
    printf "  export PATH=\"%s:$PATH\"\n" "${INSTALL_BIN_DIR}"
  fi
}

uninstall() {
  local purge="${1:-false}"
  rm -f "${INSTALL_BIN_DIR}/wamcp" || true
  rm -rf "${HOME}/.wamcp" || true
  rm -rf "${SRC_BASE_DIR}" || true
  if [[ "${purge}" == "true" ]]; then
    rm -rf "${HOME}/.wamcp-src/current" || true
    rm -rf "${HOME}/.wamcp-src" || true
  fi
  print "Uninstalled wamcp."
}

parse_args() {
  local purge=false uninstall_flag=false
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --ref) REF="${2:-}"; shift 2 ;;
      --repo) REPO_URL="${2:-}"; shift 2 ;;
      --uninstall) uninstall_flag=true; shift ;;
      --purge) purge=true; shift ;;
      -h|--help) usage; exit 0 ;;
      *) err "Unknown arg: $1"; usage; exit 1 ;;
    esac
  done

  if [[ "${uninstall_flag}" == "true" ]]; then
    uninstall "${purge}"
    exit 0
  fi

  if [[ -z "${REF}" ]]; then
    err "--ref requires a value"
    exit 1
  fi
}

main() {
  parse_args "$@"
  # Prefer git, fallback to tarball if unavailable or clone fails.
  if command -v git >/dev/null 2>&1; then
    : # ok
  else
    print "git not found; will attempt tarball download fallback."
  fi

  mkdir -p "${INSTALL_BIN_DIR}" "${SRC_BASE_DIR}"

  local target_dir="${SRC_BASE_DIR}/${REF}"

  if command -v git >/dev/null 2>&1; then
    if [[ -d "${target_dir}/.git" ]]; then
      print "Updating existing checkout: ${target_dir}"
      git -C "${target_dir}" fetch --all --tags || true
      git -C "${target_dir}" checkout -q "${REF}" || true
      git -C "${target_dir}" pull -q --ff-only || true
    else
      print "Cloning ${REPO_URL} into ${target_dir}"
      if git clone -q "${REPO_URL}" "${target_dir}"; then
        git -C "${target_dir}" checkout -q "${REF}" || true
      else
        rm -rf "${target_dir}" || true
        print "git clone failed; falling back to tarball download."
      fi
    fi
  fi

  if [[ ! -x "${target_dir}/scripts/wamcp" ]]; then
    # Tarball fallback convention (GitHub):
    # - tag: https://github.com/<owner>/<repo>/archive/refs/tags/<ref>.tar.gz
    # - branch: https://github.com/<owner>/<repo>/archive/refs/heads/<ref>.tar.gz
    if [[ "${REPO_URL}" == https://github.com/*/* ]]; then
      local tarball_url
      tarball_url="${REPO_URL}/archive/refs/tags/${REF}.tar.gz"
      print "Downloading tarball: ${tarball_url}"
      rm -rf "${target_dir}" || true
      download_and_extract_tarball "${tarball_url}" "${target_dir}" || {
        tarball_url="${REPO_URL}/archive/refs/heads/${REF}.tar.gz"
        print "Retry tarball as branch: ${tarball_url}"
        rm -rf "${target_dir}" || true
        download_and_extract_tarball "${tarball_url}" "${target_dir}"
      }
    else
      err "Cannot install without git unless REPO_URL is a GitHub repo URL."
      exit 1
    fi
  fi

  ln -sfn "${target_dir}" "${SRC_BASE_DIR}/current"
  chmod +x "${SRC_BASE_DIR}/current/scripts/wamcp"

  # Install wrapper so global `wamcp` can locate the repo root reliably.
  cat > "${INSTALL_BIN_DIR}/wamcp" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

WAMCP_ROOT_DEFAULT="${HOME}/.wamcp-src/current"
export WAMCP_ROOT="${WAMCP_ROOT:-$WAMCP_ROOT_DEFAULT}"

exec "${WAMCP_ROOT}/scripts/wamcp" "$@"
EOF
  chmod +x "${INSTALL_BIN_DIR}/wamcp"

  ensure_path_hint

  print "Installed: ${INSTALL_BIN_DIR}/wamcp"
  print "Next:"
  print "  wamcp doctor"
  print "  wamcp install   # Python deps + bridge (Linux tries prebuilt binary from GitHub Releases)"
  print "  wamcp start"
}

main "$@"

