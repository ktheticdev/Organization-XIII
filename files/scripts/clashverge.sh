#!/usr/bin/env bash
set -euo pipefail

REPO="clash-verge-rev/clash-verge-rev"
API_URL="https://api.github.com/repos/${REPO}/releases/latest"

echo "Fetching latest release metadata..."

DOWNLOAD_URL=$(curl -sL "$API_URL" \
  | grep -Eo '"browser_download_url":\s*"[^"]+\.x86_64\.rpm"' \
  | sed -E 's/.*"([^"]+)".*/\1/' \
  | head -n 1)

if [[ -z "$DOWNLOAD_URL" ]]; then
  echo "ERROR: Could not find x86_64 RPM in latest release."
  exit 1
fi

echo "Found RPM:"
echo "$DOWNLOAD_URL"

FILENAME=$(basename "$DOWNLOAD_URL")

echo "Downloading $FILENAME..."
curl -L -o "$FILENAME" "$DOWNLOAD_URL"

echo "Done."

dnf -y install --setopt=install_weak_deps=False --assumeno --disablerepo="*" "$FILENAME"
dnf clean all
