# QZ Tray Printing

QZ Tray is a desktop bridge between the browser and local printers. It exposes a local WebSocket endpoint that the browser connects to, and it can accept raw printer language commands (ESC/POS, ZPL, TSPL, EPL).

## Where the demos live
- QZ Tray ships with demo files in `C:\Program Files\QZ Tray\demo\` (Windows default install path), including `sample.html`.
- The official online demo is at `https://demo.qz.io/` (it will talk to your local QZ Tray service).
- In this repo, our JS wrapper and examples live under:
  - `frappe_apps/ck_kuruyemis_pos/ck_kuruyemis_pos/public/js/qz/`

## Windows setup (store PC)
1) Install QZ Tray from `https://qz.io/download/`.
2) Start QZ Tray and keep it running (tray icon must be visible).
3) Open the demo at `https://demo.qz.io/` and run the sample print to confirm browser-to-printer works.
4) In QZ Tray settings, allow unsigned requests for dev. For production, you must configure signing.

## Dev setup (local)
1) Download `qz-tray.js` using the script (this also records the checksum):

```powershell
./scripts/get-qz-tray.ps1
```

2) For Linux/macOS:

```bash
./scripts/get-qz-tray.sh
```

3) Build assets (if needed by your Frappe setup):

```powershell
cd infra
./start-dev.ps1
```

4) Navigate to POS Awesome (`/app/posawesome`). Use the toolbar/menu actions:
   - Print Non-Fiscal Receipt
   - Print Shelf Label

5) Use the Printer Setup page to list printers and set defaults:
   - `/app/pos_printer_setup` (or open "POS Printer Setup" from the Awesome Bar)

Defaults are stored in the `POS Printing Settings` single DocType.

## Message signing (high level)
- QZ Tray supports signed requests using a client certificate + private key.
- In development, you can enable "Allow unsigned" in QZ Tray settings and use unsigned requests.
- In production, the browser must sign requests and QZ Tray must trust the certificate.
- Our wrapper uses unsigned mode by default. This is fine for development, but NOT for production.

## Notes
- If you see "WebSocket connection failed", check firewall or QZ Tray service status.
- Ensure the printer names match your Windows printer names; defaults are stored in `POS Printing Settings`.

## Checksum
<!-- QZ_TRAY_SHA256_START -->
- Version: v2.2.5
- SHA256: dc9fe4b0a32b412e015acab93ca4e29462b61b2f4c33c044e3d3b1ba3f4052fc
<!-- QZ_TRAY_SHA256_END -->

This section is updated by the download scripts to record the exact `qz-tray.js` hash.

