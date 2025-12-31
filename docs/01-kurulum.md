# 01 - Kurulum

Bu doküman Windows + Docker Desktop kurulumunu ve ağ/port önkoşullarını anlatır.

## 1) Docker Desktop
- Docker Desktop'ı kurun ve **Linux kapsayıcıları** modunda çalıştırın.
- WSL2 desteği açık olmalı.

Doğrulama:
```powershell
docker version
```
Beklenen sonuç: Sunucu bilgisi görünür.

## 2) WSL2
WSL kurulu değilse:
```powershell
wsl --install
```
Beklenen sonuç: WSL2 kurulumu tamamlandıktan sonra yeniden başlatma istenir.

## 3) Hosts kaydı
Yerel alan adı için `hosts` dosyasına ekleyin:
```
127.0.0.1  kuruyemis.local
```
Dosya yolu: `C:\Windows\System32\drivers\etc\hosts`

## 4) Portlar
Aşağıdaki portlar boş olmalı:
- 8080 (Frappe/POS UI)
- 9000 (WebSocket)
- 3306 (MariaDB)
- 6379 (Redis)
- 8090 (Fiscal Adapter - opsiyonel)
- 8091 (Hardware Bridge - opsiyonel)
- 8182 (QZ Tray WebSocket)

Port çakışması kontrolü:
```powershell
.\scripts\windows\00-onkosul-kontrol.ps1
```

## 5) MariaDB sürüm pini (neden 10.6.x?)
Frappe/ERPNext tarafı 10.11+ sürümlerinde "test edilmemiş" uyarısı verebilir. Sahada kafa karışmaması için MariaDB **10.6.x** pinlenmiştir. Doktor kontrolü sürümü doğrular ve uyumsuz bir sürüm tespit ederse uyarı verir.

## 6) Kurulum komutları
Tek komut (önerilen):
```powershell
.\scripts\windows\kur.ps1
```

Adım adım kurulum:
```powershell
.\scripts\windows\00-onkosul-kontrol.ps1
.\scripts\windows\01-bootstrap.ps1
.\scripts\windows\02-baslat.ps1 -OpsiyonelServisler
.\scripts\windows\03-site-olustur.ps1 -SiteAdi kuruyemis.local -YoneticiSifresi admin
.\scripts\windows\04-uygulamalari-kur.ps1 -SiteAdi kuruyemis.local
```

Hızlı başlangıç için: `docs/00-hizli-baslangic.md`.

## 7) Opsiyonel modüller
Opsiyonel modüller **varsayılan kurulumda gelmez**. İsterseniz kurulum sırasında seçebilirsiniz:

```powershell
.\scripts\windows\04-uygulamalari-kur.ps1 -SiteAdi kuruyemis.local -OpsiyonelModuller insights,scale,print_designer
```

Tek komut kurulumda da aynı parametreyi verebilirsiniz:
```powershell
.\scripts\windows\kur.ps1 -OpsiyonelModuller insights,scale
```

Notlar:
- Modül isimleri küçük harf ve virgülle ayrılmış olmalıdır.
- “Bilinmeyen modül” uyarısı görürseniz isimleri tekrar kontrol edin.
