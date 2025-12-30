frappe.pages["pos_printer_setup"].on_page_load = function (wrapper) {
  const page = frappe.ui.make_app_page({
    parent: wrapper,
    title: __("POS Printer Setup"),
    single_column: true,
  });

  const SETTINGS_DOCTYPE = "POS Printing Settings";

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

  function showAlert(message, indicator) {
    if (frappe.show_alert) {
      frappe.show_alert({ message, indicator: indicator || "green" });
    }
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
      await window.ck_qz.printRaw(printer, window.ck_qz_examples.receiptPayload());
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

  fieldGroup.get_field("btn_refresh").$input.on("click", refreshPrinters);
  fieldGroup.get_field("btn_save").$input.on("click", saveSettings);
  fieldGroup.get_field("btn_test_receipt").$input.on("click", testReceipt);
  fieldGroup.get_field("btn_test_label").$input.on("click", testLabel);

  (async () => {
    await refreshPrinters();
    await applySettingsToFields();
  })();
};
