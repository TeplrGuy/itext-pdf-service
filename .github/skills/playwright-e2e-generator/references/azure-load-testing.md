# Azure Load Testing with Playwright

## Overview

Azure Load Testing supports Playwright test scripts natively. You upload your existing E2E tests and Azure runs them at scale across multiple engine instances — no test rewriting needed.

## Prerequisites

- Azure subscription with `Microsoft.LoadTestService` resource provider registered
- Azure Load Testing resource created
- Playwright test project with `@playwright/test` installed
- Azure CLI with `load` extension: `az extension add --name load`

## Configuration File

Create `azure-load-test.yml` at the project root:

```yaml
version: v0.1
testId: e2e-load-test
testType: PLAYWRIGHT
displayName: E2E Load Test — Playwright
description: Run Playwright E2E tests at scale
testPlan: e2e/  # directory containing package.json and tests
engineInstances: 1  # start with 1, scale up after baseline

autoStop:
  errorPercentage: 80
  timeWindow: 60

env:
  - name: BASE_URL
    value: https://your-app.azurecontainerapps.io
  - name: CI
    value: "true"

failureCriteria:
  - avg(response_time_ms) > 5000
  - percentage(error) > 10
```

## Running via Azure CLI

```bash
# Create and run the test
az load test create \
  --test-id e2e-load-test \
  --load-test-resource <resource-name> \
  --resource-group <rg-name> \
  --test-plan e2e/ \
  --engine-instances 1 \
  --env BASE_URL=https://your-app.azurecontainerapps.io

# Check test run status
az load test-run list \
  --test-id e2e-load-test \
  --load-test-resource <resource-name> \
  --resource-group <rg-name>

# Download results
az load test-run download-files \
  --test-run-id <run-id> \
  --load-test-resource <resource-name> \
  --resource-group <rg-name> \
  --path ./results
```

## GitHub Actions Integration

Add Azure Load Testing as a deployment gate in your workflow:

```yaml
  load-test:
    needs: [e2e-tests]  # run after E2E tests pass
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Azure Login
        uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Run Azure Load Test
        uses: azure/load-testing@v1
        with:
          loadTestConfigFile: azure-load-test.yml
          loadTestResource: ${{ vars.AZURE_LOAD_TEST_RESOURCE }}
          resourceGroup: ${{ vars.AZURE_RESOURCE_GROUP }}
          env: |
            [
              { "name": "BASE_URL", "value": "${{ vars.APP_URL }}" }
            ]
```

## Scaling Strategy

| Engine Instances | Simulated Behavior | Use Case |
|---|---|---|
| 1 | Sequential test execution | Baseline, smoke test |
| 2-5 | Moderate parallel load | Pre-production validation |
| 5-10 | High concurrency | Load testing, capacity planning |
| 10+ | Stress testing | Peak traffic simulation |

## Failure Criteria

Define quality gates that fail the test run:

```yaml
failureCriteria:
  # Response time thresholds
  - avg(response_time_ms) > 5000        # Average response > 5s
  - p90(response_time_ms) > 10000       # 90th percentile > 10s
  - p95(response_time_ms) > 15000       # 95th percentile > 15s

  # Error rate thresholds
  - percentage(error) > 10              # More than 10% errors

  # Custom metrics (from Application Insights)
  - avg(requests/duration) > 3000       # App Insights metric
```

## Best Practices

1. **Start small**: 1 engine instance first, establish baseline metrics
2. **Use staging**: Never load test production without explicit approval
3. **Set autoStop**: Prevents runaway costs if tests fail catastrophically
4. **Monitor with App Insights**: Connect Azure Load Testing to Application Insights for server-side correlation
5. **Version your config**: Keep `azure-load-test.yml` in source control
6. **Parameterize URLs**: Use `BASE_URL` env var so the same tests run against any environment
