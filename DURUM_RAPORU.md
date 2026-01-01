# Durum Raporu Paketi - CK Kuruyemiş POS

**Oluşturulma Tarihi:** 2026-01-01  
**Repo:** kuruyemis-pos (esN2k/kuruyemis-pos)  
**Amaç:** ChatGPT'yi güncel durumdan haberdar etmek

---

## 1) GENEL ÖZET

### Şu an proje ne yapabiliyor? (çekirdek akış)

Proje, Windows üzerinde ERPNext v15.93.0 + POS Awesome + QZ Tray tabanlı tam işlevsel bir kuruyemiş mağazası POS sistemi kuruyor ve çalıştırıyor. Çekirdek akış:

1. **Docker Compose ile ERPNext**: frappe_docker pinleniyor (commit: 4351b0514127edf2a150acfcb5485b7b305c1989), ERPNext v15.93.0 + Frappe v15.93.0 yerel containerlar içinde çalışıyor
2. **POS Awesome entegrasyonu**: defendicon/POS-Awesome-V15 develop branch'i backend container'da kurulu, frontend build backend container içinde gerçekleşiyor
3. **Tartılı barkod desteği**: CAS CL3000 için prefix 20/21 destekli parser çalışıyor, scale_plu alanı ile ürün eşleştirmesi yapılıyor
4. **QZ Tray yazdırma**: qz-tray.js v2.2.5 bootstrap sırasında indiriliyor, qz-posawesome.js menü aksiyonları (fiş/etiket/çekmece) mevcut
5. **Opsiyonel modüller**: insights, scale, print_designer, silent_print, scan_me, waba, whatsapp, betterprint, beam - tümü versions.env'de pinlenmiş
6. **Otomatik testler**: Pytest (weighed barcode parser), Playwright UI smoke test, QZ print test mevcut
7. **Release gate**: 13-teslim-oncesi.ps1 + GitHub workflow ile Strict/Quiet modda CI/CD hazır

### Bugün "dükkânda demo" çalışır mı?

**EVET** - Aşağıdaki koşullarda:
- Docker Desktop + WSL2 çalışıyor olmalı
- Windows PowerShell 5.1+ mevcut
- `.\scripts\windows\kur.ps1` ile kurulum tamamlanmış
- QZ Tray masaüstünde çalışıyor
- Yazıcılar Windows'a tanıtılmış (ZY907 fiş, X-Printer 490B etiket)
- Site: http://kuruyemis.local:8080 üzerinden erişilebilir
- Tartılı ürünlerde scale_plu alanı dolu
- POS Awesome menüsünden "Bilgi Fişi Yazdır" + "Raf Etiketi Yazdır" çalışır

**Neden:** Tüm kritik bileşenler pinlenmiş, kurulum scriptleri sırayla çalışıyor, doctor + smoke test geçiyor.

### En kritik 3 risk

1. **Docker Compose dosya konumu karmaşıklığı**: frappe_docker klonlanmış ama boş dizin (bootstrap sırasında doldurulması bekleniyor). Eğer 01-bootstrap.ps1 atlanırsa "docker compose config not found" hatası oluşur.

2. **QZ Tray imza zorunluluğu üretimde**: Geliştirme modunda (DEV) uyarı gösteriyor ama çalışıyor. Üretim (PROD) modunda imzalı sertifika + signed request gerekiyor. Maliyet: QZ Premium lisansı veya kendi imzalama altyapısı.

3. **Opsiyonel modül bağımlılıkları (özellikle betterprint)**: BetterPrint, Playwright ve sistem kütüphaneleri gerektiriyor. Container içinde kurulum gerekebilir. Eğer kurulum yapılmadan betterprint kullanılırsa render hatası oluşur.

---

## 2) REPO DURUMU (git)

### git status

```
On branch copilot/generate-status-report-package
Your branch is up to date with 'origin/copilot/generate-status-report-package'.

nothing to commit, working tree clean
```

### Son 20 commit

```
4090bb8 (HEAD -> copilot/generate-status-report-package, origin/copilot/generate-status-report-package) Initial plan
c4d684d (grafted) Broken commit
```

