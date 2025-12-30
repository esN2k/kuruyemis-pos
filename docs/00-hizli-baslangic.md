# 00 - Hızlı Başlangıç (5 Dakika)

Amaç: 5 dakika içinde POS'u ayağa kaldırmak, yazdırmayı test etmek ve tartılı barkodun sepete düşmesini doğrulamak.

## 1) Önkoşul kontrolü
```powershell
.\scripts\windows\00-onkosul-kontrol.ps1
```
Beklenen sonuç: Tüm kritik kontroller **OK**.

## 2) Altyapıyı hazırla (frappe_docker pin + qz-tray.js)
```powershell
.\scripts\windows\01-bootstrap.ps1
```
Beklenen sonuç: `frappe_docker` indirildi, pinli commit'e geçildi, `qz-tray.js` hazır.

## 3) Servisleri başlat
```powershell
.\scripts\windows\02-baslat.ps1 -OpsiyonelServisler
```
Beklenen sonuç: Docker container'ları ayakta.

## 4) Site oluştur
```powershell
.\scripts\windows\03-site-olustur.ps1 -SiteAdi kuruyemis.local -YoneticiSifresi admin -MariaDBRootSifresi admin
```
Beklenen sonuç: Site oluşturuldu.

## 5) Uygulamaları kur
```powershell
.\scripts\windows\04-uygulamalari-kur.ps1 -SiteAdi kuruyemis.local
```
Beklenen sonuç: ERPNext + POS Awesome + CK Kuruyemiş POS yüklendi, migrate tamamlandı ve TR varsayılanlar uygulandı.

## 6) Yazıcıları tanıt ve test et
- QZ Tray'i açın (tray ikonu görünmeli)
- `http://kuruyemis.local:8080/app/pos_printer_setup` sayfasından yazıcıları listeleyin ve varsayılanları kaydedin
- POS Awesome'da menüden "Mali Olmayan Fiş Yazdır" ve "Raf Etiketi Yazdır" ile test edin

## 7) Tartılı barkod demo
- Bir ürün kartına `scale_plu=12345` girin
- Örnek barkod: `2012345001501`
- Beklenen sonuç: Ürün sepete otomatik düşer, miktar `0.150 kg` olur

## 8) Doktor + duman testi
```powershell
.\scripts\windows\05-doctor.ps1 -SiteAdi kuruyemis.local
.\scripts\windows\09-smoke-test.ps1 -SiteAdi kuruyemis.local
```
Beklenen sonuç: Tüm kontroller **OK**.

Not: Test fiş/etiket için `DRY_RUN=0 .\scripts\windows\09-smoke-test.ps1 -SiteAdi kuruyemis.local`.

Sonraki adım: `docs/01-kurulum.md` ve `docs/06-operasyon.md`.
