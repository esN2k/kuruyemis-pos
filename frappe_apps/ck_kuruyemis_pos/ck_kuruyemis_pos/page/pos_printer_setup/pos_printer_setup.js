frappe.pages["pos_printer_setup"].on_page_load = function (wrapper) {
  const page = frappe.ui.make_app_page({
    parent: wrapper,
    title: __("POS Printer Setup"),
    single_column: true,
  });

  const SETTINGS_DOCTYPE = "POS Printing Settings";
  const JSBARCODE_PATH = "/assets/ck_kuruyemis_pos/js/qz/vendor/jsbarcode.all.min.js";
  let jsBarcodePromise = null;

  const fieldGroup = new frappe.ui.FieldGroup({
    body: page.body,
    fields: [
      {
        fieldname: "receipt_printer_name",
        label: __("Default Receipt Printer"),
        fieldtype: "Select",
      },
      {
        fieldname: "label_printer_name",
        label: __("Default Label Printer"),
        fieldtype: "Select",
      },
      {
        fieldname: "label_size_preset",
        label: __("Label Size Preset"),
        fieldtype: "Select",
        options: "38x80",
      },
      {
        fieldname: "btn_refresh",
        label: __("Refresh Printers"),
        fieldtype: "Button",
      },
      {
        fieldname: "btn_save",
        label: __("Save Defaults"),
        fieldtype: "Button",
      },
      {
        fieldname: "btn_test_receipt",
        label: __("Test Receipt Print"),
        fieldtype: "Button",
      },
      {
        fieldname: "btn_test_label",
        label: __("Test Label Print"),
        fieldtype: "Button",
      },
    ],
  });

  fieldGroup.make();

  const previewTitle = document.createElement("h3");
  previewTitle.textContent = __("Label Preview");
  previewTitle.style.marginTop = "24px";
  page.body.appendChild(previewTitle);

  const previewGroup = new frappe.ui.FieldGroup({
    body: page.body,
    fields: [
      {
        fieldname: "preview_item_name",
        label: __("Label Preview Item Name"),
        fieldtype: "Data",
        default: "Antep Fıstığı",
      },
      {
        fieldname: "preview_price",
        label: __("Label Preview Price"),
        fieldtype: "Data",
        default: "93.75",
      },
      {
        fieldname: "preview_plu",
        label: __("Label Preview PLU"),
        fieldtype: "Data",
        default: "12345",
      },
      {
        fieldname: "preview_barcode",
        label: __("Label Preview Barcode"),
        fieldtype: "Data",
        default: "2101234002508",
      },
      {
        fieldname: "preview_html",
        fieldtype: "HTML",
      },
    ],
  });

  previewGroup.make();

  const previewField = previewGroup.get_field("preview_html");
  previewField.$wrapper.html(`
    <div style="border:1px solid #e5e7eb;padding:12px;border-radius:8px;max-width:320px;">
      <div id="ck-label-preview-name" style="font-weight:600;font-size:14px;"></div>
      <div id="ck-label-preview-price" style="margin-top:4px;font-size:13px;"></div>
      <div id="ck-label-preview-plu" style="margin-top:4px;color:#6b7280;font-size:12px;"></div>
      <svg id="ck-label-preview-barcode"></svg>
      <div id="ck-label-preview-note" style="margin-top:6px;color:#ef4444;font-size:12px;"></div>
    </div>
  `);

  function showAlert(message, indicator) {
    if (frappe.show_alert) {
      frappe.show_alert({ message, indicator: indicator || "green" });
    }
  }

  function loadScript(src) {
    return new Promise((resolve, reject) => {
      const script = document.createElement("script");
      script.src = src;
      script.async = true;
      script.onload = resolve;
      script.onerror = reject;
      document.head.appendChild(script);
    });
  }

  function ensureJsBarcode() {
    if (window.JsBarcode) {
      return Promise.resolve();
    }
    if (!jsBarcodePromise) {
      jsBarcodePromise = loadScript(JSBARCODE_PATH);
    }
    return jsBarcodePromise;
  }

  async function loadSettings() {
    try {
      const response = await frappe.call("frappe.client.get_single", { doctype: SETTINGS_DOCTYPE });
      return response.message || { doctype: SETTINGS_DOCTYPE };
    } catch (err) {
      console.warn(__("Loading printer settings failed"), err);
      return { doctype: SETTINGS_DOCTYPE };
    }
  }

  async function saveSettings() {
    const values = fieldGroup.get_values();
    const doc = await loadSettings();
    doc.receipt_printer_name = values.receipt_printer_name || "";
    doc.label_printer_name = values.label_printer_name || "";
    doc.label_size_preset = values.label_size_preset || "";

    try {
      await frappe.call("frappe.client.save", { doc });
      showAlert(__("Printer defaults saved"));
    } catch (err) {
      console.error(err);
      frappe.msgprint({ message: __("Failed to save settings"), indicator: "red" });
    }
  }

  async function refreshPrinters() {
    try {
      if (!window.ck_qz) {
        frappe.msgprint({ message: __("QZ Tray wrapper not loaded"), indicator: "red" });
        return;
      }

      const printers = await window.ck_qz.listPrinters();
      const options = printers.join("\n");
      const receiptField = fieldGroup.get_field("receipt_printer_name");
      const labelField = fieldGroup.get_field("label_printer_name");

      receiptField.df.options = options;
      labelField.df.options = options;
      receiptField.refresh();
      labelField.refresh();

      showAlert(__("Printer list refreshed"));
    } catch (err) {
      console.error(err);
      frappe.msgprint({ message: __("Failed to fetch printers"), indicator: "red" });
    }
  }

  async function applySettingsToFields() {
    const doc = await loadSettings();
    fieldGroup.set_value("receipt_printer_name", doc.receipt_printer_name || "");
    fieldGroup.set_value("label_printer_name", doc.label_printer_name || "");
    fieldGroup.set_value("label_size_preset", doc.label_size_preset || "38x80");
  }

  async function testReceipt() {
    try {
      const values = fieldGroup.get_values();
      const printer = values.receipt_printer_name;
      if (!printer) {
        frappe.msgprint({ message: __("Select a receipt printer first"), indicator: "orange" });
        return;
      }
      const payload = await window.ck_qz_examples.receiptPayload();
      await window.ck_qz.printRaw(printer, payload);
      showAlert(__("Receipt sent to printer: {0}", [printer]));
    } catch (err) {
      console.error(err);
      frappe.msgprint({ message: __("Receipt print failed"), indicator: "red" });
    }
  }

  async function testLabel() {
    try {
      const values = fieldGroup.get_values();
      const printer = values.label_printer_name;
      if (!printer) {
        frappe.msgprint({ message: __("Select a label printer first"), indicator: "orange" });
        return;
      }
      await window.ck_qz.printRaw(printer, window.ck_qz_examples.labelPayloadTspl());
      showAlert(__("Label sent to printer: {0}", [printer]));
    } catch (err) {
      console.error(err);
      frappe.msgprint({ message: __("Label print failed"), indicator: "red" });
    }
  }

  async function renderPreview() {
    const values = previewGroup.get_values();
    const itemName = values.preview_item_name || "";
    const price = values.preview_price || "";
    const plu = values.preview_plu || "";
    const barcode = values.preview_barcode || "";

    const nameEl = document.getElementById("ck-label-preview-name");
    const priceEl = document.getElementById("ck-label-preview-price");
    const pluEl = document.getElementById("ck-label-preview-plu");
    const noteEl = document.getElementById("ck-label-preview-note");
    const barcodeEl = document.getElementById("ck-label-preview-barcode");

    if (nameEl) nameEl.textContent = itemName ? itemName : __("Label Preview Item Name");
    if (priceEl) priceEl.textContent = price ? `${price} TRY` : __("Label Preview Price");
    if (pluEl) pluEl.textContent = plu ? `PLU: ${plu}` : "";
    if (noteEl) noteEl.textContent = "";

    if (!barcode) {
      if (noteEl) noteEl.textContent = __("Label Preview Barcode Missing");
      if (barcodeEl) barcodeEl.innerHTML = "";
      return;
    }

    if (barcode.length !== 13) {
      if (noteEl) noteEl.textContent = __("Label Preview Barcode Invalid");
      if (barcodeEl) barcodeEl.innerHTML = "";
      return;
    }

    try {
      await ensureJsBarcode();
      if (window.JsBarcode && barcodeEl) {
        window.JsBarcode(barcodeEl, barcode, {
          format: "EAN13",
          displayValue: true,
          width: 2,
          height: 60,
          fontSize: 12,
          margin: 0,
        });
      }
    } catch (err) {
      console.error(err);
      if (noteEl) noteEl.textContent = __("Label Preview Barcode Render Failed");
    }
  }

  fieldGroup.get_field("btn_refresh").$input.on("click", refreshPrinters);
  fieldGroup.get_field("btn_save").$input.on("click", saveSettings);
  fieldGroup.get_field("btn_test_receipt").$input.on("click", testReceipt);
  fieldGroup.get_field("btn_test_label").$input.on("click", testLabel);

  ["preview_item_name", "preview_price", "preview_plu", "preview_barcode"].forEach((fieldname) => {
    const field = previewGroup.get_field(fieldname);
    if (field && field.$input) {
      field.$input.on("input", renderPreview);
    }
  });

  (async () => {
    await refreshPrinters();
    await applySettingsToFields();
    await renderPreview();
  })();
};
