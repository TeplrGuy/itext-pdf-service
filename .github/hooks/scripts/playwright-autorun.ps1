# =============================================================================
# Playwright Auto-Run — PostToolUse Hook Script (PowerShell)
# =============================================================================
# Runs Playwright tests after file edits in source or test directories
# and feeds results back to the agent for self-correction.
# =============================================================================

$inputData = [Console]::In.ReadToEnd() | ConvertFrom-Json
$toolName = $inputData.tool_name

# Only trigger on file-editing tools
if ($toolName -notin @("editFiles", "create_file", "replace_string_in_file", "multi_replace_string_in_file")) {
    exit 0
}

# Check if the edited file is in the source or test directories
$filePath = ""
if ($inputData.tool_input.filePath) { $filePath = $inputData.tool_input.filePath }
elseif ($inputData.tool_input.files) { $filePath = $inputData.tool_input.files[0] }

if (-not $filePath) { exit 0 }
if ($filePath -notmatch '(Components|tests|specs|pages|e2e)') { exit 0 }

# Run Playwright tests
Push-Location "e2e"
$result = npx playwright test --reporter=line 2>&1 | Out-String
$exitCode = $LASTEXITCODE
Pop-Location

if ($exitCode -eq 0) {
    @{
        hookSpecificOutput = @{
            hookEventName    = "PostToolUse"
            additionalContext = "Playwright tests PASSED after editing $filePath"
        }
    } | ConvertTo-Json -Depth 5 | Write-Output
} else {
    # Feed failure details back to the agent so it can self-correct
    @{
        hookSpecificOutput = @{
            hookEventName    = "PostToolUse"
            additionalContext = "Playwright tests FAILED after editing ${filePath}:`n${result}`nFix the failing tests before proceeding."
        }
    } | ConvertTo-Json -Depth 5 | Write-Output
}
exit 0
