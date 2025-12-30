# Kuruyemis Workflows

## Weighed label -> scan -> sale (store flow)
1) Customer selects bulk product; CL3000 prints a barcode label with embedded PLU + weight/price.
2) Cashier scans the label in POS Awesome.
3) Weighed barcode parser resolves the Item by `scale_plu` and sets quantity/price automatically.
4) Cashier completes sale in POS.
5) Fiscal receipt is printed manually on INPOS M530 (MVP).
6) Optional non-fiscal receipt is printed via QZ Tray.
7) Stock is decremented in ERPNext after the sale is submitted.

## Returns
- Locate original invoice, scan item barcode, and refund or replace per store policy.

## Discounts
- Line or cart discounts applied by authorized staff only (role-based permission in ERPNext).
