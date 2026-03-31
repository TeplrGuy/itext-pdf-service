using iText.Kernel.Pdf;
using iText.Kernel.Pdf.Canvas.Parser;
using iText.Kernel.Pdf.Canvas.Parser.Listener;
using ITextPdfService.Generators;
using ITextPdfService.Models;

namespace ITextPdfService.Tests;

public class TaxStatementGeneratorTests
{
    private readonly ITextTaxStatementGenerator _generator = new();

    private static TaxStatement CreateSampleStatement() => new()
    {
        TaxpayerInfo = new TaxpayerInfo
        {
            Name = "Jane Doe",
            SsnLast4 = "9876",
            TaxYear = 2025
        },
        OrganizationName = "Test Corp",
        IncomeItems =
        [
            new IncomeItem { Description = "W-2 Wages", Amount = 75000.00m },
            new IncomeItem { Description = "Freelance Income", Amount = 15000.00m }
        ],
        TotalDeductions = 12000.00m
    };

    [Fact]
    public async Task GenerateAsync_ReturnsNonEmptyByteArray()
    {
        var statement = CreateSampleStatement();
        var result = await _generator.GenerateAsync(statement);

        Assert.NotNull(result);
        Assert.True(result.Length > 0);
    }

    [Fact]
    public async Task GenerateAsync_ProducesValidPdf()
    {
        var statement = CreateSampleStatement();
        var result = await _generator.GenerateAsync(statement);

        using var stream = new MemoryStream(result);
        using var reader = new PdfReader(stream);
        using var pdfDoc = new PdfDocument(reader);

        Assert.Equal(1, pdfDoc.GetNumberOfPages());
    }

    [Fact]
    public async Task GenerateAsync_ContainsTaxpayerName()
    {
        var statement = CreateSampleStatement();
        var result = await _generator.GenerateAsync(statement);

        var text = ExtractText(result);
        Assert.Contains("Jane Doe", text);
    }

    [Fact]
    public async Task GenerateAsync_ContainsTaxYear()
    {
        var statement = CreateSampleStatement();
        var result = await _generator.GenerateAsync(statement);

        var text = ExtractText(result);
        Assert.Contains("2025", text);
    }

    [Fact]
    public async Task GenerateAsync_ContainsAllIncomeSources()
    {
        var statement = CreateSampleStatement();
        var result = await _generator.GenerateAsync(statement);

        var text = ExtractText(result);
        Assert.Contains("W-2 Wages", text);
        Assert.Contains("Freelance Income", text);
    }

    [Fact]
    public async Task GenerateAsync_ContainsFormattedAmounts()
    {
        var statement = CreateSampleStatement();
        var result = await _generator.GenerateAsync(statement);

        var text = ExtractText(result);
        Assert.Contains("$75,000.00", text);
        Assert.Contains("$15,000.00", text);
    }

    [Fact]
    public async Task GenerateAsync_SetsCorrectMetadata()
    {
        var statement = CreateSampleStatement();
        var result = await _generator.GenerateAsync(statement);

        using var stream = new MemoryStream(result);
        using var reader = new PdfReader(stream);
        using var pdfDoc = new PdfDocument(reader);
        var info = pdfDoc.GetDocumentInfo();

        Assert.Contains("Tax Statement", info.GetTitle());
        Assert.Contains("2025", info.GetTitle());
        Assert.Equal("Test Corp", info.GetAuthor());
    }

    [Fact]
    public async Task GenerateAsync_HandlesSpecialCharactersInName()
    {
        var statement = CreateSampleStatement();
        statement.TaxpayerInfo.Name = "José O'Brien-García";

        var result = await _generator.GenerateAsync(statement);
        var text = ExtractText(result);

        Assert.Contains("José", text);
    }

    [Fact]
    public async Task GenerateAsync_HandlesZeroIncome()
    {
        var statement = CreateSampleStatement();
        statement.IncomeItems = [new IncomeItem { Description = "None", Amount = 0.01m }];
        statement.TotalDeductions = 0;

        var result = await _generator.GenerateAsync(statement);
        Assert.True(result.Length > 0);
    }

    private static string ExtractText(byte[] pdfBytes)
    {
        using var stream = new MemoryStream(pdfBytes);
        using var reader = new PdfReader(stream);
        using var pdfDoc = new PdfDocument(reader);

        var strategy = new SimpleTextExtractionStrategy();
        return PdfTextExtractor.GetTextFromPage(pdfDoc.GetFirstPage(), strategy);
    }
}
