# iText PDF Service Constitution

## Core Principles

### I. Migration-Ready Architecture
All PDF generation code MUST be implemented behind an abstraction layer (IPdfGenerator interface) so that the underlying library can be swapped from iText to ABCpdf without changing consuming code. No direct iText API calls outside the implementation class.

### II. Behavioral Equivalence
Every PDF generation feature MUST produce verifiable, deterministic output. Generated PDFs MUST be validated for page count, text content, and structural integrity so that post-migration comparison testing is possible.

### III. Test-First Validation
Every public method MUST have corresponding xUnit tests. Tests MUST assert on PDF output characteristics (page count, text extraction, metadata) rather than internal implementation details, ensuring tests survive library migration.

### IV. Clean Separation of Concerns
The solution MUST separate PDF generation logic from business logic. Services handle orchestration; generators handle PDF rendering. This ensures the migration scope is contained to generator implementations only.

### V. Simplicity
Start with the minimal viable PDF feature set. Do not over-engineer. YAGNI applies. The purpose is to demonstrate a working iText implementation that can later be migrated to ABCpdf.

## Technology Constraints

- **Runtime**: .NET 8.0 (C#)
- **PDF Library**: iText 9.x (itext-core NuGet) with trial license
- **Testing**: xUnit with Microsoft.NET.Test.Sdk
- **Build**: dotnet CLI, single solution file
- **License**: iText trial license file stored at project root (not committed to source control)

## Development Workflow

- All code follows standard C# conventions (PascalCase for public members, camelCase for locals)
- Solution structure: src/ for production code, tests/ for test projects
- PDF output validated programmatically in tests (no visual inspection required)
- No external dependencies beyond iText and standard .NET libraries

## Governance

This constitution guides all development on itext-pdf-service. Any deviation from the abstraction layer principle requires explicit justification. The architecture MUST support a future library swap to ABCpdf with changes limited to a single implementation class.

**Version**: 1.0.0 | **Ratified**: 2026-03-30 | **Last Amended**: 2026-03-30
