param(
  [string]$SiteAdi = "kuruyemis.local",
  [string]$SiteUrl,
  [string]$FisYazici,
  [string]$EtiketYazici,
  [switch]$GercekBaski,
  [int]$Strict = 0,
  [int]$Quiet = 0
)

. "$PSScriptRoot\_ortak.ps1"

Set-LogMode -Quiet:($Quiet -eq 1) -Strict:($Strict -eq 1)
Reset-LogState

$composeArgs = Get-ComposeArgs
$repoRoot = Get-RepoRoot
$doPrint = $GercekBaski -or ($env:DRY_RUN -eq "0")

if (-not $SiteUrl) {
  $SiteUrl = "http://${SiteAdi}:8080"
}

Write-Bilgi "Duman testi başlıyor..."

Write-Bilgi "Pytest çalıştırılıyor..."
docker compose @composeArgs exec backend bash -lc "pip -q install pytest && PYTHONPATH=/home/frappe/frappe-bench/apps/ck_kuruyemis_pos pytest /home/frappe/frappe-bench/apps/ck_kuruyemis_pos/ck_kuruyemis_pos/tests"
if ($LASTEXITCODE -eq 0) {
  Write-Ok "Pytest başarılı."
} else {
  Write-Hata "Pytest başarısız." "Test çıktısını kontrol edin."
  exit 1
}

Write-Bilgi "Barkod presetleri kontrol ediliyor..."
$result = docker compose @composeArgs exec backend bench --site $SiteAdi execute ck_kuruyemis_pos.utils.check_weighed_barcode_presets
if ($LASTEXITCODE -ne 0) {
  Write-Hata "Preset kontrolü başarısız." "Site adını ve servisleri kontrol edin."
  exit 1
}
$lastLine = $result | Select-Object -Last 1
if ($lastLine -match "missing" -and $lastLine -match "\[\]") {
  Write-Ok "Tartılı barkod presetleri mevcut."
} else {
  Write-Hata "Tartılı barkod presetleri eksik." "04-uygulamalari-kur.ps1 çalıştırın."
  exit 1
}

Write-Bilgi "Fiş/etiket payload üretimi kontrol ediliyor..."
$payloadsRaw = docker compose @composeArgs exec backend bench --site $SiteAdi execute ck_kuruyemis_pos.utils.get_sample_print_payloads
if ($LASTEXITCODE -ne 0) {
  Write-Hata "Payload üretimi başarısız." "Site adını ve uygulama kurulumunu kontrol edin."
  exit 1
}
$payloadLine = $payloadsRaw | Select-Object -Last 1
try {
  $payloads = $payloadLine | ConvertFrom-Json
  if (-not $payloads.receipt -or -not $payloads.label) {
    Write-Hata "Payload üretimi başarısız." "Fiş veya etiket payload boş."
    exit 1
  }
  Write-Ok "Payload üretimi OK (fiş + etiket)."
} catch {
  Write-Hata "Payload çıktısı okunamadı." "JSON çıktısını ve uygulama sürümünü kontrol edin."
  exit 1
}

