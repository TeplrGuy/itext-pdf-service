# Page Object Model Patterns

## Why Page Object Models

Page Object Models (POMs) separate test logic from page structure. When the UI changes, you update the POM — not every test that touches that page.

## Structure

```typescript
// e2e/tests/pages/login.page.ts
import { type Page, type Locator, expect } from '@playwright/test';

export class LoginPage {
  readonly page: Page;

  // Declare all locators as readonly properties
  readonly emailInput: Locator;
  readonly passwordInput: Locator;
  readonly signInButton: Locator;
  readonly errorAlert: Locator;
  readonly forgotPasswordLink: Locator;

  constructor(page: Page) {
    this.page = page;
    // Use resilient locators
    this.emailInput = page.getByLabel('Email');
    this.passwordInput = page.getByLabel('Password');
    this.signInButton = page.getByRole('button', { name: 'Sign In' });
    this.errorAlert = page.getByRole('alert');
    this.forgotPasswordLink = page.getByRole('link', { name: 'Forgot password' });
  }

  // Navigation
  async goto() {
    await this.page.goto('/login');
  }

  // Actions — combine multiple steps into one method
  async login(email: string, password: string) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.signInButton.click();
  }

  // Assertions — encapsulate common checks
  async expectErrorMessage(text: string) {
    await expect(this.errorAlert).toContainText(text);
  }

  async expectRedirectToDashboard() {
    await expect(this.page).toHaveURL(/.*dashboard/);
  }
}
```

## Usage in Tests

```typescript
import { test } from '@playwright/test';
import { LoginPage } from '../pages/login.page';

test.describe('Login', () => {
  test('valid credentials redirect to dashboard', async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login('admin@example.com', 'password123');
    await loginPage.expectRedirectToDashboard();
  });

  test('invalid credentials show error', async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login('admin@example.com', 'wrong');
    await loginPage.expectErrorMessage('Invalid credentials');
  });
});
```

## Multi-Page Flows

For flows that span multiple pages, chain POMs:

```typescript
test('complete checkout flow', async ({ page }) => {
  const catalog = new CatalogPage(page);
  await catalog.goto();
  await catalog.addToCart('Widget A');

  const cart = new CartPage(page);
  await cart.expectItemCount(1);
  await cart.proceedToCheckout();

  const checkout = new CheckoutPage(page);
  await checkout.fillShipping('123 Main St', 'Springfield', '62701');
  await checkout.submitOrder();
  await checkout.expectConfirmation();
});
```

## Locator Priority

1. **`getByRole()`** — Best choice. Semantic, accessible, resilient.
2. **`getByLabel()`** — Great for form inputs with visible labels.
3. **`getByText()`** — Good for buttons, links, headings with unique text.
4. **`getByPlaceholder()`** — When label is not visible.
5. **`getByTestId()`** — Stable data attributes, good for dynamic content.
6. **CSS selectors** — Avoid. Brittle, breaks on refactors.
