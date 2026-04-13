# =============================================================================
# Playwright Test Coverage Check — SessionStart Hook Script (PowerShell)
# =============================================================================
# Discovers Blazor pages (@page directive) and checks for corresponding
# Playwright test specs. If coverage is below the threshold, shows a
# warning to the developer and injects context so the agent knows which
# pages need tests.
#
# Exit 0 with JSON stdout. Uses systemMessage for visible warnings.
# =============================================================================

$THRESHOLD = 80
$PAGES_DIR = "src/ITextPdfService/Components/Pages"
$TEST_DIR  = "e2e/tests/specs"

# Read and discard stdin (hook sends common fields we don't need here)
try { [Console]::In.ReadToEnd() | Out-Null } catch {}

# ---------------------------------------------------------------------------
# Step 1: Discover Blazor pages (*.razor files with @page directive)
# ---------------------------------------------------------------------------
$pages = @()
$razorFiles = Get-ChildItem "$PAGES_DIR/*.razor" -ErrorAction SilentlyContinue
foreach ($file in $razorFiles) {
    $content = Get-Content $file.FullName -Raw
    if ($content -match '@page\s+"([^"]+)"') {
        $pages += @{
            Name  = $file.BaseName
            Route = $Matches[1]
            File  = $file.FullName
        }
    }
}

if ($pages.Count -eq 0) { exit 0 }

# ---------------------------------------------------------------------------
# Step 2: Check for corresponding test specs
# ---------------------------------------------------------------------------
$testFiles = Get-ChildItem "$TEST_DIR/*.spec.ts" -ErrorAction SilentlyContinue
$testNames = @($testFiles | ForEach-Object { $_.BaseName -replace '\.spec$', '' })

$coveredCount = 0
$missingPages = @()

foreach ($page in $pages) {
    $pageLower = $page.Name.ToLower()
    # Match: Home.razor -> home.spec.ts or home-page.spec.ts
    # Also match kebab-case: TaxStatement.razor -> tax-statement.spec.ts
    $pageKebab = ($page.Name -creplace '([A-Z])', '-$1').TrimStart('-').ToLower()
    $found = $testNames | Where-Object {
        $_ -eq $pageLower -or
        $_ -eq "$pageLower-page" -or
        $_ -eq $pageKebab -or
        $_ -eq "$pageKebab-page" -or
        $_ -match $pageLower
    }
    if ($found) { $coveredCount++ }
    else { $missingPages += "$($page.Name) ($($page.Route))" }
}

$coveragePct = [math]::Round(($coveredCount / $pages.Count) * 100, 1)

# ---------------------------------------------------------------------------
# Step 3: Output JSON result
# ---------------------------------------------------------------------------
if ($coveragePct -ge $THRESHOLD) {
    @{
        hookSpecificOutput = @{
            hookEventName    = "SessionStart"
            additionalContext = "Playwright test coverage: $coveredCount/$($pages.Count) pages (${coveragePct}%) - meets ${THRESHOLD}% threshold."
        }
    } | ConvertTo-Json -Depth 5 | Write-Output
    exit 0
}

# Below threshold — warn the developer and inject context for the model
$missingList = ($missingPages | ForEach-Object { "  - $_" }) -join "`n"

$warningMsg = @"
PLAYWRIGHT COVERAGE: ${coveragePct}% (${coveredCount}/$($pages.Count) pages) — below ${THRESHOLD}% threshold.

Missing Playwright tests for:
$missingList

Consider adding .spec.ts files for the missing pages.
"@

$modelContext = @"
Playwright test coverage is ${coveragePct}% (${coveredCount}/$($pages.Count) Blazor pages covered).
Threshold: ${THRESHOLD}%. Missing test specs for:
$missingList
Test files go in e2e/tests/specs/*.spec.ts with Page Objects in
e2e/tests/pages/*.page.ts. Use Page Object Model pattern with stable
locators (getByRole, getByText, getByTestId). Remind the developer
about missing coverage and offer to help create the missing test specs.
"@

@{
    systemMessage      = $warningMsg
    hookSpecificOutput = @{
        hookEventName    = "SessionStart"
        additionalContext = $modelContext
    }
} | ConvertTo-Json -Depth 5 | Write-Output
exit 0
