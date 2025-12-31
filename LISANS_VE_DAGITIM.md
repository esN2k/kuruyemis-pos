# Lisans ve Dağıtım Politikası

## 1) Bu proje ne amaçla var?
Bu proje; küçük/orta ölçekli işletmelerin (KOBİ) satış, stok ve yazdırma ihtiyaçlarını karşılamak için açık kaynak bir POS çözümü geliştirmeyi hedefler. Amacımız:
- İşletmelerin sistemi kendi ihtiyacına göre uyarlayabilmesi,
- Mühendislik öğrenimi ve topluluk katkısıyla sürdürülebilir bir çözüm oluşturmak,
- Kurulum, bakım ve işletim süreçlerini anlaşılır şekilde dokümante etmektir.

> Not: Bu doküman hukuki tavsiye değildir. Lisanslarla ilgili ciddi/özel bir durumda profesyonel danışmanlık alın.

---

## 2) Projemizin lisansı
Bu repodaki **kendi geliştirdiğimiz tüm kodlar** GNU GPL v3 (veya daha yeni sürümler) altında yayınlanır.

- Kodumuzu kullanabilir, değiştirebilir, dağıtabilir ve kendi işinizde çalıştırabilirsiniz.
- Dağıtım yaptığınızda GPL'in "kaynağı paylaşma, lisans metnini koruma, değişiklikleri belirtme" gibi yükümlülükleri devreye girer.

---

## 3) Üçüncü parti (3rd-party) bileşenler
Bu proje; aşağıdaki açık kaynak bileşenleri çekirdek olarak kullanır:

- ERPNext (GPL v3)
- POS Awesome V15 (GPL v3)
- QZ Tray (LGPL 2.1)
  - QZ Tray API/demo örnekleri (örn. sample.html) kamu malı (Public Domain) olabilir.
  - qz.io üzerinden indirilen bazı binary dağıtımlarda "Premium Support / sertifika" modeli bulunabilir.

Opsiyonel modüller (varsayılan kurulumda yok):
- Frappe BetterPrint (AGPL v3)
- AgriTheory Beam (MIT)
- Scan Me (MIT)
- Silent-Print-ERPNext (MIT)
- Webapp Hardware Bridge (MIT)
- WhatsApp entegrasyonları (MIT)

Tüm üçüncü parti bileşenler için:
- Repoda `THIRD_PARTY_NOTICES.md` dosyası tutulur.
- Her bağımlılık için lisans bilgisi ve kaynak bağlantısı listelenir.
- Lisans dosyaları (LICENSE vb.) korunur.

---

## 4) Bağımlılık ekleme kuralımız
Yeni bir kütüphane/araç eklerken şu kurallar uygulanır:

1) **Lisansı açık ve net olmalı.** (MIT/Apache-2.0/BSD/GPL/LGPL vb.)
2) **GPL uyumluluğu** göz önünde bulundurulmalı.
3) Lisans "Unknown / belirsiz / çoklu ve çelişkili" görünüyorsa:
   - Varsayılan kurulumdan çıkarılır,
   - "Opsiyonel özellik" olarak bayraklanır,
   - `THIRD_PARTY_NOTICES.md` ve dokümantasyonda açıkça not düşülür.

---

## 5) Lisans raporları
Bu repo lisans raporlarını otomatik üretir:
- Windows: `.\scripts\windows\10-lisans-raporu.ps1`
- CI: `lisans-raporu.yml`

Raporlar `docs/lisans-raporlari/` altında tutulur.

---

## 6) Ticari marka ve isimlendirme
Bazı upstream projelerin (örn. ERPNext) isim/logo gibi öğeleri ticari marka olabilir. Bu nedenle:
- Bu projeyi kendi markamızla yayınlarız.
- Upstream marka/logolarını, ilgili projenin ticari marka politikasına aykırı şekilde kullanmayız.
- Ekran görüntüsü, doküman, tanıtım vb. içerikte "Kaynak/Atıf" bilgisini koruruz.

---

## 7) Dağıtım ve "toplu çalışır" hedefi
Bu repo "toplu çalışır" bir kurulum hedefler:
- Kurulum scriptleri, check-list'ler, doktor/smoke testler ve dokümantasyon repoda yer alır.
- Uygulama; işletmede yerel ağda (LAN) çalışacak şekilde tasarlanır.
- Gerekli açık kaynak bileşenler mümkün olduğunca otomatik kurulumla indirilir/doğrulanır.

---

## 8) Katkı (Contributing) ilkeleri
- Her katkı (PR) "GPL v3 uyumlu" olarak kabul edilir.
- Katkılarda:
  - Kod kalitesi (test/lint),
  - Türkçe kullanıcı metinleri/doküman standardı,
  - Donanım/iş akışı uyumluluğu,
  - Kurulumun bozulmaması (doctor + smoke) şarttır.

---

## 9) Şeffaflık ve destek
Hata/öneri için:
- Issue açın (hata adımları + beklenen/gerçek sonuç + log).
- "Destek paketi" (support bundle) çıktısını ekleyin.
- Donanım modeli ve bağlantı tipi (USB/RS232/Ethernet) bilgisini ekleyin.

Teşekkürler - hedefimiz "kimsenin mecbur kalmadığı", pratik ve güvenilir bir açık kaynak POS ekosistemi oluşturmaktır.
