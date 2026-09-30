# Apply logo.jpeg as Android launcher icons (Windows).
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$srcPath = Join-Path $root "logo.jpeg"
$res = Join-Path $root "android\app\src\main\res"

if (!(Test-Path $srcPath)) { throw "logo.jpeg not found: $srcPath" }
if (!(Test-Path $res)) { throw "Android res folder not found: $res" }

$src = [System.Drawing.Image]::FromFile($srcPath)

function Save-Png($bitmap, $path) {
  $dir = Split-Path $path -Parent
  if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
  $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function Make-Icon([int]$size, [double]$scale) {
  $bmp = New-Object System.Drawing.Bitmap $size, $size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.Clear([System.Drawing.Color]::White)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
  $draw = [int]([math]::Floor($size * $scale))
  $offset = [int]([math]::Floor(($size - $draw) / 2))
  $g.DrawImage($src, $offset, $offset, $draw, $draw)
  $g.Dispose()
  return $bmp
}

$legacy = @{
  "mipmap-mdpi" = 48
  "mipmap-hdpi" = 72
  "mipmap-xhdpi" = 96
  "mipmap-xxhdpi" = 144
  "mipmap-xxxhdpi" = 192
}
$foreground = @{
  "mipmap-mdpi" = 108
  "mipmap-hdpi" = 162
  "mipmap-xhdpi" = 216
  "mipmap-xxhdpi" = 324
  "mipmap-xxxhdpi" = 432
}

foreach ($folder in $legacy.Keys) {
  $size = $legacy[$folder]
  $outDir = Join-Path $res $folder
  $icon = Make-Icon $size 0.92
  Save-Png $icon (Join-Path $outDir "ic_launcher.png")
  Save-Png $icon (Join-Path $outDir "ic_launcher_round.png")
  $icon.Dispose()
  Write-Host "Updated $folder ic_launcher ${size}x${size}"
}

foreach ($folder in $foreground.Keys) {
  $size = $foreground[$folder]
  $outDir = Join-Path $res $folder
  $fg = Make-Icon $size 0.66
  Save-Png $fg (Join-Path $outDir "ic_launcher_foreground.png")
  $fg.Dispose()
  Write-Host "Updated $folder ic_launcher_foreground ${size}x${size}"
}

$bg = @"
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#FFFFFF</color>
</resources>
"@
Set-Content -Path (Join-Path $res "values\ic_launcher_background.xml") -Value $bg -Encoding UTF8

$src.Dispose()
Write-Host "Android launcher icons applied from logo.jpeg"
