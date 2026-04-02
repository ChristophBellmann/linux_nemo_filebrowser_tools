#!/usr/bin/env bash
set -euo pipefail

src="$(readlink -f "$1")"

command -v zenity >/dev/null || { echo "zenity fehlt"; exit 1; }
command -v pv >/dev/null || { echo "pv fehlt"; exit 1; }
command -v pigz >/dev/null || { echo "pigz fehlt"; exit 1; }
command -v tar >/dev/null || { echo "tar fehlt"; exit 1; }

target="$(zenity --file-selection --directory --title="Zielordner fuer Archiv waehlen")" || exit 0

name="$(basename "$src")"
out="$target/$name.tar.gz"
log="$(mktemp /tmp/nemo-pack.XXXXXX.log)"
fifo="$(mktemp -u)"
mkfifo "$fifo"

# Grobe Groesse fuer pv; fuer Verzeichnisse gut genug fuer die Fortschrittsanzeige.
size="$(du -sb -- "$src" | awk '{print $1}')"

zenity --progress --title="Packe $name" --text="Erstelle $out" --percentage=0 --auto-close --no-cancel < "$fifo" &
zpid=$!

set +e
tar -cf - -- "$src" 2>>"$log" | pv -n -s "$size" 2> "$fifo" | pigz -9 -p "$(nproc)" 2>>"$log" > "$out"
rc=$?
set -e

exec 3>"$fifo"
exec 3>&-
wait "$zpid" 2>/dev/null || true
rm -f "$fifo"

if [ $rc -ne 0 ]; then
  rm -f "$out"
  zenity --error --title="Fehler beim Packen" --text="Archiv wurde nicht erstellt.\n\nDetails:\n$(tail -n 60 "$log")"
else
  zenity --info --title="Fertig" --text="Archiv erstellt:\n$out"
fi

rm -f "$log"
