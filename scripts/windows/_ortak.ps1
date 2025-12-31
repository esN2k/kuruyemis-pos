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
  return @(
    "-f", (Join-Path $frappeDockerDir "compose.yaml"),
    "-f", (Join-Path $frappeDockerDir "overrides\\compose.mariadb.yaml"),
    "-f", (Join-Path $frappeDockerDir "overrides\\compose.redis.yaml"),
    "-f", (Join-Path $infraDir "docker-compose.override.yaml")
  )
}

function Write-Bilgi {
  param([string]$Mesaj)
  Write-Host "[BİLGİ] $Mesaj"
}

function Write-Ok {
  param([string]$Mesaj)
  Write-Host "[OK] $Mesaj"
}

function Write-Uyari {
  param([string]$Mesaj)
  Write-Host "[UYARI] $Mesaj"
}

function Write-Hata {
  param([string]$Mesaj, [string]$Cozum = "")
  Write-Host "[HATA] $Mesaj"
  if ($Cozum) {
    Write-Host "[ÇÖZÜM] $Cozum"
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

