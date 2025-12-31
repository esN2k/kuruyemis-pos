param(
  [Parameter(Mandatory = $true)][string]$SiteAdi,
  [Parameter(Mandatory = $true)][string]$YedekKlasoru
)

. "$PSScriptRoot\_ortak.ps1"

$composeArgs = Get-ComposeArgs

if (-not (Test-Path $YedekKlasoru)) {
  Write-Hata "Yedek klasörü bulunamadı." "Klasör yolunu kontrol edin: $YedekKlasoru"
  exit 1
}

$sqlFile = Get-ChildItem -Path $YedekKlasoru -Filter "*.sql.gz" | Select-Object -First 1
$publicFile = Get-ChildItem -Path $YedekKlasoru -Filter "*-public-files.tar" | Select-Object -First 1
$privateFile = Get-ChildItem -Path $YedekKlasoru -Filter "*-private-files.tar" | Select-Object -First 1

if (-not $sqlFile) {
  Write-Hata "SQL yedeği bulunamadı." "Klasörde *.sql.gz dosyası olmalı."
  exit 1
}

$containerId = docker compose @composeArgs ps -q backend
if (-not $containerId) {
  Write-Hata "Backend container bulunamadı." "02-baslat.ps1 ile servisleri başlatın."
  exit 1
}

$restoreDir = "/tmp/restore-$($SiteAdi.Replace('.', '-'))"
Write-Bilgi "Restore klasörü hazırlanıyor: $restoreDir"
docker compose @composeArgs exec backend bash -lc "rm -rf $restoreDir && mkdir -p $restoreDir"

Write-Bilgi "Yedek dosyaları container'a kopyalanıyor..."
docker cp "$($sqlFile.FullName)" "$containerId:$restoreDir/" | Out-Null
if ($publicFile) { docker cp "$($publicFile.FullName)" "$containerId:$restoreDir/" | Out-Null }
if ($privateFile) { docker cp "$($privateFile.FullName)" "$containerId:$restoreDir/" | Out-Null }

$sqlName = (Split-Path $sqlFile.FullName -Leaf)
$publicName = if ($publicFile) { (Split-Path $publicFile.FullName -Leaf) } else { "" }
$privateName = if ($privateFile) { (Split-Path $privateFile.FullName -Leaf) } else { "" }

$restoreCmd = "bench --site $SiteAdi restore $restoreDir/$sqlName --force"
if ($publicName) { $restoreCmd += " --with-public-files $restoreDir/$publicName" }
if ($privateName) { $restoreCmd += " --with-private-files $restoreDir/$privateName" }

Write-Bilgi "Geri yükleme başlatılıyor..."
try {
  docker compose @composeArgs exec backend bash -lc $restoreCmd
  Write-Ok "Geri yükleme tamamlandı: $SiteAdi"
} catch {
  Write-Hata "Geri yükleme başarısız." "Yedek dosyalarını ve site adını kontrol edin."
  exit 1
}

