param(
  [Parameter(Mandatory = $true)][string]$SiteAdi,
  [switch]$DemoVeriYukle,
  [string]$OpsiyonelModuller
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

function Get-VersionValue {
  param([string]$Key, [string]$Fallback)
  $value = $versions[$Key]
  if ($value) { return $value }
  return $Fallback
}

function Get-RequiredVersion {
  param([string]$Key, [string]$Label)
  $value = $versions[$Key]
  if (-not $value) {
    Write-Hata "$Label pini bulunamadı." "infra/versions.env dosyasını kontrol edin ($Key)."
    exit 1
  }
  return $value
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

$insightsRepo = Get-VersionValue "INSIGHTS_REPO" "https://github.com/frappe/insights.git"
$insightsRef = Get-RequiredVersion "INSIGHTS_REF" "Frappe Insights"
$scaleRepo = Get-VersionValue "SCALE_REPO" "https://github.com/ERPGulf/scale.git"
$scaleRef = Get-RequiredVersion "SCALE_REF" "ERPGulf Scale"
$printDesignerRepo = Get-VersionValue "PRINT_DESIGNER_REPO" "https://github.com/frappe/print_designer.git"
$printDesignerRef = Get-RequiredVersion "PRINT_DESIGNER_REF" "Print Designer"
$whbRepo = Get-VersionValue "WHB_REPO" "https://github.com/imTigger/webapp-hardware-bridge.git"
$whbRef = Get-RequiredVersion "WHB_REF" "Webapp Hardware Bridge"
$whbVersion = Get-RequiredVersion "WHB_VERSION" "Webapp Hardware Bridge"
$whbDownloadUrl = Get-RequiredVersion "WHB_DOWNLOAD_URL" "Webapp Hardware Bridge"
$whbSha256 = Get-RequiredVersion "WHB_SHA256" "Webapp Hardware Bridge"
$silentPrintRepo = Get-VersionValue "SILENT_PRINT_REPO" "https://github.com/roquegv/Silent-Print-ERPNext.git"
$silentPrintRef = Get-RequiredVersion "SILENT_PRINT_REF" "Silent-Print-ERPNext"
$scanMeRepo = Get-VersionValue "SCAN_ME_REPO" "https://github.com/Tusharp21/scan-me.git"
$scanMeRef = Get-RequiredVersion "SCAN_ME_REF" "Scan Me"
$wabaRepo = Get-VersionValue "WABA_REPO" "https://github.com/frappe/waba_integration.git"
$wabaRef = Get-RequiredVersion "WABA_REF" "Frappe WABA Integration"
$whatsappRepo = Get-VersionValue "WHATSAPP_REPO" "https://github.com/shridarpatil/frappe_whatsapp.git"
$whatsappRef = Get-RequiredVersion "WHATSAPP_REF" "Frappe WhatsApp"
$betterPrintRepo = Get-VersionValue "BETTERPRINT_REPO" "https://github.com/neocode-it/frappe_betterprint.git"
$betterPrintRef = Get-RequiredVersion "BETTERPRINT_REF" "Frappe BetterPrint"
$beamRepo = Get-VersionValue "BEAM_REPO" "https://github.com/agritheory/beam.git"
$beamRef = Get-RequiredVersion "BEAM_REF" "AgriTheory Beam"

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

function Ensure-AppRepo {
  param(
    [string]$AppName,
    [string]$RepoUrl,
    [string]$Ref,
    [string]$Label
  )

  $checkCmd = "test -d apps/$AppName/.git"
  docker compose @composeArgs exec backend bash -lc $checkCmd
  $needsClone = $LASTEXITCODE -ne 0

  if (-not $needsClone) {
    $remoteUrl = docker compose @composeArgs exec backend bash -lc "git -C apps/$AppName remote get-url origin" | Select-Object -Last 1
    $remoteNorm = Normalize-GitUrl $remoteUrl
    $expectedNorm = Normalize-GitUrl $RepoUrl
    if ($remoteNorm -ne $expectedNorm) {
      Write-Uyari "$Label kaynak deposu farklı. Yeniden indirilecek."
      $needsClone = $true
    }
  }

  if ($needsClone) {
    Write-Bilgi "$Label indiriliyor ($Ref)..."
    docker compose @composeArgs exec backend bash -lc "rm -rf apps/$AppName"
    docker compose @composeArgs exec @pipEnv backend bench get-app --branch $Ref $RepoUrl
    if ($LASTEXITCODE -ne 0) {
      Write-Hata "$Label indirilemedi." "İnternet bağlantısını ve Docker loglarını kontrol edin."
      exit 1
    }
  } else {
    $currentRef = docker compose @composeArgs exec backend bash -lc "git -C apps/$AppName rev-parse HEAD" | Select-Object -Last 1
    if ($currentRef -ne $Ref) {
      Write-Uyari "$Label pini güncelleniyor: $currentRef -> $Ref"
      docker compose @composeArgs exec backend bash -lc "git -C apps/$AppName fetch --all"
      docker compose @composeArgs exec backend bash -lc "git -C apps/$AppName checkout $Ref"
      if ($LASTEXITCODE -ne 0) {
        Write-Hata "$Label pini güncellenemedi." "Uygulama klasörünü ve git erişimini kontrol edin."
        exit 1
      }
    } else {
      Write-Ok "$Label mevcut ve pinli."
    }
  }
}

function Ensure-FrontendAssets {
  param([string]$AppName, [string]$Label)
  $hasPackage = docker compose @composeArgs exec backend bash -lc "test -f apps/$AppName/package.json"
  if ($LASTEXITCODE -eq 0) {
    Write-Bilgi "$Label ön uç bağımlılıkları (yarn) kuruluyor..."
    $installPrereqsCmd = "if ! command -v npm >/dev/null 2>&1; then apt-get update && apt-get install -y npm; fi && if ! command -v yarn >/dev/null 2>&1; then npm install -g yarn; fi"
    docker compose @composeArgs exec --user root backend bash -lc $installPrereqsCmd
    if ($LASTEXITCODE -ne 0) {
      Write-Hata "$Label önkoşul kurulumu başarısız (npm/yarn)." "Docker loglarını kontrol edin."
      exit 1
    }

    $yarnInstallCmd = "cd apps/$AppName && if [ -f yarn.lock ]; then yarn install --frozen-lockfile; else yarn install; fi"
    docker compose @composeArgs exec backend bash -lc $yarnInstallCmd
    if ($LASTEXITCODE -ne 0) {
      Write-Hata "$Label yarn kurulumu başarısız." "Yarn kurulumunu ve ağ bağlantısını kontrol edin."
      exit 1
    }

    Write-Bilgi "$Label asset build çalıştırılıyor..."
    docker compose @composeArgs exec backend bench build --app $AppName
    if ($LASTEXITCODE -ne 0) {
      Write-Hata "$Label build başarısız." "Docker loglarını kontrol edin."
      exit 1
    }
  }
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
      Write-Hata "$Label pini güncellenemedi." "Uygulama klasörünü ve git erişimini kontrol edin."
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
    docker compose @composeArgs exec @pipEnv backend bench setup requirements $ModuleName
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
docker compose @composeArgs exec @pipEnv backend bench setup requirements posawesome
if ($LASTEXITCODE -ne 0) {
  Write-Hata "POS Awesome bağımlılıkları kurulamadı." "Docker loglarını kontrol edin."
  exit 1
}

Ensure-FrontendAssets "posawesome" "POS Awesome"

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

$secimler = @()
if ($OpsiyonelModuller) {
  $secimler = $OpsiyonelModuller -split "[,; ]+" | ForEach-Object { $_.Trim().ToLowerInvariant() } | Where-Object { $_ }
}

$secimler = $secimler | Sort-Object -Unique
if ($secimler -contains "waba" -and $secimler -contains "whatsapp") {
  Write-Hata "WhatsApp opsiyonu çakışması var." "Aynı anda yalnızca 'waba' veya 'whatsapp' seçilebilir."
  exit 1
}

if ($secimler -contains "silent_print" -and -not ($secimler -contains "whb")) {
  Write-Uyari "Silent-Print-ERPNext seçildi. Webapp Hardware Bridge kurulumu da önerilir."
  $secimler += "whb"
  $secimler = $secimler | Sort-Object -Unique
}

$opsiyonelKatalog = @{
  "insights" = @{
    Type = "frappe"
    AppName = "insights"
    Label = "Frappe Insights"
    Repo = $insightsRepo
    Ref = $insightsRef
  }
  "scale" = @{
    Type = "frappe"
    AppName = "scale"
    Label = "ERPGulf Scale"
    Repo = $scaleRepo
    Ref = $scaleRef
  }
  "print_designer" = @{
    Type = "frappe"
    AppName = "print_designer"
    Label = "Print Designer"
    Repo = $printDesignerRepo
    Ref = $printDesignerRef
  }
  "whb" = @{
    Type = "external"
    Label = "Webapp Hardware Bridge"
    Repo = $whbRepo
    Ref = $whbRef
    Version = $whbVersion
    DownloadUrl = $whbDownloadUrl
    Sha256 = $whbSha256
  }
  "silent_print" = @{
    Type = "frappe"
    AppName = "silent_print"
    Label = "Silent-Print-ERPNext"
    Repo = $silentPrintRepo
    Ref = $silentPrintRef
  }
  "scan_me" = @{
    Type = "frappe"
    AppName = "scan_me"
    Label = "Scan Me"
    Repo = $scanMeRepo
    Ref = $scanMeRef
  }
  "waba" = @{
    Type = "frappe"
    AppName = "waba_integration"
    Label = "Frappe WABA Integration"
    Repo = $wabaRepo
    Ref = $wabaRef
  }
  "whatsapp" = @{
    Type = "frappe"
    AppName = "frappe_whatsapp"
    Label = "Frappe WhatsApp"
    Repo = $whatsappRepo
    Ref = $whatsappRef
  }
  "betterprint" = @{
    Type = "frappe"
    AppName = "frappe_betterprint"
    Label = "Frappe BetterPrint"
    Repo = $betterPrintRepo
    Ref = $betterPrintRef
  }
  "beam" = @{
    Type = "frappe"
    AppName = "beam"
    Label = "AgriTheory Beam"
    Repo = $beamRepo
    Ref = $beamRef
  }
}

if ($secimler.Count -gt 0) {
  $bilinenler = $opsiyonelKatalog.Keys | Sort-Object
  foreach ($secim in $secimler) {
    if (-not $opsiyonelKatalog.ContainsKey($secim)) {
      Write-Uyari "Bilinmeyen opsiyonel modül: $secim"
      Write-Uyari "Geçerli seçenekler: $($bilinenler -join ', ')"
      continue
    }
    $ayar = $opsiyonelKatalog[$secim]
    $label = $ayar.Label
    if ($ayar.Type -eq "external") {
      Write-Bilgi "$label kurulumu (harici bileşen)..."
      & "$PSScriptRoot\12-whb-kurulum.ps1"
      if ($LASTEXITCODE -ne 0) {
        Write-Hata "$label kurulumu başarısız." "12-whb-kurulum.ps1 çıktısını kontrol edin."
        exit 1
      }
      Write-Ok "$label hazır."
      continue
    }

    $appName = $ayar.AppName
    Write-Bilgi "$label kurulumu başlıyor..."
    Ensure-AppRepo $appName $ayar.Repo $ayar.Ref $label
    if ($secim -eq "betterprint") {
      Write-Uyari "BetterPrint ek bağımlılıklar gerektirir (playwright + sistem kütüphaneleri)."
      Write-Uyari "Gerekirse container içinde Playwright kurulumu yapın."
    }
    if ($secim -eq "beam") {
      Write-Uyari "Beam modülü için ERPNext v15 uyumu sahada test edilmelidir."
    }
    Write-Bilgi "$label bağımlılıkları kuruluyor..."
    docker compose @composeArgs exec @pipEnv backend bench setup requirements $appName
    if ($LASTEXITCODE -ne 0) {
      Write-Hata "$label bağımlılıkları kurulamadı." "Docker loglarını kontrol edin."
      exit 1
    }
    Ensure-FrontendAssets $appName $label
    Ensure-PythonModule $appName $label
    Ensure-AppInstalled $appName $label
    Write-Ok "$label hazır."
  }

  $modulListesi = $secimler -join ","
  Write-Bilgi "Opsiyonel modül kaydı güncelleniyor..."
  docker compose @composeArgs exec backend bench --site $SiteAdi set-config ck_kuruyemis_pos_optional_modules $modulListesi
  if ($LASTEXITCODE -ne 0) {
    Write-Uyari "Opsiyonel modül kaydı güncellenemedi."
  }
} else {
  Write-Uyari "Opsiyonel modül seçilmedi. Gerekirse -OpsiyonelModuller kullanın."
}

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

if ($DemoVeriYukle) {
  Write-Bilgi "Demo verileri yükleniyor..."
  docker compose @composeArgs exec backend bench --site $SiteAdi execute ck_kuruyemis_pos.demo_data.load_demo_data
  if ($LASTEXITCODE -ne 0) {
    Write-Hata "Demo verileri yüklenemedi." "Docker loglarını ve site durumunu kontrol edin."
    exit 1
  }
  Write-Ok "Demo verileri yüklendi."
} else {
  Write-Uyari "Demo verisi atlandı. Gerekirse -DemoVeriYukle ile tekrar çalıştırın."
}

Write-Ok "Uygulamalar kuruldu ve varsayılanlar ayarlandı."


