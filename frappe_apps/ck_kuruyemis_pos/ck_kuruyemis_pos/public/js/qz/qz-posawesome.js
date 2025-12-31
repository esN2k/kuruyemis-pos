/* POS Awesome toolbar/menu actions for QZ Tray printing. */
(function () {
  "use strict";

  const DEFAULTS = {
    receiptPrinter: "ZY907",
    labelPrinter: "X-Printer 490B",
    labelSizePreset: "38x80_hizli",
    receiptTemplate: "kuruyemis",
    labelTemplate: "kuruyemis",
    drawerCommand: "\\x1B\\x70\\x00\\x19\\xFA",
    receiptAliases: "",
    labelAliases: "",
    qzSecurityMode: "DEV",
  };
  const SETTINGS_DOCTYPE = "POS Printing Settings";
  let settingsCache = null;

  function isPosRoute() {
    const route = (window.frappe && frappe.get_route_str && frappe.get_route_str()) || window.location.pathname || "";
    const normalized = route.toLowerCase();
    return normalized.includes("posawesome") || normalized.includes("point-of-sale");
  }

  function notify(message, isError) {
    if (window.frappe && frappe.show_alert && !isError) {
      frappe.show_alert({ message, indicator: "green" });
      refocusBarcodeInput();
    } else if (window.frappe && frappe.msgprint) {
      const dialog = frappe.msgprint({
        message,
        indicator: isError ? "red" : "green",
      });
      if (dialog && typeof dialog.onhide === "function") {
        dialog.onhide = refocusBarcodeInput;
      } else {
        refocusBarcodeInput();
      }
    } else {
      alert(message);
      refocusBarcodeInput();
    }
  }

  function isVisible(el) {
    return el && el.offsetParent !== null;
  }

  function findBarcodeInput() {
    const container = document.querySelector("#posawesome-app") || document.body;
    const selectors = [
      "input[data-fieldname='barcode']",
      "input[data-fieldname='item_code']",
      "input[placeholder*='barcode' i]",
      "input[placeholder*='scan' i]",
      "input[type='text']",
    ];

    for (const selector of selectors) {
      const input = container.querySelector(selector);
      if (isVisible(input)) {
        return input;
      }
    }
    return null;
  }

  function refocusBarcodeInput() {
    setTimeout(() => {
      const input = findBarcodeInput();
      if (input) {
        input.focus();
        input.select?.();
      }
    }, 150);
  }

  async function loadSettings() {
    if (settingsCache) {
      return settingsCache;
    }

    const defaults = {
      receiptPrinter: DEFAULTS.receiptPrinter,
      labelPrinter: DEFAULTS.labelPrinter,
      labelSizePreset: DEFAULTS.labelSizePreset,
      receiptTemplate: DEFAULTS.receiptTemplate,
      labelTemplate: DEFAULTS.labelTemplate,
      drawerCommand: DEFAULTS.drawerCommand,
      receiptAliases: DEFAULTS.receiptAliases,
      labelAliases: DEFAULTS.labelAliases,
      qzSecurityMode: DEFAULTS.qzSecurityMode,
    };

    if (!window.frappe || !frappe.call) {
      settingsCache = defaults;
      return settingsCache;
    }

    try {
      const response = await frappe.call("frappe.client.get_single", { doctype: SETTINGS_DOCTYPE });
      const data = response.message || {};
      settingsCache = {
        receiptPrinter: data.receipt_printer_name || defaults.receiptPrinter,
        labelPrinter: data.label_printer_name || defaults.labelPrinter,
        labelSizePreset: data.label_size_preset || defaults.labelSizePreset,
        receiptTemplate: data.receipt_template || defaults.receiptTemplate,
        labelTemplate: data.label_template || defaults.labelTemplate,
        drawerCommand: data.cash_drawer_command || defaults.drawerCommand,
        receiptAliases: data.receipt_printer_aliases || defaults.receiptAliases,
        labelAliases: data.label_printer_aliases || defaults.labelAliases,
        qzSecurityMode: data.qz_security_mode || defaults.qzSecurityMode,
      };
      if (settingsCache.labelSizePreset === "38x80") {
        settingsCache.labelSizePreset = "38x80_hizli";
      }
      return settingsCache;
    } catch (err) {
      console.warn(__("Loading printer settings failed"), err);
      settingsCache = defaults;
      return settingsCache;
    }
  }

  function formatError(err) {
    if (!err) {
      return "";
    }
    return err.message || String(err);
  }

  function decodeEscapes(value) {
    if (!value) {
      return "";
    }
    return value
      .replace(/\\x([0-9a-fA-F]{2})/g, (_, hex) => String.fromCharCode(parseInt(hex, 16)))
      .replace(/\\n/g, "\n")
      .replace(/\\r/g, "\r")
      .replace(/\\t/g, "\t");
  }

  async function getReceiptPayload(template) {
    if (!window.ck_qz_examples || !window.ck_qz_examples.receiptPayload) {
      throw new Error(__("Receipt payload not ready"));
    }
    return window.ck_qz_examples.receiptPayload({ template });
  }

  async function getLabelPayload(template, preset) {
    if (!window.ck_qz_examples || !window.ck_qz_examples.labelPayloadTspl) {
      throw new Error(__("Label payload not ready"));
    }
    return window.ck_qz_examples.labelPayloadTspl({ template, preset });
  }

  function normalizeName(value) {
    return String(value || "").trim().toLowerCase();
  }

  function parseAliases(text) {
    if (!text) {
      return [];
    }
    return String(text)
      .split(/[\n,;]+/)
      .map((alias) => alias.trim())
      .filter((alias) => alias);
  }

  function scoreMatch(printerName, candidate) {
    const printerNorm = normalizeName(printerName);
    const candidateNorm = normalizeName(candidate);
    if (!printerNorm || !candidateNorm) {
      return 0;
    }
    if (printerNorm === candidateNorm) {
      return 3;
    }
    if (printerNorm.startsWith(candidateNorm) || candidateNorm.startsWith(printerNorm)) {
      return 2;
    }
    if (printerNorm.includes(candidateNorm) || candidateNorm.includes(printerNorm)) {
      return 1;
    }
    return 0;
  }

  function findBestPrinter(printers, candidates) {
    let best = null;
    let bestScore = 0;
    let bestLength = Number.POSITIVE_INFINITY;
    printers.forEach((printer) => {
      candidates.forEach((candidate) => {
        const score = scoreMatch(printer, candidate);
        if (score > bestScore || (score === bestScore && printer.length < bestLength)) {
          best = printer;
          bestScore = score;
          bestLength = printer.length;
        }
      });
    });
    return best;
  }

  async function resolvePrinterName(requestedName, aliasText) {
    if (!window.ck_qz || !window.ck_qz.listPrinters) {
      return requestedName;
    }
    const printers = await window.ck_qz.listPrinters();
    if (!printers || !printers.length) {
      return requestedName;
    }
    const candidates = [requestedName, ...parseAliases(aliasText)];
    const best = findBestPrinter(printers, candidates);
    return best || requestedName;
  }

  async function printReceipt() {
    try {
      const settings = await loadSettings();
      const printer = await resolvePrinterName(
        settings.receiptPrinter || DEFAULTS.receiptPrinter,
        settings.receiptAliases
      );
      const payload = await getReceiptPayload(settings.receiptTemplate || DEFAULTS.receiptTemplate);
      await window.ck_qz.printRaw(printer, payload);
      notify(__("Receipt sent to printer: {0}", [printer]));
    } catch (err) {
      console.error(err);
      notify(__("Receipt print failed: {0}", [formatError(err)]), true);
    }
  }

  async function printLabel() {
    try {
      const settings = await loadSettings();
      const printer = await resolvePrinterName(
        settings.labelPrinter || DEFAULTS.labelPrinter,
        settings.labelAliases
      );
      const payload = await getLabelPayload(
        settings.labelTemplate || DEFAULTS.labelTemplate,
        settings.labelSizePreset || DEFAULTS.labelSizePreset
      );
      await window.ck_qz.printRaw(printer, payload);
      notify(__("Label sent to printer: {0}", [printer]));
    } catch (err) {
      console.error(err);
      notify(__("Label print failed: {0}", [formatError(err)]), true);
    }
  }

  async function openDrawer() {
    try {
      const settings = await loadSettings();
      const printer = await resolvePrinterName(
        settings.receiptPrinter || DEFAULTS.receiptPrinter,
        settings.receiptAliases
      );
      const command = settings.drawerCommand || DEFAULTS.drawerCommand;
      if (!command) {
        notify(__("Cash drawer command missing"), true);
        return;
      }
      const payload = decodeEscapes(command);
      await window.ck_qz.printRaw(printer, payload);
      notify(__("Cash drawer opened"));
    } catch (err) {
      console.error(err);
      notify(__("Cash drawer open failed: {0}", [formatError(err)]), true);
    }
  }

  function addAction(page, label, action) {
    if (page.add_inner_button) {
      page.add_inner_button(label, action);
      return true;
    }
    if (page.add_action_item) {
      page.add_action_item(label, action);
      return true;
    }
    if (page.add_menu_item) {
      page.add_menu_item(label, action);
      return true;
    }
    return false;
  }

  function ensureActions() {
    if (!isPosRoute()) {
      return;
    }
    if (!window.frappe || !frappe.ui || !frappe.ui.get_cur_page) {
      return;
    }
    const page = frappe.ui.get_cur_page();
    if (!page || page.__ck_qz_actions_added) {
      return;
    }

    const addedReceipt = addAction(page, __("Print Non-Fiscal Receipt"), printReceipt);
    const addedLabel = addAction(page, __("Print Shelf Label"), printLabel);
    const addedDrawer = addAction(page, __("Open Cash Drawer"), openDrawer);
    page.__ck_qz_actions_added = addedReceipt || addedLabel || addedDrawer;
  }

  function bindRoute() {
    if (window.frappe && frappe.router && frappe.router.on) {
      frappe.router.on("change", ensureActions);
    }
    document.addEventListener("DOMContentLoaded", ensureActions);
  }

  bindRoute();
})();
