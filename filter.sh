#!/usr/bin/env bash
## SPDX-License-Identifier: MIT
# Copyright (c) 2025 Christian Ehrhardt <paelzer@gmail.com>
set -euo pipefail

DEST="../dmb"
DRY_RUN=1

usage(){
  cat <<EOF
Usage: $0 [--run]
  --run   Actually move files. Default: dry-run.
EOF
  exit 1
}

if [[ "${1:-}" == "--run" ]]; then
  DRY_RUN=0
elif [[ "${1:-}" != "" ]]; then
  usage
fi

# Positive patterns (extended regex)
POS='(#startmeeting[[:space:]]+Developer[[:space:]]+Membership[[:space:]]+Board|#topic[[:space:]]+Per-Package[[:space:]]+Uploader[[:space:]]+application|#topic[[:space:]]+Ubuntu[[:space:]]+Contributing[[:space:]]+Developer[[:space:]]+Applications|#topic[[:space:]]+MOTU[[:space:]]+Application|#topic[[:space:]]+Core[[:space:]]+Dev[[:space:]]+application|wiki.*Application)'
# Negative patterns (if any of these match, skip the file)
NEG='(#startmeeting[[:space:]]+LoCo[[:space:]]*Council|#startmeeting[[:space:]]+Community[[:space:]]+Council|Team\/ApprovalApplication|TeamApprovalApplication|CommunityCouncilAgenda|for Ubuntu Membership)'

FILES_GLOB='*/ubuntu-meeting.*.moin.txt'

shopt -s nullglob
candidates=( $FILES_GLOB )
shopt -u nullglob

if [[ ${#candidates[@]} -eq 0 ]]; then
  echo "No candidate files found."
  exit 0
fi

echo "Destination: $DEST"
echo "Dry run: $([[ $DRY_RUN -eq 1 ]] && echo yes || echo no)"
echo

for f in "${candidates[@]}"; do
  if grep -Ei "$POS" "$f"; then
    if grep -Eiq "$NEG" "$f"; then
      echo "SKIP (negative match): $f"
      continue
    fi
    rel="${f#./}"
    year_dir="${rel%%/*}"
    dest_dir="$DEST/$year_dir"
    dest_path="$dest_dir/$(basename "$rel")"
    echo "MOVE: $f -> $dest_path"
    if [[ $DRY_RUN -eq 0 ]]; then
      mkdir -p "$dest_dir"
      mv -n -- "$f" "$dest_path" || echo "Warning: failed to move $f"
    fi
  fi
done

echo
echo "Done. Use --run to perform moves."

