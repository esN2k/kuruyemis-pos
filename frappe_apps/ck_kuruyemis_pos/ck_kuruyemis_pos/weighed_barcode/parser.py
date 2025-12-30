from dataclasses import dataclass
from decimal import Decimal
from typing import Optional, Sequence


@dataclass(frozen=True)
class WeighedBarcodeRule:
    name: str
    barcode_length: int
    prefix: str
    item_code_start: int
    item_code_length: int
    weight_start: Optional[int] = None
    weight_length: Optional[int] = None
    weight_divisor: int = 1000
    price_start: Optional[int] = None
    price_length: Optional[int] = None
    price_divisor: int = 100
    check_ean13: bool = True
    item_code_prefix: str = ""
    item_code_strip_leading_zeros: bool = False
    priority: int = 0


@dataclass(frozen=True)
class ParsedWeighedBarcode:
    barcode: str
    item_code: str
    raw_item_code: str
    weight: Optional[Decimal]
    price: Optional[Decimal]
    rule_name: str


SCALE_DIVISORS = {
    "grams": 1000,
    "kilograms": 1,
    "cents": 100,
    "lira": 1,
}


def divisor_for_scale_unit(unit: Optional[str]) -> Optional[int]:
    if not unit:
        return None
    return SCALE_DIVISORS.get(unit.strip().lower())


def ean13_check_digit(body: str) -> str:
    if len(body) != 12 or not body.isdigit():
        raise ValueError("EAN-13 body must be 12 digits")
    digits = [int(ch) for ch in body]
    odd_sum = sum(digits[::2])
    even_sum = sum(digits[1::2])
    total = odd_sum + (even_sum * 3)
    check = (10 - (total % 10)) % 10
    return str(check)


def ean13_is_valid(barcode: str) -> bool:
    if len(barcode) != 13 or not barcode.isdigit():
        return False
    return barcode[-1] == ean13_check_digit(barcode[:-1])


def _slice_segment(barcode: str, start: Optional[int], length: Optional[int]) -> Optional[str]:
    if not start or not length:
        return None
    if start <= 0 or length <= 0:
        return None
    start_idx = start - 1
    end_idx = start_idx + length
    if end_idx > len(barcode):
        return None
    return barcode[start_idx:end_idx]


def _apply_item_code_rules(raw_item_code: str, rule: WeighedBarcodeRule) -> str:
    item_code = raw_item_code
    if rule.item_code_strip_leading_zeros:
        item_code = item_code.lstrip("0") or "0"
    if rule.item_code_prefix:
        item_code = f"{rule.item_code_prefix}{item_code}"
    return item_code


def _parse_decimal_segment(segment: Optional[str], divisor: int) -> Optional[Decimal]:
    if segment is None:
        return None
    if not segment.isdigit():
        return None
    if divisor <= 0:
        return None
    return Decimal(segment) / Decimal(divisor)


def parse_weighed_barcode(barcode: str, rules: Sequence[WeighedBarcodeRule]) -> Optional[ParsedWeighedBarcode]:
    candidate = barcode.strip()
    if not candidate.isdigit():
        return None

    for rule in sorted(rules, key=lambda r: r.priority, reverse=True):
        if rule.barcode_length and len(candidate) != rule.barcode_length:
            continue
        if rule.prefix and not candidate.startswith(rule.prefix):
            continue
        if rule.check_ean13 and rule.barcode_length == 13 and not ean13_is_valid(candidate):
            continue

        raw_item_code = _slice_segment(candidate, rule.item_code_start, rule.item_code_length)
        if raw_item_code is None:
            continue

        item_code = _apply_item_code_rules(raw_item_code, rule)
        weight_segment = _slice_segment(candidate, rule.weight_start, rule.weight_length)
        price_segment = _slice_segment(candidate, rule.price_start, rule.price_length)

        weight = _parse_decimal_segment(weight_segment, rule.weight_divisor)
        price = _parse_decimal_segment(price_segment, rule.price_divisor)

        if weight is None and price is None:
            continue

        return ParsedWeighedBarcode(
            barcode=candidate,
            item_code=item_code,
            raw_item_code=raw_item_code,
            weight=weight,
            price=price,
            rule_name=rule.name,
        )

    return None