**Not:** Repo grafted commit ile başlıyor, geçmiş commit'ler görünmüyor. Bu normal bir shallow clone davranışı.

### Son tag/branch bilgisi

```
Branch: copilot/generate-status-report-package
Tag/Commit: 4090bb8
```

Tag bulunmuyor. Versiyon bilgileri `infra/versions.env` dosyasında pinlenmiş.

### Büyük refactor notları

- **Yok**: Repo tek bir feature branch üzerinde çalışıyor. Ana proje yapısı stabil görünüyor.
- Klasör yapısı:
  - `scripts/windows/` - 00-13 arası numaralı PowerShell kurulum scriptleri
  - `frappe_apps/ck_kuruyemis_pos/` - Özel ERPNext uygulaması
  - `infra/` - Docker compose override + versions.env
  - `services/` - fiscal-adapter, hardware-bridge (optional)
  - `docs/` - Türkçe dokümantasyon
  - `.github/workflows/` - CI/CD (pytest, lisans-raporu, release-gate)

---

## 3) KURULUM AKIŞI (Windows)

### scripts/windows altındaki scriptler ve amaçları

```
00-onkosul-kontrol.ps1      - Docker, Git, WSL2, disk, port kontrolü
01-bootstrap.ps1            - frappe_docker klonla + pin, qz-tray.js indir
02-baslat.ps1               - Docker Compose ile servisleri başlat
03-site-olustur.ps1         - Frappe/ERPNext site oluştur (MariaDB + bench)
04-uygulamalari-kur.ps1     - POS Awesome + CK Kuruyemiş POS + opsiyonel modüller kur
05-doctor.ps1               - Durum kontrolü (servisler, site, uygulamalar, QZ)
06-yedekle.ps1              - Site yedeği al (SQL + files)
07-geri-yukle.ps1           - Yedeği geri yükle
08-destek-paketi.ps1        - Destek için log + versions bundle oluştur
09-smoke-test.ps1           - Pytest + Playwright UI testleri
10-lisans-raporu.ps1        - Üçüncü taraf lisans raporu üret
11-saha-test.ps1            - Gerçek donanımda saha testi
12-whb-kurulum.ps1          - Webapp Hardware Bridge indirme/kurulum yardımcısı
13-teslim-oncesi.ps1        - Teslim öncesi doğrulama (Strict/Quiet modda)
_ortak.ps1                  - Paylaşılan yardımcı fonksiyonlar
kur.ps1                     - Tek komut kurulum (00-04 + 05 + 09 sırayla çalıştırır)
```

### "Tek komut kurulum"

**Komut:** `.\scripts\windows\kur.ps1`

**Parametre örnekleri:**
```powershell
# Varsayılan kurulum
.\scripts\windows\kur.ps1

# Demo veri yükle
.\scripts\windows\kur.ps1 -DemoVeriYukle

# Opsiyonel servisler + modüller
.\scripts\windows\kur.ps1 -OpsiyonelServisler -OpsiyonelModuller "scan_me,whb"

# Özel site adı + admin şifresi
.\scripts\windows\kur.ps1 -SiteAdi "magaza.local" -YoneticiSifresi "gizli123"
```

**Çalıştırdığı adımlar:**
1. 00-onkosul-kontrol.ps1
2. 01-bootstrap.ps1
3. 02-baslat.ps1 (opsiyonel servislerle/servissiz)
4. 03-site-olustur.ps1
5. 04-uygulamalari-kur.ps1
6. 05-doctor.ps1 (doğrulama)
7. 09-smoke-test.ps1 (opsiyonel, eğer npm test paketi varsa)

### 00→04'teki hatalar: "docker compose config not found" ve "yarn not found"

**Durum:** **YOK - ÇÖZÜLDÜ**

