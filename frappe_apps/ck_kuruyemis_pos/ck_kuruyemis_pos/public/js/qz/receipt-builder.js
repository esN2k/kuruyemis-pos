/* Receipt builder using ReceiptPrinterEncoder with raw fallback. */
(function () {
  "use strict";

  const VENDOR_PATH = "/assets/ck_kuruyemis_pos/js/qz/vendor/receipt-printer-encoder.umd.js";
  let loadPromise = null;
  const t = (text) => (window.__ ? __(text) : text);
  const TEMPLATES = {
    kuruyemis: {
      label: t("Kuruyemiş"),
      footer: t("Afiyet olsun!"),
    },
    manav: {
      label: t("Manav"),
      footer: t("Taze ve doğal ürünler!"),
    },
    sarkuteri: {
      label: t("Şarküteri"),
      footer: t("Lezzetli seçimler!"),
    },
  };

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

  function ensureEncoderLoaded() {
    if (window.ReceiptPrinterEncoder) {
      return Promise.resolve(window.ReceiptPrinterEncoder);
    }
    if (!loadPromise) {
      loadPromise = loadScript(VENDOR_PATH);
    }
    return loadPromise.then(() => window.ReceiptPrinterEncoder);
  }

  function resolveTemplate(options) {
    const key = options && options.template ? String(options.template) : "kuruyemis";
    return TEMPLATES[key] || TEMPLATES.kuruyemis;
  }

  function bytesToHex(bytes) {
    return Array.from(bytes)
      .map((value) => value.toString(16).padStart(2, "0"))
      .join("")
      .toUpperCase();
  }

  function normalizeData(options) {
    const template = resolveTemplate(options);
    const defaults = {
      storeName: t("CK Kuruyemiş POS"),
      templateLabel: template.label,
      title: t("Bilgi Fişi (Mali Değil)"),
      itemName: t("Antep Fıstığı"),
      qty: t("0.250 kg"),
      unitPrice: t("375.00 TRY/kg"),
      total: t("93.75 TRY"),
      footer: template.footer,
    };
    return Object.assign({}, defaults, options || {});
  }

  function buildReceiptWithEncoder(options) {
    const data = normalizeData(options);
    const encoder = new window.ReceiptPrinterEncoder({
      language: "esc-pos",
      codepageMapping: "epson",
      columns: 42,
    });

    encoder
      .initialize()
      .codepage("cp857")
      .align("center")
      .bold(true)
      .text(data.storeName)
      .bold(false)
      .newline()
      .text(data.templateLabel)
      .newline()
      .text(data.title)
      .newline()
      .rule()
      .align("left")
      .text(`${t("Ürün")}: ${data.itemName}`)
      .newline()
      .text(`${t("Miktar")}: ${data.qty}`)
      .newline()
      .text(`${t("Fiyat")}: ${data.unitPrice}`)
      .newline()
      .text(`${t("Tutar")}: ${data.total}`)
      .newline()
      .rule()
      .align("center")
      .text(data.footer)
      .newline(3)
      .cut();

    const bytes = encoder.encode();
    return {
      type: "raw",
      format: "hex",
      data: bytesToHex(bytes),
    };
  }

  function buildReceiptFallback(options) {
    const data = normalizeData(options);
    const lines = [
      `${data.storeName}\n`,
      `${data.templateLabel}\n`,
      `${data.title}\n`,
      "---------------------------\n",
      `${t("Ürün")}: ${data.itemName}\n`,
      `${t("Miktar")}: ${data.qty}\n`,
      `${t("Fiyat")}: ${data.unitPrice}\n`,
      `${t("Tutar")}: ${data.total}\n`,
      "---------------------------\n",
      `${data.footer}\n\n\n`,
    ].join("");

    // ESC/POS init + cut
    return "\x1B@" + lines + "\x1DV1";
  }

  async function receiptPayload(options) {
    try {
      await ensureEncoderLoaded();
      if (!window.ReceiptPrinterEncoder) {
        return buildReceiptFallback(options);
      }
      return buildReceiptWithEncoder(options);
    } catch (err) {
      console.warn(t("Fiş kodlayıcı hata verdi, yedek çıktı kullanılıyor."), err);
      return buildReceiptFallback(options);
    }
  }

  window.ck_receipt_builder = {
    receiptPayload,
    receiptPayloadRaw: buildReceiptFallback,
  };
})();
