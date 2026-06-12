#!/bin/bash
set -euo pipefail

# measure.sh — verifies NDS pak integrity for zero28

PAK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PAK_DIR"

errors=0
shellcheck_warnings=0

# Check shellcheck
echo "=== Check 1: Shellcheck ==="
if command -v shellcheck >/dev/null 2>&1; then
  count=$(shellcheck --severity=warning launch.sh 2>/dev/null | grep -c "^In " || true)
  shellcheck_warnings=$count
  echo "Shellcheck warnings: $shellcheck_warnings"
  if [ "$shellcheck_warnings" -gt 0 ]; then
    errors=$((errors + shellcheck_warnings))
  fi
else
  echo "shellcheck not found, skipping"
fi

# Check zero28 in pak.json
echo "=== Check 2: zero28 platform support ==="
if grep -q '"zero28"' pak.json; then
  echo "OK: zero28 in pak.json"
else
  echo "FAIL: zero28 missing from pak.json"
  errors=$((errors + 1))
fi

# Check working drastic64 binary exists
echo "=== Check 3: Emulator binary ==="
if [ -f drastic/drastic64 ]; then
  size=$(wc -c < drastic/drastic64)
  echo "OK: drastic/drastic64 exists ($size bytes)"
else
  echo "FAIL: drastic/drastic64 missing"
  errors=$((errors + 1))
fi

# Check bios files exist
echo "=== Check 4: BIOS files ==="
for bios in drastic/system/drastic_bios_arm7.bin drastic/system/drastic_bios_arm9.bin; do
  if [ -f "$bios" ]; then
    echo "OK: $bios exists"
  else
    echo "FAIL: $bios missing"
    errors=$((errors + 1))
  fi
done

# Check launch.sh has the sync loop pattern
echo "=== Check 5: Launch pattern ==="
if grep -q "syncsettings.elf" launch.sh; then
  echo "OK: syncsettings.elf background loop present"
else
  echo "FAIL: syncsettings.elf pattern missing"
  errors=$((errors + 1))
fi
if grep -q "drastic64" launch.sh; then
  echo "OK: launch.sh calls drastic64 binary"
else
  echo "FAIL: launch.sh doesn't reference drastic64"
  errors=$((errors + 1))
fi
if grep -q "LOOP_PID" launch.sh; then
  echo "OK: sync loop PID tracking for cleanup"
else
  echo "FAIL: sync loop PID tracking missing"
  errors=$((errors + 1))
fi

echo ""
echo "METRIC shellcheck_warnings=$shellcheck_warnings"
echo "METRIC launch_errors=$errors"
if [ "$errors" -gt 0 ]; then
  echo "FAILED: $errors issues found"
  exit 1
fi
echo "PASSED: All checks passed"
exit 0
