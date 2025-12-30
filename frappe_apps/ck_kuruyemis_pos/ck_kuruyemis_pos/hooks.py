app_name = "ck_kuruyemis_pos"
app_title = "CK Kuruyemis POS"
app_publisher = "CK Kuruyemis"
app_description = "Custom POS workflows and weighed barcode parsing."
app_email = "ops@example.com"
app_license = "GPLv3"

# Desk-only JS assets for QZ Tray demo in POS Awesome.
app_include_js = [
    "/assets/ck_kuruyemis_pos/js/qz/qz-wrapper.js",
    "/assets/ck_kuruyemis_pos/js/qz/qz-examples.js",
    "/assets/ck_kuruyemis_pos/js/qz/qz-posawesome.js",
]

# Override ERPNext barcode resolution to inject weighed barcode parsing.
override_whitelisted_methods = {
    "erpnext.stock.get_item_details.get_item_details": "ck_kuruyemis_pos.weighed_barcode.integration.get_item_details"
}
