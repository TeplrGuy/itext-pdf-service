---
name: playwright-e2e-generator
description: "Generate Playwright E2E test scripts for CI/CD pipelines and Azure Load Testing. Use when: creating end-to-end tests, generating Playwright test files, setting up CI/CD test pipelines, configuring Azure Load Testing with Playwright, writing automated UI tests, creating test suites for deployment gates."
---

# Playwright E2E Test Generator

## When to Use

- User has explored the app with `playwright-cli` and wants to convert that into a test suite
- User asks to create E2E tests or end-to-end tests for a web app
- User wants Playwright test scripts that run in CI/CD (GitHub Actions)
- User wants to set up Azure Load Testing with Playwright
- User says "write Playwright tests for this page" or "create E2E tests"
- User wants a test suite that serves as a deployment quality gate

## Input: playwright-cli Session Data

This skill is designed to chain from a `playwright-cli` session. After the user explores the app interactively with `playwright-cli`, this skill reads:

1. **Snapshot files** in `.playwright-cli/*.yml` — contains the page's accessibility tree with element roles, names, values, and refs
2. **Generated Playwright code** from `playwright-cli` terminal output — each `fill`, `click`, `type` command outputs the equivalent `await page.getBy*()` code
3. **Screenshots** in `.playwright-cli/*.png` — visual reference of the app state

### How to Read Snapshot Data

Snapshot YAML files use this format:
```yaml
- heading "Tax Statement Generator" [level=1] [ref=e18]
- textbox "e.g. John Smith" [ref=e29]: Sarah Johnson
- button "+ Add Source" [ref=e43] [cursor=pointer]
- spinbutton [ref=e35]: "2025"
```

**Extract locators from snapshots:**
| Snapshot Entry | Playwright Locator |
|---|---|
| `heading "Page Title" [level=1]` | `page.getByRole('heading', { name: 'Page Title' })` |
| `textbox "placeholder" [ref=eN]: value` | `page.getByRole('textbox', { name: 'placeholder' })` |
| `button "Button Text" [ref=eN]` | `page.getByRole('button', { name: 'Button Text' })` |
| `spinbutton [ref=eN]: "123"` | `page.getByRole('spinbutton')` (use label context) |
| `link "Link Text" [ref=eN]` | `page.getByRole('link', { name: 'Link Text' })` |
| Generic with text like `Full Name` | `page.getByText('Full Name')` or parent label |

### How to Read Generated Code

When `playwright-cli` runs commands, it outputs the equivalent Playwright code:
```
### Ran Playwright code
```js
await page.getByRole('textbox', { name: 'e.g. John Smith' }).fill('Taylor Demo User');
```
```

Collect these code snippets to reconstruct the user flow as a test.

## Output Structure

Generated tests follow this structure:

```
e2e/
├── playwright.config.ts       # Configuration for CI/CD + local dev
├── package.json               # Dependencies (playwright, @playwright/test)
├── tests/
│   ├── pages/                 # Page Object Models
│   │   └── {page-name}.page.ts
│   └── specs/                 # Test specifications
│       └── {feature}.spec.ts
├── .github/
│   └── workflows/
│       └── playwright-e2e.yml # GitHub Actions workflow
└── azure-load-test.yml        # Azure Load Testing configuration
```

## Procedure

### Step 1: Gather Context from playwright-cli Output

Read the artifacts from a previous `playwright-cli` session:

1. **Read snapshots**: Load all `.playwright-cli/*.yml` files to understand page structure
   ```bash
   # List available snapshots
   ls .playwright-cli/*.yml
   # Read the most recent snapshot
   cat .playwright-cli/page-*.yml
   ```
2. **Extract element inventory**: From snapshots, build a table of all interactive elements:
   - Headings (page identity)
   - Text inputs, spinbuttons, selects (form controls)
   - Buttons (actions)
   - Links (navigation)
   - Alerts/status elements (feedback)
3. **Reconstruct user flows**: Review the terminal history from the `playwright-cli` session to see what commands were run and what Playwright code was generated (each command outputs `### Ran Playwright code` with the equivalent `await page.*` call)
4. **Check for screenshots**: Review `.playwright-cli/*.png` for visual context
5. If no `playwright-cli` session exists, run one:
   ```bash
   playwright-cli open <app-url>
   playwright-cli snapshot
   # Explore the app...
   playwright-cli close
   ```

### Step 2: Initialize the Playwright Test Project

```bash
mkdir -p e2e && cd e2e
npm init -y
npm install -D @playwright/test
npx playwright install --with-deps chromium
```

### Step 3: Generate playwright.config.ts

Use this template — it works for both local development and CI/CD:

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/specs',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['html', { open: 'never' }],
    ['junit', { outputFile: 'test-results/results.xml' }],
  ],

  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:5087',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'on-first-retry',
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
```

**Key CI/CD features:**
- `BASE_URL` environment variable for dynamic targets (staging, production)
- JUnit reporter for Azure DevOps / GitHub Actions test result parsing
- Traces and videos only on failure/retry (saves CI storage)
- `forbidOnly: !!process.env.CI` prevents `.only` from slipping into CI

### Step 4: Generate Page Object Models

Create one POM per page. Each POM encapsulates locators and actions:

```typescript
// tests/pages/{page-name}.page.ts
import { type Page, type Locator, expect } from '@playwright/test';

export class ExamplePage {
  readonly page: Page;

