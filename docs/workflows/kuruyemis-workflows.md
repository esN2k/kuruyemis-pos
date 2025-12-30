# Kuruyemiş İş Akışı

Bu doküman mağaza operasyonu için **net, adım adım** akışı tanımlar.

## Ana Satış Akışı
1) **Tart**: CL3000 üzerinde ürün tartılır
2) **Etiket**: Tartı, barkodlu etiket basar (Prefix 20/21)
3) **Tara**: POS Awesome'da barkod okutulur
4) **Sepet**: Ürün otomatik sepete düşer (miktar/fiyat dolu gelir)
5) **Mali Fiş**: M530 üzerinde mali fiş manuel basılır (MVP)
6) **Mali Olmayan Fiş**: İstenirse QZ Tray üzerinden basılır
7) **Stok**: ERPNext stoktan düşer

## İade Akışı (Özet)
- Müşteri fişi ile gelir
- POS'ta iade satışı yapılır
- M530 üzerinde iade mali fişi manuel basılır

## İndirim Akışı (Özet)
- POS'ta indirim uygulanır
- Toplam tutar güncellenir

Not: Barkod ve yazdırma ayarları için `docs/04-tartili-barkodlar.md` ve `docs/03-yazdirma-qz.md`.
