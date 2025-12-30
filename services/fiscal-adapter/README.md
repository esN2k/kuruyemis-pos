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

## TODO
- Implement GMP3 message framing and device communication.
- Add retries, timeouts, and error handling based on GMP3 spec.
- Secure the service before production use.