#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
CHECK_SCRIPT="${ROOT_DIR}/script/check_licenses.sh"
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/typelock-license-checks.XXXXXX")
trap 'rm -rf "${TEST_DIR}"' EXIT

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

mkdir -p "${TEST_DIR}/TypeLock" "${TEST_DIR}/script"

cat > "${TEST_DIR}/script/license-denylist.txt" <<'EOF'
# Test denylist
forbidden-package
EOF

cat > "${TEST_DIR}/Package.resolved" <<'EOF'
{
  "pins": [
    { "location": "https://github.com/example/allowed-package" }
  ]
}
EOF

printf 'import Foundation\n' > "${TEST_DIR}/TypeLock/Clean.swift"
"${CHECK_SCRIPT}" "${TEST_DIR}" "${TEST_DIR}/script/license-denylist.txt" >/dev/null

printf '// SPDX-License-Identifier: GPL-3.0-only\n' > "${TEST_DIR}/TypeLock/GPL.swift"
if "${CHECK_SCRIPT}" "${TEST_DIR}" "${TEST_DIR}/script/license-denylist.txt" >/dev/null 2>&1; then
  fail "A GPL source header was accepted."
fi
rm "${TEST_DIR}/TypeLock/GPL.swift"

cat > "${TEST_DIR}/Package.resolved" <<'EOF'
{
  "pins": [
    { "location": "https://github.com/example/forbidden-package" }
  ]
}
EOF
if "${CHECK_SCRIPT}" "${TEST_DIR}" "${TEST_DIR}/script/license-denylist.txt" >/dev/null 2>&1; then
  fail "A denied dependency was accepted."
fi

echo "License check tests passed."
