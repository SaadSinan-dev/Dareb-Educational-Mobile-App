$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path $PSScriptRoot -Parent
$res = Join-Path $root 'android/app/src/main/res'
$logo = [System.Drawing.Image]::FromFile((Join-Path $root 'assets/images/logo_white.png'))
$teal = [System.Drawing.Color]::FromArgb(47, 184, 187)
try {
  foreach ($entry in @(@('mdpi',48),@('hdpi',72),@('xhdpi',96),@('xxhdpi',144),@('xxxhdpi',192))) {
    $size = [int]$entry[1]
    $bitmap = New-Object System.Drawing.Bitmap($size, $size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
      $graphics.Clear($teal)
      $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
      $margin = [int]($size * .18)
      $graphics.DrawImage($logo, [System.Drawing.Rectangle]::new($margin, $margin, ($size - 2 * $margin), ($size - 2 * $margin)))
      $bitmap.Save((Join-Path $res "mipmap-$($entry[0])/ic_launcher.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    } finally { $graphics.Dispose(); $bitmap.Dispose() }
  }
  $launch = New-Object System.Drawing.Bitmap(220, 220)
  $graphics = [System.Drawing.Graphics]::FromImage($launch)
  try {
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.DrawImage($logo, [System.Drawing.Rectangle]::new(8, 12, 204, 196))
    $destination = Join-Path $res 'drawable-nodpi'
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
    $launch.Save((Join-Path $destination 'launch_logo.png'), [System.Drawing.Imaging.ImageFormat]::Png)
  } finally { $graphics.Dispose(); $launch.Dispose() }
} finally { $logo.Dispose() }
Write-Output 'Generated original-logo Android launcher icons and launch image.'
