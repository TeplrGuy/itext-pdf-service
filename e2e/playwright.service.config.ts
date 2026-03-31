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
import baseConfig from './playwright.config';
import dotenv from 'dotenv';

dotenv.config();

export default defineConfig(
  baseConfig,
  createAzurePlaywrightConfig({
    serviceAuthType: ServiceAuth.ACCESS_TOKEN,
  }),
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
