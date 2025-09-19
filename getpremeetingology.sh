#!/usr/bin/env bash
# Usage: ./fetch_ubuntu_logs.sh urls.txt
# or:   cat urls.txt | ./fetch_ubuntu_logs.sh

set -euo pipefail

infile="${1:--}"

while IFS= read -r url; do
  # skip empty/comment lines
  [[ -z "$url" || "$url" =~ ^# ]] && continue

  # extract parts: path like /2011/12/19/%23ubuntu-meeting.html#t14:12
  path="${url#*://*/}"   # remove protocol+host
  path="${url#*/}"       # remove host if previous failed
  # Better: use parameter expansion with host removal
  path="${url#*ubuntu.com/}"

  # get date components
  year="$(echo "$path" | cut -d'/' -f1)"
  month="$(echo "$path" | cut -d'/' -f2)"
  day_and_rest="$(echo "$path" | cut -d'/' -f3-)"   # e.g. 19/%23ubuntu-meeting.html#t14:12

  day="$(echo "$day_and_rest" | cut -d'/' -f1)"

  # extract filename part and optional fragment time
  file_and_frag="$(echo "$day_and_rest" | cut -d'/' -f2-)"  # e.g. %23ubuntu-meeting.html#t14:12
  base_with_hash="${file_and_frag%%#*}"                     # %23ubuntu-meeting.html
  frag="${file_and_frag#*#}"                                # t14:12 or the whole string if no #

  # decode %23 to #
  # use printf %b with URL decoding for limited cases
  decoded="$(printf '%b' "${base_with_hash//%/\\x}")" 2>/dev/null || decoded="$base_with_hash"
  # remove leading #
  decoded="${decoded#\#}"

  # strip .html if present then keep it for extension later
  ext=""
  name="${decoded}"
  if [[ "$name" == *.html ]]; then
    name="${name%.html}"
    ext=".html"
  fi

  # parse time fragment like t14:12 or t14:12:05
  timepart=""
  if [[ "$frag" =~ ^t([0-9]{1,2}):([0-9]{2})(:([0-9]{2}))? ]]; then
    hh="${BASH_REMATCH[1]}"
    mm="${BASH_REMATCH[2]}"
    ss="${BASH_REMATCH[4]:-}"
    if [[ -n "$ss" ]]; then
      timepart=".$hh.$mm.$ss"
    else
      timepart=".$hh.$mm"
    fi
  fi

  out="${name}.${year}-${month}-${day}${timepart}.premeetingology${ext}"

  # fetch and save
  echo "Fetching: $url -> $out"
  curl -sSf "$url" -o "$out" || { echo "Failed: $url" >&2; continue; }

done <"${infile}"

