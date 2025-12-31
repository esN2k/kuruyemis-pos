#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT_DIR="$REPO_ROOT/docs/lisans-raporlari"

mkdir -p "$REPORT_DIR"

echo "[BILGI] Lisans raporları hazırlanıyor..."

if ! command -v python3 >/dev/null 2>&1; then
  echo "[HATA] Python 3 bulunamadı."
  exit 1
fi

build_python_report() {
  local name="$1"
  local req="$2"
  if [[ ! -f "$req" ]]; then
    echo "[UYARI] $name için requirements.txt bulunamadı: $req"
    return
  fi

  local tmp
  tmp="$(mktemp -d)"
  python3 -m venv "$tmp/venv"
  "$tmp/venv/bin/python" -m pip install --quiet --upgrade pip
  "$tmp/venv/bin/python" -m pip install --quiet -r "$req"
  "$tmp/venv/bin/python" -m pip install --quiet pip-licenses

  "$tmp/venv/bin/python" -m piplicenses --format=csv --output-file "$REPORT_DIR/python-$name.csv"
  "$tmp/venv/bin/python" -m piplicenses --format=json --output-file "$REPORT_DIR/python-$name.json"

  rm -rf "$tmp"
}

build_python_report "fiscal-adapter" "$REPO_ROOT/services/fiscal-adapter/requirements.txt"
build_python_report "hardware-bridge" "$REPO_ROOT/services/hardware-bridge/requirements.txt"

if ! find "$REPO_ROOT" -name package.json -not -path "*/node_modules/*" | grep -q .; then
  echo "Bu repoda package.json bulunamadı; Node lisans raporu üretilmedi." > "$REPORT_DIR/node-yok.txt"
fi

echo "[OK] Lisans raporları üretildi: $REPORT_DIR"
