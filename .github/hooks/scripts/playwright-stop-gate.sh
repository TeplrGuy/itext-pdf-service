#!/usr/bin/env bash
# =============================================================================
# Playwright Stop Gate — Stop Hook Script (Bash)
# =============================================================================

input=$(cat)

# CRITICAL: Check stop_hook_active to prevent infinite loops
stop_active=$(echo "$input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('stop_hook_active', False))" 2>/dev/null)
if [ "$stop_active" = "True" ] || [ "$stop_active" = "true" ]; then
    exit 0
fi

# Check if any spec files exist
shopt -s nullglob
specs=(e2e/tests/specs/*.spec.ts)
shopt -u nullglob
[ ${#specs[@]} -eq 0 ] && exit 0

# Run the full Playwright test suite
cd e2e || exit 0
result=$(npx playwright test --reporter=line 2>&1)
rc=$?
cd ..

if [ "$rc" -eq 0 ]; then
    exit 0
fi

escaped=$(echo "$result" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))" 2>/dev/null | sed 's/^"//;s/"$//')
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "Stop",
    "decision": "block",
    "reason": "Playwright tests are failing. Run the test suite and fix all failures before finishing:\\n${escaped}"
  }
}
EOF
exit 0
