namespace InvoiceRegistry.App.Models;

public class Invoice
{
    public string Numero { get; set; } = "";
    public string Cliente { get; set; } = "";
    public DateTime Fecha { get; set; } = DateTime.Today;
    public decimal MontoTotal { get; set; }
}
