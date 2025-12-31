import { chromium } from "playwright";

function getArg(name, fallback) {
  const idx = process.argv.indexOf(name);
  if (idx !== -1 && process.argv[idx + 1]) {
    return process.argv[idx + 1];
  }
  return fallback;
}

function toInt(value, fallback) {
  const parsed = Number.parseInt(value, 10);
  return Number.isNaN(parsed) ? fallback : parsed;
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
const adminPass = getArg("--admin-pass", "admin");
const timeout = toInt(getArg("--timeout-ms", "30000"), 30000);
const baseUrl = baseUrlRaw.replace(/\/$/, "");

const errors = [];
const pageErrors = [];

async function fillFirst(page, selectors, value) {
  for (const selector of selectors) {
    const locator = page.locator(selector).first();
    if ((await locator.count()) > 0) {
      await locator.fill(value);
      return true;
    }
  }
  return false;
}

async function clickFirst(page, selectors) {
  for (const selector of selectors) {
    const locator = page.locator(selector).first();
    if ((await locator.count()) > 0) {
      await locator.click();
      return true;
    }
  }
  return false;
}

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
    const rootResp = await page.goto(`${baseUrl}/`, { waitUntil: "domcontentloaded", timeout });
    if (!rootResp || rootResp.status() >= 400) {
      throw new Error(`Ana sayfa HTTP ${rootResp ? rootResp.status() : "?"} döndü.`);
    }

    await page.goto(`${baseUrl}/login`, { waitUntil: "domcontentloaded", timeout });
    const emailOk = await fillFirst(page, ["#login_email", "input[name='email']", "input[type='text']"], "Administrator");
    const passOk = await fillFirst(page, ["#login_password", "input[name='password']", "input[type='password']"], adminPass);
    if (!emailOk || !passOk) {
      throw new Error("Login formu bulunamadı.");
    }

    const clicked = await clickFirst(page, ["button[type='submit']", "#login_btn", ".btn-login"]);
    if (!clicked) {
      throw new Error("Giriş butonu bulunamadı.");
    }
    await page.waitForURL(/\/app(\/|$)/, { timeout });

    await page.goto(`${baseUrl}/app/pos_printer_setup`, { waitUntil: "domcontentloaded", timeout });
    let setupOk = false;
    try {
      await page.waitForSelector("text=POS Yazıcı Kurulumu", { timeout: 10000 });
      setupOk = true;
    } catch {}
    if (!setupOk) {
      try {
        await page.waitForSelector("text=POS Printer Setup", { timeout: 5000 });
        setupOk = true;
      } catch {}
    }
    if (!setupOk) {
      throw new Error("POS Yazıcı Kurulumu sayfası render olmadı.");
    }

    await page.goto(`${baseUrl}/app/posawesome/point-of-sale`, { waitUntil: "domcontentloaded", timeout });
    try {
      await page.waitForSelector("#posawesome-app", { timeout: 20000 });
    } catch {
      throw new Error("POS Awesome sayfası render olmadı.");
    }

    if (errors.length > 0 || pageErrors.length > 0) {
      throw new Error(`Console/page error tespit edildi: ${[...errors, ...pageErrors].join(" | ")}`);
    }

    console.log("[OK] UI duman testi başarılı.");
  } catch (err) {
    await browser.close();
    fail("UI duman testi başarısız.", err);
  }

  await browser.close();
})();
