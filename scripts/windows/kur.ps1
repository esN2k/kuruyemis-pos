param(
  [string]$SiteAdi = "kuruyemis.local",
  [string]$YoneticiSifresi = "admin",
  [string]$MariaDBRootSifresi,
  [switch]$OpsiyonelServisler,
  [switch]$OpsiyonelServisleriAtla,
  [switch]$DemoVeriYukle,
  [string]$OpsiyonelModuller
)

. "$PSScriptRoot\_ortak.ps1"

function Calistir-Adim {
  param(
    [string]$Baslik,
    [string]$Komut,
    [object[]]$Argumanlar = @()
  )
  Write-Bilgi $Baslik
  & $Komut @Argumanlar
  if ($LASTEXITCODE -ne 0) {
    Write-Hata "$Baslik başarısız." "Hata mesajlarını kontrol edip tekrar deneyin."
    exit 1
  }
}

Write-Bilgi "Tek komut kurulum başlıyor..."

Calistir-Adim "Önkoşul kontrolü" "$PSScriptRoot\00-onkosul-kontrol.ps1"
Calistir-Adim "Bootstrap (frappe_docker + qz-tray.js)" "$PSScriptRoot\01-bootstrap.ps1"

if ($OpsiyonelServisleriAtla) {
  Calistir-Adim "Docker servislerini başlat" "$PSScriptRoot\02-baslat.ps1"
} else {
  $optFlag = @()
  if ($OpsiyonelServisler -or -not $OpsiyonelServisleriAtla) {
    $optFlag = @("-OpsiyonelServisler")
  }
  Calistir-Adim "Docker servislerini başlat" "$PSScriptRoot\02-baslat.ps1" $optFlag
}

$siteArgs = @("-SiteAdi", $SiteAdi, "-YoneticiSifresi", $YoneticiSifresi)
if ($MariaDBRootSifresi) {
  $siteArgs += @("-MariaDBRootSifresi", $MariaDBRootSifresi)
}
Calistir-Adim "Site oluştur" "$PSScriptRoot\03-site-olustur.ps1" $siteArgs
$installArgs = @("-SiteAdi", $SiteAdi)
if ($DemoVeriYukle) {
  $installArgs += "-DemoVeriYukle"
}
if ($OpsiyonelModuller) {
  $installArgs += @("-OpsiyonelModuller", $OpsiyonelModuller)
}
Calistir-Adim "Uygulamaları kur" "$PSScriptRoot\04-uygulamalari-kur.ps1" $installArgs
Calistir-Adim "Doktor kontrolü" "$PSScriptRoot\05-doctor.ps1" @("-SiteAdi", $SiteAdi)
Calistir-Adim "Duman testi (DRY_RUN)" "$PSScriptRoot\09-smoke-test.ps1" @("-SiteAdi", $SiteAdi)

Write-Ok "Kurulum tamamlandı. Sonraki adım: http://$SiteAdi:8080/"


