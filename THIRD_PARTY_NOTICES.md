# Üçüncü Taraf Bildirimleri (Third-Party Notices)

Bu proje; bazı açık kaynak bileşenleri ve kütüphaneleri kullanır. Bu dosyanın amacı:
- Kullandığımız bileşenleri ve lisanslarını şeffaf şekilde belirtmek,
- Lisans metinlerinin/atıfların korunmasını sağlamak,
- Projeyi kuran/katkı veren herkesin "ne nereden geliyor?" sorusunu tek yerden cevaplamaktır.

> Not: Bu dosya hukuki tavsiye değildir.

---

## 1) Çekirdek Bileşenler (Zorunlu)

### 1.1 ERPNext
- Amaç: Stok, satış, raporlama, cari vb. iş omurgası
- Kaynak: https://github.com/frappe/erpnext
- Lisans: **GPL-3.0**

### 1.2 Frappe Framework
- Amaç: ERPNext'in üzerinde çalıştığı uygulama çatısı
- Kaynak: https://github.com/frappe/frappe
- Lisans: **MIT**

### 1.3 POS Awesome (ERPNext v15)
- Amaç: Dokunmatik, hızlı kasa ekranı (Vue/Vuetify tabanlı POS)
- Kaynak: https://github.com/defendicon/POS-Awesome-V15
- Lisans: **GPL-3.0**

### 1.4 QZ Tray
- Amaç: Tarayıcıdan (POS) fiş/etiket yazıcılarına yazdırma köprüsü
- Kaynak: https://github.com/qzind/tray + qz.io dokümantasyon
- Lisans (Kaynak Kod): **LGPL-2.1**
- API/Demo Örnekleri Lisansı: **Public Domain** (örn. `sample.html`)
- Not: qz.io'dan indirilen bazı binary dağıtımlar "Premium Support / sertifika" modeli içerebilir.

---

## 2) Yazdırma / Barkod Yardımcı Kütüphaneleri

### 2.1 ReceiptPrinterEncoder
- Amaç: ESC/POS fiş komutlarını doğru üretmek (hizalama, kalın yazı, kesme vb.)
- Kaynak: https://github.com/NielsLeenheer/ReceiptPrinterEncoder
- Lisans: **MIT**

### 2.2 JsBarcode
- Amaç: Etiket önizleme için barkod üretmek (SVG/Canvas)
- Kaynak: https://github.com/lindell/JsBarcode
- Lisans: **MIT**

---

## 3) Bu projede bağımlılıklar nasıl kullanılır?
- Çekirdek bileşenler (ERPNext / POS Awesome / QZ Tray) projeye temel sağlar.
- Bizim özel kodlarımız ayrı bir uygulama olarak tutulur (örn. `ck_kuruyemis_pos`).
- Üçüncü parti projeler mümkün olduğunca upstream üzerinden bağımlılık olarak alınır.

---

## 4) Lisans uyumu için bakım kuralı
Yeni bir kütüphane/araç eklendiğinde:
1) Bu dosyaya şu formatta eklenir: Ad / Amaç / Kaynak / Lisans / Bağlantı
2) Lisans "Unknown / belirsiz" ise:
   - Varsayılan kurulumdan çıkarılır veya "opsiyonel" yapılır,
   - Dokümantasyonda açıkça not düşülür,
   - Mümkünse lisansı net bir alternatif tercih edilir.

---

## 5) Lisans metinleri nerede?
- Bu repoda `LICENSE` dosyası: projemizin lisansı
- Üçüncü taraf projelerin lisans metinleri: ilgili upstream repolarda
- Gerekli durumlarda upstream lisans dosyaları "vendor" klasöründe ayrıca korunabilir

---

## 6) İletişim / Düzeltme
Bu dosyada eksik/yanlış bir lisans veya atıf görürseniz lütfen issue açın:
- Hangi bileşen?
- Lisans kaynağı bağlantısı?
- Önerilen düzeltme?
- Teşekkürler!
