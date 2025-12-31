param(
  [string]$SiteAdi = "kuruyemis.local",
  [string]$SiteUrl,
  [string]$FisYazici,
  [string]$EtiketYazici,
  [switch]$GercekBaski
)

. "$PSScriptRoot\_ortak.ps1"

$composeArgs = Get-ComposeArgs
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
  Write-Uyari "DRY_RUN aktif. Yazdırma adımı atlandı. (Yazdırmak için DRY_RUN=0 veya -GercekBaski kullanın)"
  Write-Ok "Duman testi tamamlandı (deneme modu)."
  exit 0
}

$qzConn = Test-NetConnection -ComputerName "localhost" -Port 8182 -WarningAction SilentlyContinue
if (-not $qzConn.TcpTestSucceeded) {
  Write-Uyari "QZ Tray bağlantısı kapalı. Yazdırma adımı atlandı."
  Write-Ok "Duman testi tamamlandı (yazdırma atlandı)."
  exit 0
}

function Get-PrinterSetting {
  param([string]$FieldName)
  try {
    $output = docker compose @composeArgs exec backend bench --site $SiteAdi execute frappe.db.get_single_value --kwargs "{'doctype':'POS Printing Settings','fieldname':'$FieldName'}"
    if ($LASTEXITCODE -ne 0) { return "" }
    $line = $output | Select-Object -Last 1
    $line = $line.Trim()
    if ($line -and $line -ne "None") { return $line }
  } catch {
    return ""
  }
  return ""
}

if (-not $FisYazici) { $FisYazici = Get-PrinterSetting "receipt_printer_name" }
if (-not $EtiketYazici) { $EtiketYazici = Get-PrinterSetting "label_printer_name" }
if (-not $FisYazici) { $FisYazici = "ZY907" }
if (-not $EtiketYazici) { $EtiketYazici = "X-Printer 490B" }

$receiptPrinterSafe = $FisYazici.Replace("'", "\\'")
$labelPrinterSafe = $EtiketYazici.Replace("'", "\\'")

$htmlPath = Join-Path $env:TEMP "ck-kuruyemis-duman-testi.html"

$html = @"
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <title>CK Kuruyemiş POS - Duman Testi</title>
</head>
<body>
  <h3>CK Kuruyemiş POS - Duman Testi</h3>
  <div id="status">Baskı hazırlanıyor...</div>
  <script src="${SiteUrl}/assets/ck_kuruyemis_pos/js/qz/vendor/qz-tray.js"></script>
  <script>
    const statusEl = document.getElementById('status');
    const receiptPrinter = '${receiptPrinterSafe}';
    const labelPrinter = '${labelPrinterSafe}';

    const receiptData = ['\\x1B@',
      'CK KURUYEMİŞ POS\\n',
      'Bilgi Fişi (Mali Değil) - Duman Testi\\n',
      '---------------------------\\n',
      'Ürün: Antep Fıstığı\\n',
      'Miktar: 0.250 kg\\n',
      'Fiyat: 375.00 TRY/kg\\n',
      'Tutar: 93.75 TRY\\n',
      '---------------------------\\n',
      'Teşekkürler!\\n\\n\\n',
      '\\x1DV1'
    ].join('');

    const labelData = [
      'SIZE 38 mm,80 mm',
      'GAP 2 mm,0',
      'DENSITY 8',
      'SPEED 4',
      'DIRECTION 1',
      'CLS',
      'TEXT 20,20,"0",0,1,1,"Antep Fıstığı"',
      'TEXT 20,50,"0",0,1,1,"0.250 kg"',
      'TEXT 20,80,"0",0,1,1,"93.75 TRY"',
      'BARCODE 20,120,"128",80,1,0,2,2,"2101234002508"',
      'PRINT 1,1'
    ].join('\\n');

    function setStatus(msg, isError) {
      statusEl.innerText = msg;
      statusEl.style.color = isError ? 'red' : 'green';
    }

    qz.security.setCertificatePromise(() => Promise.resolve(null));
    qz.security.setSignaturePromise(() => Promise.resolve(null));

    qz.websocket.connect()
      .then(() => qz.printers.find(receiptPrinter))
      .then(printer => qz.print(qz.configs.create(printer, { encoding: 'utf-8' }), [receiptData]))
      .then(() => qz.printers.find(labelPrinter))
      .then(printer => qz.print(qz.configs.create(printer, { encoding: 'utf-8' }), [labelData]))
      .then(() => setStatus('Baskı tamamlandı. Fiş ve etiket çıktısını kontrol edin.', false))
      .catch(err => setStatus('Baskı hatası: ' + err, true));
  </script>
</body>
</html>
"@

$html | Set-Content -Encoding UTF8 -Path $htmlPath
Write-Bilgi "Test baskısı başlatılıyor... ($htmlPath)"
Start-Process $htmlPath
Write-Ok "Tarayıcı açıldı. Fiş ve etiket çıktısını kontrol edin."

