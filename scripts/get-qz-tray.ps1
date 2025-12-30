param(
  [string]$Version,
  [string]$VersionsEnv = (Join-Path $PSScriptRoot "..\infra\versions.env"),
  [string]$OutputPath = (Join-Path $PSScriptRoot "..\frappe_apps\ck_kuruyemis_pos\ck_kuruyemis_pos\public\js\qz\vendor\qz-tray.js"),
  [string]$DocPath = (Join-Path $PSScriptRoot "..\docs\printing\qz-tray.md")
)

function Yaz-Hata {
  param([string]$Mesaj, [string]$Cozum)
  Write-Host "[HATA] $Mesaj"
  Write-Host "[ÇÖZÜM] $Cozum"
  exit 1
}

if (-not $Version) {
  if (!(Test-Path $VersionsEnv)) {
    Yaz-Hata "versions.env bulunamadı." "infra/versions.env yolunu ve dosyayı kontrol edin."
  }
  $versions = @{}
  Get-Content $VersionsEnv | Where-Object { $_ -and -not $_.StartsWith('#') } | ForEach-Object {
    $parts = $_.Split('=', 2)
    if ($parts.Length -eq 2) { $versions[$parts[0]] = $parts[1] }
  }
  $Version = $versions["QZ_TRAY_REF"]
}

if (-not $Version) {
  Yaz-Hata "QZ Tray sürümü bulunamadı." "QZ_TRAY_REF değerini infra/versions.env içine ekleyin."
}

$sourceUrl = "https://raw.githubusercontent.com/qzind/tray/$Version/js/qz-tray.js"

Write-Host "qz-tray.js indiriliyor: $sourceUrl"
Invoke-WebRequest -Uri $sourceUrl -OutFile $OutputPath -UseBasicParsing

$hash = (Get-FileHash -Algorithm SHA256 $OutputPath).Hash.ToLower()
Write-Host "SHA256: $hash"

if (Test-Path $DocPath) {
  $content = Get-Content -Raw -Path $DocPath
  $start = "<!-- QZ_TRAY_SHA256_START -->"
  $end = "<!-- QZ_TRAY_SHA256_END -->"
  $replacement = "$start`n- Sürüm: $Version`n- SHA256: $hash`n$end"
  if ($content -match [regex]::Escape($start)) {
    $pattern = [regex]::Escape($start) + "(?s).*?" + [regex]::Escape($end)
    $content = [regex]::Replace($content, $pattern, $replacement)
  } else {
    $content = $content + "`n`n## Dosya Özeti (SHA256)`n$replacement`n"
  }
  Set-Content -Encoding UTF8 -Path $DocPath -Value $content
}
