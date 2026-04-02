#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <archive.tar.7z>" >&2
  exit 1
fi

archive="$1"

if [ ! -f "$archive" ]; then
  echo "Datei nicht gefunden: $archive" >&2
  exit 1
fi

cd "$(dirname "$archive")"
7z x -so "$archive" | pv | tar -x