  // Locators — use resilient selectors (role, label, text, testId)
  readonly heading: Locator;
  readonly submitButton: Locator;
  readonly nameInput: Locator;

  constructor(page: Page) {
    this.page = page;
    this.heading = page.getByRole('heading', { name: 'Page Title' });
    this.submitButton = page.getByRole('button', { name: 'Submit' });
    this.nameInput = page.getByRole('textbox', { name: 'Full Name' });
  }

  async goto() {
    await this.page.goto('/');
  }

  async fillForm(name: string) {
    await this.nameInput.fill(name);
  }

  async submit() {
    await this.submitButton.click();
  }

  // Assertions as methods — keeps specs clean
  async expectHeadingVisible() {
    await expect(this.heading).toBeVisible();
  }
}
```

**Locator priority (most to least resilient):**
1. `getByRole()` — semantic, survives refactors
2. `getByLabel()` — form controls
3. `getByText()` — visible text content
4. `getByTestId()` — stable data attributes
5. CSS / XPath — last resort only

### Step 5: Generate Test Specs

Each spec file tests one feature or user flow:

```typescript
// tests/specs/{feature}.spec.ts
import { test, expect } from '@playwright/test';
import { ExamplePage } from '../pages/example.page';

test.describe('Feature Name', () => {
  let page: ExamplePage;

  test.beforeEach(async ({ page: p }) => {
    page = new ExamplePage(p);
    await page.goto();
  });

  test('should display the page correctly', async () => {
    await page.expectHeadingVisible();
  });

  test('should submit form successfully', async () => {
    await page.fillForm('Test User');
    await page.submit();
    await expect(page.page.getByText('Success')).toBeVisible();
  });

  test('should validate required fields', async ({ page: p }) => {
    const exPage = new ExamplePage(p);
    await exPage.goto();
    await exPage.submit();
    // Expect validation errors
    await expect(p.getByText('required', { exact: false })).toBeVisible();
  });
});
```

**Test naming conventions:**
- `should [expected behavior]` — describes the outcome
- Group related tests in `test.describe()` blocks
- One logical assertion per test (multiple `expect()` calls are fine if testing one behavior)

### Step 6: Generate GitHub Actions Workflow

```yaml
# .github/workflows/playwright-e2e.yml
name: Playwright E2E Tests
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  e2e-tests:
    timeout-minutes: 30
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Install dependencies
        working-directory: e2e
        run: |
          npm ci
          npx playwright install --with-deps chromium

      - name: Start application
        run: |
          # Replace with your app's start command
          dotnet run --project src/ITextPdfService &
          sleep 10
        env:
          ASPNETCORE_URLS: http://localhost:5087

      - name: Run Playwright tests
        working-directory: e2e
        run: npx playwright test
        env:
          BASE_URL: http://localhost:5087
          CI: true

      - name: Upload test results
        uses: actions/upload-artifact@v4
        if: ${{ !cancelled() }}
        with:
          name: playwright-report
          path: |
            e2e/playwright-report/
            e2e/test-results/
          retention-days: 30

      - name: Upload traces
        uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: playwright-traces
          path: e2e/test-results/**/*.zip
          retention-days: 7
```

### Step 7: Configure Azure Load Testing (Optional)

Create `azure-load-test.yml` for Azure Load Testing with Playwright:

```yaml
# azure-load-test.yml
version: v0.1
testId: playwright-e2e-load
testType: PLAYWRIGHT
displayName: Playwright E2E Load Test
description: Run Playwright E2E tests at scale via Azure Load Testing
testPlan: e2e/tests/specs/  # directory with .spec.ts files
engineInstances: 1
autoStop:
  errorPercentage: 80
  timeWindow: 60
env:
  - name: BASE_URL
    value: https://your-app.azurecontainerapps.io
failureCriteria:
  - avg(response_time_ms) > 5000
  - percentage(error) > 10
```

**To run via Azure CLI:**
```bash
az load test create \
  --test-id playwright-e2e-load \
  --load-test-resource <resource-name> \
  --resource-group <rg-name> \
  --test-plan e2e/tests/specs/ \
  --engine-instances 1 \
  --env BASE_URL=https://your-app.azurecontainerapps.io
```

## Best Practices

### For CI/CD Pipelines
- Always use `--with-deps` when installing browsers in CI
- Set `CI=true` environment variable so Playwright uses CI-optimized defaults
- Upload traces/screenshots as artifacts for debugging failures
- Use JUnit reporter for test result integration with GitHub/Azure DevOps
- Pin Playwright version in `package.json` to avoid flaky CI from version drift

### For Azure Load Testing
- Start with 1 engine instance, scale up after baseline
- Set `autoStop` to prevent runaway costs
- Use `failureCriteria` to gate deployments on performance
- Test against a staging environment, not production
- The `BASE_URL` env var makes tests portable between environments

### For Test Quality
- Page Object Models keep tests maintainable as UI changes
- Use `getByRole()` locators — they survive CSS refactors
- Test user workflows, not implementation details
- Each test should be independent (no shared state between tests)
- Use `test.describe()` to group related tests logically

## Specific References

* **Page Object Model patterns** [references/page-object-model.md](references/page-object-model.md)
* **Azure Load Testing setup** [references/azure-load-testing.md](references/azure-load-testing.md)
* **CI/CD pipeline patterns** [references/cicd-patterns.md](references/cicd-patterns.md)
