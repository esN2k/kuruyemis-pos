param(
  [string]$SiteAdi = "kuruyemis.local",
  [switch]$GercekBaski
)

. "$PSScriptRoot\_ortak.ps1"

function Calistir-Adim {
  param(
    [string]$Baslik,
    [string]$Komut,
    [object[]]$Argumanlar = @()
  )
  Write-Bilgi "$Baslik çalıştırılıyor..."
  & $Komut @Argumanlar
  if ($LASTEXITCODE -ne 0) {
    Write-Hata "$Baslik başarısız." "Hata mesajlarını kontrol edip tekrar deneyin."
    return $false
  }
  Write-Ok "$Baslik başarılı."
  return $true
}

Write-Bilgi "Saha test paketi başlıyor..."

$doctorOk = Calistir-Adim "Doktor kontrolü" "$PSScriptRoot\05-doctor.ps1" @("-SiteAdi", $SiteAdi)

$smokeArgs = @("-SiteAdi", $SiteAdi)
if ($GercekBaski) {
  $smokeArgs += "-GercekBaski"
}
$smokeOk = Calistir-Adim "Duman testi" "$PSScriptRoot\09-smoke-test.ps1" $smokeArgs

Write-Host ""
$doctorLabel = if ($doctorOk) { "OK" } else { "HATA" }
$smokeLabel = if ($smokeOk) { "OK" } else { "HATA" }
$opsiyonel = Get-OpsiyonelModuller -SiteAdi $SiteAdi
$opsiyonelText = if ($opsiyonel.Count -gt 0) { $opsiyonel -join ", " } else { "Yok" }

Write-Host "Özet:"
Write-Host "- Site: $SiteAdi"
Write-Host "- Doktor: $doctorLabel"
Write-Host "- Duman Testi: $smokeLabel"
Write-Host "- Opsiyonel Modüller: $opsiyonelText"
if ($GercekBaski) {
  Write-Host "- Gerçek baskı: Evet"
} else {
  Write-Host "- Gerçek baskı: Hayır (DRY_RUN)"
}

if (-not $doctorOk -or -not $smokeOk) {
  Write-Hata "Saha testi hatalarla tamamlandı." "Hata mesajlarına göre düzeltme yapın."
  exit 1
}

Write-Ok "Saha testi tamamlandı."
