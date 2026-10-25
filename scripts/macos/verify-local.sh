#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

baseline=''
output=''
configuration=Release
skip_build=false
while (($#)); do
  case "$1" in
    --baseline-dir) (($# >= 2)) || die '--baseline-dir requires a path.'; baseline="$2"; shift 2 ;;
    --output-dir) (($# >= 2)) || die '--output-dir requires a path.'; output="$2"; shift 2 ;;
    --configuration) (($# >= 2)) || die '--configuration requires Debug or Release.'; configuration="$2"; shift 2 ;;
    --skip-build) skip_build=true; shift ;;
    -h|--help) printf '%s\n' 'Usage: verify-local.sh --baseline-dir PATH [--output-dir PATH] [--configuration Debug|Release] [--skip-build]'; exit 0 ;;
    *) die "Unknown argument: $1" ;;
  esac
done
[[ "$(uname -s)" == Darwin ]] || die 'Native validation must run on macOS.'
macos_version="$(sw_vers -productVersion)"
[[ "${macos_version%%.*}" =~ ^[0-9]+$ ]] && (( ${macos_version%%.*} >= 15 )) || die 'macOS 15 or newer is required.'
[[ "$(sysctl -in sysctl.proc_translated 2>/dev/null || true)" != 1 ]] || die 'Run from a native terminal, outside Rosetta.'
case "${configuration}" in Debug|Release) ;; *) die 'Configuration must be Debug or Release.' ;; esac
[[ -d "${baseline}" ]] || die 'Supply the local Windows reference directory via --baseline-dir.'
baseline="$(cd "${baseline}" && pwd -P)"
rid="$(host_rid)" || die 'Unsupported host architecture.'
[[ -n "${output}" ]] || output="${KEYSHARP_ROOT}/compat/reports/local-${rid}"
mkdir -p "${output}"
output="$(cd "${output}" && pwd -P)"
[[ "${output}" != "${baseline}" ]] || die 'Reference and output directories must differ.'
command -v python3 >/dev/null 2>&1 || die 'Python 3.10+ is required.'
command -v dotnet >/dev/null 2>&1 || die '.NET 10 SDK is required.'
cd "${KEYSHARP_ROOT}"
sw_vers > "${output}/host.txt"
uname -a >> "${output}/host.txt"
dotnet --info >> "${output}/host.txt"
if [[ "${skip_build}" == false ]]; then
  bash scripts/macos/build.sh --configuration "${configuration}" --rid "${rid}" > "${output}/build.log" 2>&1 || { cat "${output}/build.log" >&2; exit 1; }
fi
engine="${KEYSHARP_ROOT}/bin/${configuration}/net10.0/${rid}/Keysharp.app/Contents/MacOS/Keysharp"
[[ -x "${engine}" ]] || engine="${KEYSHARP_ROOT}/bin/${configuration}/net10.0/${rid}/Keysharp"
[[ -x "${engine}" ]] || die 'Native executable not found; build first.'
binary_info="$(file -b "${engine}")"
case "${rid}:${binary_info}" in
  osx-arm64:*arm64*|osx-x64:*x86_64*) ;;
  *) die "Executable architecture does not match ${rid}: ${binary_info}" ;;
esac
result=0
python3 compat/suite.py --engine keysharp --executable "${engine}" --output-dir "${output}" --baseline-dir "${baseline}" --timeout 120 || result=1
python3 compat/run.py --engine keysharp --executable "${engine}" --corpus compat/phase15-architecture/macos --output "${output}/native-abi.json" --timeout 120 || result=1
printf 'Local reports: %s\n' "${output}"
exit "${result}"