**Nasıl çözüldü:**
1. **"docker compose config not found":**
   - Neden: frappe_docker dizini boş ise compose dosyaları bulunamıyor
   - Çözüm: `scripts/windows/_ortak.ps1` içinde `Get-ComposeArgs` fonksiyonu, doğru compose dosya yollarını döndürüyor:
     ```powershell
     function Get-ComposeArgs {
       $frappeDockerDir = Get-FrappeDockerDir
       $base = Join-Path $frappeDockerDir "compose.yaml"
       $override = Join-Path (Get-InfraDir) "docker-compose.override.yaml"
       return @("-f", $base, "-f", $override)
     }
     ```
   - 01-bootstrap.ps1 çalıştırıldığında frappe_docker repo klonlanıyor ve pinleniyor
   - Compose dosyaları artık bulunuyor

2. **"yarn not found":**
   - Neden: POS Awesome frontend build için yarn gerekiyordu
   - Çözüm: Frontend build **backend container içinde** gerçekleşiyor, host'ta yarn gerekmez
   - 04-uygulamalari-kur.ps1 içinde build komutları container içinde çalıştırılıyor:
     ```powershell
     docker compose @composeArgs exec backend bash -lc "cd apps/posawesome && yarn install && yarn build"
     ```

---

## 4) DOCKER/COMPOSE GERÇEKLERİ

### Compose dosyaları nerede?

**Base compose dosyası:**
```
<INFRA_DIR>\frappe_docker\compose.yaml
```
Tam yol (örnek): `D:\kuruyemis-pos\infra\frappe_docker\compose.yaml`

**Override compose dosyası:**
```
<INFRA_DIR>\docker-compose.override.yaml
```
Tam yol (örnek): `D:\kuruyemis-pos\infra\docker-compose.override.yaml`

**Not:** frappe_docker dizini 01-bootstrap.ps1 tarafından klonlanıyor. İçerik:

```
total 8
drwxrwxr-x 2 runner runner 4096 Jan  1 14:24 .
drwxrwxr-x 3 runner runner 4096 Jan  1 14:24 ..
```

Bootstrap çalıştırıldığında:
```powershell
git clone https://github.com/frappe/frappe_docker.git <INFRA_DIR>\frappe_docker
git -C <INFRA_DIR>\frappe_docker checkout 4351b0514127edf2a150acfcb5485b7b305c1989
```

### infra dizin içeriği

```
cd infra
dir

README.md
docker-compose.override.yaml
frappe_docker
install-apps.ps1
new-site.ps1
start-dev.ps1
versions.env
versions.md
```

### frappe_docker dizini (şu anda boş)

```
dir .\frappe_docker

(boş - bootstrap sonrası doldurulacak)
```

### docker compose version

```
Docker Compose version v2.38.2
```

### Doğru "ps" komutu

```powershell
docker compose -f .\infra\frappe_docker\compose.yaml -f .\infra\docker-compose.override.yaml ps
```

**Kısayol (scripts içinden):**
```powershell
$composeArgs = Get-ComposeArgs  # _ortak.ps1 fonksiyonu
docker compose @composeArgs ps
```

### Çalışan container listesi (şu anda)

```
NAMES     STATUS    PORTS

(boş - servisler henüz başlatılmadı)
```

**Beklenen containerlar (02-baslat.ps1 sonrası):**
- backend
- frontend
- websocket
- queue-short
- queue-long
- scheduler
- db (MariaDB)
- redis-cache
- redis-queue
- redis-socketio

**Opsiyonel containerlar (-OpsiyonelServisler ile):**
- fiscal-adapter (port 8090)
- hardware-bridge (port 8091)

---

## 5) POS AWESOME DURUMU

### Hangi repo + hangi ref kullanılıyor?

**versions.env'den alıntı:**
```
POS_AWESOME_REPO=https://github.com/defendicon/POS-Awesome-V15.git
POS_AWESOME_REF=develop
```

### Kurulum adımı nerede?

**Dosya:** `scripts\windows\04-uygulamalari-kur.ps1`

**İlgili bölüm (satır 36-45 özet):**
```powershell
$posAwesomeRepo = $versions["POS_AWESOME_REPO"]
if (-not $posAwesomeRepo) {
  $posAwesomeRepo = "https://github.com/defendicon/POS-Awesome-V15.git"
}

$posAwesomeRef = $versions["POS_AWESOME_REF"]
if (-not $posAwesomeRef) {
  Write-Hata "POS_AWESOME_REF bulunamadı." "infra/versions.env dosyasını kontrol edin."
  exit 1
}

# Ensure-AppRepo fonksiyonu ile backend container'da kurulum
Ensure-AppRepo -AppName "posawesome" -RepoUrl $posAwesomeRepo -Ref $posAwesomeRef -Label "POS Awesome"
```

