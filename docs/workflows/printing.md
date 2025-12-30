# Printing Workflow (QZ Tray Demo)

## Goal
Verify non-fiscal receipt and shelf label printing through QZ Tray from POS Awesome.

## Demo flow
1) Start QZ Tray and ensure it is running (tray icon visible).
2) Download `qz-tray.js`:
   - `./scripts/get-qz-tray.ps1` (Windows)
   - `./scripts/get-qz-tray.sh` (Linux/macOS)
3) Open the Printer Setup page (`/app/pos_printer_setup`) or search "POS Printer Setup" in the Awesome Bar to list printers and set defaults.
4) Open POS Awesome (`/app/posawesome`).
5) Use the toolbar/menu actions to print:
   - Non-fiscal receipt (ZY907)
   - Shelf label 38x80 (X-Printer 490B)

## Notes
- If your printer name differs, update defaults in `POS Printing Settings` or via `/app/pos_printer_setup`.
- These are demo payloads only; replace with real templates later.
