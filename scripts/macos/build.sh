#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

configuration=Debug
rid=''
action=build
eto_root="${EtoRoot:-${KEYSHARP_ROOT}/.deps/Eto}"
while (($#)); do
  case "$1" in
    --configuration) (($# >= 2)) || die '--configuration requires Debug or Release.'; configuration="$2"; shift 2 ;;
    --rid) (($# >= 2)) || die '--rid requires osx-arm64 or osx-x64.'; rid="$2"; shift 2 ;;
    --eto-root) (($# >= 2)) || die '--eto-root requires a path.'; eto_root="$2"; shift 2 ;;
    --publish) action=publish; shift ;;
    -h|--help) printf '%s\n' 'Usage: build.sh [--configuration Debug|Release] [--rid osx-arm64|osx-x64] [--publish] [--eto-root PATH]'; exit 0 ;;
    *) die "Unknown argument: $1" ;;
  esac
done
case "${configuration}" in Debug|Release) ;; *) die 'Configuration must be Debug or Release.' ;; esac
[[ "$(uname -s)" == Darwin ]] || die 'Build on macOS; project platform selection depends on the host OS.'
macos_version="$(sw_vers -productVersion)"
[[ "${macos_version%%.*}" =~ ^[0-9]+$ ]] && (( ${macos_version%%.*} >= 15 )) || die "macOS 15 or newer is required (detected ${macos_version})."
[[ -n "${rid}" ]] || rid="$(host_rid)" || die 'Unknown host architecture; pass --rid osx-arm64 or --rid osx-x64.'
case "${rid}" in osx-arm64|osx-x64) ;; *) die 'RID must be osx-arm64 or osx-x64.' ;; esac
command -v dotnet >/dev/null 2>&1 || die 'Install the .NET 10 SDK, then retry.'
dotnet --list-sdks | awk '$1 ~ /^10\./ { found=1 } END { exit !found }' || die 'The .NET 10 SDK is required.'
[[ -d "${eto_root}" ]] || die 'Eto is missing; run bash scripts/macos/bootstrap.sh first.'
eto_root="$(cd "${eto_root}" && pwd -P)"
[[ -f "${eto_root}/src/Eto.Mac/build/Mac.props" && -f "${eto_root}/lib/monomac/src/MonoMac.csproj" ]] || die 'Eto or its submodules are incomplete; run bootstrap.sh.'
[[ "$(git -C "${eto_root}" rev-parse HEAD)" == "${ETO_COMMIT}" ]] || die 'Eto differs from the pinned revision; run bootstrap.sh or restore the pinned checkout.'
args=("${action}" "${KEYSHARP_ROOT}/Keysharp/Keysharp.csproj" --configuration "${configuration}" --runtime "${rid}" "-p:EtoRoot=${eto_root}" -p:PublishReadyToRun=false --nologo)
if [[ "${action}" == publish ]]; then
  args+=(--self-contained false --output "${KEYSHARP_ROOT}/dist/publish/${rid}/Keysharp")
fi
exec dotnet "${args[@]}"
