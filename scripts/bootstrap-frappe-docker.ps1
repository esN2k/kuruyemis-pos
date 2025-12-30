param(
  [string]$InfraDir = (Join-Path $PSScriptRoot "..\\infra"),
  [string]$VersionsEnv = (Join-Path $PSScriptRoot "..\\infra\\versions.env")
)

$infraPath = Resolve-Path $InfraDir
$frappeDockerDir = Join-Path $infraPath "frappe_docker"

if (!(Test-Path $VersionsEnv)) {
  throw "Missing versions.env at $VersionsEnv"
}

$versions = @{}
Get-Content $VersionsEnv | Where-Object { $_ -and -not $_.StartsWith('#') } | ForEach-Object {
  $parts = $_.Split('=', 2)
  if ($parts.Length -eq 2) { $versions[$parts[0]] = $parts[1] }
}

$frappeDockerRef = $versions["FRAPPE_DOCKER_REF"]
if (-not $frappeDockerRef) {
  throw "FRAPPE_DOCKER_REF missing in versions.env"
}

if (!(Test-Path $frappeDockerDir)) {
  git clone https://github.com/frappe/frappe_docker.git $frappeDockerDir
}

git -C $frappeDockerDir fetch --all

Write-Host "Checking out frappe_docker at $frappeDockerRef..."
git -C $frappeDockerDir checkout $frappeDockerRef

$exampleEnv = Join-Path $frappeDockerDir "example.env"
$envPath = Join-Path $frappeDockerDir ".env"

if (!(Test-Path $exampleEnv)) {
  throw "Missing example.env in $frappeDockerDir"
}

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

Set-Content -Encoding ASCII -Path $envPath -Value $updated

Write-Host "frappe_docker ready at $frappeDockerDir"
