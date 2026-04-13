#!/usr/bin/env bash
# =============================================================================
# Playwright Test Coverage Check — SessionStart Hook Script (Bash)
# =============================================================================

THRESHOLD=80
PAGES_DIR="src/ITextPdfService/Components/Pages"
TEST_DIR="e2e/tests/specs"

# Consume stdin
cat > /dev/null

# Discover Blazor pages with @page directive
pages=()
routes=()
if [ -d "$PAGES_DIR" ]; then
    for razor in "$PAGES_DIR"/*.razor; do
        [ -f "$razor" ] || continue
        route=$(grep -oP '@page\s+"([^"]+)"' "$razor" | head -1 | grep -oP '"[^"]+"' | tr -d '"')
        if [ -n "$route" ]; then
            name=$(basename "$razor" .razor)
            pages+=("$name")
            routes+=("$route")
        fi
    done
fi

total=${#pages[@]}
if [ "$total" -eq 0 ]; then exit 0; fi

# Check for corresponding test specs
covered=0
missing=()
for i in "${!pages[@]}"; do
    page="${pages[$i]}"
    route="${routes[$i]}"
    page_lower=$(echo "$page" | tr '[:upper:]' '[:lower:]')
    # Convert PascalCase to kebab-case
    page_kebab=$(echo "$page" | sed 's/\([A-Z]\)/-\1/g' | sed 's/^-//' | tr '[:upper:]' '[:lower:]')

    found=0
    for spec in "$TEST_DIR"/*.spec.ts; do
        [ -f "$spec" ] || continue
        spec_name=$(basename "$spec" .spec.ts)
        if [ "$spec_name" = "$page_lower" ] || [ "$spec_name" = "${page_lower}-page" ] || \
           [ "$spec_name" = "$page_kebab" ] || [ "$spec_name" = "${page_kebab}-page" ]; then
            found=1
            break
        fi
    done

    if [ "$found" -eq 1 ]; then
        covered=$((covered + 1))
    else
        missing+=("$page ($route)")
    fi
done

pct=$((covered * 100 / total))

if [ "$pct" -ge "$THRESHOLD" ]; then
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"SessionStart\",\"additionalContext\":\"Playwright test coverage: ${covered}/${total} pages (${pct}%) - meets ${THRESHOLD}% threshold.\"}}"
    exit 0
fi

# Build missing list
missing_str=""
for m in "${missing[@]}"; do
    missing_str="${missing_str}  - ${m}\n"
done

cat <<EOF
{
  "systemMessage": "PLAYWRIGHT COVERAGE: ${pct}% (${covered}/${total} pages) — below ${THRESHOLD}% threshold.\n\nMissing Playwright tests for:\n${missing_str}\nConsider adding .spec.ts files for the missing pages.",
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "Playwright test coverage is ${pct}% (${covered}/${total} Blazor pages covered). Threshold: ${THRESHOLD}%. Missing test specs for:\n${missing_str}Test files go in e2e/tests/specs/*.spec.ts with Page Objects in e2e/tests/pages/*.page.ts. Use Page Object Model pattern with stable locators (getByRole, getByText, getByTestId). Remind the developer about missing coverage and offer to help create the missing test specs."
  }
}
EOF
exit 0
