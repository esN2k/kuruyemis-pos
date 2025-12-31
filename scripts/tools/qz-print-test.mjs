import { chromium } from "playwright";

function getArg(name, fallback) {
  const idx = process.argv.indexOf(name);
  if (idx !== -1 && process.argv[idx + 1]) {
    return process.argv[idx + 1];
  }
  return fallback;
}

function fail(message, err) {
  if (err) {
    console.error(`[HATA] ${message}`);
    console.error(String(err));
  } else {
    console.error(`[HATA] ${message}`);
  }
  process.exit(1);
}

const baseUrlRaw = getArg("--base-url", "http://kuruyemis.local:8080");
const receiptPrinter = getArg("--receipt", "");
const labelPrinter = getArg("--label", "");
const preset = getArg("--preset", "38x80_hizli");
const baseUrl = baseUrlRaw.replace(/\/$/, "");

if (!receiptPrinter || !labelPrinter) {
  fail("Yazıcı adı eksik. --receipt ve --label zorunludur.");
}

const errors = [];
const pageErrors = [];

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  page.on("console", (msg) => {
    if (msg.type() === "error") {
      errors.push(msg.text());
    }
  });
  page.on("pageerror", (err) => {
    pageErrors.push(err?.message || String(err));
  });

  try {
    const resp = await page.goto(`${baseUrl}/`, { waitUntil: "domcontentloaded", timeout: 30000 });
    if (!resp || resp.status() >= 400) {
      throw new Error(`Ana sayfa HTTP ${resp ? resp.status() : "?"} döndü.`);
    }

    await page.addScriptTag({ url: `${baseUrl}/assets/ck_kuruyemis_pos/js/qz/vendor/qz-tray.js` });
    await page.addScriptTag({ url: `${baseUrl}/assets/ck_kuruyemis_pos/js/qz/qz-wrapper.js` });
    await page.addScriptTag({ url: `${baseUrl}/assets/ck_kuruyemis_pos/js/qz/qz-examples.js` });

    await page.evaluate(
      async ({ receiptPrinter, labelPrinter, preset }) => {
        window.ck_qz_security = {
          certificatePromise: () => Promise.resolve(null),
          signaturePromise: () => Promise.resolve(null),
        };
        if (!window.ck_qz || !window.ck_qz_examples) {
          throw new Error("QZ modülü yüklenemedi.");
        }
        const receiptPayload = await window.ck_qz_examples.receiptPayload({ template: "kuruyemis" });
        const labelPayload = await window.ck_qz_examples.labelPayloadTspl({ template: "kuruyemis", preset });
        await window.ck_qz.printRaw(receiptPrinter, receiptPayload);
        await window.ck_qz.printRaw(labelPrinter, labelPayload);
      },
      { receiptPrinter, labelPrinter, preset }
    );

    if (errors.length > 0 || pageErrors.length > 0) {
      throw new Error(`Console/page error tespit edildi: ${[...errors, ...pageErrors].join(" | ")}`);
    }

    console.log("[OK] QZ test baskısı başarılı.");
  } catch (err) {
    await browser.close();
    fail("QZ test baskısı başarısız.", err);
  }

  await browser.close();
})();
