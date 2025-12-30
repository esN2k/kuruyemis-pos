# Kuruyemis POS (ERPNext + POS Awesome)

OSS-first POS stack for a Turkish dried nuts retailer (kuruyemis). Core stack:
- ERPNext (Frappe)
- POS Awesome
- QZ Tray (browser-to-printer)

## MVP Demo Checklist
- Run Docker stack (`./scripts/bootstrap-frappe-docker.ps1`, then `cd infra; ./start-dev.ps1`)
- Create a site (`./new-site.ps1 -SiteName kuruyemis.local -AdminPassword admin -MariaDBRootPassword admin`)
- Install apps (`./install-apps.ps1 -SiteName kuruyemis.local`)
- Download `qz-tray.js` (`./scripts/get-qz-tray.ps1` or `./scripts/get-qz-tray.sh`)
- Configure printer defaults (`/app/pos_printer_setup`)
- Create a weighed barcode rule (use presets in `docs/workflows/weighed-barcodes.md`)
- Scan a sample weighed barcode and verify qty auto-fills in POS
- Print non-fiscal receipt via QZ Tray demo button
- Print shelf label 38x80 via QZ Tray demo button
