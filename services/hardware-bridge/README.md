# Donanım Köprüsü (Taslak)

Seri port / USB cihazları için FastAPI tabanlı köprü hizmeti.

## Çalıştırma (geliştirme)
```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8091
```

## Endpoint'ler
- `GET /health`

## Notlar
- RS‑232 cihazlar için `pyserial` kullanılır
- Üretim öncesi erişim kontrolü eklenmelidir
