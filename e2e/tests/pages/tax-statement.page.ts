import { type Page, type Locator, expect } from '@playwright/test';

export class TaxStatementPage {
  readonly page: Page;

  // Header
  readonly pageTitle: Locator;
  readonly subtitle: Locator;

  // Taxpayer Information
  readonly taxpayerInfoHeading: Locator;
  readonly fullNameInput: Locator;
  readonly ssnInput: Locator;
  readonly taxYearInput: Locator;
  readonly organizationInput: Locator;

  // Income Sources
  readonly incomeSourcesHeading: Locator;
  readonly addSourceButton: Locator;
  readonly deductionsInput: Locator;

  // Summary
  readonly totalIncomeDisplay: Locator;
  readonly deductionsDisplay: Locator;
  readonly netTaxOwedDisplay: Locator;

  // Actions
  readonly generateButton: Locator;
  readonly successAlert: Locator;

  constructor(page: Page) {
    this.page = page;

    // Header
    this.pageTitle = page.getByRole('heading', { name: 'Tax Statement Generator' });
    this.subtitle = page.getByText('Generate professional tax statement PDFs powered by iText');

    // Taxpayer Information
    this.taxpayerInfoHeading = page.getByRole('heading', { name: 'Taxpayer Information' });
    this.fullNameInput = page.getByRole('textbox', { name: 'e.g. John Smith' });
    this.ssnInput = page.getByRole('textbox', { name: 'e.g. 1234' });
    this.taxYearInput = page.getByLabel('Tax Year');
    this.organizationInput = page.getByLabel('Organization Name');

    // Income Sources
    this.incomeSourcesHeading = page.getByRole('heading', { name: 'Income Sources' });
    this.addSourceButton = page.getByRole('button', { name: '+ Add Source' });
    this.deductionsInput = page.getByLabel('Total Deductions ($)');

    // Summary
    this.totalIncomeDisplay = page.getByText(/\$[\d,]+\.\d{2}/).first();
    this.deductionsDisplay = page.getByText('Deductions').locator('..').getByText(/\$[\d,]+\.\d{2}/);
    this.netTaxOwedDisplay = page.getByText(/Net Tax Owed|Refund Due/).locator('..').getByText(/\$[\d,]+\.\d{2}/);

    // Actions
    this.generateButton = page.getByRole('button', { name: 'Generate Tax Statement PDF' });
    this.successAlert = page.getByText('PDF generated successfully');
  }

  async goto() {
    await this.page.goto('/');
    await expect(this.pageTitle).toBeVisible();
  }

  async fillTaxpayerInfo(name: string, ssn: string, year: string, org: string) {
    await this.fullNameInput.fill(name);
    await this.ssnInput.fill(ssn);
    await this.taxYearInput.fill(year);
    await this.organizationInput.fill(org);
  }

  getIncomeSourceInput(index: number) {
    return this.page.getByRole('textbox', { name: 'e.g. W-2 Wages' }).nth(index);
  }

  getIncomeAmountInput(index: number) {
    return this.page.locator(`input[name="statement.IncomeItems[${index}].Amount"]`);
  }

  getRemoveButton(index: number) {
    return this.page.getByRole('button', { name: '✕' }).nth(index);
  }

  async addIncomeSource(description: string, amount: string) {
    await this.addSourceButton.click();
    const count = await this.page.getByRole('textbox', { name: 'e.g. W-2 Wages' }).count();
    await this.getIncomeSourceInput(count - 1).fill(description);
    await this.getIncomeAmountInput(count - 1).fill(amount);
  }

  async fillDeductions(amount: string) {
    await this.deductionsInput.fill(amount);
  }

  async generatePdf() {
    const downloadPromise = this.page.waitForEvent('download');
    await this.generateButton.click();
    return downloadPromise;
  }

  async expectSuccess() {
    await expect(this.successAlert).toBeVisible();
  }

  async expectPageLoaded() {
    await expect(this.pageTitle).toBeVisible();
    await expect(this.taxpayerInfoHeading).toBeVisible();
    await expect(this.incomeSourcesHeading).toBeVisible();
    await expect(this.generateButton).toBeVisible();
  }
}
