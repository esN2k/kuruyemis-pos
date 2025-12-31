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
docker compose @composeArgs up -d
if ($LASTEXITCODE -ne 0) {
  Write-Hata "Docker servisleri başlatılamadı." "Docker Desktop çalışıyor mu ve compose hatalarını kontrol edin."
  exit 1
}
Write-Ok "Servisler ayakta."

