# Shared helpers for the tools/ scripts (sourced, not executed).

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
image=${LNOTES_IMAGE:-latex-lecture-notes:tl2025}

# Run a command in the TeX Live container with a memory cap.
#   in_container <memory> <command...>
# The TEXMFVAR cache persists font caches between runs (luaotfload is slow
# to rebuild them).  Swap is allowed: do not set --memory-swap to the same
# value, or a build that needs a little more memory is killed instead.
in_container() {
  local mem=$1; shift
  if ! docker image inspect "$image" >/dev/null 2>&1; then
    echo "docker image $image not found: run 'make docker-build' first" >&2
    return 125
  fi
  mkdir -p "$HOME/.cache/texmf-var-docker"
  timeout "${LNOTES_TIMEOUT:-2400}" docker run --rm --memory="$mem" \
    -v "$root":/work -w /work -u "$(id -u):$(id -g)" \
    -e HOME=/home/texlive -e TEXMFVAR=/texmf-var \
    -v "$HOME/.cache/texmf-var-docker":/texmf-var \
    "$image" "$@"
}

# Commit trailer lines (e.g. Co-Authored-By) appended to every commit made by
# the commit-*.sh scripts: $COMMIT_TRAILERS, else .git/commit-trailers.
commit_trailers() {
  if [ -n "${COMMIT_TRAILERS:-}" ]; then
    printf '%s\n' "$COMMIT_TRAILERS"
  elif [ -f "$root/.git/commit-trailers" ]; then
    cat "$root/.git/commit-trailers"
  fi
}
