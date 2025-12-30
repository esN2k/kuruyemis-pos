# 02 - Donanım Kurulum

## 1) CAS CL3000 (Tartılı Barkod)
- Barkod formatı için **Prefix 20/21** presetlerini kullanın
- PLU alanı 5 haneli olmalı (`scale_plu`)
- Detay ve örnek barkodlar: `docs/04-tartili-barkodlar.md`

## 2) CAS ER‑JR (Plan)
- MVP'de zorunlu değil
- RS‑232/USB köprü üzerinden ileride `hardware-bridge` ile bağlanacak

## 3) ZY907 (Fiş Yazıcısı)
- Windows'a yazıcı olarak ekleyin
- Sürücü kurulumundan sonra **Varsayılan Fiş Yazıcısı** olarak seçin

## 4) X‑Printer 490B (Raf Etiketi)
- Windows sürücüsünü kurun
- Etiket ölçüsü: **38x80**
- **Varsayılan Etiket Yazıcısı** olarak seçin

## 5) INPOS M530 (ÖKC)
- MVP: Mali fiş manuel basılır
- LAN'da sabit IP verin
- Ayrıntılar: `docs/05-yazarkasa-m530.md`

## 6) Barkod Okuyucu
- USB HID (klavye gibi) kullanım önerilir
- POS ekranında barkod alanı odakta olmalı

Doğrulama: `docs/03-yazdirma-qz.md` üzerinden test baskıları alın.
