param(
  [Parameter(Mandatory = $true)][string]$SiteAdi,
  [string]$YoneticiSifresi = "admin",
  [string]$MariaDBRootSifresi = "admin"
)

. "$PSScriptRoot\_ortak.ps1"

$composeArgs = Get-ComposeArgs

Write-Bilgi "Site oluşturuluyor: $SiteAdi"

$checkCmd = "test -d sites/$SiteAdi"
try {
  docker compose @composeArgs exec backend bash -lc $checkCmd
  if ($LASTEXITCODE -eq 0) {
    Write-Uyari "Site zaten var: $SiteAdi"
    exit 0
  }
} catch {
  # Yeni site oluşturulacak.
}

try {
  docker compose @composeArgs exec backend bench new-site $SiteAdi --admin-password $YoneticiSifresi --mariadb-root-password $MariaDBRootSifresi --install-app erpnext
  Write-Ok "Site oluşturuldu: $SiteAdi"
} catch {
  Write-Hata "Site oluşturulamadı." "Site adı ve şifreleri kontrol edin."
  exit 1
}
