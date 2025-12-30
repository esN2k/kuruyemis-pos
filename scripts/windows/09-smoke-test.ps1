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
  $SiteUrl = "http://$SiteAdi:8080"
}

Write-Bilgi "Duman testi başlıyor..."

Write-Bilgi "Pytest çalıştırılıyor..."
try {
  docker compose @composeArgs exec backend bash -lc "pip -q install pytest && PYTHONPATH=/home/frappe/frappe-bench/apps/ck_kuruyemis_pos pytest /home/frappe/frappe-bench/apps/ck_kuruyemis_pos/ck_kuruyemis_pos/tests"
  Write-Ok "Pytest başarılı."
} catch {
  Write-Hata "Pytest başarısız." "Test çıktısını kontrol edin."
  exit 1
}

Write-Bilgi "Barkod presetleri kontrol ediliyor..."
try {
  $result = docker compose @composeArgs exec backend bench --site $SiteAdi execute ck_kuruyemis_pos.utils.check_weighed_barcode_presets
  $lastLine = $result | Select-Object -Last 1
  if ($lastLine -match "missing" -and $lastLine -match "\[\]") {
    Write-Ok "Tartılı barkod presetleri mevcut."
  } else {
    Write-Hata "Tartılı barkod presetleri eksik." "04-uygulamalari-kur.ps1 çalıştırın."
    exit 1
  }
} catch {
  Write-Hata "Preset kontrolü başarısız." "Site adını ve servisleri kontrol edin."
  exit 1
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
      'Mali olmayan fiş (duman testi)\\n',
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
      .then(() => setStatus('Baskı tamamlandı. Fiş ve etiket çıktılarını kontrol edin.', false))
      .catch(err => setStatus('Baskı hatası: ' + err, true));
  </script>
</body>
</html>
"@

$html | Set-Content -Encoding UTF8 -Path $htmlPath
Write-Bilgi "Test baskısı başlatılıyor... ($htmlPath)"
Start-Process $htmlPath
Write-Ok "Tarayıcı açıldı. Fiş ve etiket çıktısını kontrol edin."

