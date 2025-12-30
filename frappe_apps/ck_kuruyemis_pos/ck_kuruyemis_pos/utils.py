import frappe


def set_tr_defaults() -> None:
    """Set default language, timezone, and currency for the site."""
    frappe.db.set_value("System Settings", "System Settings", "language", "tr")
    frappe.db.set_value("System Settings", "System Settings", "time_zone", "Europe/Istanbul")
    frappe.db.set_value("Global Defaults", "Global Defaults", "default_currency", "TRY")
    frappe.db.commit()


def check_weighed_barcode_presets() -> dict:
    """Duman testi için eksik tartılı barkod presetlerini döndürür."""
    required = ["CL3000-Weight-20", "CL3000-Price-21"]
    missing = [name for name in required if not frappe.db.exists("Weighed Barcode Rule", name)]
    return {"ok": not missing, "missing": missing}
