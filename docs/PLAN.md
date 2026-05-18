# Plan: App WPF de Registro de Facturas (con bug intencional)

> Objetivo: construir una app sencilla en **WPF (.NET 10)** con **tema oscuro Fluent**, capaz de registrar facturas de una empresa. La app contendrá un **bug intencional**: permitirá guardar facturas con **monto total = 0**. Esto sirve como guion para grabar un video del flujo completo en GitHub: *issue → branch → fix → unit test → commit → pull request → code review*.

Este plan está dividido en **fases independientes y verificables**. Al terminar cada fase deberías tener algo que compila/funciona, y un criterio claro de "hecho" antes de pasar a la siguiente.

---

## Resumen de fases


| Fase          | Nombre                                  | Resultado esperado                                  |
| ------------- | --------------------------------------- | --------------------------------------------------- |
| 0             | Preparación del entorno                 | .NET 10 instalado, Git/GitHub listos                |
| 1             | Solución y esqueleto del proyecto       | `dotnet build` verde sin UI todavía                 |
| 2             | Tema oscuro y ventana principal         | App abre con Fluent Dark vacío                      |
| 3             | Modelo + Validador (con bug)            | Clases `Invoice` e `InvoiceValidator`               |
| 4             | ViewModel + binding del formulario      | Formulario funcional, agrega a `DataGrid`           |
| 5             | Proyecto de tests (sin el test del bug) | `dotnet test` verde con tests felices               |
| 6             | Verificación manual del bug             | Bug reproducido en pantalla — **listo para grabar** |
| 7             | Repo en GitHub e Issue del bug          | Repo público, Issue #1 creado                       |
| 8             | Branch + fix + test del bug             | Rama `fix/issue-1-monto-cero` con cambios           |
| 9             | Commit, PR y code review                | PR mergeado, Issue cerrado automáticamente          |
| 10 (opcional) | CI con GitHub Actions                   | Check verde en el PR                                |


---

## Stack técnico (referencia transversal)


| Item         | Elección                                     |
| ------------ | -------------------------------------------- |
| Framework    | .NET 10 (WPF)                                |
| Lenguaje     | C# 13                                        |
| UI Theme     | **Fluent Dark** (`ThemeMode="Dark"`)         |
| Patrón       | MVVM ligero (sin librerías externas)         |
| Persistencia | En memoria (`ObservableCollection<Invoice>`) |
| Testing      | xUnit                                        |
| Repo         | GitHub                                       |


## Estructura final del repositorio

```
InvoiceRegistry/
├── .gitignore
├── README.md
├── InvoiceRegistry.sln
├── src/InvoiceRegistry.App/
│   ├── InvoiceRegistry.App.csproj
│   ├── App.xaml / App.xaml.cs
│   ├── MainWindow.xaml / MainWindow.xaml.cs
│   ├── Models/Invoice.cs
│   ├── ViewModels/{ViewModelBase, MainViewModel, RelayCommand}.cs
│   └── Services/InvoiceValidator.cs   ← aquí vive el bug
└── tests/InvoiceRegistry.Tests/
    ├── InvoiceRegistry.Tests.csproj
    └── InvoiceValidatorTests.cs
```

---

## Fase 0 — Preparación del entorno

**Meta:** asegurarte de que todas las herramientas necesarias están instaladas antes de tocar código.

### Pasos

1. Verificar .NET 10:
  ```powershell
   dotnet --version   # debe mostrar 10.x
  ```
2. Verificar Git:
  ```powershell
   git --version
   git config --global user.name "<Tu Nombre>"
   git config --global user.email "<tu@email.com>"
  ```
3. Tener cuenta en GitHub y configurada la autenticación (`gh auth login` o SSH key).
4. IDE: Visual Studio 2022/2026 con workload *.NET Desktop Development*, o VS Code + extensión C# Dev Kit.

### Criterio de "hecho"

- `dotnet --version` ≥ 10.0.
- `git config --global --get user.email` retorna tu correo.
- Puedes hacer `gh repo list` (o login en github.com).

---

## Fase 1 — Solución y esqueleto del proyecto

**Meta:** crear la solución, el proyecto WPF y el proyecto de tests, sin código de UI todavía.

### Pasos

```powershell
# En la raíz del repo
dotnet new sln -n InvoiceRegistry

dotnet new wpf   -n InvoiceRegistry.App   -o src/InvoiceRegistry.App   -f net10.0-windows
dotnet new xunit -n InvoiceRegistry.Tests -o tests/InvoiceRegistry.Tests -f net10.0

dotnet sln add src/InvoiceRegistry.App/InvoiceRegistry.App.csproj
dotnet sln add tests/InvoiceRegistry.Tests/InvoiceRegistry.Tests.csproj

dotnet add tests/InvoiceRegistry.Tests/InvoiceRegistry.Tests.csproj `
           reference src/InvoiceRegistry.App/InvoiceRegistry.App.csproj
