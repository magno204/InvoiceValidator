#requires -Version 5.1
<#
Generates src/InvoiceRegistry.App/Assets/app.ico from the same design described
in assets/icon.svg. Renders the icon with System.Drawing at multiple sizes
(16, 24, 32, 48, 64, 128, 256) and packages them as PNGs inside a single .ico.
#>
[CmdletBinding()]
param(
    [string]$OutputIcoPath = (Join-Path $PSScriptRoot '..\src\InvoiceRegistry.App\Assets\app.ico')
)

Add-Type -AssemblyName System.Drawing

$cs = @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class IconMaker
{
    public static Bitmap Render(int size)
    {
        var bmp = new Bitmap(size, size, PixelFormat.Format32bppArgb);
        using (var g = Graphics.FromImage(bmp))
        {
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.AntiAliasGridFit;
            g.Clear(Color.Transparent);

            float s = size / 256f;

            // --- Document body with cut top-right corner ---
            using (var docPath = new GraphicsPath())
            {
                float r = 8f * s;
                docPath.AddArc(42f * s,           22f * s,          r * 2, r * 2, 180, 90);
                docPath.AddLine(50f * s,          22f * s,          180f * s, 22f * s);
                docPath.AddLine(180f * s,         22f * s,          222f * s, 64f * s);
                docPath.AddLine(222f * s,         64f * s,          222f * s, 226f * s);
                docPath.AddArc(222f * s - r * 2,  234f * s - r * 2, r * 2, r * 2, 0, 90);
                docPath.AddLine(214f * s,         234f * s,         50f * s, 234f * s);
                docPath.AddArc(42f * s,           234f * s - r * 2, r * 2, r * 2, 90, 90);
                docPath.CloseFigure();

                using (var docBrush = new LinearGradientBrush(
                    new PointF(0, 0), new PointF(0, size),
                    Color.FromArgb(255, 0x3B, 0x82, 0xF6),
                    Color.FromArgb(255, 0x1D, 0x4E, 0xD8)))
                {
                    g.FillPath(docBrush, docPath);
                }
            }

            // --- Folded corner triangle (darker shade) ---
            using (var foldPath = new GraphicsPath())
            {
                foldPath.AddLine(180f * s, 22f * s, 222f * s, 64f * s);
                foldPath.AddLine(222f * s, 64f * s, 180f * s, 64f * s);
                foldPath.CloseFigure();
                using (var foldBrush = new SolidBrush(Color.FromArgb(255, 0x1E, 0x3A, 0x8A)))
                    g.FillPath(foldBrush, foldPath);
            }

            // --- Header line (gold) ---
            FillRoundedRect(g, Color.FromArgb(255, 0xFB, 0xBF, 0x24), 62f * s, 80f * s, 80f * s, 14f * s, 4f * s);
            // --- Body lines (light gray) ---
            FillRoundedRect(g, Color.FromArgb(255, 0xE5, 0xE7, 0xEB), 62f * s, 108f * s, 140f * s, 10f * s, 4f * s);
            FillRoundedRect(g, Color.FromArgb(255, 0xE5, 0xE7, 0xEB), 62f * s, 128f * s, 140f * s, 10f * s, 4f * s);
            FillRoundedRect(g, Color.FromArgb(255, 0xE5, 0xE7, 0xEB), 62f * s, 148f * s, 100f * s, 10f * s, 4f * s);

            // --- $ badge ---
            float cx = 186f * s, cy = 194f * s, outerR = 48f * s, innerR = 42f * s;
            using (var white = new SolidBrush(Color.White))
                g.FillEllipse(white, cx - outerR, cy - outerR, outerR * 2, outerR * 2);
            using (var green = new SolidBrush(Color.FromArgb(255, 0x10, 0xB9, 0x81)))
                g.FillEllipse(green, cx - innerR, cy - innerR, innerR * 2, innerR * 2);

            using (var font = new Font("Segoe UI", 64f * s, FontStyle.Bold, GraphicsUnit.Pixel))
            using (var white = new SolidBrush(Color.White))
            using (var sf = new StringFormat { Alignment = StringAlignment.Center, LineAlignment = StringAlignment.Center })
            {
                var rect = new RectangleF(cx - innerR, cy - innerR - 2f * s, innerR * 2, innerR * 2);
                g.DrawString("$", font, white, rect, sf);
            }
        }
        return bmp;
    }

    static void FillRoundedRect(Graphics g, Color c, float x, float y, float w, float h, float r)
    {
        if (r * 2 > w) r = w / 2;
        if (r * 2 > h) r = h / 2;
        using (var path = new GraphicsPath())
        {
            path.AddArc(x,           y,           r * 2, r * 2, 180, 90);
            path.AddArc(x + w - r*2, y,           r * 2, r * 2, 270, 90);
            path.AddArc(x + w - r*2, y + h - r*2, r * 2, r * 2, 0,   90);
            path.AddArc(x,           y + h - r*2, r * 2, r * 2, 90,  90);
            path.CloseFigure();
            using (var brush = new SolidBrush(c)) g.FillPath(brush, path);
        }
    }

    public static byte[] EncodePng(Bitmap bmp)
    {
        using (var ms = new MemoryStream())
        {
            bmp.Save(ms, ImageFormat.Png);
            return ms.ToArray();
        }
    }

    public static void WriteIco(int[] sizes, string path)
    {
        var pngs = new byte[sizes.Length][];
        for (int i = 0; i < sizes.Length; i++)
            using (var b = Render(sizes[i])) pngs[i] = EncodePng(b);

        using (var fs = File.Create(path))
        using (var bw = new BinaryWriter(fs))
        {
            bw.Write((ushort)0);           // reserved
            bw.Write((ushort)1);           // type = icon
            bw.Write((ushort)sizes.Length);// count

            int offset = 6 + 16 * sizes.Length;
            for (int i = 0; i < sizes.Length; i++)
            {
                int sz = sizes[i];
                bw.Write((byte)(sz >= 256 ? 0 : sz));   // width
                bw.Write((byte)(sz >= 256 ? 0 : sz));   // height
                bw.Write((byte)0);                       // palette
                bw.Write((byte)0);                       // reserved
                bw.Write((ushort)1);                     // planes
                bw.Write((ushort)32);                    // bpp
                bw.Write(pngs[i].Length);                // size in bytes
                bw.Write(offset);                        // offset
                offset += pngs[i].Length;
            }
            for (int i = 0; i < sizes.Length; i++) bw.Write(pngs[i]);
        }
    }
}
'@

Add-Type -TypeDefinition $cs -ReferencedAssemblies System.Drawing -Language CSharp

$dir = Split-Path $OutputIcoPath -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

[IconMaker]::WriteIco(@(16, 24, 32, 48, 64, 128, 256), $OutputIcoPath)
"Icon written: $OutputIcoPath ($((Get-Item $OutputIcoPath).Length) bytes)"
