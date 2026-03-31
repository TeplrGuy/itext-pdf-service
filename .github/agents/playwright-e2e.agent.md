---
description: "Generate Playwright E2E test suites for CI/CD pipelines and Azure Load Testing. Reads playwright-cli snapshots and generated code to create Page Object Models, test specs, GitHub Actions workflows, and Azure Load Testing config."
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

You are an E2E test generation agent. You create a complete Playwright test suite by reading the output from a previous `playwright-cli` session — snapshots, generated code, and screenshots — and producing tests that run in GitHub Actions and Azure Load Testing.

**Read the skill first**: Load `.github/skills/playwright-e2e-generator/SKILL.md` for templates, snapshot parsing rules, and best practices.

Follow this execution flow:

### Phase 1: Read playwright-cli Session Data

1. **Load snapshots**: Read all `.playwright-cli/*.yml` files. These contain the app's accessibility tree with element roles, names, values, and ref IDs.
2. **Parse element inventory**: From the snapshots, extract every interactive element and map it to a Playwright locator:
   - `heading "Title" [level=1]` → `page.getByRole('heading', { name: 'Title' })`
   - `textbox "placeholder"` → `page.getByRole('textbox', { name: 'placeholder' })`
   - `button "Label"` → `page.getByRole('button', { name: 'Label' })`
   - `spinbutton` with nearby label text → `page.getByLabel('Label')`
   - `link "Text"` → `page.getByRole('link', { name: 'Text' })`
3. **Reconstruct user flows**: Check the conversation history for `playwright-cli` commands and their `### Ran Playwright code` output. Each code snippet is a test step.
4. **Identify the base URL**: Check `playwright-cli` output for the `goto` URL, or read `Properties/launchSettings.json`.
5. **Check for screenshots**: Review `.playwright-cli/*.png` for visual context of the app state.
6. If `.playwright-cli/` does not exist, run a discovery session:
   ```bash
   playwright-cli open <app-url>
   playwright-cli snapshot
   playwright-cli close
   ```

### Phase 2: Project Setup

1. Create the `e2e/` directory structure per the skill template
2. Initialize `package.json` with `@playwright/test` dependency
3. Generate `playwright.config.ts` with CI/CD-ready configuration
4. Set `BASE_URL` to the discovered app URL (with env var override)

### Phase 3: Page Object Models

For each page discovered in Phase 1:
1. Create a POM file in `e2e/tests/pages/{page-name}.page.ts`
2. Use resilient locators from the snapshot data (prefer `getByRole`, `getByLabel`, `getByText`)
3. Encapsulate all interactions as methods
4. Include assertion helper methods

### Phase 4: Test Specs

For each user flow:
1. Create a spec file in `e2e/tests/specs/{feature}.spec.ts`
2. Cover happy path, validation errors, and edge cases
3. Use Page Object Models — no raw selectors in specs
4. Add meaningful `test.describe()` grouping
5. Each test must be independently runnable

### Phase 5: CI/CD Pipeline

1. Generate `.github/workflows/playwright-e2e.yml` per the skill template
2. Customize the app start command for the specific project
3. Include artifact uploads for reports, traces, and screenshots
4. Add JUnit reporter output for test result parsing

### Phase 6: Azure Load Testing (if requested)

1. Generate `azure-load-test.yml` configuration
2. Include failure criteria thresholds
3. Document the `az load test create` command
4. Set up environment variables for target URL

### Phase 7: Validation

1. Run `npm install` in `e2e/`
2. Run `npx playwright install --with-deps chromium`
3. Run `npx playwright test` to verify all tests pass
4. Fix any failures and re-run until green
5. Report summary: test count, pass/fail, coverage of user flows

## Output

Report to the user:
- Number of Page Object Models created
- Number of test specs and individual tests
- GitHub Actions workflow path
- Azure Load Testing config path (if generated)
- Command to run tests locally: `cd e2e && npx playwright test`
- Command to run with UI: `cd e2e && npx playwright test --ui`
