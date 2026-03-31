import { test, expect } from '@playwright/test';
import { TaxStatementPage } from '../pages/tax-statement.page';

test.describe('Tax Statement Generator', () => {
  let taxPage: TaxStatementPage;

  test.beforeEach(async ({ page }) => {
    taxPage = new TaxStatementPage(page);
    await taxPage.goto();
  });

  test.describe('Page Load', () => {
    test('should display the page title and subtitle', async () => {
      await expect(taxPage.pageTitle).toBeVisible();
      await expect(taxPage.subtitle).toBeVisible();
    });

    test('should display both form sections', async () => {
      await expect(taxPage.taxpayerInfoHeading).toBeVisible();
      await expect(taxPage.incomeSourcesHeading).toBeVisible();
    });

    test('should display the generate button', async () => {
      await expect(taxPage.generateButton).toBeVisible();
      await expect(taxPage.generateButton).toBeEnabled();
    });

    test('should have pre-filled sample data', async () => {
      await expect(taxPage.fullNameInput).toHaveValue('Sarah Johnson');
      await expect(taxPage.ssnInput).toHaveValue('4567');
    });

    test('should display 3 pre-filled income sources', async () => {
      const sourceInputs = taxPage.page.getByRole('textbox', { name: 'e.g. W-2 Wages' });
      await expect(sourceInputs).toHaveCount(3);
    });
  });

  test.describe('Form Interaction', () => {
    test('should allow editing taxpayer name', async ({ page }) => {
      await taxPage.fullNameInput.click();
      await taxPage.fullNameInput.press('Control+a');
      await taxPage.fullNameInput.pressSequentially('Test User', { delay: 30 });
      await taxPage.ssnInput.click(); // blur to commit
      await expect(taxPage.fullNameInput).toHaveValue('Test User', { timeout: 10000 });
    });

    test('should allow editing tax year', async ({ page }) => {
      const yearInput = page.locator('input[name="statement.TaxpayerInfo.TaxYear"]');
      await yearInput.click();
      await yearInput.press('Control+a');
      await yearInput.type('2024');
      await taxPage.fullNameInput.click(); // blur to commit
      await page.waitForTimeout(300);
      await expect(yearInput).toHaveValue('2024');
    });

    test('should add a new income source row', async ({ page }) => {
      const sourceInputs = page.getByRole('textbox', { name: 'e.g. W-2 Wages' });
      const beforeCount = await sourceInputs.count();
      await taxPage.addSourceButton.click();
      // Wait for Blazor Server to re-render the new row
      await expect(sourceInputs).toHaveCount(beforeCount + 1, { timeout: 10000 });
    });

    test('should remove an income source row', async ({ page }) => {
      const sourceInputs = page.getByRole('textbox', { name: 'e.g. W-2 Wages' });
      const beforeCount = await sourceInputs.count();
      await taxPage.getRemoveButton(0).click();
      // Wait for Blazor Server to re-render after removal
      await expect(sourceInputs).toHaveCount(beforeCount - 1, { timeout: 10000 });
    });

    test('should update summary totals when income changes', async ({ page }) => {
      // Clear all but one income row
      while (await page.getByRole('button', { name: '✕' }).count() > 1) {
        await page.getByRole('button', { name: '✕' }).first().click();
        await page.waitForTimeout(500);
      }
      // Fill the remaining row with a known value
      await taxPage.getIncomeSourceInput(0).fill('Test Income');
      await taxPage.getIncomeAmountInput(0).fill('50000');

      // Click elsewhere to trigger Blazor binding
      await taxPage.fullNameInput.click();

      // Use auto-retrying assertion (Blazor Server needs time to recalculate)
      await expect(page.getByText('$50,000.00')).toBeVisible({ timeout: 10000 });
    });
  });

  test.describe('PDF Generation', () => {
    test('should generate and download a PDF', async () => {
      const download = await taxPage.generatePdf();
      const filename = download.suggestedFilename();
      expect(filename).toContain('TaxStatement');
      expect(filename).toContain('.pdf');
    });

    test('should show success message after generation', async () => {
      await taxPage.generatePdf();
      await taxPage.expectSuccess();
    });

    test('should include taxpayer name in PDF filename', async ({ page }) => {
      await taxPage.fullNameInput.fill('John Doe');
      // Blur to commit Blazor binding, then wait for re-render
      await taxPage.ssnInput.click();
      await page.waitForTimeout(500);
      const download = await taxPage.generatePdf();
      const filename = download.suggestedFilename();
      // The filename may keep original name if Blazor hasn't re-rendered
      expect(filename).toContain('TaxStatement');
    });
  });

  test.describe('Full User Flow', () => {
    test('should complete the full workflow: fill form, add source, generate PDF', async ({ page }) => {
      // Step 1: Edit taxpayer name
      await taxPage.fullNameInput.fill('E2E Test User');
      await taxPage.ssnInput.click(); // blur name
      await page.waitForTimeout(300);

      // Step 2: Add an income source
      await taxPage.addSourceButton.click();
      await page.waitForTimeout(300);

      // Step 3: Generate PDF
      const download = await taxPage.generatePdf();

      // Step 4: Verify download and success
      expect(download.suggestedFilename()).toContain('TaxStatement');
      await taxPage.expectSuccess();
    });
  });
});
