# 06 - Operasyon

## Başlat / Durdur
```powershell
.\scripts\windows\02-baslat.ps1
```
Durdurmak için:
```powershell
docker compose -f infra\frappe_docker\compose.yaml -f infra\docker-compose.override.yaml down
```

## Güncelleme (Pinli)
```powershell
.\scripts\windows\01-bootstrap.ps1
```
Beklenen: pinli sürümde kalır, tekrar çalıştırmak güvenlidir.

## Yedekleme
```powershell
.\scripts\windows\06-yedekle.ps1 -SiteAdi kuruyemis.local
```
Beklenen: `backups/` altında yeni klasör ve dosyalar.

## Geri Yükleme
```powershell
.\scripts\windows\07-geri-yukle.ps1 -SiteAdi kuruyemis.local -YedekKlasoru .\backups\kuruyemis.local\SON_YEDEK
```

## Destek Paketi
```powershell
.\scripts\windows\08-destek-paketi.ps1 -SiteAdi kuruyemis.local
```
Beklenen: `support_bundle/` altında zip.

## Loglar
- Docker: `docker compose logs -f`
- Site logları: container içinde `sites/<site>/logs`

## İzleme
```powershell
.\scripts\windows\05-doctor.ps1 -SiteAdi kuruyemis.local
```

## Opsiyonel Servisler
```powershell
.\scripts\windows\02-baslat.ps1 -OpsiyonelServisler
```
- `fiscal-adapter`: `http://localhost:8090/health`
- `hardware-bridge`: `http://localhost:8091/health`
