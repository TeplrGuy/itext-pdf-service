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
import { defineConfig, type PlaywrightTestConfig } from '@playwright/test';
import { getConnectOptions } from '@azure/playwright';
import { AzureCliCredential } from '@azure/identity';
import baseConfig from './playwright.config';
import dotenv from 'dotenv';

dotenv.config();

async function createConfig(): Promise<PlaywrightTestConfig> {
  const connectOptions = await getConnectOptions({
    credential: new AzureCliCredential(),
    os: 'windows' as any,
  });

  return defineConfig(baseConfig, {
    workers: 20,
    use: {
      ...baseConfig.use,
      connectOptions,
      trace: 'on-first-retry',
      screenshot: 'on',
      video: 'retain-on-failure',
    },
  });
}

export default createConfig();
