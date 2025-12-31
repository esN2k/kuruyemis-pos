# 04 - Tartılı Barkodlar (CAS CL3000)

Bu doküman CL3000 tartıdan çıkan tartılı barkodların nasıl çözümlendiğini anlatır.

## EAN-13 Tartılı Barkod Mantığı
Örnek düzen (13 hane):
```
PP IIIII IIIII C
```
- `PP`: Prefix (20 veya 21)
- `IIIII`: PLU (5 hane) → `scale_plu`
- `IIIII`: Ağırlık (gram) veya Fiyat (kuruş)
- `C`: EAN-13 kontrol basamağı

## Varsayılan Presetler
1) **Prefix 20** → Ağırlık (gram)
- Prefix: `20`
- PLU: 5 hane (`scale_plu`)
- Ağırlık: 5 hane (gram)

2) **Prefix 21** → Fiyat (kuruş)
- Prefix: `21`
- PLU: 5 hane (`scale_plu`)
- Fiyat: 5 hane (kuruş)

## CL3000 Format Sembolleri → Parser Eşleme
- **PLU alanı** → `segment_type = item_code`
- **Ağırlık alanı** → `segment_type = weight` + `scale_unit` (gram/kg)
- **Fiyat alanı** → `segment_type = price` + `scale_unit` (kuruş/lira)
- **Kontrol basamağı** → `check_ean13` (aç/kapa)

## Örnek Barkodlar
- **Ağırlık örneği**: `2012345001501`
  - Prefix: 20
  - PLU: 12345
  - Ağırlık: 00150 → 0.150 kg
- **Fiyat örneği**: `2154321012344`
  - Prefix: 21
  - PLU: 54321
  - Fiyat: 01234 → 12.34 TRY

## Doğrulama Adımları
1) Ürün kartına `scale_plu` girin (ör. `12345`)
2) Barkodu POS'ta tarayın
3) Beklenen: ürün sepete otomatik düşer, miktar/fiyat dolu gelir

## POS İçinde Barkod Doğrulama
`/app/pos_printer_setup` sayfasındaki **Barkod Doğrulama** alanına barkodu girin.  
Beklenen sonuç: Eşleşen kural, PLU ve ağırlık/fiyat bilgileri Türkçe olarak görünür.

## Konfigürasyon
- DocType: **Tartılı Barkod Kuralı**
- `Ürün Kodu Hedefi` alanı: `Tartı PLU` (önerilen)

Ayrıntı: `docs/workflows/weighed-barcodes.md`

## Opsiyonel: Scan Me ile QR/Barkod
`scan_me` modülü kuruluysa Print Format içinde QR/Barkod üretimi yapılabilir.

Örnek Print Format snippet (QR):
```jinja
{% set qr_data = doc.name %}
<img src="{{ scan_me.utils.jinja_functions.qr(qr_data) }}" style="width:120px;height:120px;" />
```

Örnek Print Format snippet (EAN-13):
```jinja
{% set barkod = doc.barcode or doc.item_code %}
<img src="{{ scan_me.utils.jinja_functions.barcode(barkod, barcode_type='ean13') }}" style="width:220px;height:80px;" />
```

Not: `scan_me` opsiyonel modüldür ve varsayılan kurulumda gelmez.

## Çekirdek Yardımcı Modül (frappe_qr_demo uyarlaması)
`ck_kuruyemis_pos.print_helpers` modülü, Print Format içinde QR/Barkod üretimi için küçük yardımcı fonksiyonlar sağlar.

QR örneği:
```jinja
{% set qr_data = doc.name %}
<img src="{{ ck_kuruyemis_pos.print_helpers.qr_data_url(qr_data) }}" style="width:120px;height:120px;" />
```

Barcode (Code128) örneği:
```jinja
{% set barkod = doc.barcode or doc.item_code %}
{{ ck_kuruyemis_pos.print_helpers.barcode_svg(barkod) }}
```

Not: Bu yardımcılar, `qrcode` ve `python-barcode` paketleri yüklüyse çalışır. En kolay yol `scan_me` modülünü kurmaktır.
