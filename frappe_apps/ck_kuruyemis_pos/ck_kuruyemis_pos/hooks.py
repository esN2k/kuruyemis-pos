app_name = "ck_kuruyemis_pos"
app_title = "CK Kuruyemis POS"
app_publisher = "CK Kuruyemis"
app_description = "Custom POS workflows and weighed barcode parsing."
app_email = "ops@example.com"
app_license = "GPLv3"

# Override ERPNext barcode resolution to inject weighed barcode parsing.
override_whitelisted_methods = {
    "erpnext.stock.get_item_details.get_item_details": "ck_kuruyemis_pos.weighed_barcode.integration.get_item_details"
}