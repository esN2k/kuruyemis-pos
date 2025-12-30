# 09 - Sürüm Notları ve Pin Politikası

## Pin Politikası
- `infra/versions.md` ve `infra/versions.env` **tek doğruluk kaynağıdır**
- Frappe/ERPNext/POS Awesome güncellemeleri **birlikte** yapılır
- QZ Tray sürümü ayrıca pinlenir

## Sürümleme
- Uygulama sürümü semantik sürümleme formatındadır (ör. `1.2.0`)
- Her sürümde:
  - Doküman güncellemesi
  - CI (pytest + lint/format) yeşil
  - `05-doctor.ps1` ve `09-smoke-test.ps1` başarılı

## Notlar
- Üretim öncesi `docs/08-acilis-checklist.md` tamamlanmalıdır.
