param(
  [switch]$WithOptionalServices
)

$target = Resolve-Path (Join-Path $PSScriptRoot "..\scripts\windows\02-baslat.ps1")
Write-Host "Bu script taşındı: scripts/windows/02-baslat.ps1"
if ($WithOptionalServices) {
  & $target -WithOptionalServices
} else {
  & $target
}

