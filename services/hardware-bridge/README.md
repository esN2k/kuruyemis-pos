# Hardware Bridge (Stub)

Placeholder FastAPI service for serial/USB device bridging (scales, barcode scanners, etc).

## Run (dev)
```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8091
```

## Endpoints
- `GET /health`

## TODO
- Implement pyserial device discovery and read loops.
- Provide device-specific parsing for CL3000 and ER-JR scales.