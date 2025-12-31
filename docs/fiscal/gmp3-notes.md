# GMP3 Notları (INPOS M530)

Bu notlar **GMP3 eşleme protokolü** için hazırlık amaçlıdır. Protokol uygulaması **henüz yoktur**.

## Önkoşullar
- M530 ve POS aynı LAN'da olmalı
- Cihaza **sabit IP** atanmalı
- POS tarafında erişim için TCP portu açık olmalı

## Eşleme Adımları (Özet)
1) M530 menüsünde: **Harici Uygulamalar**
2) **Uygulama Eşle** seç
3) Uygulama No, IP ve Port gir
4) Eşleme onayı al

## Adaptör Mimarisi
```
POS -> fiscal-adapter -> M530 (Ethernet)
```

## Hata ve Geri Dönüş
- Adaptör hata verirse **manuel mali fiş** akışına dönülür.
- Hata logları destek paketine eklenir.

## Yapılacaklar
- GMP3 mesaj çerçeveleme
- ACK/NAK ve zaman aşımı yönetimi
- Hata kodu eşleme ve retry politikası

Referans: `docs/references/gmp3-esleme-protokolu-dokumani.pdf`
