---
description: Playwright test patterns and conventions for e2e test files
applyTo: '**/e2e/**/*.spec.ts,**/e2e/**/*.page.ts,**/tests/**/*.spec.ts,**/tests/**/*.page.ts'
---

# Playwright Test Conventions

When writing or editing Playwright tests, follow these guidelines:

## Locators

- Use `getByRole()`, `getByText()`, `getByTestId()` — stable, accessible locators
- Avoid CSS selectors and XPath unless no accessible alternative exists
- Prefer `getByLabel()` for form inputs

## Test Structure

- One `*.spec.ts` per Blazor page or feature
- Use `test.describe()` blocks to group related scenarios
- Write descriptive test names: `test('should generate PDF with valid taxpayer data')`

## Page Object Model

- Every spec file must use a corresponding `*.page.ts` in `e2e/tests/pages/`
- Page objects encapsulate selectors and actions
- Keep assertions in spec files, not page objects

## Assertions

- Use `expect()` with specific matchers: `toBeVisible()`, `toHaveText()`, `toBeEnabled()`
- Never use `setTimeout()` — rely on Playwright auto-wait
- Use `toHaveURL()` for navigation assertions

## Test Isolation

- Each test must be independent — no shared state between tests
- Use `test.beforeEach()` / `test.afterEach()` for setup/teardown
- Navigate to the page under test at the start of each test
