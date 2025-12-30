. "$PSScriptRoot\_ortak.ps1"

Write-Bilgi "Önkoşul kontrolü başlıyor..."

Test-Komut "docker" "Docker bulunamadı."
Test-Komut "git" "Git bulunamadı."

Write-Ok "Git erişilebilir."

try {
  docker info | Out-Null
  Write-Ok "Docker Desktop çalışıyor."
} catch {
  Write-Hata "Docker Desktop çalışmıyor." "Docker Desktop'ı başlatın ve tekrar deneyin."
  exit 1
}

try {
  docker compose version | Out-Null
  Write-Ok "Docker Compose kullanılabilir."
} catch {
  Write-Hata "Docker Compose bulunamadı." "Docker Desktop güncelleyin veya Docker Compose eklentisini kurun."
  exit 1
}

if (Get-Command wsl -ErrorAction SilentlyContinue) {
  try {
    wsl -l -v | Out-Null
    Write-Ok "WSL2 erişilebilir."
  } catch {
    Write-Uyari "WSL2 sorgulanamadı. Docker ayarlarınızı kontrol edin."
  }
} else {
  Write-Uyari "WSL komutu bulunamadı. WSL2 gerekli olabilir."
}

$drive = Get-PSDrive -Name C -ErrorAction SilentlyContinue
if ($drive) {
  $freeGb = [math]::Round($drive.Free / 1GB, 1)
  if ($freeGb -lt 10) {
    Write-Hata "Disk alanı düşük: ${freeGb} GB" "En az 10 GB boş alan bırakın."
    exit 1
  } else {
    Write-Ok "Disk alanı yeterli: ${freeGb} GB"
  }
}

$criticalPorts = @(8080, 9000, 3306, 6379)
$optionalPorts = @(8090, 8091)
$qzPort = 8182

foreach ($port in $criticalPorts) {
  $used = Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue
  if ($used) {
    Write-Hata "Port $port kullanımda." "Bu portu kullanan uygulamayı kapatın veya portu değiştirin."
    exit 1
  } else {
    Write-Ok "Port $port boş."
  }
}

foreach ($port in $optionalPorts) {
  $used = Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue
  if ($used) {
    Write-Uyari "Port $port kullanımda. Opsiyonel servisler çakışabilir."
  } else {
    Write-Ok "Port $port boş (opsiyonel servisler için uygun)."
  }
}

$qzUsed = Get-NetTCPConnection -State Listen -LocalPort $qzPort -ErrorAction SilentlyContinue
if ($qzUsed) {
  Write-Ok "QZ Tray portu ($qzPort) kullanımda (QZ Tray çalışıyor olabilir)."
} else {
  Write-Uyari "QZ Tray portu ($qzPort) kapalı. Yazdırma için QZ Tray'i açın."
}

Write-Ok "Önkoşullar tamam."
