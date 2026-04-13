# =============================================================================
# Playwright Stop Gate — Stop Hook Script (PowerShell)
# =============================================================================
# Prevents the agent from finishing if Playwright tests are failing.
# CRITICAL: Checks stop_hook_active to prevent infinite loops.
# =============================================================================

$inputData = [Console]::In.ReadToEnd() | ConvertFrom-Json

# CRITICAL: Check stop_hook_active to prevent infinite loops.
# If true, the agent was already continued once — let it stop this time.
if ($inputData.stop_hook_active -eq $true) {
    exit 0
}

# Check if any spec files exist — if not, no tests to run
$specFiles = Get-ChildItem "e2e/tests/specs/*.spec.ts" -ErrorAction SilentlyContinue
if (-not $specFiles -or $specFiles.Count -eq 0) {
    exit 0
}

# Run the full Playwright test suite
Push-Location "e2e"
$result = npx playwright test --reporter=line 2>&1 | Out-String
$exitCode = $LASTEXITCODE
Pop-Location

if ($exitCode -eq 0) {
    # Tests pass — let the agent stop normally
    exit 0
}

# Tests failed — block the agent from stopping
@{
    hookSpecificOutput = @{
        hookEventName = "Stop"
        decision      = "block"
        reason        = "Playwright tests are failing. Run the test suite and fix all failures before finishing:`n${result}"
    }
} | ConvertTo-Json -Depth 5 | Write-Output
exit 0