```

Crea un `.gitignore` para Visual Studio (`dotnet new gitignore`).

### Criterio de "hecho"

- `dotnet build` desde la raíz: **Build succeeded, 0 errors**.
- La solución abre en el IDE mostrando los dos proyectos.

---

## Fase 2 — Tema oscuro y ventana principal vacía

**Meta:** ver la app abrirse con tema oscuro Fluent, aunque no haga nada.

### Pasos

1. `src/InvoiceRegistry.App/App.xaml`:
  ```xml
   <Application x:Class="InvoiceRegistry.App.App"
                xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
                xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
                StartupUri="MainWindow.xaml"
                ThemeMode="Dark">
       <Application.Resources>
           <ResourceDictionary Source="pack://application:,,,/PresentationFramework.Fluent;component/Themes/Fluent.Dark.xaml" />
       </Application.Resources>
   </Application>
  ```
2. `src/InvoiceRegistry.App/MainWindow.xaml` (placeholder):
  ```xml
   <Window x:Class="InvoiceRegistry.App.MainWindow"
           xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
           xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
           Title="Registro de Facturas" Height="520" Width="900"
           ThemeMode="Dark">
       <Grid>
           <TextBlock Text="Hola tema oscuro" FontSize="24"
                      HorizontalAlignment="Center" VerticalAlignment="Center"/>
       </Grid>
   </Window>
  ```
3. `dotnet run --project src/InvoiceRegistry.App`.

### Criterio de "hecho"

- Se abre la ventana con fondo oscuro y el texto centrado.

---

## Fase 3 — Modelo + Validador (con el bug intencional)

**Meta:** introducir las clases de dominio. **Aquí se siembra el bug**, pero todavía no se nota.

### Pasos

1. `src/InvoiceRegistry.App/Models/Invoice.cs`:
  ```csharp
   namespace InvoiceRegistry.App.Models;

   public class Invoice
   {
       public string Numero      { get; set; } = "";
       public string Cliente     { get; set; } = "";
       public DateTime Fecha     { get; set; } = DateTime.Today;
       public decimal MontoTotal { get; set; }
   }
  ```
2. `src/InvoiceRegistry.App/Services/InvoiceValidator.cs` — **AQUÍ VIVE EL BUG**:
  ```csharp
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

           // BUG INTENCIONAL: debería ser <= 0; al usar < 0 deja pasar el cero.
           if (f.MontoTotal < 0)
               return (false, "El monto total no puede ser negativo.");

           return (true, null);
       }
   }
  ```

### Criterio de "hecho"

- `dotnet build` verde.
- No hay UI aún ligada, solo clases.

---

## Fase 4 — ViewModel + binding del formulario

**Meta:** UI completa y funcional. Se pueden guardar facturas en la lista.

### Pasos

1. `ViewModels/ViewModelBase.cs` con `INotifyPropertyChanged`.
2. `ViewModels/RelayCommand.cs` (implementación mínima de `ICommand`).
3. `ViewModels/MainViewModel.cs`:
  - Propiedades: `Numero`, `Cliente`, `Fecha`, `MontoTotal` (string o decimal), `MensajeError`.
  - `ObservableCollection<Invoice> Facturas`.
  - `GuardarCommand` → llama a `InvoiceValidator.Validar`; si OK agrega a la lista y limpia el formulario; si no, asigna `MensajeError`.
4. `MainWindow.xaml`: formulario izquierdo + `DataGrid` derecho (ver layout en sección de UI más abajo).
5. En `MainWindow.xaml.cs`: `DataContext = new MainViewModel();`.

### Layout XAML de referencia

```xml
<Grid Margin="16">
    <Grid.ColumnDefinitions>
        <ColumnDefinition Width="320"/>
        <ColumnDefinition Width="*"/>
    </Grid.ColumnDefinitions>

    <StackPanel Grid.Column="0" Margin="0,0,16,0">
        <TextBlock Text="Nueva Factura" FontSize="20" FontWeight="SemiBold" Margin="0,0,0,12"/>
        <TextBlock Text="Número"/>
        <TextBox Text="{Binding Numero, UpdateSourceTrigger=PropertyChanged}"/>
        <TextBlock Text="Cliente" Margin="0,8,0,0"/>
        <TextBox Text="{Binding Cliente, UpdateSourceTrigger=PropertyChanged}"/>
        <TextBlock Text="Fecha" Margin="0,8,0,0"/>
        <DatePicker SelectedDate="{Binding Fecha}"/>
        <TextBlock Text="Monto Total" Margin="0,8,0,0"/>
        <TextBox Text="{Binding MontoTotal, UpdateSourceTrigger=PropertyChanged}"/>
        <Button Content="Guardar" Margin="0,16,0,0" Command="{Binding GuardarCommand}"/>
        <TextBlock Text="{Binding MensajeError}" Foreground="#FF6B6B"
                   Margin="0,8,0,0" TextWrapping="Wrap"/>
    </StackPanel>

    <DataGrid Grid.Column="1"
              ItemsSource="{Binding Facturas}"
              AutoGenerateColumns="False"
              IsReadOnly="True">
        <DataGrid.Columns>
            <DataGridTextColumn Header="Número"  Binding="{Binding Numero}"  Width="100"/>
            <DataGridTextColumn Header="Cliente" Binding="{Binding Cliente}" Width="*"/>
            <DataGridTextColumn Header="Fecha"   Binding="{Binding Fecha, StringFormat=d}" Width="100"/>
            <DataGridTextColumn Header="Monto"   Binding="{Binding MontoTotal, StringFormat=C}" Width="120"/>
        </DataGrid.Columns>
    </DataGrid>
