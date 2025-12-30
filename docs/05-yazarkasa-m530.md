# 05 - Yazarkasa (INPOS M530)

MVP'de mali fiş **manuel** basılır. Otomatik entegrasyon için **mali adaptör** taslağı hazırdır.

## MVP Akışı (Manuel)
1) Satış POS'ta tamamlanır
2) Kasiyer M530 üzerinde **mali fişi manuel** basar
3) POS'ta satış kapatılır

## Adaptör Planı (Gelecek)
```
POS -> Fiscal Adapter -> INPOS M530 (Ethernet)
```
- Cihaz aynı LAN'da, **sabit IP** ile çalışmalı
- GMP3 mesaj çerçeveleme **yapılacak**
- Adaptör hata verirse: manuel fiş akışına geri dönülür

Ayrıntılı notlar: `docs/fiscal/gmp3-notes.md`
