param(
  [string]$SiteAdi = "kuruyemis.local"
)

. "$PSScriptRoot\_ortak.ps1"

$repoRoot = Get-RepoRoot
$composeArgs = Get-ComposeArgs
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$bundleRoot = Join-Path $repoRoot "support_bundle"
$bundleDir = Join-Path $bundleRoot $timestamp
New-Item -ItemType Directory -Force -Path $bundleDir | Out-Null

Write-Bilgi "Destek paketi hazırlanıyor..."

try {
  docker compose @composeArgs ps | Out-File -Encoding UTF8 (Join-Path $bundleDir "docker_ps.txt")
  docker compose @composeArgs logs --tail 200 | Out-File -Encoding UTF8 (Join-Path $bundleDir "docker_logs.txt")
} catch {
  Write-Uyari "Docker logları alınamadı."
}

$infraDir = Get-InfraDir
Copy-Item (Join-Path $infraDir "versions.md") (Join-Path $bundleDir "versions.md") -Force
Copy-Item (Join-Path $infraDir "versions.env") (Join-Path $bundleDir "versions.env") -Force

try {
  docker version | Out-File -Encoding UTF8 (Join-Path $bundleDir "docker_version.txt")
} catch {
  Write-Uyari "Docker sürüm bilgisi alınamadı."
}

$containerId = docker compose @composeArgs ps -q backend
if ($containerId) {
  $siteConfigPath = "/home/frappe/frappe-bench/sites/$SiteAdi/site_config.json"
  $logsPath = "/home/frappe/frappe-bench/sites/$SiteAdi/logs/."
  try {
    docker cp "$containerId:$siteConfigPath" (Join-Path $bundleDir "site_config.json") | Out-Null
  } catch {
    Write-Uyari "site_config.json kopyalanamadı."
  }
  try {
    $logsDir = Join-Path $bundleDir "site_logs"
    New-Item -ItemType Directory -Force -Path $logsDir | Out-Null
    docker cp "$containerId:$logsPath" $logsDir | Out-Null
  } catch {
    Write-Uyari "Site logları kopyalanamadı."
  }
}

$zipPath = Join-Path $bundleRoot "support_bundle_$timestamp.zip"
try {
  Compress-Archive -Path $bundleDir\* -DestinationPath $zipPath -Force
  Write-Ok "Destek paketi hazır: $zipPath"
} catch {
  Write-Hata "Destek paketi ziplenemedi." "Disk alanını ve izinleri kontrol edin."
  exit 1
}
