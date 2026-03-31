using System.ComponentModel.DataAnnotations;

namespace ITextPdfService.Models;

public class TaxpayerInfo
{
    [Required(ErrorMessage = "Taxpayer name is required")]
    public string Name { get; set; } = string.Empty;

    [StringLength(4, MinimumLength = 4, ErrorMessage = "Must be exactly 4 digits")]
    public string SsnLast4 { get; set; } = string.Empty;

    [Required(ErrorMessage = "Tax year is required")]
    [Range(2000, 2030, ErrorMessage = "Tax year must be between 2000 and 2030")]
    public int TaxYear { get; set; } = DateTime.Now.Year;
}
