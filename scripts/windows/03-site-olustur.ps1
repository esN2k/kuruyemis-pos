param(
  [Parameter(Mandatory = $true)][string]$SiteAdi,
  [string]$YoneticiSifresi = "admin",
  [string]$MariaDBRootSifresi
)

. "$PSScriptRoot\_ortak.ps1"

if (-not $MariaDBRootSifresi) {
  $MariaDBRootSifresi = Get-DbPassword
}

$composeArgs = Get-ComposeArgs
$backendId = docker compose @composeArgs ps -q backend
if (-not $backendId) {
  Write-Hata "Backend servisi çalışmıyor." "Önce scripts/windows/02-baslat.ps1 çalıştırın."
  exit 1
}

$dbId = docker compose @composeArgs ps -q db
if (-not $dbId) {
  Write-Hata "Veritabanı servisi çalışmıyor." "Compose dosyalarının MariaDB override içerdiğini kontrol edin."
  exit 1
}

Write-Bilgi "Veritabanı hazır bekleniyor..."
$maxWaitSeconds = 60
$waited = 0
while ($waited -lt $maxWaitSeconds) {
  $dbId = docker compose @composeArgs ps -q db
  if (-not $dbId) {
    Write-Hata "Veritabanı servisi bulunamadı." "02-baslat.ps1 ile servisleri başlatın."
    exit 1
  }
  $health = docker inspect -f '{{.State.Health.Status}}' $dbId 2>$null
  if ($health -eq "healthy") {
    break
  }
  Start-Sleep -Seconds 2
  $waited += 2
}
if ($health -ne "healthy") {
  Write-Hata "Veritabanı hazır değil." "Biraz bekleyip tekrar deneyin."
  exit 1
}

Write-Bilgi "Site oluşturuluyor: $SiteAdi"

$checkCmd = "test -d sites/$SiteAdi"
docker compose @composeArgs exec backend bash -lc $checkCmd
if ($LASTEXITCODE -eq 0) {
  $appsCheck = docker compose @composeArgs exec backend bench --site $SiteAdi list-apps
  if ($LASTEXITCODE -eq 0) {
    Write-Uyari "Site zaten var: $SiteAdi"
    exit 0
  }
  Write-Hata "Site klasörü var ama erişilemiyor: $SiteAdi" "Yarım kurulum olabilir. Gerekirse bench drop-site ile temizleyin."
  exit 1
}

docker compose @composeArgs exec backend bench new-site $SiteAdi --admin-password $YoneticiSifresi --mariadb-root-password $MariaDBRootSifresi --install-app erpnext
if ($LASTEXITCODE -ne 0) {
  Write-Hata "Site oluşturulamadı." "Site adı ve şifreleri kontrol edin."
  exit 1
}
Write-Ok "Site oluşturuldu: $SiteAdi"

