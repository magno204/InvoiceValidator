# InvoiceRegistry

Aplicación de escritorio para el **registro de facturas** de una empresa. Construida en **WPF (.NET 10)** con tema oscuro Fluent y arquitectura **MVVM**.

## Características

- Registro de facturas con número, cliente, fecha y monto total.
- Listado en tiempo real de las facturas registradas.
- Validación de los campos del formulario con mensajes claros para el usuario.
- Interfaz nativa de Windows con tema oscuro Fluent.
- Suite de pruebas unitarias sobre la lógica de validación.

## Stack técnico

| Componente | Tecnología |
|---|---|
| Plataforma | .NET 10 |
| UI | WPF + Fluent Theme (Dark) |
| Patrón | MVVM (sin librerías externas) |
| Lenguaje | C# 13 |
| Pruebas | xUnit |

## Requisitos

- Windows 10/11.
- [.NET 10 SDK](https://dotnet.microsoft.com/download) (o superior).
- Opcional: Visual Studio 2022/2026 con la workload *.NET Desktop Development*, o VS Code con la extensión *C# Dev Kit*.

Verificar la instalación del SDK:

```powershell
dotnet --version    # debe imprimir 10.x
```

## Cómo ejecutar

Clonar el repositorio y, desde la raíz del proyecto:

```powershell
dotnet restore
dotnet build
dotnet run --project src/InvoiceRegistry.App
```

## Estructura del repositorio

```
InvoiceRegistry/
├── InvoiceRegistry.slnx
├── README.md
├── assets/                          # Recursos fuente (SVG del ícono, etc.)
├── docs/                            # Documentación del proyecto
├── tools/                           # Scripts auxiliares (generación de íconos, etc.)
├── src/
│   └── InvoiceRegistry.App/
│       ├── App.xaml                 # Tema Fluent Dark a nivel de aplicación
│       ├── MainWindow.xaml          # Ventana principal
│       ├── Models/
│       │   └── Invoice.cs           # Modelo de dominio
│       ├── ViewModels/
│       │   ├── ViewModelBase.cs     # INotifyPropertyChanged base
│       │   ├── RelayCommand.cs      # ICommand minimalista
│       │   └── MainViewModel.cs     # ViewModel de la ventana principal
│       ├── Services/
│       │   └── InvoiceValidator.cs  # Reglas de validación
│       └── Assets/
│           └── app.ico              # Ícono de la aplicación
└── tests/
    └── InvoiceRegistry.Tests/
        └── InvoiceValidatorTests.cs # Pruebas unitarias del validador
```

## Pruebas

Ejecutar la suite completa desde la raíz:

```powershell
dotnet test
```

Las pruebas cubren las reglas de validación implementadas en `Services/InvoiceValidator.cs`.

## Validación de facturas

Al guardar una factura, se aplican las siguientes reglas:

| Regla | Mensaje al usuario |
|---|---|
| El número de factura no puede estar vacío | *"El número de factura es obligatorio."* |
| El cliente no puede estar vacío | *"El cliente es obligatorio."* |
| El monto total no puede ser negativo | *"El monto total no puede ser negativo."* |

Si la factura cumple todas las reglas, se agrega a la lista y el formulario se limpia automáticamente.

## Ícono de la aplicación

El ícono vive en `src/InvoiceRegistry.App/Assets/app.ico`. La fuente vectorial está en `assets/icon.svg`. Para regenerar el `.ico` (varias resoluciones embebidas) tras modificar el diseño:

```powershell
.\tools\Build-Icon.ps1
```
