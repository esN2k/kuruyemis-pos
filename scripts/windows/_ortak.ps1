$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ErrorActionPreference = "Stop"

function Initialize-KonsolUtf8 {
  $utf8 = New-Object System.Text.UTF8Encoding($false)
  $global:OutputEncoding = $utf8
  [Console]::OutputEncoding = $utf8
  [Console]::InputEncoding = $utf8
  if ($Host.Name -eq "ConsoleHost") {
    try {
      & cmd /c "chcp 65001 >nul" | Out-Null
    } catch {
      # Kod sayfası değiştirilemezse sessizce devam et.
    }
  }
}

Initialize-KonsolUtf8

$script:QuietMode = $false
$script:StrictMode = $false
$script:HadWarning = $false
$script:LogFilePath = $env:CK_POS_LOG_FILE

if ($env:CK_POS_QUIET -and $env:CK_POS_QUIET -ne "0") {
  $script:QuietMode = $true
}
if ($env:CK_POS_STRICT -and $env:CK_POS_STRICT -ne "0") {
  $script:StrictMode = $true
}

function Set-LogMode {
  param([bool]$Quiet = $false, [bool]$Strict = $false)
  $script:QuietMode = $Quiet
  $script:StrictMode = $Strict
}

function Set-LogFilePath {
  param([string]$Path)
  $script:LogFilePath = $Path
}

function Reset-LogState {
  $script:HadWarning = $false
}

function Get-HasWarning {
  return $script:HadWarning
}

function Write-LogLine {
  param([string]$Line)
  if (-not $script:LogFilePath) {
    return
  }
  try {
    Add-Content -Path $script:LogFilePath -Value $Line -Encoding UTF8
  } catch {
    # Log yazımı hata verirse ana akışı bozmayalım.
  }
}

$script:OrtakRoot = $PSScriptRoot
if (-not $script:OrtakRoot -and $MyInvocation.PSCommandPath) {
  $script:OrtakRoot = Split-Path -Parent $MyInvocation.PSCommandPath
}
if (-not $script:OrtakRoot -and $MyInvocation.MyCommand.Path) {
  $script:OrtakRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}

function Get-RepoRoot {
  if (-not $script:OrtakRoot) {
    throw "Ortak script yolu bulunamadı. scripts/windows/_ortak.ps1 konumunu kontrol edin."
  }
  return (Resolve-Path (Join-Path $script:OrtakRoot "..\.."))
}

function Get-InfraDir {
  return (Join-Path (Get-RepoRoot) "infra")
}

function Get-FrappeDockerDir {
  return (Join-Path (Get-InfraDir) "frappe_docker")
}

function Get-DbPassword {
  $envPath = Join-Path (Get-FrappeDockerDir) ".env"
  if (Test-Path $envPath) {
    $line = Get-Content $envPath | Where-Object { $_ -match '^DB_PASSWORD=' } | Select-Object -First 1
    if ($line) {
      $value = $line.Split('=', 2)[1]
      if ($value) {
        return $value
      }
    }
  }
  return "123"
}

function Get-ComposeArgs {
  $infraDir = Get-InfraDir
  $frappeDockerDir = Get-FrappeDockerDir
  
  # Frappe Docker compose dosyalarını kontrol et
  $baseCompose = Join-Path $frappeDockerDir "compose.yaml"
  if (-not (Test-Path $baseCompose)) {
    Write-Hata "Compose dosyası bulunamadı: $baseCompose" "Önce scripts\windows\01-bootstrap.ps1 çalıştırın."
    exit 1
  }
  
  $mariadbCompose = Join-Path $frappeDockerDir "overrides\compose.mariadb.yaml"
  $redisCompose = Join-Path $frappeDockerDir "overrides\compose.redis.yaml"
  $overrideCompose = Join-Path $infraDir "docker-compose.override.yaml"
  
  # Zorunlu dosyaları kontrol et
  if (-not (Test-Path $mariadbCompose)) {
    Write-Hata "MariaDB override bulunamadı: $mariadbCompose" "frappe_docker repo'su doğru klonlanmamış olabilir."
    exit 1
  }
  if (-not (Test-Path $redisCompose)) {
    Write-Hata "Redis override bulunamadı: $redisCompose" "frappe_docker repo'su doğru klonlanmamış olabilir."
    exit 1
  }
  
  return @(
    "-f", $baseCompose,
    "-f", $mariadbCompose,
    "-f", $redisCompose,
    "-f", $overrideCompose
  )
}

function Write-Bilgi {
  param([string]$Mesaj)
  if ($script:QuietMode) {
    return
  }
  $line = "[BİLGİ] $Mesaj"
  Write-Host $line
  Write-LogLine $line
}

function Write-Ok {
  param([string]$Mesaj)
  $line = "[OK] $Mesaj"
  Write-Host $line
  Write-LogLine $line
}

function Write-Uyari {
  param([string]$Mesaj)
  $script:HadWarning = $true
  $line = "[UYARI] $Mesaj"
  Write-Host $line
  Write-LogLine $line
}

function Write-Hata {
  param([string]$Mesaj, [string]$Cozum = "")
  $line = "[HATA] $Mesaj"
  Write-Host $line
  Write-LogLine $line
  if ($Cozum) {
    $solutionLine = "[ÇÖZÜM] $Cozum"
    Write-Host $solutionLine
    Write-LogLine $solutionLine
  }
}

function Exit-If-StrictWarnings {
  param([string]$Baslik = "İşlem")
  if ($script:StrictMode -and $script:HadWarning) {
    Write-Hata "$Baslik uyarılarla tamamlandı." "Strict modda uyarılar hata kabul edilir."
    exit 2
  }
}

function Test-Komut {
  param([string]$Komut, [string]$HataMesaji)
  if (-not (Get-Command $Komut -ErrorAction SilentlyContinue)) {
    Write-Hata $HataMesaji "$Komut komutunu kurup tekrar deneyin."
    exit 1
  }
}

function Ensure-Path {
  param([string]$Path, [string]$HataMesaji)
  if (-not (Test-Path $Path)) {
    Write-Hata $HataMesaji "Beklenen yol: $Path"
    exit 1
  }
}

function Get-OpsiyonelModuller {
  param([string]$SiteAdi)

  if (-not $SiteAdi) {
    return @()
  }

  $composeArgs = Get-ComposeArgs
  $py = @"
import json
path = "sites/$SiteAdi/site_config.json"
try:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    val = data.get("ck_kuruyemis_pos_optional_modules", "")
    if isinstance(val, list):
        val = ",".join(val)
    print(val or "")
except Exception:
    print("")
"@
  $cmd = "python - <<'PY'\n$py\nPY"
  $raw = docker compose @composeArgs exec -T backend bash -lc $cmd 2>$null
  if ($LASTEXITCODE -ne 0) {
    return @()
  }

  $line = ($raw | Select-Object -Last 1).Trim()
  if (-not $line) {
    return @()
  }

  return $line -split "[,; ]+" | ForEach-Object { $_.Trim().ToLowerInvariant() } | Where-Object { $_ }
}

