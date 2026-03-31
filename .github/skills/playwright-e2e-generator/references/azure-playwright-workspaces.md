# Azure Playwright Workspaces

## Overview

Azure Playwright Workspaces (part of Azure App Testing) runs your existing Playwright tests on cloud-hosted browsers. Your test code stays the same — the service provides the browsers in Azure instead of running them locally. This means:

- **Same tests, cloud browsers**: No test rewriting needed
- **Parallel at scale**: Up to 50 parallel workers on cloud browsers
- **Cross-browser**: Chromium, Firefox, WebKit all available
- **Results portal**: View test results, traces, screenshots in the Azure portal
- **CI/CD ready**: Integrates with GitHub Actions via OIDC auth

## How It Works

1. **Local config** (`playwright.config.ts`) — your normal test config
2. **Service config** (`playwright.service.config.ts`) — extends local config, connects to Azure
3. **Run locally**: `npx playwright test` — uses local browsers
4. **Run in cloud**: `npx playwright test --config=playwright.service.config.ts` — uses Azure browsers

The key difference: cloud execution uses Azure-hosted browsers while your test runner still runs on your machine or CI agent. The `PLAYWRIGHT_SERVICE_URL` environment variable tells Playwright where to connect.

## Setup

### 1. Create Workspace (Azure Portal)

1. Go to [Azure Portal](https://portal.azure.com)
2. Search "Playwright Workspaces" → Create
3. Select subscription, resource group, name, and region
4. Copy the **Browser Endpoint URL** from the Get Started page

### 2. Install Package

```bash
cd e2e
npm install --save-dev @azure/playwright dotenv
```

### 3. Create playwright.service.config.ts

```typescript
import { defineConfig } from '@playwright/test';
import { getServiceConfig } from '@azure/playwright';
import baseConfig from './playwright.config';
import dotenv from 'dotenv';

dotenv.config();

export default defineConfig(
  baseConfig,
  getServiceConfig(baseConfig),
  {
    workers: 20,
    use: {
      ...baseConfig.use,
      trace: 'on-first-retry',
      screenshot: 'on',
      video: 'retain-on-failure',
    },
  }
);
```

### 4. Set Environment Variable

Create `.env` file:
```
PLAYWRIGHT_SERVICE_URL=wss://westus3.api.playwright.microsoft.com/accounts/xxx/browsers
```

### 5. Authenticate

```bash
# For local dev — use Azure CLI
az login

# For CI — use OIDC (service principal with federated credential)
# Set AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID as secrets
```

### 6. Run Tests

```bash
# Local browsers (normal)
npx playwright test

# Azure cloud browsers
npx playwright test --config=playwright.service.config.ts

# Azure cloud browsers with parallel workers
npx playwright test --config=playwright.service.config.ts --workers=20
```

## GitHub Actions Integration

```yaml
  playwright-cloud:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Install dependencies
        working-directory: e2e
        run: npm ci

      - name: Azure Login (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Run tests on Azure Playwright Workspace
        working-directory: e2e
        run: npx playwright test --config=playwright.service.config.ts --workers=20
        env:
          PLAYWRIGHT_SERVICE_URL: ${{ secrets.PLAYWRIGHT_SERVICE_URL }}
          BASE_URL: https://your-app.azurewebsites.net
          CI: true
```

## Local vs Cloud Comparison

| Aspect | Local (`playwright.config.ts`) | Cloud (`playwright.service.config.ts`) |
|--------|------|-------|
| Browsers | Installed locally | Azure-hosted |
| Workers | Limited by machine CPU | Up to 50 parallel |
| Speed | Fast for small suites | Fast for large suites (parallel) |
| Cost | Free | Pay per test minute |
| Setup | `npx playwright install` | Azure workspace + OIDC auth |
| Best for | Development, debugging | CI/CD, cross-browser, scale |

## Best Practices

1. **Develop locally, run in cloud for CI**: Use local config during development, service config in pipelines
2. **Start with few workers**: Begin with 5-10, increase after baseline
3. **Use OIDC auth**: No secrets to manage, auto-rotating credentials
4. **Set BASE_URL via env**: Makes tests portable between local/staging/prod
5. **Keep .env out of git**: Add `.env` to `.gitignore`
