using System.Globalization;
using iText.IO.Font.Constants;
using iText.Kernel.Colors;
using iText.Kernel.Font;
using iText.Kernel.Pdf;
using iText.Layout;
using iText.Layout.Borders;
using iText.Layout.Element;
using iText.Layout.Properties;
using ITextPdfService.Abstractions;
using ITextPdfService.Models;

namespace ITextPdfService.Generators;

public class ITextTaxStatementGenerator : IPdfGenerator
{
    private static readonly Color HeaderBlue = new DeviceRgb(0, 51, 102);
    private static readonly Color LightGray = new DeviceRgb(245, 245, 245);
    private static readonly Color AccentBlue = new DeviceRgb(0, 102, 204);

    public Task<byte[]> GenerateAsync(TaxStatement statement)
    {
        var memoryStream = new MemoryStream();
        var writerProperties = new WriterProperties();
        var writer = new PdfWriter(memoryStream, writerProperties);
        writer.SetCloseStream(false);
        var pdfDoc = new PdfDocument(writer);

        var boldFont = PdfFontFactory.CreateFont(StandardFonts.HELVETICA_BOLD);
        var italicFont = PdfFontFactory.CreateFont(StandardFonts.HELVETICA_OBLIQUE);

        // Set metadata
        var info = pdfDoc.GetDocumentInfo();
        info.SetTitle($"Tax Statement - {statement.TaxpayerInfo.TaxYear}");
        info.SetAuthor(statement.OrganizationName);
        info.SetSubject("Tax Statement");
        info.SetCreator("iText PDF Service");

        var document = new Document(pdfDoc);
        document.SetMargins(40, 50, 40, 50);

        // Header
        AddHeader(document, statement, boldFont);

        // Taxpayer Info
        AddTaxpayerInfo(document, statement, boldFont);

        // Income Breakdown Table
        AddIncomeTable(document, statement, boldFont);

        // Summary
        AddSummary(document, statement, boldFont);

        // Footer
        AddFooter(document, italicFont);

        document.Close();
        return Task.FromResult(memoryStream.ToArray());
    }

    private static void AddHeader(Document document, TaxStatement statement, PdfFont boldFont)
    {
        var orgName = new Paragraph(statement.OrganizationName)
            .SetFontSize(20)
            .SetFontColor(HeaderBlue)
            .SetFont(boldFont)
            .SetTextAlignment(TextAlignment.CENTER)
            .SetMarginBottom(4);
        document.Add(orgName);

        var title = new Paragraph($"Tax Statement — {statement.TaxpayerInfo.TaxYear}")
            .SetFontSize(14)
            .SetFontColor(AccentBlue)
            .SetTextAlignment(TextAlignment.CENTER)
            .SetMarginBottom(4);
        document.Add(title);

        var dateLine = new Paragraph($"Generated: {DateTime.Now:MMMM dd, yyyy}")
            .SetFontSize(9)
            .SetFontColor(ColorConstants.GRAY)
            .SetTextAlignment(TextAlignment.CENTER)
            .SetMarginBottom(20);
        document.Add(dateLine);

        // Divider line
        var divider = new Table(1).UseAllAvailableWidth();
        divider.AddCell(new Cell()
            .SetBorderBottom(new SolidBorder(AccentBlue, 2))
            .SetBorderTop(Border.NO_BORDER)
            .SetBorderLeft(Border.NO_BORDER)
            .SetBorderRight(Border.NO_BORDER)
            .SetHeight(1));
        document.Add(divider);
        document.Add(new Paragraph().SetMarginBottom(12));
    }

    private static void AddTaxpayerInfo(Document document, TaxStatement statement, PdfFont boldFont)
    {
        var sectionTitle = new Paragraph("Taxpayer Information")
            .SetFontSize(13)
            .SetFont(boldFont)
            .SetFontColor(HeaderBlue)
            .SetMarginBottom(8);
        document.Add(sectionTitle);

        var infoTable = new Table(new float[] { 150, 300 });
        infoTable.SetMarginBottom(20);

        AddInfoRow(infoTable, "Name:", statement.TaxpayerInfo.Name, boldFont);
        AddInfoRow(infoTable, "SSN (last 4):", $"***-**-{statement.TaxpayerInfo.SsnLast4}", boldFont);
        AddInfoRow(infoTable, "Tax Year:", statement.TaxpayerInfo.TaxYear.ToString(), boldFont);

        document.Add(infoTable);
    }

    private static void AddInfoRow(Table table, string label, string value, PdfFont boldFont)
    {
        table.AddCell(new Cell()
            .Add(new Paragraph(label).SetFont(boldFont).SetFontSize(10))
            .SetBorder(Border.NO_BORDER)
            .SetPaddingBottom(4));
        table.AddCell(new Cell()
            .Add(new Paragraph(value).SetFontSize(10))
            .SetBorder(Border.NO_BORDER)
            .SetPaddingBottom(4));
    }

