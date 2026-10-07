# Turns raw emulator screenshots (1080x2400) into App Store screenshots for the
# "iPhone with Dynamic Island (medium display)" slot (1206x2622): crops the Android status bar and the gesture
# bar, scales to width, and pads top/bottom with the app's ivory.
#
#   powershell -File tool/make-store-shots.ps1 <in-dir> <out-dir>
#
# Every *.png in <in-dir> becomes <out-dir>/<same-name>.png.
param([string]$In, [string]$Out)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
New-Item -ItemType Directory -Force $Out | Out-Null
$W = 1206; $H = 2622
$topCrop = 96      # Android status bar
$bottomCrop = 72   # gesture pill
$ivory = [System.Drawing.Color]::FromArgb(255, 250, 247, 241)
Get-ChildItem "$In\*.png" | ForEach-Object {
  $src = New-Object System.Drawing.Bitmap $_.FullName
  $cropH = $src.Height - $topCrop - $bottomCrop
  $scale = $W / $src.Width
  $drawH = [int]($cropH * $scale)
  $y = [int](($H - $drawH) / 2)
  $dst = New-Object System.Drawing.Bitmap $W, $H
  $g = [System.Drawing.Graphics]::FromImage($dst)
  $g.Clear($ivory)
  $g.InterpolationMode = 'HighQualityBicubic'
  $g.DrawImage($src,
    (New-Object System.Drawing.Rectangle 0, $y, $W, $drawH),
    (New-Object System.Drawing.Rectangle 0, $topCrop, $src.Width, $cropH),
    [System.Drawing.GraphicsUnit]::Pixel)
  $g.Dispose()
  $dst.Save((Join-Path $Out $_.Name), [System.Drawing.Imaging.ImageFormat]::Png)
  $dst.Dispose(); $src.Dispose()
  "$($_.Name) -> ${W}x${H}"
}
