# Dev Setup (Docker)

This project follows the official `frappe_docker` layout and uses a thin override file for local development.

## Prereqs
- Docker Desktop
- Git

## Bootstrap
1) Fetch `frappe_docker` at the pinned commit:

```powershell
./scripts/bootstrap-frappe-docker.ps1
```

2) Review `infra/versions.md` and confirm the pinned branches in `infra/frappe_docker.env`.

3) Start the stack:

```powershell
cd infra
# Uses upstream compose + our override
./start-dev.ps1
```

To include optional services (fiscal-adapter + hardware-bridge):

```powershell
./start-dev.ps1 -WithOptionalServices
```

## Create a site
```powershell
cd infra
./new-site.ps1 -SiteName kuruyemis.local -AdminPassword admin -MariaDBRootPassword admin
```

## Install ERPNext + POS Awesome + ck_kuruyemis_pos
```powershell
cd infra
./install-apps.ps1 -SiteName kuruyemis.local
```

## QZ Tray vendor JS
```powershell
./scripts/get-qz-tray.ps1
```

## Notes
- POS Awesome must match the ERPNext major version. If you bump ERPNext, update `infra/versions.md` and `infra/frappe_docker.env` together.
- All custom code lives under `frappe_apps/ck_kuruyemis_pos`.
- Optional services:
  - `fiscal-adapter` on port `8090` (env: `FISCAL_DEVICE_IP`, `FISCAL_DEVICE_PORT`, `FISCAL_APP_NO`, `FISCAL_TIMEOUT_SECONDS`)
  - `hardware-bridge` on port `8091`
