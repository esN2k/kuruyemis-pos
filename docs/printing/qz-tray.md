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
1) Download `qz-tray.js` from the QZ Tray release assets (same version as your tray app).
2) Place it here so Frappe can serve it:
   - `frappe_apps/ck_kuruyemis_pos/ck_kuruyemis_pos/public/js/qz/vendor/qz-tray.js`
3) Build assets (if needed by your Frappe setup):

```powershell
cd infra
./start-dev.ps1
```

4) Navigate to POS Awesome (`/app/posawesome`). A small demo panel appears with two buttons:
   - Non-fiscal receipt
   - Shelf label

## Message signing (high level)
- QZ Tray supports signed requests using a client certificate + private key.
- In development, you can enable "Allow unsigned" in QZ Tray settings and use unsigned requests.
- In production, the browser must sign requests and QZ Tray must trust the certificate.
- Our wrapper uses unsigned mode by default. This is fine for development, but NOT for production.

## Notes
- If you see "WebSocket connection failed", check firewall or QZ Tray service status.
- Ensure the printer names match your Windows printer names; the demo buttons use defaults that you can change in JS.
