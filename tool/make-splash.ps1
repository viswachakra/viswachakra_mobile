# Builds the splash-screen images from the app icon.
#
#   assets/splash/splash.png      chakra, centred (Android < 12, iOS)
#   assets/splash/splash_a12.png  chakra inside the 768 px circle Android 12+ masks to
#   assets/splash/branding.png    "Viswachakra Hospitals" in deep red under a gold rule,
#                                 placed at the bottom by flutter_native_splash
#
# Then:  dart run flutter_native_splash:create
#
# The background colour in pubspec.yaml (flutter_native_splash: color) must match
# the icon's own paper colour or the icon shows as a square; this script prints
# the icon's corner pixel so the two can be kept identical.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
$icon = [System.Drawing.Image]::FromFile("$root\assets\icon\icon.png")
New-Item -ItemType Directory -Force "$root\assets\splash" | Out-Null

$corner = ([System.Drawing.Bitmap]$icon).GetPixel(8, 8)
"icon paper colour: #{0:X2}{1:X2}{2:X2}  <- set flutter_native_splash.color to this" -f $corner.R, $corner.G, $corner.B

function NewCanvas($w, $h) {
  $b = New-Object System.Drawing.Bitmap $w, $h
  $g = [System.Drawing.Graphics]::FromImage($b)
  $g.Clear([System.Drawing.Color]::Transparent)
  $g.InterpolationMode = 'HighQualityBicubic'
  $g.SmoothingMode = 'AntiAlias'
  $g.TextRenderingHint = 'AntiAliasGridFit'
  return $b, $g
}

# 1. plain chakra, 900 px (shown at ~225 dp)
$b, $g = NewCanvas 900 900
$g.DrawImage($icon, 0, 0, 900, 900)
$b.Save("$root\assets\splash\splash.png", [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $b.Dispose()

# 2. Android 12: 1152 canvas, content within the central 768 circle
$b, $g = NewCanvas 1152 1152
$g.DrawImage($icon, 192, 192, 768, 768)
$b.Save("$root\assets\splash\splash_a12.png", [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $b.Dispose()

# 3. branding strip
$red  = [System.Drawing.Color]::FromArgb(255, 180, 35, 46)
$gold = [System.Drawing.Color]::FromArgb(255, 201, 162, 39)
$b, $g = NewCanvas 1000 220
$g.FillRectangle((New-Object System.Drawing.SolidBrush $gold), 400, 20, 200, 6)
$font = New-Object System.Drawing.Font 'Georgia', 58, ([System.Drawing.FontStyle]::Bold)
$fmt = New-Object System.Drawing.StringFormat
$fmt.Alignment = 'Center'; $fmt.LineAlignment = 'Center'
$g.DrawString('Viswachakra Hospitals', $font, (New-Object System.Drawing.SolidBrush $red),
  (New-Object System.Drawing.RectangleF 0, 40, 1000, 160), $fmt)
$b.Save("$root\assets\splash\branding.png", [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $b.Dispose()
$icon.Dispose()
'wrote assets/splash/{splash,splash_a12,branding}.png'
