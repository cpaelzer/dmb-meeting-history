#!/usr/bin/env bash
## SPDX-License-Identifier: MIT
# Copyright (c) 2025 Christian Ehrhardt <paelzer@gmail.com>
set -exuo pipefail

# Configuration
BASE_URL="https://ubottu.com/meetingology/logs/ubuntu-meeting"
USER_AGENT="fetch-moin/1.0 (+https://example.com/)"
TMP_PAGE="$(mktemp)"

for year in $(seq 2011 2025); do
  # Prep for iteration
  yurl="${BASE_URL}/${year}/"
  mkdir -p "${year}"

  # Fetch the directory listing
  curl -sSL -A "$USER_AGENT" "$yurl" -o "$TMP_PAGE"

  # Extract hrefs that end with .moin.txt (handles quoted/unquoted, relative links)
  # This produces absolute URLs when input contains absolute hrefs; otherwise it prefixes BASE_URL.
  grep -oE 'href=["'\'']?[^"'\'' >]+' "$TMP_PAGE" \
    | sed -E 's/^href=["'\'']?//' \
    | grep -E '\.moin\.txt$' \
    | while read -r link; do
      # If link is absolute (starts with http), use as-is; otherwise prefix BASE_URL
      if printf '%s' "$link" | grep -qE '^https?://'; then
        url="$link"
      else
        # Strip any leading ./ or / to form proper URL
        link="${link#./}"
        link="${link#/}"
        url="${yurl%/}/$link"
      fi

      echo "Downloading: $url"
      wget -q -U "$USER_AGENT" -P "${year}" "$url"
    done

  echo "Saved .moin.txt files to: ${year}"
  ls -laF "${year}/"
done

# Clean up
rm -f "$TMP_PAGE"
