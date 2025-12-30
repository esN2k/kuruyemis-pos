param(
  [Parameter(Mandatory = $true)][string]$SiteName,
  [string]$FrappeDockerDir = (Join-Path $PSScriptRoot "frappe_docker"),
  [string]$VersionsEnv = (Join-Path $PSScriptRoot "versions.env")
)

if (!(Test-Path $VersionsEnv)) {
  throw "Missing versions.env at $VersionsEnv"
}

$versions = @{}
Get-Content $VersionsEnv | Where-Object { $_ -and -not $_.StartsWith('#') } | ForEach-Object {
  $parts = $_.Split('=', 2)
  if ($parts.Length -eq 2) { $versions[$parts[0]] = $parts[1] }
}

$posAwesomeRef = $versions["POS_AWESOME_REF"]
if (-not $posAwesomeRef) {
  throw "POS_AWESOME_REF missing in versions.env"
}

$composeArgs = @(
  "-f", (Join-Path $FrappeDockerDir "compose.yaml"),
  "-f", (Join-Path $PSScriptRoot "docker-compose.override.yaml")
)

Write-Host "Ensuring POS Awesome app is present..."
$checkCmd = "test -d apps/posawesome"
docker compose @composeArgs exec backend bash -lc $checkCmd
if ($LASTEXITCODE -ne 0) {
  docker compose @composeArgs exec backend bench get-app --branch $posAwesomeRef https://github.com/yrestom/POS-Awesome.git
}

Write-Host "Installing POS Awesome and ck_kuruyemis_pos on $SiteName..."
docker compose @composeArgs exec backend bench --site $SiteName install-app posawesome
docker compose @composeArgs exec backend bench --site $SiteName install-app ck_kuruyemis_pos

Write-Host "Running migrations..."
docker compose @composeArgs exec backend bench --site $SiteName migrate