#!/usr/bin/env bash
# download_and_install_model.sh
set -euo pipefail

URL="${1:-}"
if [[ -z "${URL}" ]]; then
  echo "Usage: $0 <PRESIGNED_S3_URL>"
  exit 1
fi

TARGET_DIR="${HOME}/workspace/finetuned_model"
TMP_DIR="$(mktemp -d)"
ARCHIVE="${TMP_DIR}/archive.tar"
EXTRACT_DIR="${TMP_DIR}/extracted"

mkdir -p "${TARGET_DIR}" "${EXTRACT_DIR}"

echo "[1/3] Downloading..."
# -L follows redirects; -f fails on HTTP errors; --retry handles flakiness
curl -fL --retry 3 --retry-connrefused --continue-at - \
  -o "${ARCHIVE}" "${URL}"

echo "[2/3] Extracting..."
# Try gzip first; fall back to plain tar
if tar -tzf "${ARCHIVE}" >/dev/null 2>&1; then
  tar -xzf "${ARCHIVE}" -C "${EXTRACT_DIR}"
else
  tar -xf "${ARCHIVE}" -C "${EXTRACT_DIR}"
fi

echo "[3/3] Copying to ${TARGET_DIR}..."
# Use rsync if available for robust copying; otherwise cp -a
if command -v rsync >/dev/null 2>&1; then
  rsync -a "${EXTRACT_DIR}/" "${TARGET_DIR}/"
else
  cp -a "${EXTRACT_DIR}/." "${TARGET_DIR}/"
fi

echo "✔ Done."
