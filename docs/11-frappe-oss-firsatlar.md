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

## 5) ERPGulf/GPos
- Ne işe yarar? Alternatif POS yaklaşımı (ERPNext için başka bir POS uygulaması).
- Mağazamıza faydası: Uzun vadede kıyas/alternatif.
- Riskler: POS Awesome ile çatışma, kullanıcı eğitim maliyeti, UX farklılığı.
- Lisans: **MIT**
- Kurulum şekli: **şimdilik yok** (yalnızca değerlendirme)
- Öncelik: **Düşük** (mevcut POS Awesome odaklıyız)

## Kurulum politikası
- Opsiyonel modüller yalnızca **ihtiyaç halinde** açılır.
- Varsayılan kurulumda yalnızca çekirdek bileşenler yer alır.
- Lisansı belirsiz veya uyumu net olmayan uygulamalar **otomatik kurulmaz**.

## Teknik notlar
- Opsiyonel modüller için pinler: `infra/versions.env`
- Kurulum komutları: `scripts/windows/04-uygulamalari-kur.ps1`
- Dokümantasyon ve lisans kayıtları: `THIRD_PARTY_NOTICES.md`
