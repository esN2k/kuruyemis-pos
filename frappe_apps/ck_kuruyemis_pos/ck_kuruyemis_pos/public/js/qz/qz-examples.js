/* Example raw payloads for receipt and shelf label printing. */
(function () {
  "use strict";

  function receiptPayload() {
    const lines = [
      "CK KURUYEMIS POS\n",
      "Non-fiscal receipt (demo)\n",
      "---------------------------\n",
      "Item: Antep Pistachio\n",
      "Qty : 0.250 kg\n",
      "Price: 375.00 TRY/kg\n",
      "Total: 93.75 TRY\n",
      "---------------------------\n",
      "Thank you!\n\n\n",
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
      "TEXT 20,20,\"0\",0,1,1,\"Antep Pistachio\"",
      "TEXT 20,50,\"0\",0,1,1,\"0.250 kg\"",
      "TEXT 20,80,\"0\",0,1,1,\"93.75 TRY\"",
      "BARCODE 20,120,\"128\",80,1,0,2,2,\"2101234002508\"",
      "PRINT 1,1",
    ].join("\n");
  }

  window.ck_qz_examples = {
    receiptPayload,
    labelPayloadTspl,
  };
})();