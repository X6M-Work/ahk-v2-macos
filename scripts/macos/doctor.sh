#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

status=0
printf 'OS: %s\nArchitecture: %s\n' "$(uname -s)" "$(uname -m)"
if [[ "$(uname -s)" == Darwin ]]; then
  macos_version="$(sw_vers -productVersion)"
  printf 'macOS version: %s\n' "${macos_version}"
  if [[ ! "${macos_version%%.*}" =~ ^[0-9]+$ ]] || (( ${macos_version%%.*} < 15 )); then
    printf '%s\n' 'macOS 15 or newer is required.'
    status=1
  fi
else
  printf '%s\n' 'macOS is required for native builds and runtime verification.'
  status=1
fi
if command -v dotnet >/dev/null 2>&1; then
  printf '%s\n' '.NET SDKs:'
  dotnet --list-sdks || status=1
  if ! dotnet --list-sdks | awk '$1 ~ /^10\./ { found=1 } END { exit !found }'; then
    printf '%s\n' '.NET 10 SDK is missing.'
    status=1
  fi
else
  printf '%s\n' '.NET SDK: missing (install the .NET 10 SDK).'
  status=1
fi
eto_root="${EtoRoot:-${KEYSHARP_ROOT}/.deps/Eto}"
printf 'Eto: %s\nExpected revision: %s\n' "${eto_root}" "${ETO_COMMIT}"
if command -v git >/dev/null 2>&1 && [[ -e "${eto_root}/.git" ]]; then
  actual_commit="$(git -C "${eto_root}" rev-parse HEAD 2>/dev/null || true)"
  printf 'Actual revision: %s\n' "${actual_commit:-unavailable}"
  [[ "${actual_commit}" == "${ETO_COMMIT}" ]] || status=1
  submodules="$(git -C "${eto_root}" submodule status --recursive)" || status=1
  printf '%s\n' "${submodules}"
  if [[ "${submodules}" == *$'\n-'* || "${submodules}" == -* || "${submodules}" == *$'\n+'* || "${submodules}" == +* || "${submodules}" == *$'\nU'* || "${submodules}" == U* ]]; then
    status=1
  fi
else
  printf '%s\n' 'Pinned dependency checkout is missing; run bootstrap.sh.'
  status=1
fi
if resolve_keysharp; then
  printf 'Executable: %s\n' "${KEYSHARP_PATH}"
else
  printf '%s\n' 'Executable: missing (build.sh, or set KEYSHARP_EXECUTABLE).'
  status=1
fi
printf '%s\n' \
  'Permissions: System Settings > Privacy & Security.' \
  'Review Accessibility and Input Monitoring for input/window automation.' \
  'Review Screen Recording for screen capture, and Automation for Apple Events.' \
  'Grant permissions to the app/terminal macOS identifies. Relaunch after changes.' \
  'This report does not inspect or change permission grants or prove runtime compatibility.'
exit "${status}"
