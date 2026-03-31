using ITextPdfService.Models;

namespace ITextPdfService.Abstractions;

public interface IPdfGenerator
{
    Task<byte[]> GenerateAsync(TaxStatement statement);
}
