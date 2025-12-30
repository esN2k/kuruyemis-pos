app_name = "ck_kuruyemis_pos"
app_title = "CK Kuruyemiş POS"
app_publisher = "CK Kuruyemiş"
app_description = "Kuruyemiş POS özelleştirmeleri ve tartılı barkod iş akışları."
app_email = "ops@example.com"
app_license = "GPLv3"

# Desk-only JS assets for QZ Tray demo in POS Awesome.
app_include_js = [
    "/assets/ck_kuruyemis_pos/js/qz/qz-wrapper.js",
    "/assets/ck_kuruyemis_pos/js/qz/qz-examples.js",
    "/assets/ck_kuruyemis_pos/js/qz/qz-posawesome.js",
]

# Fixtures for default settings and barcode presets.
fixtures = [
    "Custom Field",
    "Weighed Barcode Rule",
]

# Override ERPNext barcode resolution to inject weighed barcode parsing.
override_whitelisted_methods = {
    "erpnext.stock.get_item_details.get_item_details": "ck_kuruyemis_pos.weighed_barcode.integration.get_item_details"
}
