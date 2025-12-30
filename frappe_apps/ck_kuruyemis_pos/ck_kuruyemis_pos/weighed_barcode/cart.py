from dataclasses import dataclass
from decimal import Decimal
from typing import Iterable, Optional

from ck_kuruyemis_pos.weighed_barcode.parser import ParsedWeighedBarcode


@dataclass(frozen=True)
class ItemRef:
    item_code: str
    scale_plu: Optional[str] = None


def resolve_item_code(parsed: ParsedWeighedBarcode, items: Iterable[ItemRef]) -> Optional[str]:
    if parsed.item_code_target == "scale_plu":
        for item in items:
            if item.scale_plu == parsed.raw_item_code:
                return item.item_code
        return None

    for item in items:
        if item.item_code == parsed.item_code:
            return item.item_code
    return None


def build_cart_line(parsed: ParsedWeighedBarcode, items: Iterable[ItemRef]) -> Optional[dict]:
    item_code = resolve_item_code(parsed, items)
    if not item_code:
        return None

    qty = float(parsed.weight) if parsed.weight is not None else 1.0
    price = float(parsed.price) if parsed.price is not None else None

    return {
        "item_code": item_code,
        "qty": qty,
        "price": price,
    }