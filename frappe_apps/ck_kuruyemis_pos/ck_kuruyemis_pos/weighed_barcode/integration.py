from typing import List, Optional

import frappe
from erpnext.stock.get_item_details import get_item_details as erpnext_get_item_details

from ck_kuruyemis_pos.weighed_barcode.parser import (
    ParsedWeighedBarcode,
    WeighedBarcodeRule,
    ean13_is_valid,
    divisor_for_scale_unit,
    parse_weighed_barcode,
    _slice_segment,
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
            "item_code_target",
            "item_code_prefix",
            "item_code_strip_leading_zeros",
            "weight_start",
            "weight_length",
            "weight_divisor",
            "weight_scale_unit",
            "price_start",
            "price_length",
            "price_divisor",
            "price_scale_unit",
            "check_ean13",
        ],
        order_by="priority desc, name asc",
    )

    rules: List[WeighedBarcodeRule] = []
    for row in rows:
        rule_name = row.get("rule_name") or row.get("name")

        item_code_start = int(row.get("item_code_start") or 0)
        item_code_length = int(row.get("item_code_length") or 0)
        item_code_target = (row.get("item_code_target") or "scale_plu").strip().lower()
        weight_start = int(row.get("weight_start") or 0) or None
        weight_length = int(row.get("weight_length") or 0) or None
        weight_divisor = int(row.get("weight_divisor") or 1000)
        price_start = int(row.get("price_start") or 0) or None
        price_length = int(row.get("price_length") or 0) or None
        price_divisor = int(row.get("price_divisor") or 100)

        weight_scale_divisor = divisor_for_scale_unit(row.get("weight_scale_unit"))
        if weight_scale_divisor is not None:
            weight_divisor = weight_scale_divisor

        price_scale_divisor = divisor_for_scale_unit(row.get("price_scale_unit"))
        if price_scale_divisor is not None:
            price_divisor = price_scale_divisor

        try:
            doc = frappe.get_doc("Weighed Barcode Rule", row.get("name"))
        except Exception:
            doc = None

        if doc and getattr(doc, "segments", None):
            for segment in doc.segments:
                seg_type = (segment.segment_type or "").strip().lower()
                seg_start = int(segment.start or 0)
                seg_length = int(segment.length or 0)
                if seg_start <= 0 or seg_length <= 0:
                    continue

                seg_divisor = divisor_for_scale_unit(segment.scale_unit)

                if seg_type == "item_code":
                    item_code_start = seg_start
                    item_code_length = seg_length
                elif seg_type == "weight":
                    weight_start = seg_start
                    weight_length = seg_length
                    if seg_divisor is not None:
                        weight_divisor = seg_divisor
                elif seg_type == "price":
                    price_start = seg_start
                    price_length = seg_length
                    if seg_divisor is not None:
                        price_divisor = seg_divisor

        rules.append(
            WeighedBarcodeRule(
                name=rule_name,
                barcode_length=int(row.get("barcode_length") or 0),
                prefix=(row.get("prefix") or ""),
                item_code_start=item_code_start,
                item_code_length=item_code_length,
                item_code_target=item_code_target,
                weight_start=weight_start,
                weight_length=weight_length,
                weight_divisor=weight_divisor,
                price_start=price_start,
                price_length=price_length,
                price_divisor=price_divisor,
                check_ean13=bool(row.get("check_ean13")),
                item_code_prefix=row.get("item_code_prefix") or "",
                item_code_strip_leading_zeros=bool(row.get("item_code_strip_leading_zeros")),
                priority=int(row.get("priority") or 0),
            )
        )
    return rules


def _resolve_item_code(parsed: ParsedWeighedBarcode) -> Optional[str]:
    if parsed.item_code_target == "scale_plu":
        plu_match = frappe.db.get_value("Item", {"scale_plu": parsed.raw_item_code}, "name")
        if plu_match:
            return plu_match

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


@frappe.whitelist()
def validate_weighed_barcode(barcode: str) -> dict:
    candidate = (barcode or "").strip()
    if not candidate:
        return {
            "ok": False,
            "message": frappe._("Barkod boş olamaz."),
            "hint": frappe._("Örnek: 2012345001501"),
        }
    if not candidate.isdigit():
        return {
            "ok": False,
            "message": frappe._("Barkod sadece rakamlardan oluşmalıdır."),
            "hint": frappe._("Örnek: 2012345001501"),
        }
    if len(candidate) != 13:
        return {
            "ok": False,
            "message": frappe._("Barkod 13 haneli olmalıdır."),
            "hint": frappe._("Örnek: 2012345001501"),
        }

    rules = _load_rules_from_db()
    parsed = parse_weighed_barcode(candidate, rules)
    if not parsed:
        if not ean13_is_valid(candidate):
            return {
                "ok": False,
                "message": frappe._("EAN-13 kontrol basamağı hatalı."),
                "hint": frappe._("Etiket doğru basıldı mı kontrol edin."),
            }
        return {
            "ok": False,
            "message": frappe._("Barkod hiçbir kuralla eşleşmedi."),
            "hint": frappe._("Prefix 20 (ağırlık) veya 21 (fiyat) olmalı."),
        }

    matched_rule = next((rule for rule in rules if rule.name == parsed.rule_name), None)
    weight_segment = _slice_segment(
        candidate,
        matched_rule.weight_start if matched_rule else None,
        matched_rule.weight_length if matched_rule else None,
    )
    price_segment = _slice_segment(
        candidate,
        matched_rule.price_start if matched_rule else None,
        matched_rule.price_length if matched_rule else None,
    )

    return {
        "ok": True,
        "rule_name": parsed.rule_name,
        "prefix": matched_rule.prefix if matched_rule else "",
        "item_code_target": parsed.item_code_target,
        "raw_item_code": parsed.raw_item_code,
        "item_code": parsed.item_code,
        "weight": str(parsed.weight) if parsed.weight is not None else None,
        "price": str(parsed.price) if parsed.price is not None else None,
        "weight_segment": weight_segment,
        "price_segment": price_segment,
        "weight_divisor": matched_rule.weight_divisor if matched_rule else None,
        "price_divisor": matched_rule.price_divisor if matched_rule else None,
    }
