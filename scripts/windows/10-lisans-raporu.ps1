param(
  [switch]$BelirsizLisanslaraIzinVer
)

. "$PSScriptRoot\_ortak.ps1"

$repoRoot = Get-RepoRoot
$reportDir = Join-Path $repoRoot "docs\lisans-raporlari"
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null

function Resolve-Python {
  $python = Get-Command python -ErrorAction SilentlyContinue
  if ($python) { return $python.Source }
  $py = Get-Command py -ErrorAction SilentlyContinue
  if ($py) { return "$($py.Source) -3" }
  return $null
}

function New-TempDir {
  $tmp = Join-Path $env:TEMP ("ck-lisans-" + [guid]::NewGuid().ToString("N"))
  New-Item -ItemType Directory -Force -Path $tmp | Out-Null
  return $tmp
}

function Test-UnknownLicense {
  param([string]$JsonPath)
  if (-not (Test-Path $JsonPath)) { return @() }
  try {
    $raw = Get-Content -Raw -Path $JsonPath | ConvertFrom-Json
  } catch {
    return @()
  }
  $items = @()
  if ($raw -is [System.Collections.IDictionary]) {
    foreach ($key in $raw.Keys) {
      $items += $raw[$key]
    }
  } elseif ($raw -is [System.Collections.IEnumerable]) {
    $items = @($raw)
  } else {
    $items = @($raw)
  }

  $unknown = @()
  foreach ($item in $items) {
    $license = ($item.License -as [string]).Trim()
    if (-not $license -or $license -match "UNKNOWN|UNLICENSED|NOASSERTION|SEE LICENSE") {
      $unknown += $item
    }
  }
  return $unknown
}

function Build-PythonLicenseReport {
  param(
    [string]$Name,
    [string]$RequirementsPath
  )

  if (-not (Test-Path $RequirementsPath)) {
    Write-Uyari "$Name için requirements.txt bulunamadı: $RequirementsPath"
    return
  }

  $pythonCmd = Resolve-Python
  if (-not $pythonCmd) {
    Write-Hata "Python bulunamadı." "Python 3 kurun ve tekrar deneyin."
    exit 1
  }

  $tempDir = New-TempDir
  try {
    Write-Bilgi "$Name için geçici ortam hazırlanıyor..."
    $venvDir = Join-Path $tempDir "venv"
    if ($pythonCmd -like "*py* -3") {
      & $pythonCmd -m venv $venvDir
    } else {
      & $pythonCmd -m venv $venvDir
    }
    $venvPython = Join-Path $venvDir "Scripts\python.exe"

    & $venvPython -m pip install --quiet --upgrade pip
    & $venvPython -m pip install --quiet -r $RequirementsPath
    & $venvPython -m pip install --quiet pip-licenses

    $csvPath = Join-Path $reportDir "python-$Name.csv"
    $jsonPath = Join-Path $reportDir "python-$Name.json"

    & $venvPython -m piplicenses --format=csv --output-file $csvPath
    & $venvPython -m piplicenses --format=json --output-file $jsonPath

    $unknown = Test-UnknownLicense -JsonPath $jsonPath
    if ($unknown.Count -gt 0 -and -not $BelirsizLisanslaraIzinVer) {
      Write-Hata "Belirsiz lisans bulundu ($Name)." "Belirsiz lisansları temizleyin veya -BelirsizLisanslaraIzinVer ile devam edin."
      exit 1
    }
  } finally {
    if (Test-Path $tempDir) {
      Remove-Item -Recurse -Force -Path $tempDir
    }
  }
}

Write-Bilgi "Lisans raporları hazırlanıyor..."

Build-PythonLicenseReport -Name "fiscal-adapter" -RequirementsPath (Join-Path $repoRoot "services\fiscal-adapter\requirements.txt")
Build-PythonLicenseReport -Name "hardware-bridge" -RequirementsPath (Join-Path $repoRoot "services\hardware-bridge\requirements.txt")

$packageJsonFiles = Get-ChildItem -Path $repoRoot -Recurse -Filter "package.json" -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch "node_modules" }

if (-not $packageJsonFiles) {
  $nodeNote = Join-Path $reportDir "node-yok.txt"
  "Bu repoda package.json bulunamadı; Node lisans raporu üretilmedi." | Set-Content -Encoding UTF8 -Path $nodeNote
} else {
  foreach ($pkg in $packageJsonFiles) {
    $projectDir = Split-Path -Parent $pkg.FullName
    $projectName = Split-Path -Leaf $projectDir
    Write-Bilgi "Node lisans raporu hazırlanıyor: $projectName"

    if (Test-Path (Join-Path $projectDir "package-lock.json")) {
      Test-Komut "npm" "Node.js (npm) bulunamadı."
      npm ci --prefix $projectDir | Out-Null
    } elseif (Test-Path (Join-Path $projectDir "yarn.lock")) {
      Test-Komut "yarn" "Yarn bulunamadı."
      yarn --cwd $projectDir install --frozen-lockfile | Out-Null
    } elseif (Test-Path (Join-Path $projectDir "pnpm-lock.yaml")) {
      Test-Komut "pnpm" "pnpm bulunamadı."
      pnpm --dir $projectDir install --frozen-lockfile | Out-Null
    } else {
      Test-Komut "npm" "Node.js (npm) bulunamadı."
      npm install --prefix $projectDir | Out-Null
    }

    $nodeOut = Join-Path $reportDir "node-$projectName.json"
    npx --yes license-checker --production --json --out $nodeOut | Out-Null

    $unknownNode = Test-UnknownLicense -JsonPath $nodeOut
    if ($unknownNode.Count -gt 0 -and -not $BelirsizLisanslaraIzinVer) {
      Write-Hata "Belirsiz lisans bulundu (Node: $projectName)." "Belirsiz lisansları temizleyin veya -BelirsizLisanslaraIzinVer ile devam edin."
      exit 1
    }
  }
}

$created = Get-ChildItem -Path $reportDir -File | Select-Object -ExpandProperty Name
Write-Ok "Lisans raporları üretildi."
Write-Host "Oluşturulan dosyalar:"
foreach ($file in $created) {
  Write-Host "- $file"
}

