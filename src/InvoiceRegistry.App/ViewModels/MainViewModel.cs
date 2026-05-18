using System.Collections.ObjectModel;
using System.Windows.Input;
using InvoiceRegistry.App.Models;
using InvoiceRegistry.App.Services;

namespace InvoiceRegistry.App.ViewModels;

public class MainViewModel : ViewModelBase
{
    private string _numero = "";
    private string _cliente = "";
    private DateTime _fecha = DateTime.Today;
    private decimal _montoTotal;
    private string _mensajeError = "";

    public string Numero
    {
        get => _numero;
        set => SetProperty(ref _numero, value);
    }

    public string Cliente
    {
        get => _cliente;
        set => SetProperty(ref _cliente, value);
    }

    public DateTime Fecha
    {
        get => _fecha;
        set => SetProperty(ref _fecha, value);
    }

    public decimal MontoTotal
    {
        get => _montoTotal;
        set => SetProperty(ref _montoTotal, value);
    }

    public string MensajeError
    {
        get => _mensajeError;
        set => SetProperty(ref _mensajeError, value);
    }

    public ObservableCollection<Invoice> Facturas { get; } = new();

    public ICommand GuardarCommand { get; }

    public MainViewModel()
    {
        GuardarCommand = new RelayCommand(Guardar);
    }

    private void Guardar()
    {
        var factura = new Invoice
        {
            Numero = Numero,
            Cliente = Cliente,
            Fecha = Fecha,
            MontoTotal = MontoTotal
        };

        var (ok, error) = InvoiceValidator.Validar(factura);
        if (!ok)
        {
            MensajeError = error ?? "Factura inválida.";
            return;
        }

        Facturas.Add(factura);
        Limpiar();
    }

    private void Limpiar()
    {
        Numero = "";
        Cliente = "";
        Fecha = DateTime.Today;
        MontoTotal = 0m;
        MensajeError = "";
    }
}
