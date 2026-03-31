# Tasks: Tax Statement PDF Generator

**Feature**: 001-tax-statement-pdf
**Created**: 2026-03-30
**Total Tasks**: 16

## Phase 1: Project Setup

- [ ] T001 Create .NET 8 Blazor Server project with `dotnet new blazor --interactivity Server` at `src/ITextPdfService/`
- [ ] T002 Create xUnit test project at `tests/ITextPdfService.Tests/` with reference to main project
- [ ] T003 Create solution file `itext-pdf-service.sln` and add both projects
- [ ] T004 Add iText NuGet packages (itext.kernel, itext.layout, itext.bouncy-castle-adapter) to main project
- [ ] T005 Create `.gitignore` with .NET, Blazor, and output patterns
- [ ] T006 Copy iText license JSON file to project root and configure license loading in Program.cs

## Phase 2: Models and Abstractions

- [ ] T007 [P] [US1] Create `src/ITextPdfService/Models/TaxpayerInfo.cs` — Name (string, required), SsnLast4 (string, 4 chars), TaxYear (int, required)
- [ ] T008 [P] [US1] Create `src/ITextPdfService/Models/IncomeItem.cs` — Description (string, required), Amount (decimal, required)
- [ ] T009 [P] [US1] Create `src/ITextPdfService/Models/TaxStatement.cs` — TaxpayerInfo, List\<IncomeItem\>, TotalDeductions (decimal), OrganizationName (string); calculated TotalIncome and NetTaxOwed properties
- [ ] T010 [US1] Create `src/ITextPdfService/Abstractions/IPdfGenerator.cs` — interface with `Task<byte[]> GenerateAsync(TaxStatement statement)`

## Phase 3: PDF Generation (User Story 1 — Core)

- [ ] T011 [US1] Create `src/ITextPdfService/Generators/ITextTaxStatementGenerator.cs` implementing IPdfGenerator:
  - Header with organization name and "Tax Statement" title
  - Taxpayer info section (name, SSN last 4, tax year)
  - Income breakdown table (source, amount columns)
  - Summary section (total income, deductions, net tax owed)
  - Currency formatting ($X,XXX.XX)
  - PDF metadata (title, author, subject, creation date)
- [ ] T012 [US1] Register IPdfGenerator → ITextTaxStatementGenerator in DI container in Program.cs

## Phase 4: Web UI (User Story 2 — Blazor Form)

- [ ] T013 [US2] Create `src/ITextPdfService/Components/Pages/Home.razor` — Blazor form with:
  - Taxpayer info fields (name, SSN last 4, tax year, organization name)
  - Dynamic income source rows (add/remove buttons)
  - Deductions input
  - "Generate Tax Statement" button
  - Download link after generation
  - Form validation for required fields
  - Professional Bootstrap styling with card layout
- [ ] T014 [US2] Add custom CSS at `src/ITextPdfService/wwwroot/css/app.css` for demo polish (accent colors, form spacing, header branding)

## Phase 5: Tests

- [ ] T015 [US1] Create `tests/ITextPdfService.Tests/TaxStatementGeneratorTests.cs`:
  - Test PDF generation produces valid non-empty byte array
  - Test generated PDF text contains taxpayer name and tax year
  - Test generated PDF text contains all income source descriptions
  - Test generated PDF text contains formatted monetary amounts
  - Test PDF metadata has correct title and author
  - Test handling of special characters in taxpayer name
  - Test zero income and negative amounts (refund)

## Phase 6: Polish

- [ ] T016 Verify full workflow: `dotnet build` → `dotnet test` → `dotnet run` → open browser → fill form → generate → download PDF

## Dependencies

```text
T001 → T002 → T003 → T004 → T005 → T006
T006 → T007, T008, T009 (parallel)
T007, T008, T009 → T010 → T011 → T012
T012 → T013, T014 (parallel)
T012 → T015
T013, T014, T015 → T016
```

## Implementation Strategy

1. **MVP**: Phase 1-3 (project setup + PDF engine) — can be tested via unit tests
2. **Demo-ready**: Phase 4 (Blazor UI) — interactive demo experience
3. **Validated**: Phase 5-6 (tests + polish) — production confidence
