# Mali Adaptör (Taslak)

INPOS M530 mali adaptörü için FastAPI taslağıdır.

## Çalıştırma (geliştirme)
```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8090
```

## Endpoint'ler
- `GET /health`
- `POST /fiscal/sale`

## Ortam Değişkenleri
- `FISCAL_DEVICE_IP` (varsayılan `192.168.1.50`)
- `FISCAL_DEVICE_PORT` (varsayılan `9100`)
- `FISCAL_APP_NO` (varsayılan `1`)
- `FISCAL_TIMEOUT_SECONDS` (varsayılan `5`)

## Yapılacaklar
- GMP3 mesaj çerçeveleme ve cihaz iletişimi
- Retry, timeout ve hata yönetimi
- Üretim öncesi güvenlik sertifikası
