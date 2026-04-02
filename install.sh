#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
actions_src="$repo_dir/actions"
scripts_src="$repo_dir/scripts"

data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
default_bin_dir="$HOME/.local/bin"

actions_dst="${NEMO_ACTIONS_DIR:-$data_home/nemo/actions}"
bin_dst="${BIN_DIR:-${XDG_BIN_HOME:-$default_bin_dir}}"

mkdir -p "$actions_dst" "$bin_dst"

found_actions=0
for action in "$actions_src"/*.nemo_action; do
  [ -e "$action" ] || continue
  install -m 0644 "$action" "$actions_dst/"
  found_actions=1
done

found_scripts=0
for script in "$scripts_src"/*.sh; do
  [ -e "$script" ] || continue
  install -m 0755 "$script" "$bin_dst/"
  found_scripts=1
done

if [ "$found_actions" -eq 0 ]; then
  echo "Keine .nemo_action-Dateien in $actions_src gefunden." >&2
  exit 1
fi

if [ "$found_scripts" -eq 0 ]; then
  echo "Keine .sh-Skripte in $scripts_src gefunden." >&2
  exit 1
fi

echo "Installiert nach:"
echo "  $actions_dst"
echo "  $bin_dst"
echo
echo "Nemo ggf. neu starten:"
echo "  nemo -q"
