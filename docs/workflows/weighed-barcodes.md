# Weighed Barcodes (CAS CL3000 Concepts)

CAS CL3000 uses configurable barcode formats and format symbols that map segments to meanings (item code, weight, or price). Our parser config mirrors this by defining segments and their meaning.

## Typical EAN-13 weighed layouts
Common pattern (13 digits):
- Prefix (2 digits): scale or format prefix
- Item code (5 digits): PLU or internal item code
- Value (5 digits): weight or price
- Check digit (1 digit)

In our config:
- `segment_type = item_code` maps the PLU segment.
- `segment_type = weight` maps a weight segment.
- `segment_type = price` maps a price segment.

## Segment scale units
- Weight: `grams` (divisor 1000) or `kilograms` (divisor 1)
- Price: `cents` (divisor 100) or `lira` (divisor 1)

## Default rule presets

### Preset A: Prefix + ItemCode + Weight + Check (grams)
- Prefix: `21`
- Item code: start 3, length 5
- Weight: start 8, length 5, scale unit `grams`
- Check digit: enabled

Sample barcode (passes tests): `2112345001500`

### Preset B: Prefix + ItemCode + Price + Check (cents)
- Prefix: `22`
- Item code: start 3, length 5
- Price: start 8, length 5, scale unit `cents`
- Check digit: enabled

Sample barcode (passes tests): `2254321012343`

## Notes
- If you prefer the older fixed fields, you can still set `weight_start`/`price_start` and `weight_divisor`/`price_divisor`.
- When the `Segments` table is filled, it takes precedence for parsing.
