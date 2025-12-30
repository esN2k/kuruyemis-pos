param(
  [string]$SiteAdi = "kuruyemis.local",
  [string]$SiteUrl
)

. "$PSScriptRoot\_ortak.ps1"

$hasError = $false
$repoRoot = Get-RepoRoot
$composeArgs = Get-ComposeArgs

if (-not $SiteUrl) {
  $SiteUrl = "http://$SiteAdi:8080"
}

Write-Bilgi "Doktor kontrolü başlıyor..."

try {
  docker info | Out-Null
  Write-Ok "Docker Desktop çalışıyor."
} catch {
  Write-Hata "Docker Desktop çalışmıyor." "Docker Desktop'ı başlatın."
  exit 1
}

try {
  docker compose @composeArgs ps | Out-Null
} catch {
  Write-Hata "Docker compose dosyaları bulunamadı." "Önce 01-bootstrap.ps1 çalıştırın."
  exit 1
}

try {
  docker compose @composeArgs exec backend bash -lc "test -d sites/$SiteAdi"
  Write-Ok "Site bulundu: $SiteAdi"
} catch {
  Write-Hata "Site bulunamadı: $SiteAdi" "03-site-olustur.ps1 çalıştırın."
  $hasError = $true
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
      Write-Uyari "Opsiyonel servis kapalı: $Name"
    }
    return
  }
  $status = docker inspect -f '{{.State.Status}}' $id
  if ($status -ne "running") {
    if ($Required) {
      Write-Hata "Servis durumu sorunlu: $Name ($status)" "Docker loglarını kontrol edin."
      $script:hasError = $true
    } else {
      Write-Uyari "Opsiyonel servis durumu: $Name ($status)"
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
Check-Service "fiscal-adapter" $false
Check-Service "hardware-bridge" $false

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
  Write-Uyari "QZ Tray bağlantısı kapalı (port $qzPort)."
}

$qzVendor = Join-Path $repoRoot "frappe_apps\ck_kuruyemis_pos\ck_kuruyemis_pos\public\js\qz\vendor\qz-tray.js"
if (Test-Path $qzVendor) {
  Write-Ok "qz-tray.js mevcut."
} else {
  Write-Uyari "qz-tray.js bulunamadı. scripts/get-qz-tray.ps1 çalıştırın."
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

if ($hasError) {
  Write-Hata "Doktor kontrolü hatalarla tamamlandı." "Hata mesajlarına göre düzeltme yapın."
  exit 1
}

Write-Ok "Doktor kontrolü tamamlandı."
