/*
  Minimal QZ Tray wrapper used by POS Awesome demo buttons.
  Requires qz-tray.js loaded before or via dynamic loader.
*/
(function () {
  "use strict";

  const VENDOR_PATH = "/assets/ck_kuruyemis_pos/js/qz/vendor/qz-tray.js";
  let loadPromise = null;

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

  function ensureQzLoaded() {
    if (window.qz) {
      return Promise.resolve();
    }
    if (!loadPromise) {
      loadPromise = loadScript(VENDOR_PATH);
    }
    return loadPromise;
  }

  function setDevSecurity() {
    if (!window.qz || !qz.security) {
      return;
    }
    qz.security.setCertificatePromise(() => Promise.resolve(null));
    qz.security.setSignaturePromise(() => Promise.resolve(null));
  }

  async function connect() {
    await ensureQzLoaded();
    setDevSecurity();
    if (!qz.websocket.isActive()) {
      await qz.websocket.connect();
    }
  }

  async function listPrinters() {
    await connect();
    return qz.printers.find();
  }

  async function findPrinter(name) {
    await connect();
    return qz.printers.find(name);
  }

  async function printRaw(printerName, rawData, options) {
    await connect();
    const printer = await qz.printers.find(printerName);
    const config = qz.configs.create(printer, options || { encoding: "utf-8" });
    const data = Array.isArray(rawData) ? rawData : [rawData];
    return qz.print(config, data);
  }

  window.ck_qz = {
    ensureQzLoaded,
    connect,
    listPrinters,
    findPrinter,
    printRaw,
  };
})();