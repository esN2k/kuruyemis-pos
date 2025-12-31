# 11 - Frappe OSS Fırsatları (Opsiyonel Modüller)

Bu doküman, Frappe ekosistemindeki faydalı açık kaynak projelerini CK Kuruyemiş POS için değerlendirir. Amaç; **sahada güvenilir** kalırken, değer katan özellikleri **opsiyonel modüller** şeklinde sunmaktır.

## Karar özeti
- Varsayılan kurulum: **yalın, stabil, minimum risk**
- Opsiyonel modüller: kullanıcı ihtiyacına göre kurulabilir
- Lisansı belirsiz olanlar: varsayılan kurulumdan **hariç**, önce lisans netleşir

## 1) ERPGulf/scale
- Ne işe yarar? Tartılı barkod/terazi odaklı ayar ve ekranlar için ek uygulama.
- Mağazamıza faydası: CL3000 gibi tartı senaryolarında yönetimi kolaylaştırabilir.
- Riskler: ERPNext sürüm uyumu ve saha performansı test edilmeden varsayılan olamaz.
- Lisans: **MIT**
- Kurulum şekli: **opsiyonel**
  - Script: `.\scripts\windows\04-uygulamalari-kur.ps1 -OpsiyonelModuller scale`
  - Tek komut: `.\scripts\windows\kur.ps1 -OpsiyonelModuller scale`
- Öncelik: **Orta** (uyum testinden sonra önerilir)

## 2) aisenyi/pasigono
- Ne işe yarar? QZ Tray imzalama ve çekmece gibi yardımcı akışlarda örnekler.
- Mağazamıza faydası: QZ sertifika yönetimi ve kasa çekmecesi için referans olabilir.
- Riskler: Lisans belirsizliği, sürüm/uyumluluk ve bakım riski.
- Lisans: **Belirsiz (NOASSERTION)** → **varsayılan kurulum dışı**
- Kurulum şekli: **şimdilik yok** (sadece inceleme)
- Öncelik: **Düşük** (lisans netleşmeden kurulum yok)

## 3) frappe/insights
- Ne işe yarar? Yönetici raporları ve görsel dashboard (BI).
- Mağazamıza faydası: Şube/performans takibi, satış ve stok görselleştirme.
- Riskler: Ek kaynak tüketimi, eğitim ihtiyacı.
- Lisans: **AGPL-3.0**
- Kurulum şekli: **opsiyonel**
  - Script: `.\scripts\windows\04-uygulamalari-kur.ps1 -OpsiyonelModuller insights`
  - Tek komut: `.\scripts\windows\kur.ps1 -OpsiyonelModuller insights`
- Öncelik: **Orta-Yüksek** (yönetici ihtiyacına göre)

## 4) frappe/print_designer
- Ne işe yarar? ERPNext/Frappe için görsel yazdırma şablon tasarım aracı.
- Mağazamıza faydası: Fiş/etiket tasarımlarını görsel olarak yönetmek.
- Riskler: Öğrenme eğrisi, ek bakım yükü.
- Lisans: **AGPL-3.0**
- Kurulum şekli: **opsiyonel**
  - Script: `.\scripts\windows\04-uygulamalari-kur.ps1 -OpsiyonelModuller print_designer`
  - Tek komut: `.\scripts\windows\kur.ps1 -OpsiyonelModuller print_designer`
- Öncelik: **Orta** (tasarım ihtiyacı oluştuğunda)

## 5) neocode-it/frappe_betterprint
- Ne işe yarar? PDF ve yazdırma kalitesini iyileştiren gelişmiş print altyapısı.
- Mağazamıza faydası: Fiş/etiket çıktılarında daha iyi raster/HTML/PDF işleme.
- Riskler: Playwright ve sistem kütüphaneleri gerektirir; kurulum daha ağır.
- Lisans: **AGPL-3.0**
- Kurulum şekli: **opsiyonel**
  - Script: `.\scripts\windows\04-uygulamalari-kur.ps1 -OpsiyonelModuller betterprint`
- Öncelik: **Orta** (kalite ihtiyacı artınca)

## 6) agritheory/beam
- Ne işe yarar? Barkod tarama, sayım ve depo operasyonları için yardımcı modül.
- Mağazamıza faydası: Mal kabul, sayım ve barkod akışlarında hız/izlenebilirlik.
- Riskler: ERPNext v15 uyumu sahada test edilmelidir; bazı bağımlılıklar Git üzerinden gelir.
- Lisans: **MIT** (license.txt)
- Kurulum şekli: **opsiyonel**
  - Script: `.\scripts\windows\04-uygulamalari-kur.ps1 -OpsiyonelModuller beam`
- Öncelik: **Orta**

