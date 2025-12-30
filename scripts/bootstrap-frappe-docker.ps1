param(
  [switch]$QzYenile
)

$target = Join-Path $PSScriptRoot "windows\01-bootstrap.ps1"
Write-Host "Bu script taşındı: scripts/windows/01-bootstrap.ps1"
& $target @PSBoundParameters