</Grid>
```

### Criterio de "hecho"

- Lanzo la app, lleno los 4 campos con monto `100`, clic en *Guardar* → aparece la factura en la grilla.
- Si dejo el cliente vacío, aparece el mensaje de error en rojo.

---

## Fase 5 — Proyecto de tests (sin tocar el bug todavía)

**Meta:** tener `dotnet test` ya verde con casos "felices" y de validación obvia. Esto demuestra que el proyecto de tests funciona, **sin revelar todavía el bug del cero**.

### Pasos

`tests/InvoiceRegistry.Tests/InvoiceValidatorTests.cs`:

```csharp
using InvoiceRegistry.App.Models;
using InvoiceRegistry.App.Services;
using Xunit;

public class InvoiceValidatorTests
{
    private static Invoice FacturaBase() => new()
    {
        Numero  = "F-001",
        Cliente = "Acme S.A.",
        Fecha   = new DateTime(2026, 5, 17),
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
        var f = FacturaBase(); f.Numero = "";
        var (ok, _) = InvoiceValidator.Validar(f);
        Assert.False(ok);
    }

    [Fact]
    public void Validar_MontoNegativo_RetornaInvalida()
    {
        var f = FacturaBase(); f.MontoTotal = -1m;
        var (ok, _) = InvoiceValidator.Validar(f);
        Assert.False(ok);
    }
}
```

### Criterio de "hecho"

- `dotnet test` → **3/3 passed**.

---

## Fase 6 — Verificación manual del bug

**Meta:** confirmar visualmente que el bug existe. Este es el **estado inicial que vamos a grabar**.

### Pasos

1. `dotnet run --project src/InvoiceRegistry.App`.
2. Llenar Número, Cliente, Fecha; dejar **Monto Total = 0**.
3. Clic en *Guardar*. La factura aparece en la grilla con `$0.00`.

### Caracterización del bug


|                |                                                               |
| -------------- | ------------------------------------------------------------- |
| **Síntoma**    | Al guardar con "Monto Total" = 0, la app la agrega sin error. |
| **Esperado**   | Rechazar con *"El monto total debe ser mayor que cero"*.      |
| **Causa raíz** | `InvoiceValidator.Validar` usa `< 0` en lugar de `<= 0`.      |
| **Severidad**  | Media (datos inconsistentes).                                 |


### Criterio de "hecho"

- Bug reproducido en pantalla. **A partir de aquí empieza la grabación del video.**

---

## Fase 7 — Repo en GitHub e Issue del bug

**Meta:** subir el código y abrir el Issue #1.

### Pasos

```powershell
git init
git add .
git commit -m "feat: initial WPF invoice registry with dark theme"
git branch -M main
gh repo create InvoiceRegistry --public --source=. --remote=origin --push
# o manual: git remote add origin https://github.com/<usuario>/InvoiceRegistry.git && git push -u origin main
```

Crear el Issue en GitHub → **New Issue**:

- Título: **"Bug: se pueden guardar facturas con monto total igual a cero"**
- Cuerpo:
  ```markdown
  ## Descripción
  La aplicación permite registrar facturas cuyo "Monto Total" es 0,
  generando datos inválidos en la lista.

  ## Pasos para reproducir
  1. Abrir la aplicación.
  2. Completar Número, Cliente y Fecha.
  3. Dejar "Monto Total" en 0.
  4. Pulsar "Guardar".

  ## Resultado actual
  La factura se agrega a la lista sin mostrar error.

  ## Resultado esperado
  El sistema debería rechazar la factura con el mensaje:
  "El monto total debe ser mayor que cero."

  ## Posible causa
  `InvoiceValidator.Validar` compara con `< 0` en lugar de `<= 0`.
  ```
- Labels: `bug`, `validation`.

### Criterio de "hecho"

- Repo visible en GitHub con todo el código.
- Issue #1 creado.

---

## Fase 8 — Branch + fix + test del bug

**Meta:** rama de trabajo con el fix aplicado y la prueba que lo cubre.

### Pasos

1. ```powershell
  git checkout -b fix/issue-1-monto-cero
   ```
2. Editar `Services/InvoiceValidator.cs`:
  ```diff
   - if (f.MontoTotal < 0)
   -     return (false, "El monto total no puede ser negativo.");
   + if (f.MontoTotal <= 0)
   +     return (false, "El monto total debe ser mayor que cero.");
  ```
3. Agregar a `InvoiceValidatorTests.cs`:
  ```csharp
   [Fact]
   public void Validar_MontoCero_RetornaInvalida()
   {
       var f = FacturaBase();
       f.MontoTotal = 0m;

       var (ok, error) = InvoiceValidator.Validar(f);

       Assert.False(ok);
       Assert.Equal("El monto total debe ser mayor que cero.", error);
   }
  ```
4. ```powershell
  dotnet test   # 4/4 passed
   ```

> **Tip TDD para grabar:** primero escribe el test, corre `dotnet test` y muestra que **falla** (rojo), luego aplica el fix y muestra **verde**.

### Criterio de "hecho"

- Rama creada, archivos modificados, `dotnet test` verde con 4 pruebas.

---

## Fase 9 — Commit, PR y code review

**Meta:** cerrar el ciclo en GitHub.

### Pasos

1. ```powershell
  git add src/InvoiceRegistry.App/Services/InvoiceValidator.cs `
           tests/InvoiceRegistry.Tests/InvoiceValidatorTests.cs
   git commit -m "fix: reject invoices with total amount <= 0 (closes #1)"
   git push -u origin fix/issue-1-monto-cero
   ```
