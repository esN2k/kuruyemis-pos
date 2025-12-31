# 03 - Yazdırma (QZ Tray)

QZ Tray, tarayıcı ile yazıcı arasındaki köprüdür. POS Awesome, QZ Tray üzerinden raw fiş/etiket basar.

## QZ Tray Nasıl Çalışır?
- Tarayıcıda çalışan JS (`qz-tray.js`) QZ Tray'e WebSocket ile bağlanır.
- QZ Tray, Windows yazıcılarına raw veri gönderir.
- Dev ortamında imza/sertifika doğrulaması kapatılabilir (uyarılar normaldir).

## Kurulum (Windows)
1) QZ Tray'i kurun ve çalıştırın
   - İndir: https://qz.io/download/
   - Tray ikonunun görünür olması gerekir.

2) Demo ile yazıcı listesi doğrulama
   - `https://demo.qz.io` sayfasını açın.
   - "List Printers" ile yazıcıları görmeyi doğrulayın.
   - QZ Tray kurulum klasöründe `sample.html` bulunur (lokal demo).

3) Uygulamada yazıcı ayarı
   - `http://kuruyemis.local:8080/app/pos_printer_setup`
   - Varsayılan fiş ve etiket yazıcılarını kaydedin.

## qz-tray.js Dosyası (Vendor)
`qz-tray.js` dosyası otomatik indirilir. Gerekirse manuel:
```powershell
.\scripts\get-qz-tray.ps1
```
```bash
./scripts/get-qz-tray.sh
```
Dosya özeti (SHA256) bilgisi: `docs/printing/qz-tray.md`

## İmza / Sertifika (Dev ve Prod)
QZ Tray güvenlik modeli gereği **üretimde imza zorunludur**. Bu proje dev ortamında imza doğrulamasını kapatarak çalışır.

### DEV (Geliştirme) - Site Manager ile demo sertifika
1) QZ Tray > **Site Manager** açın.
2) “Add Site” ile `http://kuruyemis.local:8080` ekleyin.
3) “Generate Certificate” ile demo sertifika üretin.
4) Tarayıcıda QZ uyarılarını onaylayın.

Not: Dev modunda uyarı görmek normaldir.

### PROD (Üretim) - İmzalı dağıtım
1) QZ signing anahtarı ve sertifika zinciri edinilir.
2) POS uygulaması imzalı mesaj üretir.
3) QZ Tray, imzayı doğrular ve yalnızca imzalı istekleri kabul eder.

Önemli: Bu süreç için **QZ Premium Support gerekebilir**. Ayrıntılar için QZ lisans dokümanlarını inceleyin.

## Test Baskısı
- POS Awesome menü:
  - “Bilgi Fişi Yazdır (Mali Değil)”
  - “Raf Etiketi Yazdır (38x80)”
- Alternatif: `docs/workflows/printing.md` ve `scripts/windows/09-smoke-test.ps1`
- Gerçek baskı için: `DRY_RUN=0 .\scripts/windows/09-smoke-test.ps1 -SiteAdi kuruyemis.local`

Sorun yaşıyorsanız: `docs/07-sorun-giderme.md`.
