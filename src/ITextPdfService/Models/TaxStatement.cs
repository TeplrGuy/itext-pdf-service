using System.ComponentModel.DataAnnotations;

namespace ITextPdfService.Models;

public class TaxStatement
{
    public TaxpayerInfo TaxpayerInfo { get; set; } = new();

    [MinLength(1, ErrorMessage = "At least one income source is required")]
    public List<IncomeItem> IncomeItems { get; set; } = [new()];

    [Range(0, double.MaxValue, ErrorMessage = "Deductions cannot be negative")]
    public decimal TotalDeductions { get; set; }

    [Required(ErrorMessage = "Organization name is required")]
    public string OrganizationName { get; set; } = "Contoso Financial Services";

    public decimal TotalIncome => IncomeItems.Sum(i => i.Amount);

    public decimal NetTaxOwed => TotalIncome - TotalDeductions;
}
