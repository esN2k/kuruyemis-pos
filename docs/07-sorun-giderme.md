# 07 - Sorun Giderme

Aşağıdaki maddelerde “neden + çözüm” formatı kullanılır.

## 1) Site açılmıyor (`http://kuruyemis.local:8080`)
- Neden: Docker servisleri ayakta değil.
- Çözüm: `.\scripts\windows\02-baslat.ps1` çalıştırın ve `05-doctor.ps1` ile doğrulayın.

## 2) MySQL/MariaDB bağlantı hatası
- Neden: DB servisi ayakta değil veya şifre yanlış.
- Çözüm: `.\scripts\windows\02-baslat.ps1` sonrası `.\scripts\windows\03-site-olustur.ps1` tekrar deneyin. Gerekirse `infra/frappe_docker/.env` içindeki `DB_PASSWORD` değerini kontrol edin.

## 3) POS Awesome görünmüyor / güncellemeler gelmiyor
- Neden: Cache/storageda eski build kalmış olabilir.
- Çözüm: Tarayıcıda Site Data/Storage temizleyin (Chrome: Ayarlar → Gizlilik → Site Verileri → `kuruyemis.local`). Ardından sayfayı yenileyin.

## 4) QZ Tray bağlantısı kapalı
- Neden: QZ Tray çalışmıyor veya port kapalı.
- Çözüm: QZ Tray'i açın. `https://demo.qz.io` ile yazıcı listesini doğrulayın.

## 5) Yazıcı listesi gelmiyor
- Neden: QZ Tray izin verilmedi, yazıcı sürücüleri eksik.
- Çözüm: QZ Tray Site Manager'da siteyi yetkilendirin, Windows yazıcılarını kontrol edin.

## 6) QZ imza uyarıları
- Neden: Dev modunda imzasız çağrı yapılıyor.
- Çözüm: Devde uyarı normaldir. Üretimde QZ signing sertifikası gerekir (bkz. `docs/03-yazdirma-qz.md`).

## 7) Tartılı barkod sepete düşmüyor
- Neden: `scale_plu` eşleşmesi yok veya kural kapalı.
- Çözüm: Ürün kartında `scale_plu` alanını doldurun, `Tartılı Barkod Kuralı` DocType'ında kuralın etkin olduğunu doğrulayın.

## 8) MariaDB sürüm uyarısı
- Neden: 10.11+ sürüm kullanılıyor.
- Çözüm: MariaDB 10.6.x pinine dönün (`docs/01-kurulum.md`).

## 9) Yazdırma testleri başarısız
- Neden: QZ Tray yok / yazıcı adı yanlış.
- Çözüm: `pos_printer_setup` sayfasında yazıcı adlarını kaydedin ve `09-smoke-test.ps1` ile test edin.

## 10) Kurulum yarım kaldı
- Neden: Docker veya ağ hatası.
- Çözüm: `.\scripts\windows\kur.ps1` ile tekrar deneyin; sorun devam ediyorsa `08-destek-paketi.ps1` çıktısını paylaşın.
