param(
  [string]$SiteAdi = "kuruyemis.local",
  [string]$SiteUrl,
  [int]$Strict = 0,
  [int]$Quiet = 0,
  [int]$QzZorunlu = 1
)

. "$PSScriptRoot\_ortak.ps1"

Set-LogMode -Quiet:($Quiet -eq 1) -Strict:($Strict -eq 1)
Reset-LogState

$hasError = $false
$repoRoot = Get-RepoRoot
$composeArgs = Get-ComposeArgs

if (-not $SiteUrl) {
  $SiteUrl = "http://${SiteAdi}:8080"
}

Write-Bilgi "Doktor kontrolü başlıyor..."

docker info *> $null
if ($LASTEXITCODE -ne 0) {
  Write-Hata "Docker Desktop çalışmıyor." "Docker Desktop'ı başlatın."
  exit 1
}
Write-Ok "Docker Desktop çalışıyor."

try {
  docker compose @composeArgs ps *> $null
  if ($LASTEXITCODE -ne 0) { throw "compose hata" }
} catch {
  Write-Hata "Docker compose dosyaları bulunamadı." "Önce 01-bootstrap.ps1 çalıştırın."
  exit 1
}

docker compose @composeArgs exec backend bash -lc "test -d sites/$SiteAdi"
if ($LASTEXITCODE -eq 0) {
  Write-Ok "Site bulundu: $SiteAdi"
} else {
  Write-Hata "Site bulunamadı: $SiteAdi" "03-site-olustur.ps1 çalıştırın."
  $hasError = $true
}

$apps = docker compose @composeArgs exec backend bench --site $SiteAdi list-apps
if ($LASTEXITCODE -eq 0) {
  foreach ($app in @("erpnext", "posawesome", "ck_kuruyemis_pos")) {
    if ($apps -match "(?m)^$app$") {
      Write-Ok "Uygulama kurulu: $app"
    } else {
      Write-Uyari "Uygulama eksik: $app"
    }
  }
} else {
  Write-Uyari "Uygulama listesi alınamadı."
}

$opsiyonelModuller = Get-OpsiyonelModuller -SiteAdi $SiteAdi
if ($opsiyonelModuller.Count -gt 0) {
  Write-Bilgi "Opsiyonel modüller tespit edildi: $($opsiyonelModuller -join ', ')"
} else {
  Write-Bilgi "Opsiyonel modül kaydı bulunamadı."
}

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

if ($apps -and $opsiyonelModuller.Count -gt 0) {
  foreach ($modul in $opsiyonelModuller) {
    if (-not $opsiyonelUygulamalar.ContainsKey($modul)) {
      continue
    }
    $entry = $opsiyonelUygulamalar[$modul]
    $appName = $entry.App
    $label = $entry.Label
    if ($apps -match "(?m)^$appName$") {
      Write-Ok "Opsiyonel uygulama kurulu: $label"
    } else {
      Write-Hata "Opsiyonel uygulama eksik: $label" "04-uygulamalari-kur.ps1 -OpsiyonelModuller $modul çalıştırın."
      $hasError = $true
    }
  }
}

if ($opsiyonelModuller -contains "betterprint") {
  Write-Uyari "BetterPrint aktif. Playwright ve sistem kütüphaneleri gerektirir; çıktı sorunlarında kurulum dokümanını kontrol edin."
}

function Check-Service {
  param(
    [string]$Name,
    [bool]$Required = $true
  )
  $id = docker compose @composeArgs ps -q $Name
  if (-not $id) {
    if ($Required) {
      Write-Hata "Servis çalışmıyor: $Name" "02-baslat.ps1 ile servisleri başlatın."
      $script:hasError = $true
    } else {
      Write-Bilgi "Opsiyonel servis kapalı: $Name"
    }
    return
  }
  $status = docker inspect -f '{{.State.Status}}' $id
  if ($status -ne "running") {
    if ($Required) {
      Write-Hata "Servis durumu sorunlu: $Name ($status)" "Docker loglarını kontrol edin."
      $script:hasError = $true
    } else {
      Write-Bilgi "Opsiyonel servis durumu: $Name ($status)"
    }
  } else {
    Write-Ok "Servis çalışıyor: $Name"
  }
}

Check-Service "backend" $true
Check-Service "frontend" $true
Check-Service "websocket" $true
Check-Service "queue-short" $true
Check-Service "queue-long" $true
Check-Service "scheduler" $true
Check-Service "db" $true
Check-Service "redis-cache" $true
Check-Service "redis-queue" $true
Check-Service "fiscal-adapter" $false
Check-Service "hardware-bridge" $false

if ($opsiyonelModuller -contains "waba" -and $opsiyonelModuller -contains "whatsapp") {
  Write-Hata "WhatsApp opsiyonları çakışıyor." "Yalnızca 'waba' veya 'whatsapp' seçili olmalıdır."
  $hasError = $true
}

