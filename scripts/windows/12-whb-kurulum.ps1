param(
  [string]$HedefKlasor,
  [switch]$SadeceYardim
)

. "$PSScriptRoot\_ortak.ps1"

$repoRoot = Get-RepoRoot
$infraDir = Get-InfraDir
$versionsEnv = Join-Path $infraDir "versions.env"
Ensure-Path $versionsEnv "versions.env bulunamadı."

$versions = @{}
Get-Content $versionsEnv | Where-Object { $_ -and -not $_.StartsWith('#') } | ForEach-Object {
  $parts = $_.Split('=', 2)
  if ($parts.Length -eq 2) { $versions[$parts[0]] = $parts[1] }
}

$downloadUrl = $versions["WHB_DOWNLOAD_URL"]
$sha256Expected = $versions["WHB_SHA256"]
$version = $versions["WHB_VERSION"]

if (-not $downloadUrl -or -not $sha256Expected -or -not $version) {
  Write-Hata "WHB sürüm bilgileri eksik." "infra/versions.env dosyasındaki WHB_* değerlerini kontrol edin."
  exit 1
}

if (-not $HedefKlasor) {
  $HedefKlasor = Join-Path $repoRoot "tools\whb"
}

$fileName = "whb-$version.exe"
$exePath = Join-Path $HedefKlasor $fileName

Write-Bilgi "Webapp Hardware Bridge kurulumu başlıyor..."
Write-Bilgi "Sürüm: $version"
Write-Bilgi "İndirme adresi: $downloadUrl"

if (-not $SadeceYardim) {
  if (-not (Test-Path $HedefKlasor)) {
    New-Item -ItemType Directory -Path $HedefKlasor | Out-Null
  }

  if (-not (Test-Path $exePath)) {
    Write-Bilgi "WHB indiriliyor..."
    try {
      Invoke-WebRequest -Uri $downloadUrl -OutFile $exePath -UseBasicParsing
    } catch {
      Write-Hata "WHB indirilemedi." "İnternet bağlantısını ve URL bilgisini kontrol edin."
      exit 1
    }
  } else {
    Write-Uyari "WHB dosyası zaten var. Doğrulama yapılacak."
  }

  $hash = (Get-FileHash -Algorithm SHA256 -Path $exePath).Hash
  if ($hash -ne $sha256Expected) {
    Write-Hata "WHB checksum doğrulaması başarısız." "Beklenen: $sha256Expected / Gelen: $hash"
    exit 1
  }
  Write-Ok "WHB dosyası doğrulandı: $exePath"
}

Write-Host ""
Write-Bilgi "Kurulum adımları (özet):"
Write-Host "1) $exePath dosyasını çalıştırın."
Write-Host "2) Kurulum tamamlandıktan sonra 'Webapp Hardware Bridge' uygulamasını başlatın."
Write-Host "3) Web UI (varsayılan): http://127.0.0.1:12212"
Write-Host "4) Yazıcı/seri port eşlemesini Web UI üzerinden yapın."
Write-Host "5) Silent-Print-ERPNext kullanıyorsanız uygulama içinden WHB adresini doğrulayın."
Write-Host ""
Write-Bilgi "Varsayılanlar:"
Write-Host "- Adres: 127.0.0.1"
Write-Host "- Port: 12212"
Write-Host "- Kimlik doğrulama: Kapalı"
Write-Host ""
Write-Bilgi "Doğrulama:"
Write-Host "Test-NetConnection -ComputerName localhost -Port 12212"
Write-Host ""
Write-Ok "WHB kurulumu tamamlandı. (İndirildi ve doğrulandıysa hazırdır.)"
