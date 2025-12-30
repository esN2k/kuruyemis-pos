param(
  [Parameter(Mandatory = $true)][string]$SiteName
)

$target = Resolve-Path (Join-Path $PSScriptRoot "..\scripts\windows\04-uygulamalari-kur.ps1")
Write-Host "Bu script taşındı: scripts/windows/04-uygulamalari-kur.ps1"
& $target -SiteAdi $SiteName
