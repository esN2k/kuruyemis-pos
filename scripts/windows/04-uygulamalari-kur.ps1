param(
  [Parameter(Mandatory = $true)][string]$SiteAdi
)

. "$PSScriptRoot\_ortak.ps1"

$infraDir = Get-InfraDir
$versionsEnv = Join-Path $infraDir "versions.env"
Ensure-Path $versionsEnv "versions.env bulunamadı."

$versions = @{}
Get-Content $versionsEnv | Where-Object { $_ -and -not $_.StartsWith('#') } | ForEach-Object {
  $parts = $_.Split('=', 2)
  if ($parts.Length -eq 2) { $versions[$parts[0]] = $parts[1] }
}

$posAwesomeRepo = $versions["POS_AWESOME_REPO"]
if (-not $posAwesomeRepo) {
  $posAwesomeRepo = "https://github.com/defendicon/POS-Awesome-V15.git"
}

$posAwesomeRef = $versions["POS_AWESOME_REF"]
if (-not $posAwesomeRef) {
  Write-Hata "POS_AWESOME_REF bulunamadı." "infra/versions.env dosyasını kontrol edin."
  exit 1
}

$composeArgs = Get-ComposeArgs
$backendId = docker compose @composeArgs ps -q backend
if (-not $backendId) {
  Write-Hata "Backend servisi çalışmıyor." "Önce scripts/windows/02-baslat.ps1 çalıştırın."
  exit 1
}

$pipEnv = @(
  "-e", "UV_PIP_NO_BUILD_ISOLATION=1",
  "-e", "PIP_NO_BUILD_ISOLATION=1"
)

function Normalize-GitUrl {
  param([string]$Url)
  if (-not $Url) { return "" }
  $value = $Url.Trim()
  if ($value.EndsWith(".git")) {
    $value = $value.Substring(0, $value.Length - 4)
  }
  return $value.TrimEnd("/")
}

Write-Bilgi "POS Awesome uygulaması kontrol ediliyor..."
$checkCmd = "test -f apps/posawesome/posawesome/__init__.py"
docker compose @composeArgs exec backend bash -lc $checkCmd
$needsClone = $LASTEXITCODE -ne 0

if (-not $needsClone) {
  $remoteUrl = docker compose @composeArgs exec backend bash -lc "git -C apps/posawesome remote get-url origin" | Select-Object -Last 1
  $remoteNorm = Normalize-GitUrl $remoteUrl
  $expectedNorm = Normalize-GitUrl $posAwesomeRepo
  if ($remoteNorm -ne $expectedNorm) {
    Write-Uyari "POS Awesome kaynak deposu farklı. Yeniden indirilecek."
    $needsClone = $true
  }
}

if ($needsClone) {
  Write-Bilgi "POS Awesome indiriliyor ($posAwesomeRef)..."
  docker compose @composeArgs exec backend bash -lc "rm -rf apps/posawesome"
  docker compose @composeArgs exec @pipEnv backend bench get-app --branch $posAwesomeRef $posAwesomeRepo
  if ($LASTEXITCODE -ne 0) {
    Write-Hata "POS Awesome indirilemedi." "İnternet bağlantısını ve Docker loglarını kontrol edin."
    exit 1
  }
} else {
  $currentRef = docker compose @composeArgs exec backend bash -lc "git -C apps/posawesome rev-parse HEAD" | Select-Object -Last 1
  if ($currentRef -ne $posAwesomeRef) {
    Write-Uyari "POS Awesome pini güncelleniyor: $currentRef -> $posAwesomeRef"
    docker compose @composeArgs exec backend bash -lc "git -C apps/posawesome fetch --all"
    docker compose @composeArgs exec backend bash -lc "git -C apps/posawesome checkout $posAwesomeRef"
    if ($LASTEXITCODE -ne 0) {
      Write-Hata "POS Awesome pini güncellenemedi." "POS Awesome klasörünü ve git erişimini kontrol edin."
      exit 1
    }
  } else {
    Write-Ok "POS Awesome mevcut ve pinli."
  }
}

