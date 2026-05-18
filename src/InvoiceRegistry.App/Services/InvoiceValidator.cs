using InvoiceRegistry.App.Models;

namespace InvoiceRegistry.App.Services;

public static class InvoiceValidator
{
    public static (bool EsValida, string? Error) Validar(Invoice f)
    {
        if (string.IsNullOrWhiteSpace(f.Numero))
            return (false, "El número de factura es obligatorio.");

        if (string.IsNullOrWhiteSpace(f.Cliente))
            return (false, "El cliente es obligatorio.");

        if (f.MontoTotal <= 0)
            return (false, "El monto total no puede ser negativo.");

        return (true, null);
    }
}