## 7) ERPGulf/GPos
- Ne işe yarar? Alternatif POS yaklaşımı (ERPNext için başka bir POS uygulaması).
- Mağazamıza faydası: Uzun vadede kıyas/alternatif.
- Riskler: POS Awesome ile çatışma, kullanıcı eğitim maliyeti, UX farklılığı.
- Lisans: **MIT**
- Kurulum şekli: **şimdilik yok** (yalnızca değerlendirme)
- Öncelik: **Düşük** (mevcut POS Awesome odaklıyız)

## 8) Webapp Hardware Bridge (WHB)
- Ne işe yarar? Tarayıcıdan sessiz yazdırma ve seri port erişimi sağlayan yerel köprü.
- Mağazamıza faydası: Sessiz yazdırma, seri tartı entegrasyonu.
- Riskler: Ek kurulum ve yerel servis yönetimi.
- Lisans: **MIT**
- Kurulum şekli: **opsiyonel**
  - Script: `.\scripts\windows\12-whb-kurulum.ps1`
  - Opsiyonel modül: `whb`
- Öncelik: **Orta** (sessiz yazdırma ihtiyacında)

## 9) Silent-Print-ERPNext
- Ne işe yarar? ERPNext/Frappe üzerinden WHB ile sessiz yazdırma.
- Mağazamıza faydası: Fiş/etiket yazdırmayı arka planda ve kullanıcı onayı olmadan yapar.
- Riskler: WHB bağımlılığı, ek konfigürasyon.
- Lisans: **MIT**
- Kurulum şekli: **opsiyonel**
  - Script: `.\scripts\windows\04-uygulamalari-kur.ps1 -OpsiyonelModuller silent_print`
- Öncelik: **Orta**

## 10) Scan Me
- Ne işe yarar? QR ve barkod üretimi/doğrulaması için Frappe uygulaması.
- Mağazamıza faydası: Ürün doğrulama, ambalaj etiketi için QR entegrasyonu.
- Riskler: Ek bağımlılıklar ve kullanım eğrisi.
- Lisans: **MIT**
- Kurulum şekli: **opsiyonel**
  - Script: `.\scripts\windows\04-uygulamalari-kur.ps1 -OpsiyonelModuller scan_me`
- Öncelik: **Orta**

## 11) frappe_qr_demo (uyarlanan yardımcı)
- Ne işe yarar? QR/barkod üretim demo mantığı; çekirdek projeye küçük yardımcı fonksiyon olarak uyarlandı.
- Mağazamıza faydası: Print Format içine QR/barkod gömme.
- Riskler: `qrcode` / `python-barcode` bağımlılığı gerekir.
- Lisans: **MIT**
- Kurulum şekli: **çekirdek içinde yardımcı modül** (opsiyonel modül değildir)
- Öncelik: **Orta**

## 12) WhatsApp Entegrasyonu (Seçilebilir)
İki seçenek vardır. **Aynı anda kurulmamalıdır.**

### 12.1 Frappe WABA Integration
- Ne işe yarar? Meta WhatsApp Business API üzerinden resmi entegrasyon.
- Mağazamıza faydası: Otomatik bilgilendirme ve raporlama.
- Riskler: API hesabı, ek maliyet ve teknik kurulum.
- Lisans: **MIT**
- Kurulum şekli: **opsiyonel**
  - Script: `.\scripts\windows\04-uygulamalari-kur.ps1 -OpsiyonelModuller waba`
- Öncelik: **Orta**

### 12.2 Frappe WhatsApp (shridarpatil)
- Ne işe yarar? WhatsApp entegrasyonu için alternatif uygulama.
- Mağazamıza faydası: Hızlı entegrasyon ve şablon yönetimi.
- Riskler: Kurulum karmaşıklığı ve bakım ihtiyacı.
- Lisans: **MIT**
- Kurulum şekli: **opsiyonel**
  - Script: `.\scripts\windows\04-uygulamalari-kur.ps1 -OpsiyonelModuller whatsapp`
- Öncelik: **Orta**

Örnek mağaza otomasyonları:
- **Gün sonu satış özeti** (toplam ciro + adet) → WhatsApp yöneticisine
- **Stok kritik seviyeye düştü** → sorumlu kişiye uyarı
- **Fiyat listesi güncellendi** → kasa ekiplerine bilgilendirme

## Kurulum politikası
- Opsiyonel modüller yalnızca **ihtiyaç halinde** açılır.
- Varsayılan kurulumda yalnızca çekirdek bileşenler yer alır.
- Lisansı belirsiz veya uyumu net olmayan uygulamalar **otomatik kurulmaz**.

## Teknik notlar
- Opsiyonel modüller için pinler: `infra/versions.env`
- Kurulum komutları: `scripts/windows/04-uygulamalari-kur.ps1`
- Dokümantasyon ve lisans kayıtları: `THIRD_PARTY_NOTICES.md`
