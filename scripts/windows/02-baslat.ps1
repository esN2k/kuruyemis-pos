param(
  [switch]$OpsiyonelServisler,
  [switch]$WithOptionalServices
)

. "$PSScriptRoot\_ortak.ps1"

$useOptional = $OpsiyonelServisler -or $WithOptionalServices
$composeArgs = Get-ComposeArgs

if ($useOptional) {
  $composeArgs = @("--profile", "optional") + $composeArgs
}

Write-Bilgi "Docker servisleri başlatılıyor..."
try {
  docker compose @composeArgs up -d
  Write-Ok "Servisler ayakta."
} catch {
  Write-Hata "Docker servisleri başlatılamadı." "Docker Desktop çalışıyor mu kontrol edin."
  exit 1
}
