param(
  [Parameter(Mandatory = $true)][string]$SiteAdi
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

$posAwesomeRef = $versions["POS_AWESOME_REF"]
if (-not $posAwesomeRef) {
  Write-Hata "POS_AWESOME_REF bulunamadı." "infra/versions.env dosyasını kontrol edin."
  exit 1
}

$composeArgs = Get-ComposeArgs

Write-Bilgi "POS Awesome uygulaması kontrol ediliyor..."
$checkCmd = "test -d apps/posawesome"
try {
  docker compose @composeArgs exec backend bash -lc $checkCmd
  if ($LASTEXITCODE -ne 0) {
    throw "posawesome yok"
  }
  Write-Ok "POS Awesome mevcut."
} catch {
  Write-Bilgi "POS Awesome indiriliyor ($posAwesomeRef)..."
  docker compose @composeArgs exec backend bench get-app --branch $posAwesomeRef https://github.com/yrestom/POS-Awesome.git
}

try {
  $installedApps = docker compose @composeArgs exec backend bench --site $SiteAdi list-apps
} catch {
  Write-Hata "Uygulama listesi alınamadı." "Site adını ve servisleri kontrol edin."
  exit 1
}

function Ensure-AppInstalled {
  param([string]$AppName, [string]$Label)
  if ($installedApps -match "(?m)^$AppName$") {
    Write-Ok "$Label zaten kurulu."
  } else {
    Write-Bilgi "$Label kuruluyor..."
    docker compose @composeArgs exec backend bench --site $SiteAdi install-app $AppName
  }
}

Ensure-AppInstalled "erpnext" "ERPNext"
Ensure-AppInstalled "posawesome" "POS Awesome"
Ensure-AppInstalled "ck_kuruyemis_pos" "CK Kuruyemiş POS"

Write-Bilgi "Migrasyon çalıştırılıyor..."
docker compose @composeArgs exec backend bench --site $SiteAdi migrate

Write-Bilgi "TR varsayılanları uygulanıyor (dil, saat dilimi, para birimi)..."
docker compose @composeArgs exec backend bench --site $SiteAdi execute ck_kuruyemis_pos.utils.set_tr_defaults

Write-Ok "Uygulamalar kuruldu ve varsayılanlar ayarlandı."
