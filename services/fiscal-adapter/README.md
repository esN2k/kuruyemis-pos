# Fiscal Adapter (Stub)

This is a stub FastAPI service for the INPOS M530 fiscal adapter.

## Run (dev)
```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8090
```

## Endpoints
- `GET /health`
- `POST /fiscal/sale`

## Environment
- `FISCAL_DEVICE_IP` (default `192.168.1.50`)
- `FISCAL_DEVICE_PORT` (default `9100`)
- `FISCAL_APP_NO` (default `1`)
- `FISCAL_TIMEOUT_SECONDS` (default `5`)

## TODO
- Implement GMP3 message framing and device communication.
- Add retries, timeouts, and error handling based on GMP3 spec.
- Secure the service before production use.
