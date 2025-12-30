param(
  [Parameter(Mandatory = $true)][string]$SiteName,
  [string]$AdminPassword = "admin",
  [string]$MariaDBRootPassword = "admin",
  [string]$FrappeDockerDir = (Join-Path $PSScriptRoot "frappe_docker")
)

$composeArgs = @(
  "-f", (Join-Path $FrappeDockerDir "compose.yaml"),
  "-f", (Join-Path $PSScriptRoot "docker-compose.override.yaml")
)

Write-Host "Creating site $SiteName..."
docker compose @composeArgs exec backend bench new-site $SiteName --admin-password $AdminPassword --mariadb-root-password $MariaDBRootPassword --install-app erpnext