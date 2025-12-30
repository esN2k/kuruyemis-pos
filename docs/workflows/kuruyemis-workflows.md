# Kuruyemis Workflows

## Weighed label -> scan -> sale
1) Customer selects bulk product; CL3000 prints a barcode label with embedded item code + weight.
2) Cashier scans the label in POS Awesome.
3) Weighed barcode parser resolves item + quantity automatically.
4) Sale proceeds with correct weight and pricing.

## Returns
- Locate original invoice, scan item barcode, and refund or replace per store policy.

## Discounts
- Line or cart discounts applied by authorized staff only (role-based permission in ERPNext).