2. En GitHub: **Compare & pull request**.
  - Título: **"Fix #1: rechazar facturas con monto total cero"**.
  - Cuerpo:
    ```markdown
    ## Resumen
    - Corrige la validación en `InvoiceValidator`: ahora rechaza `MontoTotal <= 0`.
    - Mensaje de error actualizado a "El monto total debe ser mayor que cero.".
    - Agrega test `Validar_MontoCero_RetornaInvalida`.

    Closes #1.

    ## Cómo probar
    ```
  1. `dotnet test` → 4/4 verde.
  2. Ejecutar la app, intentar guardar con monto 0 → debe mostrar el mensaje.
    `
3. Code review (en el mismo PR, mismo usuario o reviewer):
  - Pestaña **Files changed** → revisar diff.
  - Comentario en línea (ej.: *"Buen catch del edge case del cero"*).
  - **Review → Approve**.
  - **Merge pull request** (squash merge recomendado).
  - Verificar que **Issue #1 quedó cerrado automáticamente**.
  - Borrar la rama remota.

### Criterio de "hecho"

- PR mergeado en `main`.
- Issue #1 cerrado por el merge.
- `main` actualizado en local: `git checkout main && git pull`.

---

## Fase 10 (opcional) — CI con GitHub Actions

**Meta:** que el PR muestre un check verde de tests, para reforzar la demo.

### Pasos

`.github/workflows/ci.yml`:

```yaml
name: CI
on:
  push:
    branches: [ main ]
  pull_request:
on:
permissions:
  contents: read
jobs:
  build-test:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '10.x'
      - run: dotnet restore
      - run: dotnet build --no-restore --configuration Release
      - run: dotnet test  --no-build --configuration Release --verbosity normal
```

### Criterio de "hecho"

- En el siguiente PR, aparece el check ✅ *CI / build-test* antes de mergear.

---

## Checklist final antes de grabar

- Fases 0–6 completas (app corre, bug reproducible).
- Repo en GitHub creado pero **Issue #1 aún no creado** (lo creas en cámara).
- Estás parado en `main` con working tree limpio (`git status`).
- Terminal con fuente grande, IDE con tema oscuro a juego con la app.
- Cierra apps ruidosas / notificaciones.

## Cheat-sheet de grabación (10 pasos)

1. Mostrar la app corriendo → reproducir el bug con monto 0.
2. GitHub → **New Issue** → pegar plantilla → crear `#1`.
3. Terminal: `git checkout -b fix/issue-1-monto-cero`.
4. Editar `InvoiceValidator.cs` → cambiar `< 0` por `<= 0` y el mensaje.
5. Agregar `Validar_MontoCero_RetornaInvalida` en `InvoiceValidatorTests.cs`.
6. `dotnet test` → mostrar 4/4 verde.
7. `git add … && git commit -m "fix: … (closes #1)" && git push`.
8. GitHub → **Compare & pull request** → llenar plantilla → crear PR.
9. Pestaña *Files changed* → comentario en línea → **Approve**.
10. **Merge pull request** → confirmar cierre automático del Issue #1.

