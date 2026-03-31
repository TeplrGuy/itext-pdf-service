/**
 * Playwright Service Configuration
 * 
 * This config extends the base playwright.config.ts and connects to
 * Azure Playwright Workspaces for cloud-hosted browser execution.
 * 
 * Usage:
 *   npx playwright test --config=playwright.service.config.ts
 *   npx playwright test --config=playwright.service.config.ts --workers=20
 * 
 * Requires:
 *   PLAYWRIGHT_SERVICE_URL environment variable set to your workspace endpoint
 *   Azure CLI login (az login) for authentication
 */
import { defineConfig } from '@playwright/test';
import { createAzurePlaywrightConfig, ServiceAuth } from '@azure/playwright';
import { AzureCliCredential } from '@azure/identity';
import baseConfig from './playwright.config';
import dotenv from 'dotenv';

dotenv.config();

// Use access token if available (CI), otherwise AzureCliCredential (local dev)
const serviceConfig = process.env.PLAYWRIGHT_SERVICE_ACCESS_TOKEN
  ? createAzurePlaywrightConfig({
      serviceAuthType: ServiceAuth.ACCESS_TOKEN,
    })
  : createAzurePlaywrightConfig({
      credential: new AzureCliCredential(),
    });

export default defineConfig(
  baseConfig,
  serviceConfig,
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
