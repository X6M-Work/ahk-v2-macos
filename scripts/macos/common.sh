#!/usr/bin/env bash

MACOS_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYSHARP_ROOT="$(cd "${MACOS_SCRIPTS_DIR}/../.." && pwd)"
ETO_REPOSITORY=https://github.com/keysharp-org/Eto.git
ETO_COMMIT=0fb601a1ab078211d68ccbec86b7ff16ab3b21ad

die() { printf '%s\n' "$*" >&2; exit 1; }

host_rid() {
  case "$(uname -m)" in
    arm64|aarch64) printf '%s\n' osx-arm64 ;;
    x86_64|amd64) printf '%s\n' osx-x64 ;;
    *) return 1 ;;
  esac
}

resolve_keysharp() {
  KEYSHARP_PATH=''
  if [[ -n "${KEYSHARP_EXECUTABLE:-}" ]]; then
    if [[ -f "${KEYSHARP_EXECUTABLE}" && -x "${KEYSHARP_EXECUTABLE}" ]]; then
      KEYSHARP_PATH="${KEYSHARP_EXECUTABLE}"
      return 0
    fi
    return 1
  fi
  local rid config base candidate
  rid="$(host_rid)" || return 1
  local bases=("${KEYSHARP_ROOT}/dist/publish/${rid}/Keysharp")
  for config in Release Debug; do
    bases+=("${KEYSHARP_ROOT}/bin/${config}/net10.0/${rid}" "${KEYSHARP_ROOT}/bin/${config}/net10.0")
  done
  bases+=("${KEYSHARP_ROOT}" "${HOME}/Applications" /Applications)
  for base in "${bases[@]}"; do
    for candidate in "${base}/Keysharp.app/Contents/MacOS/Keysharp" "${base}/Keysharp"; do
      if [[ -f "${candidate}" && -x "${candidate}" ]]; then
        KEYSHARP_PATH="${candidate}"
        return 0
      fi
    done
  done
  return 1
}
