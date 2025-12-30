# Printing Workflow (QZ Tray Demo)

## Goal
Verify non-fiscal receipt and shelf label printing through QZ Tray from POS Awesome.

## Demo flow
1) Start QZ Tray and ensure it is running (tray icon visible).
2) Ensure `qz-tray.js` is placed at:
   - `frappe_apps/ck_kuruyemis_pos/ck_kuruyemis_pos/public/js/qz/vendor/qz-tray.js`
3) Open POS Awesome (`/app/posawesome`).
4) Use the demo panel to print:
   - Non-fiscal receipt (ZY907)
   - Shelf label 38x80 (X-Printer 490B)

## Notes
- If your printer name differs, update `window.ck_qz_settings` in the browser console:
  - `window.ck_qz_settings = { receiptPrinter: "<printer>", labelPrinter: "<printer>" }`
- These are demo payloads only; replace with real templates later.