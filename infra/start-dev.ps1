param(
  [string]$FrappeDockerDir = (Join-Path $PSScriptRoot "frappe_docker"),
  [switch]$WithOptionalServices
)

$composeArgs = @()
if ($WithOptionalServices) {
  $composeArgs += "--profile"
  $composeArgs += "optional"
}
$composeArgs += @(
  "-f", (Join-Path $FrappeDockerDir "compose.yaml"),
  "-f", (Join-Path $PSScriptRoot "docker-compose.override.yaml")
)

Write-Host "Starting frappe_docker with local overrides..."
docker compose @composeArgs up -d