$opsiyonelModuller = Get-OpsiyonelModuller -SiteAdi $SiteAdi
if ($opsiyonelModuller.Count -gt 0) {
  Write-Bilgi "Opsiyonel modül kontrolleri başlıyor..."
  $apps = docker compose @composeArgs exec backend bench --site $SiteAdi list-apps
  $opsiyonelUygulamalar = @{
    "insights" = @{ App = "insights"; Label = "Frappe Insights" }
    "scale" = @{ App = "scale"; Label = "ERPGulf Scale" }
    "print_designer" = @{ App = "print_designer"; Label = "Print Designer" }
    "silent_print" = @{ App = "silent_print"; Label = "Silent-Print-ERPNext" }
    "scan_me" = @{ App = "scan_me"; Label = "Scan Me" }
    "waba" = @{ App = "waba_integration"; Label = "Frappe WABA Integration" }
    "whatsapp" = @{ App = "frappe_whatsapp"; Label = "Frappe WhatsApp" }
    "betterprint" = @{ App = "frappe_betterprint"; Label = "Frappe BetterPrint" }
    "beam" = @{ App = "beam"; Label = "AgriTheory Beam" }
  }

  $optionalError = $false
  foreach ($modul in $opsiyonelModuller) {
    if (-not $opsiyonelUygulamalar.ContainsKey($modul)) {
      continue
    }
    $entry = $opsiyonelUygulamalar[$modul]
    $appName = $entry.App
    $label = $entry.Label
    if ($apps -match "(?m)^$appName$") {
      Write-Ok "Opsiyonel uygulama doğrulandı: $label"
    } else {
      Write-Hata "Opsiyonel uygulama eksik: $label" "04-uygulamalari-kur.ps1 -OpsiyonelModuller $modul çalıştırın."
      $optionalError = $true
    }
  }

  if ($opsiyonelModuller -contains "waba" -and $opsiyonelModuller -contains "whatsapp") {
    Write-Hata "WhatsApp opsiyonları çakışıyor." "Yalnızca 'waba' veya 'whatsapp' seçili olmalıdır."
    $optionalError = $true
  }

  if ($opsiyonelModuller -contains "whb" -or $opsiyonelModuller -contains "silent_print") {
    $whbPort = 12212
    $whbConn = Test-NetConnection -ComputerName "localhost" -Port $whbPort -WarningAction SilentlyContinue
    if ($whbConn.TcpTestSucceeded) {
      Write-Ok "WHB bağlantısı açık (port $whbPort)."
    } else {
      Write-Hata "WHB bağlantısı kapalı (port $whbPort)." "WHB uygulamasını başlatın veya 12-whb-kurulum.ps1 çalıştırın."
      $optionalError = $true
    }
  }

  if ($optionalError) {
    Write-Hata "Opsiyonel modül kontrolleri başarısız." "Eksikleri giderip duman testini yeniden çalıştırın."
    exit 1
  }
} else {
  Write-Bilgi "Opsiyonel modül kontrolü atlandı (kayıt yok)."
}

if (-not $doPrint) {
  Write-Bilgi "DRY_RUN aktif. Yazdırma adımı atlandı."
  Exit-If-StrictWarnings "Duman testi"
  Write-Ok "Duman testi tamamlandı (DRY_RUN)."
  exit 0
}

$qzConn = Test-NetConnection -ComputerName "localhost" -Port 8182 -WarningAction SilentlyContinue
if (-not $qzConn.TcpTestSucceeded) {
  Write-Hata "QZ Tray bağlantısı kapalı." "QZ Tray'i başlatın ve tekrar deneyin."
  exit 1
}

function Get-PosSettings {
  try {
    $raw = docker compose @composeArgs exec -T backend bench --site $SiteAdi execute ck_kuruyemis_pos.utils.get_pos_printing_settings
    if ($LASTEXITCODE -ne 0) { return $null }
    $line = $raw | Select-Object -Last 1
    if (-not $line) { return $null }
    return $line | ConvertFrom-Json
  } catch {
    return $null
  }
}

$posSettings = Get-PosSettings
$receiptAliases = if ($posSettings) { $posSettings.receipt_printer_aliases } else { "" }
$labelAliases = if ($posSettings) { $posSettings.label_printer_aliases } else { "" }
$labelPreset = if ($posSettings -and $posSettings.label_size_preset) { $posSettings.label_size_preset } else { "38x80_hizli" }
if ($labelPreset -eq "38x80") { $labelPreset = "38x80_hizli" }

$receiptPrinter = if ($FisYazici) {
  $FisYazici
} elseif ($posSettings -and $posSettings.receipt_printer_name) {
  $posSettings.receipt_printer_name
} else {
  "ZY907"
}

$labelPrinter = if ($EtiketYazici) {
  $EtiketYazici
} elseif ($posSettings -and $posSettings.label_printer_name) {
  $posSettings.label_printer_name
} else {
  "X-Printer 490B"
}

try {
  $printers = Get-Printer -ErrorAction Stop
  if (-not $printers -or $printers.Count -eq 0) {
    Write-Hata "Windows yazıcı listesi boş." "Yazıcı sürücülerini kontrol edin."
    exit 1
  }
} catch {
  Write-Hata "Windows yazıcı listesi alınamadı." "Yazıcı sürücülerini kontrol edin."
  exit 1
}

function Normalize-PrinterName {
  param([string]$Value)
  return ($Value | ForEach-Object { $_.ToString().Trim().ToLowerInvariant() })
}

function Parse-Aliases {
  param([string]$Text)
  if (-not $Text) {
    return @()
  }
  return $Text -split "[,;`n`r]+" | ForEach-Object { $_.Trim() } | Where-Object { $_ }
}

