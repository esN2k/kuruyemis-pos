param(
  [string]$SiteAdi = "kuruyemis.local",
  [string]$AdminSifresi = "admin",
  [int]$Strict = 1,
  [int]$Quiet = 1,
  [int]$GercekBaski = 0
)

. "$PSScriptRoot\_ortak.ps1"

$quietMode = ($Quiet -eq 1)
$strictMode = ($Strict -eq 1)

if ($quietMode) {
  $env:CK_POS_QUIET = "1"
} else {
  Remove-Item Env:CK_POS_QUIET -ErrorAction SilentlyContinue
}
if ($strictMode) {
  $env:CK_POS_STRICT = "1"
} else {
  Remove-Item Env:CK_POS_STRICT -ErrorAction SilentlyContinue
}

if ($GercekBaski -eq 1) {
  $env:CK_POS_QZ_ZORUNLU = "1"
} else {
  $env:CK_POS_QZ_ZORUNLU = "0"
}

if ($GercekBaski -eq 1) {
  $env:DRY_RUN = "0"
} else {
  $env:DRY_RUN = "1"
}

Set-LogMode -Quiet:$quietMode -Strict:$strictMode
Reset-LogState

$repoRoot = Get-RepoRoot
$infraDir = Get-InfraDir
$composeArgs = Get-ComposeArgs

function Invoke-Step {
  param(
    [string]$Baslik,
    [string]$Komut,
    [object[]]$Argumanlar = @()
  )

  Write-Bilgi "$Baslik başlıyor..."
  $logPath = Join-Path $env:TEMP ("ck-kuruyemis-step-" + [guid]::NewGuid().ToString("N") + ".log")
  $env:CK_POS_LOG_FILE = $logPath
  & $Komut @Argumanlar
  $exitCode = $LASTEXITCODE
  Remove-Item Env:CK_POS_LOG_FILE -ErrorAction SilentlyContinue

  $hasWarning = $false
  if (Test-Path $logPath) {
    $lines = Get-Content -Path $logPath -ErrorAction SilentlyContinue
    if ($lines -match '^\[UYARI\]') {
      $hasWarning = $true
    }
    Remove-Item -Path $logPath -ErrorAction SilentlyContinue
  }

  if ($exitCode -ne 0) {
    Write-Hata "$Baslik başarısız." "Hata mesajlarını kontrol edip tekrar deneyin."
    return $false
  }

  if ($strictMode -and $hasWarning) {
    Write-Hata "$Baslik uyarılarla tamamlandı." "Strict modda uyarılar hata kabul edilir."
    return $false
  }

  Write-Ok "$Baslik başarılı."
  return $true
}

function Test-SiteExists {
  $cmd = "test -d sites/$SiteAdi"
  docker compose @composeArgs exec -T backend bash -lc $cmd
  return ($LASTEXITCODE -eq 0)
}

function Invoke-HttpRouteCheck {
  param(
    [string]$Url,
    [string]$ExpectedRoute
  )
  try {
    $resp = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10
  } catch {
    Write-Hata "HTTP erişimi başarısız: $Url" "Site ve Docker servislerini kontrol edin."
    return $false
  }

  if ($resp.StatusCode -lt 200 -or $resp.StatusCode -ge 400) {
    Write-Hata "HTTP erişimi başarısız: $Url" "HTTP $($resp.StatusCode) döndü."
    return $false
  }

  $finalUri = $resp.BaseResponse.ResponseUri.AbsoluteUri
  if ($finalUri -match [regex]::Escape("redirect-to=$ExpectedRoute")) {
    return $true
  }

  if ($finalUri -match [regex]::Escape($ExpectedRoute)) {
    return $true
  }

  Write-Uyari "Sayfa yönlendirmesi beklenenden farklı: $Url"
  return $true
}

