import json
from pathlib import Path

import frappe


DATA_DIR = Path(__file__).parent / "demo_data"
PLACEHOLDER_IMAGE = "/assets/ck_kuruyemis_pos/images/placeholder.svg"


def _load_json(name: str) -> list:
    path = DATA_DIR / name
    if not path.exists():
        return []
    return json.loads(path.read_text(encoding="utf-8"))


def _ensure_item_groups(groups: list) -> int:
    created = 0
    for group in groups:
        if frappe.db.exists("Item Group", group.get("name")):
            continue
        frappe.get_doc({"doctype": "Item Group", **group}).insert(ignore_permissions=True)
        created += 1
    return created


def _ensure_item_prices(items: list, price_list: str) -> int:
    created = 0
    if not frappe.db.exists("Price List", price_list):
        return created

    for item in items:
        if not item.get("price"):
            continue
        if frappe.db.exists(
            "Item Price", {"item_code": item["item_code"], "price_list": price_list}
        ):
            continue
        frappe.get_doc(
            {
                "doctype": "Item Price",
                "item_code": item["item_code"],
                "price_list": price_list,
                "price_list_rate": item["price"],
                "selling": 1,
            }
        ).insert(ignore_permissions=True)
        created += 1
    return created


@frappe.whitelist()
def load_demo_data() -> dict:
    groups = _load_json("item_groups.json")
    items = _load_json("items.json")

    created = {
        "item_groups": _ensure_item_groups(groups),
        "items": 0,
        "prices": 0,
    }

    for item in items:
        if frappe.db.exists("Item", item.get("item_code")):
            continue
        doc = frappe.get_doc(
            {
                "doctype": "Item",
                "item_code": item["item_code"],
                "item_name": item["item_name"],
                "item_group": item["item_group"],
                "stock_uom": item["stock_uom"],
                "is_stock_item": 1,
                "image": PLACEHOLDER_IMAGE,
            }
        )
        if item.get("scale_plu"):
            doc.scale_plu = item["scale_plu"]
        doc.insert(ignore_permissions=True)
        created["items"] += 1

    created["prices"] = _ensure_item_prices(items, "Standard Selling")

    frappe.db.commit()
    return {
        "ok": True,
        "created": created,
        "message": frappe._("Demo verileri yüklendi."),
    }
