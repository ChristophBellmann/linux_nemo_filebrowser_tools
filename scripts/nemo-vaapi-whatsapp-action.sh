#!/usr/bin/env bash
set -u

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$script_dir/vaapi_whatsapp_180mb.sh"

"$SCRIPT" "$@"
rc=$?

if [[ $rc -ne 0 ]]; then
  echo
  echo "Fehler beim Konvertieren (Exit $rc)."
  echo "Taste druecken zum Schliessen..."
  read -r _
fi

exit $rc
