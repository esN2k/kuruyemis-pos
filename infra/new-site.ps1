param(
  [Parameter(Mandatory = $true)][string]$SiteName,
  [string]$AdminPassword = "admin",
  [string]$MariaDBRootPassword = "admin"
)

$target = Resolve-Path (Join-Path $PSScriptRoot "..\scripts\windows\03-site-olustur.ps1")
Write-Host "Bu script taşındı: scripts/windows/03-site-olustur.ps1"
& $target -SiteAdi $SiteName -YoneticiSifresi $AdminPassword -MariaDBRootSifresi $MariaDBRootPassword
