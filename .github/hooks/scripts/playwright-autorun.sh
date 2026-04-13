#!/usr/bin/env bash
# =============================================================================
# Playwright Auto-Run — PostToolUse Hook Script (Bash)
# =============================================================================

input=$(cat)
tool_name=$(echo "$input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null)

# Only trigger on file-editing tools
case "$tool_name" in
    editFiles|create_file|replace_string_in_file|multi_replace_string_in_file) ;;
    *) exit 0 ;;
esac

file_path=$(echo "$input" | python3 -c "
import sys, json
d = json.load(sys.stdin)
ti = d.get('tool_input', {})
print(ti.get('filePath', '') or (ti.get('files', [''])[0] if ti.get('files') else ''))
" 2>/dev/null)

[ -z "$file_path" ] && exit 0
echo "$file_path" | grep -qE '(Components|tests|specs|pages|e2e)' || exit 0

# Run Playwright tests
cd e2e || exit 0
result=$(npx playwright test --reporter=line 2>&1)
rc=$?
cd ..

if [ "$rc" -eq 0 ]; then
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"Playwright tests PASSED after editing $file_path\"}}"
else
    escaped=$(echo "$result" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))" 2>/dev/null | sed 's/^"//;s/"$//')
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"Playwright tests FAILED after editing ${file_path}:\\n${escaped}\\nFix the failing tests before proceeding.\"}}"
fi
exit 0
