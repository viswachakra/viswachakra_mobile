# Pixelates rectangles in a PNG: redact.ps1 <file> "x,y,w,h;x,y,w,h;..."
param([string]$File, [string]$Rects)
Add-Type -AssemblyName System.Drawing
$b = New-Object System.Drawing.Bitmap $File
$g = [System.Drawing.Graphics]::FromImage($b)
$g.InterpolationMode = 'NearestNeighbor'; $g.PixelOffsetMode = 'Half'
foreach ($r in $Rects.Split(';')) {
  $p = $r.Split(',') | ForEach-Object { [int]$_ }
  $x=$p[0]; $y=$p[1]; $w=$p[2]; $h=$p[3]
  $small = New-Object System.Drawing.Bitmap ([Math]::Max(1,[int]($w/22))), ([Math]::Max(1,[int]($h/22)))
  $gs = [System.Drawing.Graphics]::FromImage($small); $gs.InterpolationMode='HighQualityBilinear'
  $gs.DrawImage($b, (New-Object System.Drawing.Rectangle 0,0,$small.Width,$small.Height), (New-Object System.Drawing.Rectangle $x,$y,$w,$h), [System.Drawing.GraphicsUnit]::Pixel)
  $gs.Dispose()
  $g.DrawImage($small, (New-Object System.Drawing.Rectangle $x,$y,$w,$h), (New-Object System.Drawing.Rectangle 0,0,$small.Width,$small.Height), [System.Drawing.GraphicsUnit]::Pixel)
  $small.Dispose()
}
$g.Dispose()
$tmp = "$File.tmp.png"; $b.Save($tmp, [System.Drawing.Imaging.ImageFormat]::Png); $b.Dispose()
Move-Item -Force $tmp $File
"redacted $File"
