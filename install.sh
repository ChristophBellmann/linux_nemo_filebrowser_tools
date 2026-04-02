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
merge_ram_settings="${MERGE_NEMO_RAM_SETTINGS:-1}"

sync_multicore_zip_ram_settings() {
  local source_config="$1"
  local target="$2"
  local key value
  local -a ram_keys=(
    NEMO_7Z_RAM_BUDGET_GIB
    NEMO_7Z_THREADS
    NEMO_7Z_DICT
    NEMO_7Z_ESTIMATE_FACTOR
    NEMO_TAR_MEMORY_MAX
  )

  [ -e "$target" ] || return 0

  for key in "${ram_keys[@]}"; do
    if grep -Eq "^[[:space:]]*${key}=" "$target"; then
      continue
    fi

    value="$(awk -F= -v key="$key" '$1 == key {sub(/^[^=]*=/, "", $0); print $0; exit}' "$source_config")"
    [ -n "$value" ] || continue
    printf '%s=%s\n' "$key" "$value" >> "$target"
  done
}

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
  for source_config in "$config_src"/*.conf; do
    [ -e "$source_config" ] || continue
    found_configs=1

    base_name="$(basename "$source_config")"
    target="$config_dst/$base_name"

    if [ "$overwrite_config" = "1" ] || [ ! -e "$target" ]; then
      install -m 0644 "$source_config" "$target"
    elif [ "$merge_ram_settings" = "1" ] && [ "$base_name" = "multicore-zip.conf" ]; then
      sync_multicore_zip_ram_settings "$source_config" "$target"
    fi
  done

  if [ "$found_configs" -eq 0 ]; then
    echo "Keine .conf-Dateien in $config_src gefunden." >&2
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
