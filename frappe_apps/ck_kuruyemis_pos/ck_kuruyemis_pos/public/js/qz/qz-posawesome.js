/* POS Awesome demo buttons for QZ Tray printing. */
(function () {
  "use strict";

  const DEFAULTS = {
    receiptPrinter: "ZY907",
    labelPrinter: "X-Printer 490B",
  };

  function isPosRoute() {
    const route = (window.frappe && frappe.get_route_str && frappe.get_route_str()) || window.location.pathname || "";
    const normalized = route.toLowerCase();
    return normalized.includes("posawesome") || normalized.includes("point-of-sale");
  }

  function notify(message) {
    if (window.frappe && frappe.msgprint) {
      frappe.msgprint(message);
    } else {
      alert(message);
    }
  }

  function ensurePanel() {
    if (!isPosRoute()) {
      return;
    }
    if (document.getElementById("ck-qz-demo-panel")) {
      return;
    }

    const panel = document.createElement("div");
    panel.id = "ck-qz-demo-panel";
    panel.style.position = "fixed";
    panel.style.right = "16px";
    panel.style.bottom = "16px";
    panel.style.zIndex = "9999";
    panel.style.background = "#f5f5f5";
    panel.style.border = "1px solid #d1d1d1";
    panel.style.padding = "10px";
    panel.style.boxShadow = "0 2px 6px rgba(0,0,0,0.15)";
    panel.style.fontSize = "12px";

    const title = document.createElement("div");
    title.textContent = "QZ Tray Demo";
    title.style.marginBottom = "6px";
    title.style.fontWeight = "600";

    const receiptBtn = document.createElement("button");
    receiptBtn.textContent = "Non-fiscal receipt";
    receiptBtn.style.marginRight = "6px";

    const labelBtn = document.createElement("button");
    labelBtn.textContent = "Shelf label";

    panel.appendChild(title);
    panel.appendChild(receiptBtn);
    panel.appendChild(labelBtn);
    document.body.appendChild(panel);

    receiptBtn.addEventListener("click", async () => {
      try {
        const settings = window.ck_qz_settings || {};
        const printer = settings.receiptPrinter || DEFAULTS.receiptPrinter;
        await window.ck_qz.printRaw(printer, window.ck_qz_examples.receiptPayload());
        notify("Receipt sent to printer: " + printer);
      } catch (err) {
        console.error(err);
        notify("Receipt print failed: " + err);
      }
    });

    labelBtn.addEventListener("click", async () => {
      try {
        const settings = window.ck_qz_settings || {};
        const printer = settings.labelPrinter || DEFAULTS.labelPrinter;
        await window.ck_qz.printRaw(printer, window.ck_qz_examples.labelPayloadTspl());
        notify("Label sent to printer: " + printer);
      } catch (err) {
        console.error(err);
        notify("Label print failed: " + err);
      }
    });
  }

  function bindRoute() {
    if (window.frappe && frappe.router && frappe.router.on) {
      frappe.router.on("change", ensurePanel);
    }
    document.addEventListener("DOMContentLoaded", ensurePanel);
  }

  bindRoute();
})();
