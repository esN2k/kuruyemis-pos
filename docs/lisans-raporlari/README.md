# Lisans Raporları

Bu klasör, bağımlılık lisans raporlarını saklar.

## Neden var?
- Üçüncü parti lisanslarını görünür kılar.
- "Unknown / belirsiz" lisansları tespit eder.
- Üretim öncesi lisans uyumluluğunu doğrular.

## Nasıl üretilir?
Windows:
```powershell
.\scripts\windows\10-lisans-raporu.ps1
```
Belirsiz lisanslara geçici izin vermek için:
```powershell
.\scripts\windows\10-lisans-raporu.ps1 -BelirsizLisanslaraIzinVer
```
Not: Script varsayılan olarak belirsiz lisans tespit ederse hata verir.

## CI nasıl çalışır?
GitHub Actions `lisans-raporu.yml` workflow'u raporları üretir ve artifact olarak yükler. İsteğe bağlı olarak raporlar değiştiyse otomatik PR açar.

## "Unknown / belirsiz lisans" çıkarsa ne yapılır?
- Varsayılan kurulumdan çıkarılır veya "opsiyonel" yapılır.
- Dokümantasyonda açıkça not düşülür.
- Mümkünse lisansı net bir alternatif tercih edilir.
