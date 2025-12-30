param(
  [Parameter(Mandatory = $true)][string]$SiteAdi
)

. "$PSScriptRoot\_ortak.ps1"

$repoRoot = Get-RepoRoot
$composeArgs = Get-ComposeArgs
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupRoot = Join-Path $repoRoot "backups"
$backupDir = Join-Path $backupRoot $SiteAdi
$destDir = Join-Path $backupDir $timestamp

New-Item -ItemType Directory -Force -Path $destDir | Out-Null

Write-Bilgi "Yedek alınıyor: $SiteAdi"
try {
  docker compose @composeArgs exec backend bench --site $SiteAdi backup --with-files
  Write-Ok "Yedek oluşturuldu (container içinde)."
} catch {
  Write-Hata "Yedek alınamadı." "Site adını ve servisleri kontrol edin."
  exit 1
}

$containerId = docker compose @composeArgs ps -q backend
if (-not $containerId) {
  Write-Hata "Backend container bulunamadı." "02-baslat.ps1 ile servisleri başlatın."
  exit 1
}

$containerPath = "/home/frappe/frappe-bench/sites/$SiteAdi/private/backups/."
Write-Bilgi "Yedek dosyaları kopyalanıyor: $destDir"
try {
  docker cp "$containerId:$containerPath" "$destDir" | Out-Null
  Write-Ok "Yedek kopyalandı: $destDir"
} catch {
  Write-Hata "Yedek dosyaları kopyalanamadı." "Docker yetkilerini ve site adını kontrol edin."
  exit 1
}
