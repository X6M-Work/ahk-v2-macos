#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

eto_root="${EtoRoot:-${KEYSHARP_ROOT}/.deps/Eto}"
while (($#)); do
  case "$1" in
    --eto-root) (($# >= 2)) || die '--eto-root requires a path.'; eto_root="$2"; shift 2 ;;
    -h|--help) printf '%s\n' 'Usage: bootstrap.sh [--eto-root PATH]'; exit 0 ;;
    *) die "Unknown argument: $1" ;;
  esac
done
[[ -n "${eto_root}" ]] || die 'Eto root must not be empty.'
command -v git >/dev/null 2>&1 || die 'Git is required.'
if [[ ! -e "${eto_root}" ]]; then
  mkdir -p "${eto_root}"
fi
[[ -d "${eto_root}" ]] || die "Not a directory: ${eto_root}"
eto_root="$(cd "${eto_root}" && pwd -P)"
if [[ ! -e "${eto_root}/.git" ]]; then
  [[ -z "$(ls -A "${eto_root}")" ]] || die "Refusing to replace a non-Git directory: ${eto_root}"
  git init --quiet "${eto_root}"
  git -C "${eto_root}" remote add origin "${ETO_REPOSITORY}"
else
  checkout_root="$(git -C "${eto_root}" rev-parse --show-toplevel)"
  [[ "$(cd "${checkout_root}" && pwd -P)" == "${eto_root}" ]] || die 'Eto root must be the checkout root.'
fi
[[ -z "$(git -C "${eto_root}" status --porcelain --untracked-files=all --ignore-submodules=none)" ]] || die "Eto checkout has local changes; nothing was overwritten: ${eto_root}"
head_commit="$(git -C "${eto_root}" rev-parse --verify HEAD 2>/dev/null || true)"
if [[ "${head_commit}" != "${ETO_COMMIT}" ]]; then
  git -C "${eto_root}" fetch --depth 1 "${ETO_REPOSITORY}" "${ETO_COMMIT}"
  git -C "${eto_root}" checkout --detach "${ETO_COMMIT}"
fi
git -C "${eto_root}" submodule update --init --recursive
[[ "$(git -C "${eto_root}" rev-parse HEAD)" == "${ETO_COMMIT}" ]] || die 'Eto revision verification failed.'
printf 'Eto ready: %s (%s)\n' "${eto_root}" "${ETO_COMMIT}"