function Invoke-UiSmoke {
  param(
    [string]$BaseUrl,
    [string]$AdminPassword
  )

  $scriptPath = Join-Path $repoRoot "scripts\tools\ui-smoke.mjs"
  if (-not (Test-Path $scriptPath)) {
    Write-Hata "UI duman testi scripti bulunamadı." "scripts/tools/ui-smoke.mjs dosyasını kontrol edin."
    return $false
  }

  if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Uyari "Node.js bulunamadı. HTTP kontrolüne geçiliyor."
    $ok1 = Invoke-HttpRouteCheck -Url $BaseUrl -ExpectedRoute "/app"
    $ok2 = Invoke-HttpRouteCheck -Url "$BaseUrl/app/pos_printer_setup" -ExpectedRoute "/app/pos_printer_setup"
    $ok3 = Invoke-HttpRouteCheck -Url "$BaseUrl/app/posawesome/point-of-sale" -ExpectedRoute "/app/posawesome/point-of-sale"
    return ($ok1 -and $ok2 -and $ok3)
  }

  $packageLock = Join-Path $repoRoot "package-lock.json"
  if (-not (Test-Path $packageLock)) {
    Write-Uyari "Playwright kilit dosyası bulunamadı. HTTP kontrolüne geçiliyor."
    $ok1 = Invoke-HttpRouteCheck -Url $BaseUrl -ExpectedRoute "/app"
    $ok2 = Invoke-HttpRouteCheck -Url "$BaseUrl/app/pos_printer_setup" -ExpectedRoute "/app/pos_printer_setup"
    $ok3 = Invoke-HttpRouteCheck -Url "$BaseUrl/app/posawesome/point-of-sale" -ExpectedRoute "/app/posawesome/point-of-sale"
    return ($ok1 -and $ok2 -and $ok3)
  }

  $playwrightDir = Join-Path $repoRoot "node_modules\playwright"
  Push-Location $repoRoot
  try {
    if (-not (Test-Path $playwrightDir)) {
      Write-Bilgi "Playwright bağımlılıkları kuruluyor..."
      npm ci --silent
      if ($LASTEXITCODE -ne 0) {
        Write-Hata "Playwright kurulumu başarısız." "npm ci çıktısını kontrol edin."
        return $false
      }
    }

    Write-Bilgi "Playwright tarayıcıları kontrol ediliyor (Chromium)..."
    npx playwright install chromium
    if ($LASTEXITCODE -ne 0) {
      Write-Hata "Playwright tarayıcı kurulumu başarısız." "npx playwright install chromium çıktısını kontrol edin."
      return $false
    }

    Write-Bilgi "UI duman testi (Playwright) çalıştırılıyor..."
    node $scriptPath --base-url $BaseUrl --admin-pass $AdminPassword
    if ($LASTEXITCODE -ne 0) {
      Write-Hata "UI duman testi başarısız." "Playwright loglarını kontrol edin."
      return $false
    }
  } finally {
    Pop-Location
  }

  Write-Ok "UI duman testi başarılı."
  return $true
}

Write-Bilgi "Teslim öncesi doğrulama başlıyor..."

if (-not (Invoke-Step "Önkoşul kontrolü" "$PSScriptRoot\00-onkosul-kontrol.ps1")) { exit 1 }
if (-not (Invoke-Step "Bootstrap (frappe_docker + qz-tray.js)" "$PSScriptRoot\01-bootstrap.ps1")) { exit 1 }
if (-not (Invoke-Step "Docker servislerini başlat" "$PSScriptRoot\02-baslat.ps1")) { exit 1 }

if (-not (Test-SiteExists)) {
  $siteArgs = @("-SiteAdi", $SiteAdi, "-YoneticiSifresi", $AdminSifresi)
  if (-not (Invoke-Step "Site oluştur" "$PSScriptRoot\03-site-olustur.ps1" $siteArgs)) { exit 1 }
} else {
  Write-Bilgi "Site zaten mevcut: $SiteAdi (oluşturma atlandı)"
}

$installArgs = @("-SiteAdi", $SiteAdi)
if (-not (Invoke-Step "Uygulamaları kur" "$PSScriptRoot\04-uygulamalari-kur.ps1" $installArgs)) { exit 1 }

$qzZorunlu = if ($GercekBaski -eq 1) { 1 } else { 0 }
$doctorArgs = @("-SiteAdi", $SiteAdi, "-Strict", $Strict, "-Quiet", $Quiet, "-QzZorunlu", $qzZorunlu)
if (-not (Invoke-Step "Doktor kontrolü" "$PSScriptRoot\05-doctor.ps1" $doctorArgs)) { exit 1 }

$smokeArgs = @("-SiteAdi", $SiteAdi, "-Strict", $Strict, "-Quiet", $Quiet)
if ($GercekBaski -eq 1) {
  $smokeArgs += "-GercekBaski"
}
if (-not (Invoke-Step "Duman testi" "$PSScriptRoot\09-smoke-test.ps1" $smokeArgs)) { exit 1 }

$uiOk = Invoke-UiSmoke -BaseUrl "http://${SiteAdi}:8080" -AdminPassword $AdminSifresi
if (-not $uiOk) {
  Write-Hata "UI duman testi başarısız." "UI hatalarını giderip tekrar deneyin."
  exit 1
}

Exit-If-StrictWarnings "Teslim öncesi doğrulama"

$versionsPath = Join-Path $infraDir "versions.env"
$pinSummary = ""
if (Test-Path $versionsPath) {
  $lines = Get-Content $versionsPath | Where-Object { $_ -and -not $_.StartsWith('#') }
  $map = @{}
  foreach ($line in $lines) {
    $parts = $line.Split('=', 2)
    if ($parts.Length -eq 2) { $map[$parts[0]] = $parts[1] }
  }
  $keys = @("FRAPPE_DOCKER_REF", "ERPNEXT_VERSION", "POS_AWESOME_REF", "QZ_TRAY_REF")
  $items = @()
  foreach ($key in $keys) {
    if ($map.ContainsKey($key)) {
      $items += "$key=$($map[$key])"
    }
  }
  $pinSummary = $items -join ", "
}

if (-not $pinSummary) {
  $pinSummary = "(versions.env bulunamadı)"
}

Write-Host "[TESLİME HAZIR] Tüm kontroller geçti. Versiyon pinleri: $pinSummary"
