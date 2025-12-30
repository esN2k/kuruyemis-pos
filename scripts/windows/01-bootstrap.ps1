param(
  [switch]$QzYenile
)

. "$PSScriptRoot\_ortak.ps1"

$repoRoot = Get-RepoRoot
$infraDir = Get-InfraDir
$versionsEnv = Join-Path $infraDir "versions.env"
$frappeDockerDir = Get-FrappeDockerDir

Test-Komut "git" "Git bulunamadı."
Ensure-Path $versionsEnv "versions.env bulunamadı."

$versions = @{}
Get-Content $versionsEnv | Where-Object { $_ -and -not $_.StartsWith('#') } | ForEach-Object {
  $parts = $_.Split('=', 2)
  if ($parts.Length -eq 2) { $versions[$parts[0]] = $parts[1] }
}

$frappeDockerRef = $versions["FRAPPE_DOCKER_REF"]
if (-not $frappeDockerRef) {
  Write-Hata "FRAPPE_DOCKER_REF bulunamadı." "infra/versions.env dosyasını kontrol edin."
  exit 1
}

if (-not (Test-Path $frappeDockerDir)) {
  Write-Bilgi "frappe_docker indiriliyor..."
  git clone https://github.com/frappe/frappe_docker.git $frappeDockerDir | Out-Null
}

Write-Bilgi "frappe_docker güncelleniyor..."
git -C $frappeDockerDir fetch --all | Out-Null

Write-Bilgi "frappe_docker pinleniyor: $frappeDockerRef"
git -C $frappeDockerDir checkout $frappeDockerRef | Out-Null

$exampleEnv = Join-Path $frappeDockerDir "example.env"
$envPath = Join-Path $frappeDockerDir ".env"

Ensure-Path $exampleEnv "example.env bulunamadı."
Copy-Item $exampleEnv $envPath -Force

$overrideKeys = @("FRAPPE_BRANCH", "ERPNEXT_BRANCH", "ERPNEXT_VERSION")
$lines = Get-Content $envPath
$updated = @()
foreach ($line in $lines) {
  if ($line -match '^[A-Z0-9_]+=') {
    $parts = $line.Split('=', 2)
    $key = $parts[0]
    if ($overrideKeys -contains $key -and $versions.ContainsKey($key)) {
      $updated += "$key=$($versions[$key])"
    } else {
      $updated += $line
    }
  } else {
    $updated += $line
  }
}

foreach ($key in $overrideKeys) {
  if (-not ($updated | Where-Object { $_ -match "^$key=" })) {
    if ($versions.ContainsKey($key)) {
      $updated += "$key=$($versions[$key])"
    }
  }
}

Set-Content -Encoding UTF8 -Path $envPath -Value $updated
Write-Ok "frappe_docker hazır: $frappeDockerDir"

$qzVendor = Join-Path $repoRoot "frappe_apps\ck_kuruyemis_pos\ck_kuruyemis_pos\public\js\qz\vendor\qz-tray.js"
$qzScript = Join-Path $repoRoot "scripts\get-qz-tray.ps1"

if ($QzYenile -or -not (Test-Path $qzVendor)) {
  if (Test-Path $qzScript) {
    Write-Bilgi "qz-tray.js indiriliyor..."
    & $qzScript
  } else {
    Write-Uyari "QZ indirme scripti bulunamadı: $qzScript"
  }
} else {
  Write-Ok "qz-tray.js zaten mevcut."
}
