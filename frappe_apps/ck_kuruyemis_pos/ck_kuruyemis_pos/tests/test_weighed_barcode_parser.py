from decimal import Decimal

from ck_kuruyemis_pos.weighed_barcode.parser import (
    ean13_check_digit,
    ean13_is_valid,
    parse_weighed_barcode,
    WeighedBarcodeRule,
)


def _make_ean13(body: str) -> str:
    return f"{body}{ean13_check_digit(body)}"


def test_parse_weight_barcode():
    rule = WeighedBarcodeRule(
        name="CL3000-weight",
        barcode_length=13,
        prefix="21",
        item_code_start=3,
        item_code_length=5,
        weight_start=8,
        weight_length=5,
        weight_divisor=1000,
        check_ean13=True,
    )

    body = "21" + "12345" + "00150"
    barcode = _make_ean13(body)

    parsed = parse_weighed_barcode(barcode, [rule])

    assert parsed is not None
    assert parsed.item_code == "12345"
    assert parsed.weight == Decimal("0.150")
    assert parsed.price is None


def test_parse_price_barcode():
    rule = WeighedBarcodeRule(
        name="CL3000-price",
        barcode_length=13,
        prefix="21",
        item_code_start=3,
        item_code_length=5,
        price_start=8,
        price_length=5,
        price_divisor=100,
        check_ean13=True,
    )

    body = "21" + "54321" + "01234"
    barcode = _make_ean13(body)

    parsed = parse_weighed_barcode(barcode, [rule])

    assert parsed is not None
    assert parsed.item_code == "54321"
    assert parsed.price == Decimal("12.34")
    assert parsed.weight is None


def test_strip_leading_zeros_and_prefix():
    rule = WeighedBarcodeRule(
        name="strip-zero",
        barcode_length=13,
        prefix="21",
        item_code_start=3,
        item_code_length=5,
        weight_start=8,
        weight_length=5,
        weight_divisor=1000,
        item_code_prefix="ITM-",
        item_code_strip_leading_zeros=True,
        check_ean13=True,
    )

    body = "21" + "00042" + "00010"
    barcode = _make_ean13(body)

    parsed = parse_weighed_barcode(barcode, [rule])

    assert parsed is not None
    assert parsed.item_code == "ITM-42"
    assert parsed.weight == Decimal("0.010")


def test_invalid_checksum_rejected():
    rule = WeighedBarcodeRule(
        name="checksum",
        barcode_length=13,
        prefix="21",
        item_code_start=3,
        item_code_length=5,
        weight_start=8,
        weight_length=5,
        weight_divisor=1000,
        check_ean13=True,
    )

    body = "21" + "12345" + "00150"
    barcode = _make_ean13(body)
    bad_digit = "0" if barcode[-1] != "0" else "1"
    bad_barcode = barcode[:-1] + bad_digit

    assert ean13_is_valid(bad_barcode) is False
    assert parse_weighed_barcode(bad_barcode, [rule]) is None


def test_non_digit_barcode_rejected():
    rule = WeighedBarcodeRule(
        name="digits",
        barcode_length=13,
        prefix="21",
        item_code_start=3,
        item_code_length=5,
        weight_start=8,
        weight_length=5,
        weight_divisor=1000,
        check_ean13=True,
    )

    assert parse_weighed_barcode("21ABC", [rule]) is None
