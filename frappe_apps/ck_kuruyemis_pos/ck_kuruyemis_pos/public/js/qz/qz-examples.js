/* Example payloads for receipt and shelf label printing. */
(function () {
  "use strict";

  const t = (text) => (window.__ ? __(text) : text);
  const sample = {
    storeName: t("CK Kuruyemiş POS"),
    title: t("Bilgi Fişi (Mali Değil)"),
    itemName: t("Antep Fıstığı"),
    qty: t("0.250 kg"),
    unitPrice: t("375.00 TRY/kg"),
    total: t("93.75 TRY"),
    barcode: "2101234002508",
  };

  async function receiptPayload(options) {
    if (window.ck_receipt_builder && window.ck_receipt_builder.receiptPayload) {
      return window.ck_receipt_builder.receiptPayload(options);
    }

    const lines = [
      `${sample.storeName}\n`,
      `${sample.title}\n`,
      "---------------------------\n",
      `${t("Ürün")}: ${sample.itemName}\n`,
      `${t("Miktar")}: ${sample.qty}\n`,
      `${t("Fiyat")}: ${sample.unitPrice}\n`,
      `${t("Tutar")}: ${sample.total}\n`,
      "---------------------------\n",
      `${t("Teşekkürler!")}\n\n\n`,
    ].join("");

    // ESC/POS init + cut
    return "\x1B@" + lines + "\x1DV1";
  }

  function labelPayloadTspl() {
    return [
      "SIZE 38 mm,80 mm",
      "GAP 2 mm,0",
      "DENSITY 8",
      "SPEED 4",
      "DIRECTION 1",
      "CLS",
      `TEXT 20,20,\"0\",0,1,1,\"${sample.itemName}\"`,
      `TEXT 20,50,\"0\",0,1,1,\"${sample.qty}\"`,
      `TEXT 20,80,\"0\",0,1,1,\"${sample.total}\"`,
      `BARCODE 20,120,\"128\",80,1,0,2,2,\"${sample.barcode}\"`,
      "PRINT 1,1",
    ].join("\n");
  }

  window.ck_qz_examples = {
    receiptPayload,
    labelPayloadTspl,
  };
})();