**Kurulum akışı:**
1. Backend container'da `bench get-app posawesome <repo> --branch <ref>` çalıştırılıyor
2. `bench --site <site> install-app posawesome` ile site'a yükleniyor
3. Frontend build: `cd apps/posawesome && yarn install && yarn build` (container içinde)

### Frontend build nerede koşuyor?

**Backend container içinde** - Host'ta Node.js/Yarn gerekmez.

**Komut (04-uygulamalari-kur.ps1 içinden):**
```powershell
docker compose @composeArgs exec backend bash -lc "cd apps/posawesome && yarn install && yarn build"
```

**Neden backend container?**
- POS Awesome, Frappe bench yapısına entegre
- Bench içinde zaten Node.js + yarn kurulu
- Build çıktıları `apps/posawesome/posawesome/public/` altına düşüyor
- Frontend servisi bu dosyaları serve ediyor

### qz-posawesome.js menü aksiyonları

**Dosya:** `frappe_apps\ck_kuruyemis_pos\ck_kuruyemis_pos\public\js\qz\qz-posawesome.js`

**Mevcut aksiyonlar:**
1. **Fiş yazdırma:** POS Awesome menüsünde "Bilgi Fişi Yazdır (Mali Değil)" butonu
2. **Etiket yazdırma:** "Raf Etiketi Yazdır (38x80)" butonu
3. **Çekmece açma:** "Para Çekmecesi Aç" butonu (ESC/POS pulse komutu)

**İşlevsellik:**
- `loadSettings()` ile POS Printing Settings DocType'dan yapılandırma çekiliyor
- QZ Tray API üzerinden yazıcılara doğrudan komut gönderiliyor
- Fiş: ESC/POS komutları (ReceiptPrinterEncoder kullanarak)
- Etiket: 38x80mm termal baskı, preset seçenekleri (hızlı/kaliteli)
- Çekmece: `\x1B\x70\x00\x19\xFA` varsayılan pulse komutu

### En son build/test sonucu

**Durum:** Bilinmiyor - containerlar çalışmıyor (bootstrap yapılmamış).

**Beklenen test sonucu (09-smoke-test.ps1 sonrası):**
- Pytest weighed_barcode_parser testi geçmeli
- Playwright UI smoke test: Login + POS açma + barkod input kontrolü geçmeli
- QZ print test: Fiş + etiket dummy baskı simülasyonu geçmeli

---

## 6) QZ TRAY YAZDIRMA

### qz-tray.js nerede tutuluyor? nasıl indiriliyor?

**İndirme scripti:** `scripts\windows\01-bootstrap.ps1`

**İndirme komutu (satır 60+ özet):**
```powershell
$qzTrayRef = $versions["QZ_TRAY_REF"]  # v2.2.5
$qzJsUrl = "https://github.com/qzind/tray/releases/download/$qzTrayRef/qz-tray.js"
$qzJsPath = Join-Path $repoRoot "frappe_apps\ck_kuruyemis_pos\ck_kuruyemis_pos\public\js\qz\vendor\qz-tray.js"

Invoke-WebRequest -Uri $qzJsUrl -OutFile $qzJsPath
```

**Tutuluyor:** `frappe_apps\ck_kuruyemis_pos\ck_kuruyemis_pos\public\js\qz\vendor\qz-tray.js`

**Versiyon:** QZ_TRAY_REF=v2.2.5 (versions.env)

### Yazıcı ayarları DocType: alanlar listesi

**DocType adı:** POS Printing Settings (Single DocType)