$installedApps = docker compose @composeArgs exec backend bench --site $SiteAdi list-apps
if ($LASTEXITCODE -ne 0) {
  Write-Hata "Uygulama listesi alınamadı." "Site adını ve servisleri kontrol edin."
  exit 1
}

function Ensure-PythonModule {
  param([string]$ModuleName, [string]$Label)
  docker compose @composeArgs exec backend bash -lc "python -c \"import $ModuleName\""
  if ($LASTEXITCODE -ne 0) {
    Write-Bilgi "$Label paketleri kuruluyor..."
    docker compose @composeArgs exec @pipEnv backend bench setup requirements --app $ModuleName
    if ($LASTEXITCODE -ne 0) {
      Write-Hata "$Label paket kurulumu başarısız." "Docker loglarını kontrol edin."
      exit 1
    }
    docker compose @composeArgs exec backend bash -lc "python -c \"import $ModuleName\""
    if ($LASTEXITCODE -ne 0) {
      Write-Hata "$Label modülü yüklenemedi." "POS Awesome klasörü ve bağımlılıklarını kontrol edin."
      exit 1
    }
  }
}

Write-Bilgi "POS Awesome bağımlılıkları kuruluyor..."
docker compose @composeArgs exec @pipEnv backend bench setup requirements --app posawesome
if ($LASTEXITCODE -ne 0) {
  Write-Hata "POS Awesome bağımlılıkları kurulamadı." "Docker loglarını kontrol edin."
  exit 1
}

Write-Bilgi "POS Awesome ön uç bağımlılıkları (yarn) kuruluyor..."
$yarnCmd = "cd apps/posawesome && if command -v yarn >/dev/null 2>&1; then if [ -f yarn.lock ]; then yarn install --frozen-lockfile; else yarn install; fi; else echo 'Yarn bulunamadı'; exit 1; fi"
docker compose @composeArgs exec backend bash -lc $yarnCmd
if ($LASTEXITCODE -ne 0) {
  Write-Hata "POS Awesome yarn kurulumu başarısız." "Yarn kurulumunu ve ağ bağlantısını kontrol edin."
  exit 1
}

Write-Bilgi "POS Awesome asset build çalıştırılıyor..."
docker compose @composeArgs exec backend bench build --app posawesome
if ($LASTEXITCODE -ne 0) {
  Write-Hata "POS Awesome build başarısız." "Docker loglarını kontrol edin."
  exit 1
}

function Ensure-AppInstalled {
  param([string]$AppName, [string]$Label)
  if ($installedApps -match "(?m)^$AppName$") {
    Write-Ok "$Label zaten kurulu."
  } else {
    Write-Bilgi "$Label kuruluyor..."
    docker compose @composeArgs exec @pipEnv backend bench --site $SiteAdi install-app $AppName
    if ($LASTEXITCODE -ne 0) {
      Write-Hata "$Label kurulamadı." "Docker loglarını ve site durumunu kontrol edin."
      exit 1
    }
  }
}

Ensure-AppInstalled "erpnext" "ERPNext"
Ensure-PythonModule "posawesome" "POS Awesome"
Ensure-AppInstalled "posawesome" "POS Awesome"
Ensure-AppInstalled "ck_kuruyemis_pos" "CK Kuruyemiş POS"

Write-Bilgi "Migrasyon çalıştırılıyor..."
docker compose @composeArgs exec backend bench --site $SiteAdi migrate
if ($LASTEXITCODE -ne 0) {
  Write-Hata "Migrasyon başarısız." "Docker loglarını ve site durumunu kontrol edin."
  exit 1
}

Write-Bilgi "TR varsayılanları uygulanıyor (dil, saat dilimi, para birimi)..."
docker compose @composeArgs exec backend bench --site $SiteAdi execute ck_kuruyemis_pos.utils.set_tr_defaults
if ($LASTEXITCODE -ne 0) {
  Write-Hata "TR varsayılanları uygulanamadı." "Site durumunu ve logları kontrol edin."
  exit 1
}

Write-Ok "Uygulamalar kuruldu ve varsayılanlar ayarlandı."

