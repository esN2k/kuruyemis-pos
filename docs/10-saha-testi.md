# 10 - Saha Testi (15 Dakika)

Amaç: Mağazada gerçek cihazlarla POS’un uçtan uca çalıştığını doğrulamak.

## Önkoşullar
- Docker servisleri ayakta.
- QZ Tray kurulu ve açık.
- Yazıcı sürücüleri yüklü (ZY907, X‑Printer 490B).
- CL3000 etiketli barkod basabiliyor.

## 1) Otomatik Kontroller (2 dk)
```powershell
.\scripts\windows\11-saha-test.ps1 -SiteAdi kuruyemis.local
```
Beklenen sonuç: Doktor + duman testi **OK**. (Gerçek baskı istenmiyorsa DRY_RUN)

## 2) Yazıcı Testi (3 dk)
```powershell
.\scripts\windows\11-saha-test.ps1 -SiteAdi kuruyemis.local -GercekBaski
```
Beklenen sonuç:
- ZY907’den bilgi fişi çıktı.
- X‑Printer 490B’den 38x80 raf etiketi çıktı.

## 3) Yazıcı Ayarları (2 dk)
- `http://kuruyemis.local:8080/app/pos_printer_setup` sayfasını açın.
- “Varsayılan Fiş Yazıcısı” ve “Varsayılan Etiket Yazıcısı” değerlerini kaydedin.
- “Fiş Şablonu” ve “Etiket Şablonu” seçin.
Beklenen sonuç: Yazıcı listesi geliyor ve ayarlar kaydediliyor.

## 4) CL3000 Tartım + Etiket (3 dk)
- CL3000 üzerinde ürün seçin (PLU doğru olmalı).
- 0.250 kg örnek tartım yapın ve etiket basın.
Beklenen sonuç: Barkod üzerinde PLU ve ağırlık alanları doğru.

## 5) POS’ta Barkod Doğrulama (2 dk)
- POS Yazıcı Kurulumu sayfasında “Barkod Doğrula” alanına barkodu girin.
Beklenen sonuç: Eşleşen kural, PLU ve ağırlık Türkçe olarak görüntülenir.

## 6) POS’ta Satış Akışı (3 dk)
- POS Awesome içinde barkodu okutun.
- Ürün sepete düşmeli ve miktar otomatik gelmeli.
- Satışı tamamlayın.
Beklenen sonuç: Stok düşer, satış kaydı oluşur.

## 7) Mali Fiş (MVP)
- INPOS M530 üzerinde manuel mali fiş basın.
Beklenen sonuç: Satışa ait mali fiş elle alınır (adaptör henüz taslak).

## Kapanış
- Test sonuçlarını not alın.
- Hata varsa `docs/07-sorun-giderme.md` kontrol edin ve `08-destek-paketi.ps1` ile paket oluşturun.
