#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
actions_src="$repo_dir/actions"
scripts_src="$repo_dir/scripts"

actions_dst="${HOME}/.local/share/nemo/actions"
bin_dst="${HOME}/.local/bin"

mkdir -p "$actions_dst" "$bin_dst"

install -m 0644 \
  "$actions_src/extract_tar7z_to_moar_space.nemo_action" \
  "$actions_src/multicore-zip.nemo_action" \
  "$actions_src/vaapi-whatsapp-180mb.nemo_action" \
  "$actions_dst/"

install -m 0755 \
  "$scripts_src/nemo-extract-tar7z-here.sh" \
  "$scripts_src/nemo-multicore-zip.sh" \
  "$scripts_src/nemo-vaapi-whatsapp-action.sh" \
  "$scripts_src/vaapi_whatsapp_180mb.sh" \
  "$bin_dst/"

echo "Installiert nach:"
echo "  $actions_dst"
echo "  $bin_dst"
echo
echo "Nemo ggf. neu starten:"
echo "  nemo -q"
