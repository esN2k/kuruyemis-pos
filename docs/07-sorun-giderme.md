# 07 - Sorun Giderme

## 1) POS açılmıyor (kuruyemis.local:8080)
- **Neden**: Docker container'ları ayakta değil
- **Çözüm**: `scripts/windows/02-baslat.ps1` çalıştırın ve `docker compose ps` ile kontrol edin

## 2) QZ Tray görünmüyor
- **Neden**: QZ Tray çalışmıyor veya güvenlik uyarısı reddedildi
- **Çözüm**: QZ Tray'i açın, tray ikonunu doğrulayın, tarayıcı uyarılarını onaylayın

## 3) Yazıcı listesi boş
- **Neden**: Windows yazıcıları kurulu değil veya spooler kapalı
- **Çözüm**: Yazıcı sürücüsünü kurun, `Get-Printer` ile doğrulayın

## 4) Barkod sepete düşmüyor
- **Neden**: Prefix/PLU düzeni yanlış veya `scale_plu` boş
- **Çözüm**: `docs/04-tartili-barkodlar.md` ve Tartılı Barkod Kuralı'nı kontrol edin

## 5) Site bulunamadı (kuruyemis.local)
- **Neden**: `hosts` kaydı yok
- **Çözüm**: `docs/01-kurulum.md` içindeki hosts adımını uygulayın

## 6) QZ bağlantı hatası (8182)
- **Neden**: QZ Tray WebSocket kapalı
- **Çözüm**: QZ Tray'i yeniden başlatın, 8182 portunu kontrol edin

## 7) Duman testi başarısız
- **Neden**: Presetler yüklenmemiş veya test bağımlılıkları eksik
- **Çözüm**: `scripts/windows/04-uygulamalari-kur.ps1` ve ardından `09-smoke-test.ps1`