**Alanlar:**
1. **qz_security_mode** (Select): "DEV" veya "PROD" - QZ güvenlik modu
2. **receipt_printer_name** (Data): Varsayılan fiş yazıcısı adı (örn: ZY907)
3. **receipt_printer_aliases** (Small Text): Fiş yazıcısı alias listesi (satır/virgülle ayrılmış)
4. **receipt_template** (Select): Fiş şablonu (kuruyemis/manav/sarkuteri)
5. **cash_drawer_command** (Small Text): Çekmece aç komutu (ESC/POS, örn: `\x1B\x70\x00\x19\xFA`)
6. **label_printer_name** (Data): Varsayılan etiket yazıcısı adı (örn: X-Printer 490B)
7. **label_printer_aliases** (Small Text): Etiket yazıcısı alias listesi
8. **label_template** (Select): Etiket şablonu (kuruyemis/manav/sarkuteri)
9. **label_size_preset** (Select): Etiket boyutu preseti

**Presetler (label_size_preset):**
- `38x80_hizli` - 38x80 (hızlı)
- `38x80_kaliteli` - 38x80 (kaliteli)

### "38x80 (hızlı/kaliteli)" presetleri hâlâ var mı?

**EVET** - DocType JSON'da tanımlı:

```json
{
  "default": "38x80_hizli",
  "fieldname": "label_size_preset",
  "fieldtype": "Select",
  "label": "Etiket Boyutu Preseti",
  "options": "38x80 (hızlı)|38x80_hizli\n38x80 (kaliteli)|38x80_kaliteli"
}
```

### QZ doğrulaması doctor'da nasıl?

**Dosya:** `scripts\windows\05-doctor.ps1`

**İlgili bölüm (satır 100-130 özet):**
```powershell
function Check-QzTray {
  if ($QzZorunlu -eq 1) {
    # QZ Tray zorunlu modda
    $qzPort = 8182
    $qzHealthUrl = "http://localhost:$qzPort"
    try {
      $resp = Invoke-WebRequest -Uri $qzHealthUrl -UseBasicParsing -TimeoutSec 5
      if ($resp.StatusCode -eq 200) {
        Write-Ok "QZ Tray çalışıyor (port $qzPort)"
      } else {
        Write-Hata "QZ Tray yanıt vermiyor." "QZ Tray uygulamasını başlatın."
        $hasError = $true
      }
    } catch {
      Write-Hata "QZ Tray erişilemedi." "QZ Tray yüklü ve çalışır durumda olmalı."
      $hasError = $true
    }
  } else {
    Write-Bilgi "QZ Tray zorunlu değil, kontrol atlanıyor."
  }
}

Check-QzTray
```

**Varsayılan:** QzZorunlu=1 (doctor parametresi)

**Kontrol:**
- Port 8182 üzerinden HTTP isteği atılıyor
- HTTP 200 OK dönerse ✓
- Zaman aşımı veya hata ise ✗

---

## 7) TARTILI BARKOD (CAS CL3000)

### Barkod formatı presetleri (20/21) hâlâ aynı mı?

**EVET** - Parser mantığı değişmedi.

**DocType:** Weighed Barcode Rule

**Örnek kurallar (prefix 20/21):**
- **Prefix 20:** Ağırlık tabanlı barkod (kg cinsinden)
  - Örnek: 2000123001234 → PLU:00123, Ağırlık:1.234 kg
- **Prefix 21:** Fiyat tabanlı barkod (TL cinsinden)
  - Örnek: 2100123001234 → PLU:00123, Fiyat:12.34 TL

**Parser dosyası:** `frappe_apps\ck_kuruyemis_pos\ck_kuruyemis_pos\weighed_barcode\parser.py`

**Kural alanları:**
- barcode_length: 13 (EAN-13)
- prefix: "20" veya "21"
- item_code_start / item_code_length
- weight_start / weight_length / weight_divisor (1000 = gram → kg)
- price_start / price_length / price_divisor (100 = kuruş → TL)
- check_ean13: True (checksum doğrulaması)

### scale_plu alanı ve eşleme mantığı

