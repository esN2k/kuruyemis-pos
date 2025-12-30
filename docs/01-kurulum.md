# 01 - Kurulum

Bu doküman Windows + Docker Desktop kurulumunu ve ağ/port önkoşullarını anlatır.

## 1) Docker Desktop
- Docker Desktop'ı kurun ve **Linux kapsayıcıları** modunda çalıştırın
- WSL2 desteği açık olmalı

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
- 9000 (Websocket)
- 3306 (MariaDB)
- 6379 (Redis)
- 8090 (Fiscal Adapter – opsiyonel)
- 8091 (Hardware Bridge – opsiyonel)
- 8182 (QZ Tray WebSocket)

Port çakışması kontrolü:
```powershell
.\scripts\windows\00-onkosul-kontrol.ps1
```

## 5) İlk kurulum komutları
Hızlı başlangıç için `docs/00-hizli-baslangic.md`.
