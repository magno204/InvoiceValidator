using InvoiceRegistry.App.Models;
using InvoiceRegistry.App.Services;

namespace InvoiceRegistry.Tests;

public class InvoiceValidatorTests
{
    private static Invoice FacturaBase() => new()
    {
        Numero = "F-001",
        Cliente = "Acme S.A.",
        Fecha = new DateTime(2026, 5, 17),
        MontoTotal = 100m
    };

    [Fact]
    public void Validar_FacturaCompleta_RetornaValida()
    {
        var (ok, error) = InvoiceValidator.Validar(FacturaBase());

        Assert.True(ok);
        Assert.Null(error);
    }

    [Fact]
    public void Validar_SinNumero_RetornaInvalida()
    {
        var f = FacturaBase();
        f.Numero = "";

        var (ok, error) = InvoiceValidator.Validar(f);

        Assert.False(ok);
        Assert.Equal("El número de factura es obligatorio.", error);
    }

    [Fact]
    public void Validar_MontoNegativo_RetornaInvalida()
    {
        var f = FacturaBase();
        f.MontoTotal = -1m;

        var (ok, error) = InvoiceValidator.Validar(f);

        Assert.False(ok);
        Assert.Equal("El monto total no puede ser negativo.", error);
    }
}