if ($opsiyonelModuller -contains "whb" -or $opsiyonelModuller -contains "silent_print") {
  $whbPort = 12212
  $whbConn = Test-NetConnection -ComputerName "localhost" -Port $whbPort -WarningAction SilentlyContinue
  if ($whbConn.TcpTestSucceeded) {
    Write-Ok "WHB bağlantısı açık (port $whbPort)."
  } else {
    Write-Uyari "WHB bağlantısı kapalı (port $whbPort)." 
    Write-Uyari "WHB uygulamasını başlatın veya 12-whb-kurulum.ps1 çalıştırın."
  }
}

Write-Bilgi "MariaDB sürümü kontrol ediliyor..."
$dbPassword = Get-DbPassword
$versionRaw = docker compose @composeArgs exec -T db mysql -uroot -p$dbPassword -N -s -e "SELECT VERSION();" 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Uyari "MariaDB sürümü okunamadı." "DB şifresini ve db servisini kontrol edin."
} else {
  $version = ($versionRaw | Select-Object -Last 1).Trim()
  if ($version) {
    $parts = $version.Split(".")
    $major = [int]$parts[0]
    $minor = if ($parts.Length -gt 1) { [int]$parts[1] } else { 0 }
    if ($major -gt 10 -or ($major -eq 10 -and $minor -ge 11)) {
      Write-Uyari "MariaDB sürümü yüksek: $version" "10.6.x önerilir; aksi halde Frappe uyarı verebilir."
    } else {
      Write-Ok "MariaDB sürümü uygun: $version"
    }
  } else {
    Write-Uyari "MariaDB sürümü boş döndü."
  }
}

try {
  $resp = Invoke-WebRequest -Uri $SiteUrl -UseBasicParsing -TimeoutSec 5
  if ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 400) {
    Write-Ok "Site erişimi OK: $SiteUrl"
  } else {
    Write-Uyari "Site erişimi beklenmeyen durum: HTTP $($resp.StatusCode)"
  }
} catch {
  Write-Uyari "Site erişimi başarısız: $SiteUrl"
}

$qzPort = 8182
$qzConn = Test-NetConnection -ComputerName "localhost" -Port $qzPort -WarningAction SilentlyContinue
if ($qzConn.TcpTestSucceeded) {
  Write-Ok "QZ Tray bağlantısı açık (port $qzPort)."
} else {
  if ($QzZorunlu -eq 1) {
    Write-Uyari "QZ Tray bağlantısı kapalı (port $qzPort)."
  } else {
    Write-Bilgi "QZ Tray bağlantısı kapalı (port $qzPort)."
  }
}

$posSettings = $null
try {
  $raw = docker compose @composeArgs exec -T backend bench --site $SiteAdi execute ck_kuruyemis_pos.utils.get_pos_printing_settings
  if ($LASTEXITCODE -eq 0) {
    $jsonLine = $raw | Select-Object -Last 1
    if ($jsonLine) {
      $posSettings = $jsonLine | ConvertFrom-Json
    }
  }
} catch {
  $posSettings = $null
}

$qzVendor = Join-Path $repoRoot "frappe_apps\ck_kuruyemis_pos\ck_kuruyemis_pos\public\js\qz\vendor\qz-tray.js"
if (Test-Path $qzVendor) {
  Write-Ok "qz-tray.js mevcut."
} else {
  Write-Uyari "qz-tray.js bulunamadı. scripts/get-qz-tray.ps1 çalıştırın."
}

$qzWrapper = Join-Path $repoRoot "frappe_apps\ck_kuruyemis_pos\ck_kuruyemis_pos\public\js\qz\qz-wrapper.js"
if (Test-Path $qzWrapper) {
  $wrapperText = Get-Content -Raw -Path $qzWrapper
  if ($wrapperText -match "Promise\\.resolve\\(null\\)") {
    if ($posSettings -and $posSettings.qz_security_mode -eq "PROD") {
      Write-Hata "QZ güvenlik modu PROD seçili ancak imza/sertifika tanımlı değil." "POS Yazdırma Ayarları'ndan DEV/PROD modunu kontrol edin ve üretimde imzalı istek kullanın."
      $hasError = $true
    } else {
      Write-Uyari "QZ imzalama DEV modunda. Üretimde sertifika/imza zorunludur."
    }
  } else {
    Write-Ok "QZ imzalama kontrolü: özel sertifika bekleniyor olabilir."
  }
} else {
  Write-Uyari "QZ wrapper bulunamadı. Yazdırma entegrasyonunu kontrol edin."
}

