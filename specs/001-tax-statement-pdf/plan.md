# Implementation Plan: Tax Statement PDF Generator

**Feature**: 001-tax-statement-pdf
**Created**: 2026-03-30
**Tech Stack**: C# .NET 8.0, iText 9.x (itext-core), xUnit

## Technical Context

| Aspect | Choice |
|--------|--------|
| Runtime | .NET 8.0 |
| Language | C# 12 |
| PDF Library | iText 9.x (itext.kernel, itext.layout) via NuGet |
| Web Framework | Blazor Server (included in ASP.NET Core) |
| UI Styling | Bootstrap 5 (included with Blazor template) |
| Test Framework | xUnit + Microsoft.NET.Test.Sdk |
| Build Tool | dotnet CLI |
| Architecture Pattern | Interface-based abstraction (IPdfGenerator) |

## Constitution Check

| Principle | Status | Notes |
|-----------|--------|-------|
| Migration-Ready Architecture | PASS | IPdfGenerator interface isolates iText dependency |
| Behavioral Equivalence | PASS | Tests validate PDF output content, not internal calls |
| Test-First Validation | PASS | xUnit tests assert on extracted PDF text and metadata |
| Clean Separation | PASS | Models → Interface → Implementation → Service layers |
| Simplicity | PASS | Single feature, minimal dependencies, console app |

## Project Structure

```text
itext-pdf-service/
├── itext-pdf-service.sln
├── src/
│   └── ITextPdfService/
│       ├── ITextPdfService.csproj
│       ├── Models/
│       │   ├── TaxpayerInfo.cs
│       │   ├── IncomeItem.cs
│       │   └── TaxStatement.cs
│       ├── Abstractions/
│       │   └── IPdfGenerator.cs
│       ├── Generators/
│       │   └── ITextTaxStatementGenerator.cs
│       ├── Components/
│       │   ├── Layout/
│       │   │   └── MainLayout.razor
│       │   ├── Pages/
│       │   │   └── Home.razor
│       │   ├── App.razor
│       │   ├── Routes.razor
│       │   └── _Imports.razor
│       ├── wwwroot/
│       │   └── css/
│       │       └── app.css
│       └── Program.cs
├── tests/
│   └── ITextPdfService.Tests/
│       ├── ITextPdfService.Tests.csproj
│       └── TaxStatementGeneratorTests.cs
├── .gitignore
└── specs/                (spec-kit artifacts)
```

## Design Decisions

### D1: Interface Abstraction
- `IPdfGenerator` defines `Task<byte[]> GenerateAsync(TaxStatement statement)` — returns PDF bytes for web download
- `ITextTaxStatementGenerator` implements using iText APIs
- Future ABCpdf migration creates `AbcPdfTaxStatementGenerator` implementing same interface
- Registered in DI container so Blazor pages inject `IPdfGenerator`

### D2: Model Classes (Plain POCOs)
- `TaxpayerInfo`: Name, SsnLast4, TaxYear
- `IncomeItem`: Description, Amount (decimal)
- `TaxStatement`: TaxpayerInfo, List\<IncomeItem\>, TotalDeductions, OrganizationName
- Calculated property: NetTaxOwed = TotalIncome - TotalDeductions

### D3: iText Usage Pattern
- Use `PdfWriter` → `PdfDocument` → `Document` pipeline
- Use `Table` for income breakdown
- Use `Paragraph` with bold/regular fonts for sections
- Set `PdfDocumentInfo` for metadata
- Use `PdfTextExtractor` in tests to verify content

### D4: License Configuration
- iText license JSON file referenced at runtime
- License file path passed via environment variable or hardcoded for demo
- License file NOT committed to source control (.gitignore)

### D5: Blazor Server Web UI
- Single-page Blazor Server app with a professional form layout
- Bootstrap 5 styling (comes with Blazor template) for clean demo appearance
- Form sections: Taxpayer Info, Income Sources (dynamic add/remove rows), Deductions, Generate button
- Generated PDF returned as in-browser download via `IJSRuntime` file save
- Form validation using DataAnnotations on model classes
- Custom CSS for accent colors and demo polish

## Dependencies (NuGet)

| Package | Version | Purpose |
|---------|---------|---------|
| itext.kernel | 9.* | Core PDF creation |
| itext.layout | 9.* | High-level layout API (Table, Paragraph) |
| itext.bouncy-castle-adapter | 9.* | Required by iText |
| xunit | 2.* | Test framework |
| xunit.runner.visualstudio | 2.* | VS test runner |
| Microsoft.NET.Test.Sdk | 17.* | Test SDK |
| Microsoft.AspNetCore.Components.Web | (built-in) | Blazor Server |
