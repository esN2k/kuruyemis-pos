param(
  [string]$Version,
  [string]$VersionsEnv = (Join-Path $PSScriptRoot "..\\infra\\versions.env"),
  [string]$OutputPath = (Join-Path $PSScriptRoot "..\\frappe_apps\\ck_kuruyemis_pos\\ck_kuruyemis_pos\\public\\js\\qz\\vendor\\qz-tray.js"),
  [string]$DocPath = (Join-Path $PSScriptRoot "..\\docs\\printing\\qz-tray.md")
)

if (-not $Version) {
  if (!(Test-Path $VersionsEnv)) {
    throw "Missing versions.env at $VersionsEnv"
  }
  $versions = @{}
  Get-Content $VersionsEnv | Where-Object { $_ -and -not $_.StartsWith('#') } | ForEach-Object {
    $parts = $_.Split('=', 2)
    if ($parts.Length -eq 2) { $versions[$parts[0]] = $parts[1] }
  }
  $Version = $versions["QZ_TRAY_REF"]
}

if (-not $Version) {
  throw "QZ Tray version not provided and QZ_TRAY_REF missing"
}

$sourceUrl = "https://raw.githubusercontent.com/qzind/tray/$Version/js/qz-tray.js"

Write-Host "Downloading qz-tray.js from $sourceUrl"
Invoke-WebRequest -Uri $sourceUrl -OutFile $OutputPath -UseBasicParsing

$hash = (Get-FileHash -Algorithm SHA256 $OutputPath).Hash.ToLower()
Write-Host "SHA256: $hash"

if (Test-Path $DocPath) {
  $content = Get-Content -Raw -Path $DocPath
  $start = "<!-- QZ_TRAY_SHA256_START -->"
  $end = "<!-- QZ_TRAY_SHA256_END -->"
  $replacement = "$start`n- Version: $Version`n- SHA256: $hash`n$end"
  if ($content -match [regex]::Escape($start)) {
    $pattern = [regex]::Escape($start) + "(?s).*?" + [regex]::Escape($end)
    $content = [regex]::Replace($content, $pattern, $replacement)
  } else {
    $content = $content + "`n`n## Checksum`n$replacement`n"
  }
  Set-Content -Encoding ASCII -Path $DocPath -Value $content
}