try {
  $printers = Get-Printer -ErrorAction Stop
  if ($printers.Count -gt 0) {
    Write-Ok "Windows yazıcı listesi alınabildi ($($printers.Count) adet)."
  } else {
    Write-Uyari "Windows yazıcı listesi boş."
  }
} catch {
  Write-Uyari "Windows yazıcı listesi alınamadı."
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

function Check-PrinterMapping {
  param(
    [string]$Label,
    [string]$SelectedName,
    [string]$AliasText,
    [string[]]$Printers
  )
  if (-not $SelectedName) {
    Write-Uyari "$Label seçilmemiş."
    return
  }
  if (-not $Printers -or $Printers.Count -eq 0) {
    Write-Uyari "$Label doğrulanamadı (yazıcı listesi boş)."
    return
  }

  $candidates = @($SelectedName) + (Parse-Aliases $AliasText)
  $best = Find-BestPrinter $Printers $candidates
  if ($best) {
    if ((Normalize-PrinterName $best) -eq (Normalize-PrinterName $SelectedName)) {
      Write-Ok "$Label eşleşti: $best"
    } else {
      Write-Ok "$Label alias ile eşleşti: $best"
    }
  } else {
    Write-Hata "$Label QZ listesinde bulunamadı." "Yazıcı adını kontrol edin, QZ Tray izinlerini doğrulayın ve Windows yazıcıyı yeniden ekleyin."
    $script:hasError = $true
  }
}

if ($qzConn.TcpTestSucceeded -and $printers -and $posSettings) {
  $printerNames = $printers | Select-Object -ExpandProperty Name
  Check-PrinterMapping "Fiş yazıcısı" $posSettings.receipt_printer_name $posSettings.receipt_printer_aliases $printerNames
  Check-PrinterMapping "Etiket yazıcısı" $posSettings.label_printer_name $posSettings.label_printer_aliases $printerNames
}

foreach ($svc in @(@("fiscal-adapter", 8090), @("hardware-bridge", 8091))) {
  $name = $svc[0]
  $port = $svc[1]
  $id = docker compose @composeArgs ps -q $name
  if ($id) {
    try {
      $health = Invoke-WebRequest -Uri "http://localhost:$port/health" -UseBasicParsing -TimeoutSec 5
      Write-Ok "$name /health erişimi OK."
    } catch {
      Write-Uyari "$name /health erişimi başarısız."
    }
  }
}

function Test-Utf8File {
  param([string]$Path)
  try {
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
    $null = $utf8.GetString($bytes)
    return $true
  } catch {
    return $false
  }
}

$encodingTargets = @(
  (Join-Path $repoRoot "README.md"),
  (Join-Path $repoRoot "THIRD_PARTY_NOTICES.md"),
  (Join-Path $repoRoot "LISANS_VE_DAGITIM.md")
)
$encodingTargets += Get-ChildItem (Join-Path $repoRoot "docs") -Recurse -Filter *.md | ForEach-Object { $_.FullName }
$encodingTargets += Get-ChildItem (Join-Path $repoRoot "scripts") -Recurse -Filter *.ps1 | ForEach-Object { $_.FullName }
$encodingTargets += Get-ChildItem (Join-Path $repoRoot "frappe_apps\ck_kuruyemis_pos\ck_kuruyemis_pos\translations") -Filter *.csv | ForEach-Object { $_.FullName }

$invalidUtf8 = @()
$mojibake = @()
$mojibakePattern = "Ã¶|Ã¼|Ã§|ÃŸ|Ã–|Ãœ|Ã‡|ÅŸ|Åž|Ä±|ÄŸ"
$mojibakeSkip = @(
  (Join-Path $repoRoot "scripts\windows\05-doctor.ps1")
)

foreach ($path in $encodingTargets) {
  if (-not (Test-Path $path)) { continue }
  if (-not (Test-Utf8File $path)) {
    $invalidUtf8 += $path
    continue
  }
  $text = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
  if ($mojibakeSkip -contains $path) {
    continue
  }
  if ($text -match $mojibakePattern) {
    $mojibake += $path
  }
}

if ($invalidUtf8.Count -gt 0) {
  Write-Uyari "UTF-8 kodlama sorunu tespit edildi: $($invalidUtf8.Count) dosya." "Dosyaları UTF-8 olarak yeniden kaydedin."
}
if ($mojibake.Count -gt 0) {
  Write-Uyari "Bozuk Türkçe karakter şüphesi: $($mojibake.Count) dosya." "Dosyaları UTF-8 olarak yeniden kaydedin."
}

if ($hasError) {
  Write-Hata "Doktor kontrolü hatalarla tamamlandı." "Hata mesajlarına göre düzeltme yapın."
  exit 1
}

Exit-If-StrictWarnings "Doktor kontrolü"

Write-Ok "Doktor kontrolü tamamlandı."