    private static void AddIncomeTable(Document document, TaxStatement statement, PdfFont boldFont)
    {
        var sectionTitle = new Paragraph("Income Breakdown")
            .SetFontSize(13)
            .SetFont(boldFont)
            .SetFontColor(HeaderBlue)
            .SetMarginBottom(8);
        document.Add(sectionTitle);

        var table = new Table(new float[] { 350, 150 }).UseAllAvailableWidth();

        // Header row
        table.AddHeaderCell(new Cell()
            .Add(new Paragraph("Source").SetFont(boldFont).SetFontColor(ColorConstants.WHITE).SetFontSize(10))
            .SetBackgroundColor(HeaderBlue)
            .SetPadding(8));
        table.AddHeaderCell(new Cell()
            .Add(new Paragraph("Amount").SetFont(boldFont).SetFontColor(ColorConstants.WHITE).SetFontSize(10)
                .SetTextAlignment(TextAlignment.RIGHT))
            .SetBackgroundColor(HeaderBlue)
            .SetPadding(8));

        // Data rows
        bool alternate = false;
        foreach (var item in statement.IncomeItems)
        {
            var bgColor = alternate ? LightGray : ColorConstants.WHITE;

            table.AddCell(new Cell()
                .Add(new Paragraph(item.Description).SetFontSize(10))
                .SetBackgroundColor(bgColor)
                .SetPadding(6)
                .SetBorder(new SolidBorder(ColorConstants.LIGHT_GRAY, 0.5f)));
            table.AddCell(new Cell()
                .Add(new Paragraph(item.Amount.ToString("C2", CultureInfo.GetCultureInfo("en-US"))).SetFontSize(10)
                    .SetTextAlignment(TextAlignment.RIGHT))
                .SetBackgroundColor(bgColor)
                .SetPadding(6)
                .SetBorder(new SolidBorder(ColorConstants.LIGHT_GRAY, 0.5f)));

            alternate = !alternate;
        }

        // Total income row
        table.AddCell(new Cell()
            .Add(new Paragraph("Total Income").SetFont(boldFont).SetFontSize(10))
            .SetPadding(8)
            .SetBorderTop(new SolidBorder(HeaderBlue, 1.5f))
            .SetBorderBottom(Border.NO_BORDER)
            .SetBorderLeft(Border.NO_BORDER)
            .SetBorderRight(Border.NO_BORDER));
        table.AddCell(new Cell()
            .Add(new Paragraph(statement.TotalIncome.ToString("C2", CultureInfo.GetCultureInfo("en-US"))).SetFont(boldFont).SetFontSize(10)
                .SetTextAlignment(TextAlignment.RIGHT))
            .SetPadding(8)
            .SetBorderTop(new SolidBorder(HeaderBlue, 1.5f))
            .SetBorderBottom(Border.NO_BORDER)
            .SetBorderLeft(Border.NO_BORDER)
            .SetBorderRight(Border.NO_BORDER));

        document.Add(table);
        document.Add(new Paragraph().SetMarginBottom(16));
    }

    private static void AddSummary(Document document, TaxStatement statement, PdfFont boldFont)
    {
        var sectionTitle = new Paragraph("Tax Summary")
            .SetFontSize(13)
            .SetFont(boldFont)
            .SetFontColor(HeaderBlue)
            .SetMarginBottom(8);
        document.Add(sectionTitle);

        var summaryTable = new Table(new float[] { 350, 150 }).UseAllAvailableWidth();

        AddSummaryRow(summaryTable, "Total Income:", statement.TotalIncome.ToString("C2", CultureInfo.GetCultureInfo("en-US")), false, boldFont);
        AddSummaryRow(summaryTable, "Total Deductions:", $"({statement.TotalDeductions.ToString("C2", CultureInfo.GetCultureInfo("en-US"))})", false, boldFont);

        // Net owed - highlighted
        summaryTable.AddCell(new Cell()
            .Add(new Paragraph(statement.NetTaxOwed >= 0 ? "Net Tax Owed:" : "Refund Due:")
                .SetFont(boldFont).SetFontSize(12).SetFontColor(HeaderBlue))
            .SetPadding(10)
            .SetBorderTop(new SolidBorder(AccentBlue, 2))
            .SetBorderBottom(Border.NO_BORDER)
            .SetBorderLeft(Border.NO_BORDER)
            .SetBorderRight(Border.NO_BORDER));
        summaryTable.AddCell(new Cell()
            .Add(new Paragraph(Math.Abs(statement.NetTaxOwed).ToString("C2", CultureInfo.GetCultureInfo("en-US")))
                .SetFont(boldFont).SetFontSize(12).SetFontColor(HeaderBlue)
                .SetTextAlignment(TextAlignment.RIGHT))
            .SetPadding(10)
            .SetBorderTop(new SolidBorder(AccentBlue, 2))
            .SetBorderBottom(Border.NO_BORDER)
            .SetBorderLeft(Border.NO_BORDER)
            .SetBorderRight(Border.NO_BORDER));

        document.Add(summaryTable);
    }

    private static void AddSummaryRow(Table table, string label, string value, bool bold, PdfFont boldFont)
    {
        table.AddCell(new Cell()
            .Add(new Paragraph(label).SetFontSize(10).SetFont(boldFont))
            .SetBorder(Border.NO_BORDER)
            .SetPaddingBottom(4)
            .SetPaddingLeft(8));
        table.AddCell(new Cell()
            .Add(new Paragraph(value).SetFontSize(10)
                .SetTextAlignment(TextAlignment.RIGHT))
            .SetBorder(Border.NO_BORDER)
            .SetPaddingBottom(4)
            .SetPaddingRight(8));
    }

    private static void AddFooter(Document document, PdfFont italicFont)
    {
        document.Add(new Paragraph().SetMarginBottom(30));
        var footer = new Paragraph("This document was generated electronically and is valid without a signature.")
            .SetFontSize(8)
            .SetFontColor(ColorConstants.GRAY)
            .SetTextAlignment(TextAlignment.CENTER)
            .SetFont(italicFont);
        document.Add(footer);
    }
}
