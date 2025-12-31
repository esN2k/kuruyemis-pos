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

## 3) Opsiyonel Frappe Modülleri

> Bu bölümdeki modüller **varsayılan kurulumda gelmez**. Sadece ihtiyaç halinde kurulmalıdır.

### 3.1 Frappe Insights
- Amaç: Yönetici dashboard ve raporlama
- Kaynak: https://github.com/frappe/insights
- Lisans: **AGPL-3.0**

### 3.2 ERPGulf Scale
- Amaç: Tartılı barkod/terazi odaklı ayarlar
- Kaynak: https://github.com/ERPGulf/scale
- Lisans: **MIT**

### 3.3 Frappe Print Designer
- Amaç: Yazdırma şablonu tasarımı
- Kaynak: https://github.com/frappe/print_designer
- Lisans: **AGPL-3.0**

### 3.4 Frappe BetterPrint
- Amaç: PDF/yazdırma kalitesi iyileştirmeleri
- Kaynak: https://github.com/neocode-it/frappe_betterprint
- Lisans: **AGPL-3.0**

### 3.5 AgriTheory Beam
- Amaç: Barkod tarama / depo operasyonları
- Kaynak: https://github.com/agritheory/beam
- Lisans: **MIT** (license.txt)

### 3.6 Scan Me
- Amaç: QR ve barkod üretimi/doğrulaması
- Kaynak: https://github.com/Tusharp21/scan-me
- Lisans: **MIT**

### 3.7 Silent-Print-ERPNext
- Amaç: Sessiz yazdırma (WHB ile)
- Kaynak: https://github.com/roquegv/Silent-Print-ERPNext
- Lisans: **MIT**

### 3.8 Frappe WABA Integration
- Amaç: WhatsApp Business API entegrasyonu
- Kaynak: https://github.com/frappe/waba_integration
- Lisans: **MIT** (license.txt)

### 3.9 Frappe WhatsApp
- Amaç: WhatsApp entegrasyonu (alternatif)
- Kaynak: https://github.com/shridarpatil/frappe_whatsapp
- Lisans: **MIT** (license.txt)

### 3.10 ERPGulf GPos
- Amaç: Alternatif POS uygulaması (gelecek opsiyonu)
- Kaynak: https://github.com/ERPGulf/GPos
- Lisans: **MIT**

### 3.11 aisenyi/pasigono
- Amaç: QZ Tray odaklı referans uygulama (inceleme amaçlı)
- Kaynak: https://github.com/aisenyi/pasigono
- Lisans: **Belirsiz (NOASSERTION)** → **varsayılan kurulum dışı**

### 3.12 Webapp Hardware Bridge (WHB)
- Amaç: Sessiz yazdırma ve seri port köprüsü
- Kaynak: https://github.com/imTigger/webapp-hardware-bridge
- Lisans: **MIT**

### 3.13 frappe_qr_demo (uyarlanan yardımcı)
- Amaç: QR/Barkod üretimi için demo mantığı (ck_kuruyemis_pos içine uyarlandı)
- Kaynak: https://github.com/alyf-de/frappe_qr_demo
- Lisans: **MIT**

---

## 4) Bu projede bağımlılıklar nasıl kullanılır?
- Çekirdek bileşenler (ERPNext / POS Awesome / QZ Tray) projeye temel sağlar.
- Bizim özel kodlarımız ayrı bir uygulama olarak tutulur (örn. `ck_kuruyemis_pos`).
- Üçüncü parti projeler mümkün olduğunca upstream üzerinden bağımlılık olarak alınır.

---

## 5) Lisans uyumu için bakım kuralı
Yeni bir kütüphane/araç eklendiğinde:
1) Bu dosyaya şu formatta eklenir: Ad / Amaç / Kaynak / Lisans / Bağlantı
2) Lisans "Unknown / belirsiz" ise:
   - Varsayılan kurulumdan çıkarılır veya "opsiyonel" yapılır,
   - Dokümantasyonda açıkça not düşülür,
   - Mümkünse lisansı net bir alternatif tercih edilir.

---

## 6) Lisans metinleri nerede?
- Bu repoda `LICENSE` dosyası: projemizin lisansı
- Üçüncü taraf projelerin lisans metinleri: ilgili upstream repolarda
- Gerekli durumlarda upstream lisans dosyaları "vendor" klasöründe ayrıca korunabilir

---

## 7) İletişim / Düzeltme
Bu dosyada eksik/yanlış bir lisans veya atıf görürseniz lütfen issue açın:
- Hangi bileşen?
- Lisans kaynağı bağlantısı?
- Önerilen düzeltme?
- Teşekkürler!
