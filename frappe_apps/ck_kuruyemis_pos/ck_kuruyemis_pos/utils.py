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


def get_pos_printing_settings() -> dict:
    """Doktor kontrolü için POS yazdırma ayarlarını döndürür."""
    doc = frappe.get_single("POS Printing Settings")
    data = {
        "receipt_printer_name": doc.receipt_printer_name or "",
        "label_printer_name": doc.label_printer_name or "",
        "receipt_printer_aliases": doc.receipt_printer_aliases or "",
        "label_printer_aliases": doc.label_printer_aliases or "",
        "qz_security_mode": doc.qz_security_mode or "DEV",
        "label_size_preset": doc.label_size_preset or "38x80_hizli",
    }
    return frappe.as_json(data)


def get_sample_print_payloads() -> dict:
    """Duman testi için örnek fiş/etiket payload'ları üretir."""
    receipt_lines = [
        "CK Kuruyemiş POS",
        "Bilgi Fişi (Mali Değil)",
        "---------------------------",
        "Ürün: Antep Fıstığı",
        "Miktar: 0.250 kg",
        "Fiyat: 375.00 TRY/kg",
        "Tutar: 93.75 TRY",
        "---------------------------",
        "Afiyet olsun!",
    ]
    receipt_payload = "\x1B@" + "\n".join(receipt_lines) + "\n\n\n" + "\x1DV1"

    label_payload = "\n".join(
        [
            "SIZE 38 mm,80 mm",
            "GAP 2 mm,0",
            "DENSITY 8",
            "SPEED 4",
            "DIRECTION 1",
            "CLS",
            'TEXT 20,10,"0",0,1,1,"Kuruyemiş"',
            'TEXT 20,35,"0",0,1,1,"Antep Fıstığı"',
            'TEXT 20,60,"0",0,1,1,"0.250 kg"',
            'TEXT 20,85,"0",0,1,1,"93.75 TRY"',
            'BARCODE 20,120,"128",70,1,0,2,2,"2101234002508"',
            "PRINT 1,1",
        ]
    )

    return frappe.as_json({"receipt": receipt_payload, "label": label_payload})
