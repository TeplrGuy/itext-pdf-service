# CI/CD Pipeline Patterns for Playwright E2E Tests

## Pipeline Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    GitHub Actions                        │
│                                                          │
│  ┌──────────┐   ┌──────────┐   ┌────────────────────┐  │
│  │  Build &  │──▶│  E2E     │──▶│  Azure Load        │  │
│  │  Deploy   │   │  Tests   │   │  Testing           │  │
│  │  (staging)│   │(Playwright)  │  (scale test)      │  │
│  └──────────┘   └──────────┘   └────────────────────┘  │
│        │              │                   │              │
│        ▼              ▼                   ▼              │
│   App running    Test report       Load test report     │
│   on staging     + traces          + failure criteria    │
└─────────────────────────────────────────────────────────┘
```

## Complete Workflow Template

```yaml
name: Build, Test & Load Test
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  DOTNET_VERSION: '10.0.x'
  NODE_VERSION: '20'
  APP_PORT: 5087

jobs:
  # Job 1: Build and start the app
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}
      - run: dotnet build --configuration Release
      - run: dotnet test --configuration Release --no-build

  # Job 2: Run Playwright E2E tests
  e2e-tests:
    needs: build
    timeout-minutes: 30
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}

      - uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}

      # Start the app in background
      - name: Start application
        run: |
          dotnet run --project src/ITextPdfService &
          sleep 10
        env:
          ASPNETCORE_URLS: http://localhost:${{ env.APP_PORT }}

      # Install Playwright
      - name: Install Playwright
        working-directory: e2e
        run: |
          npm ci
          npx playwright install --with-deps chromium

      # Run tests
      - name: Run E2E tests
        working-directory: e2e
        run: npx playwright test
        env:
          BASE_URL: http://localhost:${{ env.APP_PORT }}
          CI: true

      # Upload HTML report (always)
      - name: Upload report
        uses: actions/upload-artifact@v4
        if: ${{ !cancelled() }}
        with:
          name: playwright-report
          path: e2e/playwright-report/
          retention-days: 14

      # Upload JUnit results for GitHub test summary
      - name: Upload test results
        uses: actions/upload-artifact@v4
        if: ${{ !cancelled() }}
        with:
          name: test-results
          path: e2e/test-results/
          retention-days: 14

      # Upload traces only on failure
      - name: Upload traces
        uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: playwright-traces
          path: e2e/test-results/**/*.zip
          retention-days: 7

  # Job 3: Azure Load Testing (on main branch only)
  load-test:
    needs: e2e-tests
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Azure Login
        uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Run Load Test
        uses: azure/load-testing@v1
        with:
          loadTestConfigFile: azure-load-test.yml
          loadTestResource: ${{ vars.AZURE_LOAD_TEST_RESOURCE }}
          resourceGroup: ${{ vars.AZURE_RESOURCE_GROUP }}
          env: |
            [
              { "name": "BASE_URL", "value": "${{ vars.STAGING_URL }}" }
            ]
```

## Environment Variables

| Variable | Where Set | Purpose |
|---|---|---|
| `BASE_URL` | Workflow env / Azure Load Test env | Target app URL — makes tests portable |
| `CI` | Workflow env (`true`) | Triggers CI-optimized Playwright defaults |
| `AZURE_CREDENTIALS` | GitHub Secrets | Service principal for Azure Load Testing |
| `AZURE_LOAD_TEST_RESOURCE` | GitHub Variables | Azure Load Testing resource name |
| `AZURE_RESOURCE_GROUP` | GitHub Variables | Resource group for Load Testing |
| `STAGING_URL` | GitHub Variables | Deployed staging app URL |

## Pull Request Workflow

For PRs, run E2E tests against a temporary app instance but skip load testing:

```yaml
  e2e-tests:
    if: github.event_name == 'pull_request'
    # ... same as above, but skip load-test job

  load-test:
    if: github.ref == 'refs/heads/main'  # only on merge to main
```

## Artifacts and Debugging

| Artifact | When Uploaded | Contains |
|---|---|---|
| `playwright-report` | Always | Interactive HTML report with screenshots |
| `test-results` | Always | JUnit XML, screenshot PNGs |
| `playwright-traces` | On failure only | Trace ZIP files for step-by-step debugging |

To view traces locally:
```bash
npx playwright show-trace test-results/trace.zip
```

## Best Practices

1. **Separate jobs**: Build → E2E → Load Test. Each has its own timeout and failure mode.
2. **Pin browser versions**: Use `npx playwright install --with-deps chromium` (not `--with-deps` alone which installs all browsers).
3. **Use `!cancelled()`**: Upload artifacts even when tests fail — you need the report to debug.
4. **Conditional load testing**: Only run on `main` branch merges, not on every PR.
5. **Timeout**: Set `timeout-minutes: 30` on E2E jobs to prevent stuck tests from blocking the pipeline.