function Score-Match {
  param([string]$PrinterName, [string]$Candidate)
  $p = Normalize-PrinterName $PrinterName
  $c = Normalize-PrinterName $Candidate
  if (-not $p -or -not $c) { return 0 }
  if ($p -eq $c) { return 3 }
  if ($p.StartsWith($c) -or $c.StartsWith($p)) { return 2 }
  if ($p.Contains($c) -or $c.Contains($p)) { return 1 }
  return 0
}

function Find-BestPrinter {
  param([string[]]$Printers, [string[]]$Candidates)
  $best = $null
  $bestScore = 0
  $bestLength = [int]::MaxValue
  foreach ($printer in $Printers) {
    foreach ($candidate in $Candidates) {
      $score = Score-Match $printer $candidate
      if ($score -gt $bestScore -or ($score -eq $bestScore -and $printer.Length -lt $bestLength)) {
        $best = $printer
        $bestScore = $score
        $bestLength = $printer.Length
      }
    }
  }
  return $best
}

function Resolve-Printer {
  param(
    [string]$Label,
    [string]$SelectedName,
    [string]$AliasText,
    [string[]]$Printers
  )
  if (-not $SelectedName) {
    Write-Hata "$Label seçilmemiş." "POS Yazdırma Ayarları'ndan yazıcı seçin."
    exit 1
  }
  $candidates = @($SelectedName) + (Parse-Aliases $AliasText)
  $best = Find-BestPrinter $Printers $candidates
  if (-not $best) {
    Write-Hata "$Label QZ listesinde bulunamadı." "Yazıcı adını kontrol edin, QZ Tray izinlerini doğrulayın ve Windows yazıcıyı yeniden ekleyin."
    exit 1
  }
  if ((Normalize-PrinterName $best) -eq (Normalize-PrinterName $SelectedName)) {
    Write-Ok "$Label eşleşti: $best"
  } else {
    Write-Ok "$Label alias ile eşleşti: $best"
  }
  return $best
}

$printerNames = $printers | Select-Object -ExpandProperty Name
$resolvedReceipt = Resolve-Printer "Fiş yazıcısı" $receiptPrinter $receiptAliases $printerNames
$resolvedLabel = Resolve-Printer "Etiket yazıcısı" $labelPrinter $labelAliases $printerNames

$printScript = Join-Path $repoRoot "scripts\tools\qz-print-test.mjs"
if (-not (Test-Path $printScript)) {
  Write-Hata "QZ test scripti bulunamadı." "scripts/tools/qz-print-test.mjs dosyasını kontrol edin."
  exit 1
}

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  Write-Hata "Node.js bulunamadı." "Node.js 18+ kurun ve tekrar deneyin."
  exit 1
}

$packageLock = Join-Path $repoRoot "package-lock.json"
if (-not (Test-Path $packageLock)) {
  Write-Hata "Playwright kilit dosyası bulunamadı." "npm ci çalıştırmadan önce package-lock.json oluşturulmalı."
  exit 1
}

$playwrightDir = Join-Path $repoRoot "node_modules\playwright"
Push-Location $repoRoot
try {
  if (-not (Test-Path $playwrightDir)) {
    Write-Bilgi "Playwright bağımlılıkları kuruluyor..."
    npm ci --silent
    if ($LASTEXITCODE -ne 0) {
      Write-Hata "Playwright kurulumu başarısız." "npm ci çıktısını kontrol edin."
      exit 1
    }
  }

  Write-Bilgi "Playwright tarayıcıları kontrol ediliyor (Chromium)..."
  npx playwright install chromium
  if ($LASTEXITCODE -ne 0) {
    Write-Hata "Playwright tarayıcı kurulumu başarısız." "npx playwright install chromium çıktısını kontrol edin."
    exit 1
  }

  Write-Bilgi "QZ test baskısı başlatılıyor..."
  node $printScript --base-url $SiteUrl --receipt "$resolvedReceipt" --label "$resolvedLabel" --preset "$labelPreset"
  if ($LASTEXITCODE -ne 0) {
    Write-Hata "QZ test baskısı başarısız." "QZ Tray ve yazıcı bağlantılarını kontrol edin."
    exit 1
  }
} finally {
  Pop-Location
}

Write-Ok "QZ test baskısı başarılı."

Exit-If-StrictWarnings "Duman testi"
Write-Ok "Duman testi tamamlandı."

