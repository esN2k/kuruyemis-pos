frappe.pages["pos_printer_setup"].on_page_load = function (wrapper) {
  const page = frappe.ui.make_app_page({
    parent: wrapper,
    title: __("POS Printer Setup"),
    single_column: true,
  });

  const SETTINGS_DOCTYPE = "POS Printing Settings";
  const JSBARCODE_PATH = "/assets/ck_kuruyemis_pos/js/qz/vendor/jsbarcode.all.min.js";
  const TEMPLATE_OPTIONS = [
    `${__("Kuruyemiş")}|kuruyemis`,
    `${__("Manav")}|manav`,
    `${__("Şarküteri")}|sarkuteri`,
  ].join("\n");
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
        fieldname: "receipt_template",
        label: __("Receipt Template"),
        fieldtype: "Select",
        options: TEMPLATE_OPTIONS,
      },
      {
        fieldname: "cash_drawer_command",
        label: __("Cash Drawer Command"),
        fieldtype: "Small Text",
        default: "\\x1B\\x70\\x00\\x19\\xFA",
      },
      {
        fieldname: "label_template",
        label: __("Label Template"),
        fieldtype: "Select",
        options: TEMPLATE_OPTIONS,
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

  const validationTitle = document.createElement("h3");
  validationTitle.textContent = __("Barcode Validation");
  validationTitle.style.marginTop = "24px";
  page.body.appendChild(validationTitle);

  const validationGroup = new frappe.ui.FieldGroup({
    body: page.body,
    fields: [
      {
        fieldname: "validate_barcode",
        label: __("Barcode to Validate"),
        fieldtype: "Data",
      },
      {
        fieldname: "btn_validate_barcode",
        label: __("Validate Barcode"),
        fieldtype: "Button",
      },
      {
        fieldname: "validation_result",
        fieldtype: "HTML",
      },
    ],
  });

  validationGroup.make();

  const validationField = validationGroup.get_field("validation_result");
  validationField.$wrapper.html(`
    <div style="border:1px solid #e5e7eb;padding:12px;border-radius:8px;max-width:420px;">
      <div id="ck-barcode-validate-result"></div>
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
    doc.receipt_template = values.receipt_template || "";
    doc.cash_drawer_command = values.cash_drawer_command || "";
    doc.label_template = values.label_template || "";
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
    fieldGroup.set_value("receipt_template", doc.receipt_template || "kuruyemis");
    fieldGroup.set_value("cash_drawer_command", doc.cash_drawer_command || "\\x1B\\x70\\x00\\x19\\xFA");
    fieldGroup.set_value("label_template", doc.label_template || "kuruyemis");
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
      const payload = await window.ck_qz_examples.receiptPayload({
        template: values.receipt_template,
      });
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
      await window.ck_qz.printRaw(
        printer,
        window.ck_qz_examples.labelPayloadTspl({ template: values.label_template })
      );
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

  function escapeHtml(value) {
    return String(value || "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function formatWeight(data) {
    if (!data.weight) {
      return "-";
    }
    const weight = Number(data.weight);
    if (Number.isNaN(weight)) {
      return escapeHtml(data.weight);
    }
    if (Number(data.weight_divisor) === 1000) {
      const grams = Math.round(weight * 1000);
      return `${grams} g (${weight.toFixed(3)} kg)`;
    }
    return `${weight} kg`;
  }

  function formatPrice(data) {
    if (!data.price) {
      return "-";
    }
    const price = Number(data.price);
    if (Number.isNaN(price)) {
      return escapeHtml(data.price);
    }
    if (Number(data.price_divisor) === 100) {
      const cents = data.price_segment ? Number(data.price_segment) : Math.round(price * 100);
      return `${price.toFixed(2)} TRY (${cents} ${__("Kuruş")})`;
    }
    return `${price} TRY`;
  }

  function renderValidationMessage(message, indicator, hint) {
    const resultEl = document.getElementById("ck-barcode-validate-result");
    if (!resultEl) {
      return;
    }
    const color = indicator === "red" ? "#ef4444" : indicator === "orange" ? "#f97316" : "#16a34a";
    const hintHtml = hint
      ? `<div style="margin-top:6px;color:#6b7280;">${escapeHtml(hint)}</div>`
      : "";
    resultEl.innerHTML = `<div style="color:${color};font-weight:600;">${escapeHtml(message)}</div>${hintHtml}`;
  }

  function renderValidationResult(data) {
    const resultEl = document.getElementById("ck-barcode-validate-result");
    if (!resultEl) {
      return;
    }
    const target =
      data.item_code_target === "scale_plu" ? __("Scale PLU") : __("Item Code");
    const lines = [
      `<div><strong>${__("Matched Rule")}:</strong> ${escapeHtml(data.rule_name)}</div>`,
      `<div><strong>${__("Prefix")}:</strong> ${escapeHtml(data.prefix || "-")}</div>`,
      `<div><strong>${__("Item Code Target")}:</strong> ${escapeHtml(target)}</div>`,
      `<div><strong>${__("Raw Item Code")}:</strong> ${escapeHtml(data.raw_item_code)}</div>`,
      `<div><strong>${__("Parsed Item Code")}:</strong> ${escapeHtml(data.item_code)}</div>`,
      `<div><strong>${__("Weight")}:</strong> ${formatWeight(data)}</div>`,
      `<div><strong>${__("Price")}:</strong> ${formatPrice(data)}</div>`,
    ];
    resultEl.innerHTML = lines.join("");
  }

  async function validateBarcode() {
    const values = validationGroup.get_values();
    const barcode = (values.validate_barcode || "").trim();
    if (!barcode) {
      renderValidationMessage(__("Please enter a barcode to validate"), "orange");
      return;
    }
    try {
      const response = await frappe.call(
        "ck_kuruyemis_pos.weighed_barcode.integration.validate_weighed_barcode",
        { barcode }
      );
      const data = response.message || {};
      if (!data.ok) {
        renderValidationMessage(
          data.message || __("Barcode validation failed"),
          "red",
          data.hint || ""
        );
        return;
      }
      renderValidationResult(data);
    } catch (err) {
      console.error(err);
      renderValidationMessage(__("Barcode validation failed"), "red");
    }
  }

  fieldGroup.get_field("btn_refresh").$input.on("click", refreshPrinters);
  fieldGroup.get_field("btn_save").$input.on("click", saveSettings);
  fieldGroup.get_field("btn_test_receipt").$input.on("click", testReceipt);
  fieldGroup.get_field("btn_test_label").$input.on("click", testLabel);
  validationGroup.get_field("btn_validate_barcode").$input.on("click", validateBarcode);

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
