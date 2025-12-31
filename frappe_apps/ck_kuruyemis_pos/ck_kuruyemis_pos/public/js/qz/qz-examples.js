/* Example payloads for receipt and shelf label printing. */
(function () {
  "use strict";

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

  const sample = {
    storeName: t("CK Kuruyemiş POS"),
    title: t("Bilgi Fişi (Mali Değil)"),
    itemName: t("Antep Fıstığı"),
    qty: t("0.250 kg"),
    unitPrice: t("375.00 TRY/kg"),
    total: t("93.75 TRY"),
    barcode: "2101234002508",
  };

  function resolveTemplate(options) {
    const key = options && options.template ? String(options.template) : "kuruyemis";
    return TEMPLATES[key] || TEMPLATES.kuruyemis;
  }

  async function receiptPayload(options) {
    if (window.ck_receipt_builder && window.ck_receipt_builder.receiptPayload) {
      return window.ck_receipt_builder.receiptPayload(options);
    }

    const template = resolveTemplate(options);
    const lines = [
      `${sample.storeName}\n`,
      `${template.label}\n`,
      `${sample.title}\n`,
      "---------------------------\n",
      `${t("Ürün")}: ${sample.itemName}\n`,
      `${t("Miktar")}: ${sample.qty}\n`,
      `${t("Fiyat")}: ${sample.unitPrice}\n`,
      `${t("Tutar")}: ${sample.total}\n`,
      "---------------------------\n",
      `${template.footer}\n\n\n`,
    ].join("");

    // ESC/POS init + cut
    return "\x1B@" + lines + "\x1DV1";
  }

  function labelPayloadTspl(options) {
    const template = resolveTemplate(options);
    const header = `${template.label}`;

    return [
      "SIZE 38 mm,80 mm",
      "GAP 2 mm,0",
      "DENSITY 8",
      "SPEED 4",
      "DIRECTION 1",
      "CLS",
      `TEXT 20,10,\"0\",0,1,1,\"${header}\"`,
      `TEXT 20,35,\"0\",0,1,1,\"${sample.itemName}\"`,
      `TEXT 20,60,\"0\",0,1,1,\"${sample.qty}\"`,
      `TEXT 20,85,\"0\",0,1,1,\"${sample.total}\"`,
      `BARCODE 20,120,\"128\",70,1,0,2,2,\"${sample.barcode}\"`,
      "PRINT 1,1",
    ].join("\n");
  }

  window.ck_qz_examples = {
    receiptPayload,
    labelPayloadTspl,
  };
})();
