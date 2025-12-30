# Infra

Docker-based development uses the upstream `frappe_docker` compose files with a local override.

- Pinned versions: `infra/versions.md`
- Override compose: `infra/docker-compose.override.yaml`
- Scripts: `infra/start-dev.ps1`, `infra/new-site.ps1`, `infra/install-apps.ps1`

Optional services (enable with `./start-dev.ps1 -WithOptionalServices`):
- `fiscal-adapter` on port `8090`
- `hardware-bridge` on port `8091`
