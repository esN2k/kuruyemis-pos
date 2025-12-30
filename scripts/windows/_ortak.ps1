$ErrorActionPreference = "Stop"

function Get-RepoRoot {
  $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
  return (Resolve-Path (Join-Path $scriptDir "..\.."))
}

function Get-InfraDir {
  return (Join-Path (Get-RepoRoot) "infra")
}

function Get-FrappeDockerDir {
  return (Join-Path (Get-InfraDir) "frappe_docker")
}

function Get-ComposeArgs {
  $infraDir = Get-InfraDir
  $frappeDockerDir = Get-FrappeDockerDir
  return @(
    "-f", (Join-Path $frappeDockerDir "compose.yaml"),
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
