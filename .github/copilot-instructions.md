# Project Instructions

## Application

This is a Blazor Server (.NET 10) application that generates tax statement PDFs using iText. The main UI is in `src/ITextPdfService/Components/Pages/`.

## Testing Requirements

- **Always write Playwright e2e tests** for any new feature or bug fix
- Run `npx playwright test` (from `e2e/` directory) before considering work complete
- All tests must pass before opening a pull request
- Use Page Object Model pattern for test organization

## Development Commands

- Build: `dotnet build`
- Run app: `dotnet run --project src/ITextPdfService`
- Run tests: `cd e2e && npx playwright test`
- Run headed: `cd e2e && npx playwright test --headed`

## Repository Structure

- `src/ITextPdfService/` — Blazor Server application
- `e2e/tests/specs/` — Playwright test specs (`*.spec.ts`)
- `e2e/tests/pages/` — Page Object Model classes (`*.page.ts`)
- `e2e/playwright.config.ts` — Local Playwright configuration
- `e2e/playwright.service.config.ts` — Azure Playwright Workspace config

## Testing Guidelines

1. Every new page/feature MUST have a corresponding `.spec.ts`
2. Use stable locators: `getByRole()`, `getByText()`, `getByTestId()`
3. Never use `setTimeout()` — rely on Playwright auto-wait
4. Write isolated tests — each test must not depend on another
5. Always verify tests pass with `npx playwright test` before submitting
