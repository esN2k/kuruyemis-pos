# Architecture Overview

## Core stack (mandatory)
- ERPNext (Frappe) as backend and POS core
- POS Awesome as cashier UI (touchscreen with item images)
- QZ Tray as the browser-to-printer bridge

## Local services
- Optional hardware bridge service for serial/USB devices (planned)
- Fiscal adapter stub service for INPOS M530 (planned)

## Data flow (high-level)
1) POS Awesome calls ERPNext APIs to search items and build carts.
2) Weighed barcode scans are parsed in a custom Frappe app and routed to the correct item + weight.
3) Printing is handled in the browser via QZ Tray with raw templates.
4) Fiscal printing is manual in MVP; adapter planned via GMP3 protocol.