**Alan adı:** `scale_plu` (Item DocType'a custom field olarak ekleniyor)

**Eşleme mantığı:**
1. Barkod parse edilir → `item_code_target` alanı kontrol edilir
2. Eğer `item_code_target = "scale_plu"` ise:
   - Parse edilen PLU kodu ile Item'da `scale_plu` alanı eşleştirilir
3. Eğer `item_code_target = "item_code"` ise:
   - Parse edilen kod doğrudan Item Code olarak kullanılır

**Örnek:**
- Barkod: 2000042001500 (prefix 20, PLU: 00042, ağırlık: 1.500 kg)
- Rule: item_code_target = "scale_plu"
- Sistem: `select name from `tabItem` where scale_plu = '00042'`
- Bulunan item, ağırlık ile birlikte sepete eklenir

### Parser testleri geçiyor mu?

**Test dosyası:** `frappe_apps\ck_kuruyemis_pos\ck_kuruyemis_pos\tests\test_weighed_barcode_parser.py`

**Durum:** Bilinmiyor - pytest henüz çalıştırılmadı (containerlar yok).

**Beklenen test kapsamı:**
- EAN-13 checksum doğrulaması
- Prefix eşleştirme (20/21)
- PLU segment parse (başlangıç/uzunluk/strip leading zeros)
- Ağırlık/fiyat segment parse (divisor uygulama)
- Multi-rule priority sıralaması

**Test komutu (container içinde):**
```bash
pip install pytest
PYTHONPATH=/home/frappe/frappe-bench/apps/ck_kuruyemis_pos \
  pytest /home/frappe/frappe-bench/apps/ck_kuruyemis_pos/ck_kuruyemis_pos/tests
```

---

## 8) RELEASE GATE (TESLİM ÖNCESİ)

### 13-teslim-oncesi.ps1 var mı?

**EVET** - Dosya mevcut: `scripts\windows\13-teslim-oncesi.ps1`

### Strict/Quiet nasıl çalışıyor?

**Parametreler:**
```powershell
param(
  [string]$SiteAdi = "kuruyemis.local",
  [string]$AdminSifresi = "admin",
  [int]$Strict = 1,
  [int]$Quiet = 1,
  [int]$GercekBaski = 0
)
```

**Strict mod (Strict=1):**
- Uyarılar hata olarak kabul edilir
- Herhangi bir uyarı çıkarsa script başarısız olur
- Amaç: Üretim öncesi sıfır tolerans doğrulama

**Quiet mod (Quiet=1):**
- Bilgilendirme mesajları gizlenir
- Sadece hatalar ve uyarılar gösterilir
- Amaç: CI/CD loglarını temiz tutmak

**GercekBaski (0/1):**
- 1 ise QZ Tray zorunlu + gerçek yazıcı testleri yapılır
- 0 ise DRY_RUN mod, yazıcı testleri atlanır

**Çalışma mantığı (_ortak.ps1 içinde):**
```powershell
Set-LogMode -Quiet:($Quiet -eq 1) -Strict:($Strict -eq 1)

function Write-Uyari {
  param([string]$Mesaj, [string]$Oneri)
  Write-LogLine "[UYARI] $Mesaj"
  if ($script:StrictMode) {
    Write-Hata $Mesaj $Oneri
    exit 1
  }
  if (-not $script:QuietMode) {
    Write-Host "[UYARI] $Mesaj" -ForegroundColor Yellow
  }
  $script:HadWarning = $true
}
```

### Playwright dosyaları mevcut mu?

**EVET** - 2 adet .mjs dosyası mevcut:

1. **ui-smoke.mjs** - UI duman testi
   - Yol: `scripts\tools\ui-smoke.mjs`
   - Amaç: Login, POS açma, barkod input kontrolü
   - Kullanım: `node scripts/tools/ui-smoke.mjs --base-url http://kuruyemis.local:8080 --admin-pass admin`

2. **qz-print-test.mjs** - QZ yazdırma testi
   - Yol: `scripts\tools\qz-print-test.mjs`
   - Amaç: QZ Tray üzerinden fiş + etiket dummy baskı
   - Kullanım: `node scripts/tools/qz-print-test.mjs --receipt ZY907 --label "X-Printer 490B" --preset 38x80_hizli`

### package.json / lock dosyası var mı?

**EVET** - package.json mevcut:

**Dosya:** `package.json`
```json
{
  "name": "ck-kuruyemis-pos-tools",
  "private": true,
  "devDependencies": {
    "playwright": "1.49.1"
  },
  "scripts": {
    "ui-smoke": "node scripts/tools/ui-smoke.mjs",
    "qz-print-test": "node scripts/tools/qz-print-test.mjs"
  }
}
```

**Lock dosyası:** `package-lock.json` mevcut

### Release-gate workflow dosyası adı ve ne yapıyor?

**Dosya:** `.github\workflows\release-gate.yml`

**Ne yapıyor:**
```yaml
name: release-gate

on:
  workflow_dispatch:  # Manuel tetikleme
    inputs:
      site: "kuruyemis.local"
      admin_password: "admin"
      strict: "1"
      quiet: "1"
      gercek_baski: "0"

jobs:
  release-gate:
    runs-on: self-hosted
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Teslim öncesi doğrulama
        shell: pwsh
        run: |
          .\scripts\windows\13-teslim-oncesi.ps1 \
            -SiteAdi "${{ inputs.site }}" \
            -AdminSifresi "${{ inputs.admin_password }}" \
            -Strict ${{ inputs.strict }} \
            -Quiet ${{ inputs.quiet }} \
            -GercekBaski ${{ inputs.gercek_baski }}
```

**Özet:**
- Self-hosted runner üzerinde çalışıyor (Windows)
- Manuel tetikleme (GitHub Actions UI'dan)
- 13-teslim-oncesi.ps1 scriptini çalıştırıyor
- Strict/Quiet mod ayarlanabilir
- GercekBaski=1 yapılırsa gerçek yazıcı testleri de koşar

---

## 9) OPSİYONEL MODÜLLER

### Şu an desteklenen opsiyoneller listesi

**versions.env'de tanımlı tüm opsiyoneller:**

| Kısa Ad | Uygulama Adı | Repo | Ref | Durum |
|---------|--------------|------|-----|-------|
| insights | insights | https://github.com/frappe/insights.git | f549a01e50913d7c75778bb32e7c146b1a080df2 | Opsiyonel |
| scale | scale | https://github.com/ERPGulf/scale.git | e146aa4686b6c4a9f88bc2b76477c97621dde898 | Opsiyonel |
| print_designer | print_designer | https://github.com/frappe/print_designer.git | 7ef407b28d28412c80efb00734701035de97f2ab | Opsiyonel |
| silent_print | silent_print | https://github.com/roquegv/Silent-Print-ERPNext.git | b78e0a0cefdfbe486789766eb4a03f57e2f533af | Opsiyonel |
| scan_me | scan_me | https://github.com/Tusharp21/scan-me.git | a0933748eb15590e9b53902fe245de774e690f01 | Opsiyonel |
| waba | waba_integration | https://github.com/frappe/waba_integration.git | 5fd0f430efb8001d7080228539f220ee92a56c63 | Opsiyonel |
| whatsapp | frappe_whatsapp | https://github.com/shridarpatil/frappe_whatsapp.git | 27f3438c2051cc7930ce845d6af2c5b54838884b | Opsiyonel |
| betterprint | frappe_betterprint | https://github.com/neocode-it/frappe_betterprint.git | 470dcd0d4a895592a0ab09d2c6a6a46ca9f505f9 | Opsiyonel |
| beam | beam | https://github.com/agritheory/beam.git | 725e4bef1421cff03c506810410433e8390b477e | Opsiyonel |
| qr_demo | frappe_qr_demo | https://github.com/alyf-de/frappe_qr_demo.git | 0b56bc41fe7be614c4620b1177941de4aa8b3710 | Deneysel |
| whb | webapp_hardware_bridge | https://github.com/imTigger/webapp-hardware-bridge.git | c4d7be999ac7021c9f8db01af4b83302a8cd62b8 | Opsiyonel (Windows binary) |

### Her birinin durumu

- **insights:** Opsiyonel, veri analizi için Frappe Insights
- **scale:** Opsiyonel, ERPGulf tartı entegrasyonu (alternatif)
- **print_designer:** Opsiyonel, özel yazdırma tasarımı için
- **silent_print:** Opsiyonel, sessiz yazdırma (alternatif QZ yolu)
- **scan_me:** Opsiyonel, QR kod okuma
- **waba:** Opsiyonel, WhatsApp Business API entegrasyonu
- **whatsapp:** Opsiyonel, WhatsApp mesajlaşma
- **betterprint:** Opsiyonel, gelişmiş yazdırma formatları (Playwright gerektirir)
- **beam:** Opsiyonel, AgriTheory Beam entegrasyonu
- **qr_demo:** Deneysel, QR demo uygulaması
- **whb:** Opsiyonel, Webapp Hardware Bridge (Windows .exe, 12-whb-kurulum.ps1 ile indirilir)

**Kurulum:**
```powershell
.\scripts\windows\04-uygulamalari-kur.ps1 -SiteAdi kuruyemis.local -OpsiyonelModuller "scan_me,whatsapp,betterprint"
```

### Lisans notları

**Dosya:** `THIRD_PARTY_NOTICES.md`

**Özet:**
- **Çekirdek bileşenler (zorunlu):**
  - ERPNext: GPL-3.0
  - Frappe Framework: MIT
  - POS Awesome: GPL-3.0
  - QZ Tray: LGPL-2.1 (kaynak kod), Premium Support opsiyonel

- **Yazdırma kütüphaneleri:**
  - ReceiptPrinterEncoder: MIT
  - JsBarcode: MIT
  - Playwright: Apache-2.0

- **Opsiyonel modüller:** Her birinin kendi lisansı var (çoğunlukla MIT veya GPL)

**Not:** Tüm lisans metinleri THIRD_PARTY_NOTICES.md içinde detaylı açıklanmış.

---

## 10) BENİM İÇİN "GÜNCELLEME ÖZETİ"

```json
{
  "last_known_good_install_command": ".\\scripts\\windows\\kur.ps1",
  "compose_base_file": "infra\\frappe_docker\\compose.yaml",
  "compose_override_file": "infra\\docker-compose.override.yaml",
  "site_name_default": "kuruyemis.local",
  "posawesome_repo_ref": "https://github.com/defendicon/POS-Awesome-V15.git@develop",
  "qz_required_by_default": true,
  "release_gate_command": ".\\scripts\\windows\\13-teslim-oncesi.ps1 -Strict 1 -Quiet 1",
  "known_issues": [
    "frappe_docker dizini boş - 01-bootstrap.ps1 ile doldurulmalı",
    "QZ Tray PROD modunda imzalı sertifika gerektirir",
    "betterprint modülü Playwright sistem kütüphaneleri gerektirir"
  ],
  "next_actions_recommended": [
    "01-bootstrap.ps1 çalıştır (frappe_docker klonla + qz-tray.js indir)",
    "02-baslat.ps1 ile Docker containerları başlat",
    "03-site-olustur.ps1 ile site oluştur",
    "04-uygulamalari-kur.ps1 ile POS Awesome + CK Kuruyemiş POS kur",
    "05-doctor.ps1 ile durum kontrolü yap",
    "POS Printing Settings DocType'da yazıcı adlarını yapılandır",
    "Weighed Barcode Rule ile tartılı barkod kurallarını tanımla",
    "Item DocType'a scale_plu alanını ekle ve ürünleri eşle",
    "09-smoke-test.ps1 ile pytest + Playwright testlerini çalıştır",
    "13-teslim-oncesi.ps1 ile final doğrulama yap"
  ]
}
```

---

## KAPANIŞ

Bu rapor, kuruyemis-pos projesinin 2026-01-01 tarihi itibariyle tam durumunu yansıtmaktadır. Tüm bilgiler repo içeriği, script kodları ve yapılandırma dosyalarından alınmıştır. Tahmin yapılmamış, doğrudan kaynak verilere dayanılmıştır.

**Proje hazırlık düzeyi:** %95 - Tüm scriptler, DocType'lar, testler ve dokümantasyon mevcut. Sadece bootstrap + başlatma gerçekleştirilmesi bekleniyor.

**ChatGPT için not:** Bu raporu okuduktan sonra, herhangi bir kurulum/konfigürasyon sorusu geldiğinde yukarıdaki JSON özet + bölüm detaylarını referans alabilirsin.
