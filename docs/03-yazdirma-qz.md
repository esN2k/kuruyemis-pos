# 03 - Yazdırma (QZ Tray)

QZ Tray, tarayıcı ile yazıcı arasındaki köprüdür. POS Awesome, QZ Tray üzerinden raw fiş/etiket basar.

## QZ Tray Nasıl Çalışır?
- Tarayıcıda çalışan JS (`qz-tray.js`) QZ Tray'e WebSocket ile bağlanır
- QZ Tray, Windows yazıcılarına raw veri gönderir
- Dev ortamında imza/sertifika doğrulaması kapatılabilir (uyarılar normaldir)

## Kurulum (Windows)
1) QZ Tray'i kurun ve çalıştırın
- İndir: https://qz.io/download/
- Tray ikonunun görünür olması gerekir

2) Demo ile yazıcı listesi doğrulama
- `https://demo.qz.io` sayfasını açın
- "List Printers" ile yazıcıları görmeyi doğrulayın
- QZ Tray kurulum klasöründe `sample.html` bulunur (lokal demo)

3) Uygulamada yazıcı ayarı
- `http://kuruyemis.local:8080/app/pos_printer_setup`
- Varsayılan fiş ve etiket yazıcılarını kaydedin

## qz-tray.js Dosyası (Vendor)
`qz-tray.js` dosyası otomatik indirilir. Gerekirse manuel:
```powershell
.\scripts\get-qz-tray.ps1
```
```bash
./scripts/get-qz-tray.sh
```
Dosya özeti (SHA256) bilgisi: `docs/printing/qz-tray.md`

## İmza / Sertifika Notu (Üretim)
- Üretimde **imza zorunludur** (QZ Tray güvenlik modeli)
- Bu projede **geliştirme modu** kullanılır: sertifika ve imza `null`
- Prod'a geçerken imza anahtarı ve sertifika zinciri kurulmalıdır

## Test Baskısı
- POS Awesome menü: "Mali Olmayan Fiş Yazdır"
- POS Awesome menü: "Raf Etiketi Yazdır"
- Alternatif: `docs/workflows/printing.md` ve `scripts/windows/09-smoke-test.ps1`
- Gerçek baskı için: `DRY_RUN=0 .\scripts\windows\09-smoke-test.ps1 -SiteAdi kuruyemis.local`

Sorun yaşıyorsanız: `docs/07-sorun-giderme.md`.
