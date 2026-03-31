using ITextPdfService.Abstractions;
using ITextPdfService.Components;
using ITextPdfService.Generators;

// Load iText license
var licensePath = Path.Combine(AppContext.BaseDirectory, "itext-license.json");
if (File.Exists(licensePath))
{
    iText.Licensing.Base.LicenseKey.LoadLicenseFile(new FileInfo(licensePath));
}

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

// Register PDF generator (swap this line for migration)
builder.Services.AddSingleton<IPdfGenerator, ITextTaxStatementGenerator>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
}
app.UseStatusCodePagesWithReExecute("/not-found", createScopeForStatusCodePages: true);
app.UseAntiforgery();

app.MapStaticAssets();
app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

app.Run();
