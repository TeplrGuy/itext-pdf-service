# Feature Specification: Tax Statement PDF Generator

**Feature Branch**: `001-tax-statement-pdf`
**Created**: 2026-03-30
**Status**: Draft
**Input**: Build a small tax statement PDF generation service using iText for .NET that creates professional tax summary documents with tables, headers, and form fields — designed to later be migrated to ABCpdf.

## User Scenarios & Testing

### User Story 1 - Generate Tax Statement PDF (Priority: P1)

A finance team member provides taxpayer information (name, SSN last 4, tax year, income, deductions, tax owed) and the system generates a formatted PDF tax statement with a header, taxpayer details section, income breakdown table, and summary totals.

**Why this priority**: This is the core value proposition — generating a structured PDF document. Without this, nothing else matters.

**Independent Test**: Can be fully tested by calling the generator with sample taxpayer data and verifying the output PDF contains the correct text content, has exactly 1 page, and includes all required sections.

**Acceptance Scenarios**:

1. **Given** valid taxpayer data with name, tax year, and income details, **When** the user generates a tax statement, **Then** a PDF file is created with a professional header, taxpayer info section, income table, and total amount owed.
2. **Given** taxpayer data with multiple income sources, **When** the statement is generated, **Then** the income breakdown table lists each source with its amount and the total is calculated correctly.
3. **Given** the generated PDF, **When** the text is extracted, **Then** the taxpayer name, tax year, and all monetary amounts appear in the extracted text.

---

### User Story 2 - Web UI for Tax Statement Generation (Priority: P2)

A user opens a web application in their browser, fills out a form with taxpayer details (name, SSN last 4, tax year, organization name), adds one or more income sources, optionally enters deductions, and clicks "Generate PDF". The system generates the tax statement PDF and provides a download link. The UI has a clean, professional look suitable for demos.

**Why this priority**: A visual UI makes the demo compelling and interactive. The PDF generation engine (US1) works without it, but the UI is essential for presenting to stakeholders.

**Independent Test**: Can be tested by opening the web app, filling out the form with sample data, clicking Generate, and verifying a PDF file downloads with the correct content.

**Acceptance Scenarios**:

1. **Given** the web app is running, **When** the user navigates to the home page, **Then** a clean form is displayed with fields for taxpayer name, SSN last 4, tax year, organization name, and an income sources section.
2. **Given** the user has filled out all required fields and added at least one income source, **When** they click "Generate Tax Statement", **Then** a PDF is generated and a download link appears.
3. **Given** the user has not filled out required fields, **When** they click "Generate", **Then** validation errors are displayed next to the missing fields.
4. **Given** the user clicks the download link, **When** the PDF opens, **Then** it contains all the data they entered in the form.

---

### User Story 3 - PDF Metadata and Properties (Priority: P3)

The generated PDF includes proper document metadata (title, author, creation date) and document properties that identify it as a tax statement for organizational and search purposes.

**Why this priority**: Metadata is important for document management but the core PDF generation and UI work without it.

**Independent Test**: Can be tested by generating a PDF and reading its metadata properties to verify title, author, and subject are set correctly.

**Acceptance Scenarios**:

1. **Given** a generated tax statement PDF, **When** the document properties are read, **Then** the title contains "Tax Statement" and the tax year, the author is set to the organization name, and the subject identifies the document type.

---

### Edge Cases

- What happens when taxpayer name contains special characters (accents, apostrophes)?
- How does the system handle zero income or negative amounts (refunds)?
- What happens when income source description is very long (>100 characters)?

## Requirements

### Functional Requirements

- **FR-001**: System MUST generate a single-page PDF tax statement from structured taxpayer data
- **FR-002**: System MUST render a header section with organization name and "Tax Statement" title
- **FR-003**: System MUST render a taxpayer information section with name, last 4 of SSN, and tax year
- **FR-004**: System MUST render an income breakdown table with columns for source description and amount
- **FR-005**: System MUST render a summary section with total income, total deductions, and net tax owed
- **FR-006**: System MUST set PDF document metadata (title, author, subject, creation date)
- **FR-007**: System MUST implement the PDF generation behind an IPdfGenerator interface to support future library swaps
- **FR-008**: System MUST handle special characters in taxpayer names without errors
- **FR-009**: System MUST format monetary values with currency symbol and two decimal places
- **FR-010**: System MUST provide a web-based form UI for entering taxpayer data and income sources
- **FR-011**: System MUST validate required fields (name, tax year, at least one income source) before generating
- **FR-012**: System MUST allow the user to dynamically add and remove income source rows in the form
- **FR-013**: System MUST provide a download button/link for the generated PDF

### Key Entities

- **TaxStatement**: Represents a complete tax statement with taxpayer info, income items, deductions, and calculated totals
- **IncomeItem**: Represents a single income source with description and amount
- **TaxpayerInfo**: Represents taxpayer identity data (name, SSN last 4, tax year)

## Success Criteria

### Measurable Outcomes

- **SC-001**: System generates a valid PDF file from taxpayer data in under 2 seconds
- **SC-002**: Generated PDF contains all taxpayer information verifiable via text extraction
- **SC-003**: All monetary values are correctly formatted and totals are arithmetically accurate
- **SC-004**: PDF document metadata is correctly set and readable by standard PDF readers
- **SC-005**: The PDF generation interface allows swapping the underlying library without changing any calling code

## Assumptions

- The system is a Blazor Server web application for demo purposes
- Tax statement is a single-page document for simplicity
- Currency is USD
- The iText trial license is available and valid for development
- No authentication or user management is needed
- PDF output is generated server-side and served as a file download to the browser
- The UI uses Bootstrap (included with Blazor) for a clean, professional appearance
