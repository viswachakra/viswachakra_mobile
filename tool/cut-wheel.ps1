# Makes assets/icon/wheel.png: the app icon with its paper background keyed
# out to transparency, for places that sit on white (login card, splash).
# Paper colour is sampled from the corner; pixels near it fade out.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
$src = New-Object System.Drawing.Bitmap "$root\assets\icon\icon.png"
$paper = $src.GetPixel(8, 8)
$out = New-Object System.Drawing.Bitmap $src.Width, $src.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
for ($y = 0; $y -lt $src.Height; $y++) {
  for ($x = 0; $x -lt $src.Width; $x++) {
    $p = $src.GetPixel($x, $y)
    $d = [Math]::Sqrt(($p.R - $paper.R) * ($p.R - $paper.R) + ($p.G - $paper.G) * ($p.G - $paper.G) + ($p.B - $paper.B) * ($p.B - $paper.B))
    $a = [int][Math]::Min(255, [Math]::Max(0, ($d - 12) * 255 / 40))
    $out.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($a, $p.R, $p.G, $p.B))
  }
}
$out.Save("$root\assets\icon\wheel.png", [System.Drawing.Imaging.ImageFormat]::Png)
"wrote assets/icon/wheel.png (paper #{0:X2}{1:X2}{2:X2} keyed out)" -f $paper.R, $paper.G, $paper.B
