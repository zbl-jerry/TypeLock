#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
DENYLIST="${2:-${ROOT_DIR}/script/license-denylist.txt}"
FAILED=0

fail() {
  echo "::error title=License check failed::$1" >&2
  FAILED=1
}

if [[ -f "${ROOT_DIR}/Package.resolved" && -f "${DENYLIST}" ]]; then
  while IFS= read -r pattern; do
    [[ -z "${pattern}" || "${pattern}" == \#* ]] && continue
    if grep -Fq -- "${pattern}" "${ROOT_DIR}/Package.resolved"; then
      fail "Package.resolved contains denied dependency pattern: ${pattern}"
    fi
  done < "${DENYLIST}"
fi

SOURCE_DIRS=()
for directory in "${ROOT_DIR}/TypeLock" "${ROOT_DIR}/TypeLockTests"; do
  [[ -d "${directory}" ]] && SOURCE_DIRS+=("${directory}")
done

if (( ${#SOURCE_DIRS[@]} > 0 )); then
  while IFS= read -r -d '' file; do
    if grep -Eq 'SPDX-License-Identifier:[[:space:]]*(GPL|AGPL)|GNU (General Public License|Affero General Public License)' "${file}"; then
      fail "GPL/AGPL source header found in ${file#"${ROOT_DIR}/"}"
    fi
  done < <(
    find "${SOURCE_DIRS[@]}" -type f \
      \( -name '*.swift' -o -name '*.h' -o -name '*.m' -o -name '*.mm' \
      -o -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.hpp' \) \
      -print0
  )
fi

if (( FAILED != 0 )); then
  exit 1
fi

echo "License checks passed."
