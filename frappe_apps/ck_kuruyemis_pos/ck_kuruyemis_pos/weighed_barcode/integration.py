from typing import List, Optional

import frappe
from erpnext.stock.get_item_details import get_item_details as erpnext_get_item_details

from ck_kuruyemis_pos.weighed_barcode.parser import (
    ParsedWeighedBarcode,
    WeighedBarcodeRule,
    parse_weighed_barcode,
)


def _load_rules_from_db() -> List[WeighedBarcodeRule]:
    rows = frappe.get_all(
        "Weighed Barcode Rule",
        filters={"enabled": 1},
        fields=[
            "name",
            "rule_name",
            "priority",
            "barcode_length",
            "prefix",
            "item_code_start",
            "item_code_length",
            "item_code_prefix",
            "item_code_strip_leading_zeros",
            "weight_start",
            "weight_length",
            "weight_divisor",
            "price_start",
            "price_length",
            "price_divisor",
            "check_ean13",
        ],
        order_by="priority desc, name asc",
    )

    rules: List[WeighedBarcodeRule] = []
    for row in rows:
        rule_name = row.get("rule_name") or row.get("name")
        rules.append(
            WeighedBarcodeRule(
                name=rule_name,
                barcode_length=int(row.get("barcode_length") or 0),
                prefix=(row.get("prefix") or ""),
                item_code_start=int(row.get("item_code_start") or 0),
                item_code_length=int(row.get("item_code_length") or 0),
                weight_start=int(row.get("weight_start") or 0) or None,
                weight_length=int(row.get("weight_length") or 0) or None,
                weight_divisor=int(row.get("weight_divisor") or 1000),
                price_start=int(row.get("price_start") or 0) or None,
                price_length=int(row.get("price_length") or 0) or None,
                price_divisor=int(row.get("price_divisor") or 100),
                check_ean13=bool(row.get("check_ean13")),
                item_code_prefix=row.get("item_code_prefix") or "",
                item_code_strip_leading_zeros=bool(row.get("item_code_strip_leading_zeros")),
                priority=int(row.get("priority") or 0),
            )
        )
    return rules


def _resolve_item_code(parsed: ParsedWeighedBarcode) -> Optional[str]:
    if not parsed.item_code:
        return None

    if frappe.db.exists("Item", parsed.item_code):
        return parsed.item_code

    parent = frappe.db.get_value("Item Barcode", {"barcode": parsed.item_code}, "parent")
    if parent:
        return parent

    return None


@frappe.whitelist()
def get_item_details(*args, **kwargs):
    barcode = kwargs.get("barcode") or kwargs.get("item_code")
    if barcode:
        parsed = parse_weighed_barcode(barcode, _load_rules_from_db())
        if parsed:
            resolved_item_code = _resolve_item_code(parsed)
            if resolved_item_code:
                kwargs["item_code"] = resolved_item_code
                if parsed.weight is not None:
                    kwargs["qty"] = float(parsed.weight)
                kwargs.pop("barcode", None)
                kwargs["scanned_barcode"] = barcode
    return erpnext_get_item_details(*args, **kwargs)
