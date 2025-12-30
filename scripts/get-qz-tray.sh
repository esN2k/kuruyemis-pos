#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSIONS_ENV="$ROOT_DIR/infra/versions.env"
OUTPUT_PATH="$ROOT_DIR/frappe_apps/ck_kuruyemis_pos/ck_kuruyemis_pos/public/js/qz/vendor/qz-tray.js"
DOC_PATH="$ROOT_DIR/docs/printing/qz-tray.md"

if [[ -z "$VERSION" ]]; then
  if [[ ! -f "$VERSIONS_ENV" ]]; then
    echo "versions.env bulunamadı: $VERSIONS_ENV" >&2
    exit 1
  fi
  VERSION=$(grep '^QZ_TRAY_REF=' "$VERSIONS_ENV" | head -n1 | cut -d'=' -f2-)
fi

if [[ -z "$VERSION" ]]; then
  echo "QZ Tray sürümü bulunamadı (QZ_TRAY_REF eksik)." >&2
  exit 1
fi

URL="https://raw.githubusercontent.com/qzind/tray/$VERSION/js/qz-tray.js"

printf "qz-tray.js indiriliyor: %s\n" "$URL"

if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$URL" -o "$OUTPUT_PATH"
elif command -v wget >/dev/null 2>&1; then
  wget -q "$URL" -O "$OUTPUT_PATH"
else
  echo "curl veya wget gerekli." >&2
  exit 1
fi

if command -v sha256sum >/dev/null 2>&1; then
  HASH=$(sha256sum "$OUTPUT_PATH" | awk '{print $1}')
elif command -v shasum >/dev/null 2>&1; then
  HASH=$(shasum -a 256 "$OUTPUT_PATH" | awk '{print $1}')
else
  echo "sha256sum veya shasum gerekli." >&2
  exit 1
fi

printf "SHA256: %s\n" "$HASH"

if [[ -f "$DOC_PATH" ]]; then
  START='<!-- QZ_TRAY_SHA256_START -->'
  END='<!-- QZ_TRAY_SHA256_END -->'
  TMP_FILE="$DOC_PATH.tmp"
  awk -v start="$START" -v end="$END" -v version="$VERSION" -v hash="$HASH" '
    BEGIN { inblock=0 }
    $0 ~ start {
      print start
      print "- Sürüm: " version
      print "- SHA256: " hash
      inblock=1
      next
    }
    $0 ~ end { inblock=0; print end; next }
    inblock==0 { print }
  ' "$DOC_PATH" > "$TMP_FILE"
  mv "$TMP_FILE" "$DOC_PATH"
fi
