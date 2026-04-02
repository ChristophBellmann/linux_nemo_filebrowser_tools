#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
actions_src="$repo_dir/actions"
scripts_src="$repo_dir/scripts"
config_src="$repo_dir/config"

data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
default_bin_dir="$HOME/.local/bin"

actions_dst="${NEMO_ACTIONS_DIR:-$data_home/nemo/actions}"
bin_dst="${BIN_DIR:-${XDG_BIN_HOME:-$default_bin_dir}}"
config_dst="${NEMO_CONFIG_DIR:-$config_home/nemo-actions}"
install_config="${INSTALL_NEMO_CONFIG:-1}"
overwrite_config="${OVERWRITE_NEMO_CONFIG:-0}"

mkdir -p "$actions_dst" "$bin_dst"

if [ "$install_config" = "1" ]; then
  mkdir -p "$config_dst"
fi

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

if [ "$install_config" = "1" ]; then
  found_configs=0
  for template in "$config_src"/*.conf.example; do
    [ -e "$template" ] || continue
    found_configs=1

    base_name="$(basename "$template" .example)"
    target="$config_dst/$base_name"
    dist_target="$config_dst/$(basename "$template")"

    install -m 0644 "$template" "$dist_target"

    if [ "$overwrite_config" = "1" ] || [ ! -e "$target" ]; then
      install -m 0644 "$template" "$target"
    fi
  done

  if [ "$found_configs" -eq 0 ]; then
    echo "Keine .conf.example-Dateien in $config_src gefunden." >&2
    exit 1
  fi
fi

echo "Installiert nach:"
echo "  $actions_dst"
echo "  $bin_dst"
if [ "$install_config" = "1" ]; then
  echo "  $config_dst"
fi
echo
echo "Nemo ggf. neu starten:"
echo "  nemo -q"
