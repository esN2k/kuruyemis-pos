from __future__ import annotations

import base64
from io import BytesIO

import frappe
from frappe import _


def _require_module(module_name: str, hint: str) -> None:
    try:
        __import__(module_name)
    except ModuleNotFoundError as exc:
        frappe.throw(_(hint))


def qr_data_url(data: str) -> str:
    """Print Format için QR kodunu base64 data URL olarak döndürür."""
    if not data:
        return ""

    _require_module(
        "qrcode",
        "QR üretimi için 'qrcode' bağımlılığı gerekli. 'scan_me' modülünü kurun veya qrcode paketini yükleyin.",
    )
    import qrcode

    img = qrcode.make(data)
    buffered = BytesIO()
    img.save(buffered, format="PNG")
    encoded = base64.b64encode(buffered.getvalue()).decode("utf-8")
    return f"data:image/png;base64,{encoded}"


def barcode_svg(data: str, module_width_mm: float = 0.2, module_height_mm: float = 15.0) -> str:
    """Print Format için Code128 barkodu SVG olarak döndürür."""
    if not data:
        return ""

    _require_module(
        "barcode",
        "Barkod üretimi için 'python-barcode' bağımlılığı gerekli. 'scan_me' modülünü kurun veya paketi yükleyin.",
    )
    from barcode.codex import Code128

    buffered = BytesIO()
    Code128(data).write(
        buffered,
        {
            "module_width": module_width_mm,
            "module_height": module_height_mm,
            "font_size": 0,
            "quiet_zone": 0,
        },
    )
    return buffered.getvalue().decode("utf-8")
