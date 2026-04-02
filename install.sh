#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./install.sh [options]

Installable tools:
  --all                 Install all current Nemo tools
  --extract-tar7z       Install the tar.7z extraction action
  --multicore-zip       Install the multicore 7z creation action
  --vaapi-whatsapp      Install the WhatsApp MP4 VA-API action

General options:
  -h, --help            Show this help
  --no-config           Do not install config files
  --overwrite-config    Overwrite existing active config files
  --no-merge-ram        Do not merge missing RAM settings into multicore-zip.conf

Environment overrides:
  NEMO_ACTIONS_DIR
  BIN_DIR
  NEMO_CONFIG_DIR
  XDG_DATA_HOME
  XDG_BIN_HOME
  XDG_CONFIG_HOME
  INSTALL_NEMO_CONFIG
  OVERWRITE_NEMO_CONFIG
  MERGE_NEMO_RAM_SETTINGS

Examples:
  ./install.sh --all
  ./install.sh --vaapi-whatsapp
  ./install.sh --extract-tar7z --multicore-zip
EOF
}

if [ "$#" -eq 0 ]; then
  usage
  exit 0
fi

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

declare -a selected_tools=()

add_tool() {
  local tool="$1"
  local existing
  for existing in "${selected_tools[@]}"; do
    if [ "$existing" = "$tool" ]; then
      return 0
    fi
  done
  selected_tools+=("$tool")
}

select_all_tools() {
  selected_tools=()
  add_tool "extract-tar7z"
  add_tool "multicore-zip"
  add_tool "vaapi-whatsapp"
}

sync_missing_keys() {
  local source_config="$1"
  local target="$2"
  local key value
  shift 2

  [ -e "$target" ] || return 0

  for key in "$@"; do
    if grep -Eq "^[[:space:]]*${key}=" "$target"; then
      continue
    fi

    value="$(awk -F= -v key="$key" '$1 == key {sub(/^[^=]*=/, "", $0); print $0; exit}' "$source_config")"
    [ -n "$value" ] || continue
    printf '%s=%s\n' "$key" "$value" >> "$target"
  done
}

install_config_file() {
  local base_name="$1"
  local source_config="$config_src/$base_name"
  local target="$config_dst/$base_name"

  [ -e "$source_config" ] || {
    echo "Fehlende Config-Datei: $source_config" >&2
    exit 1
  }

  if [ "$overwrite_config" = "1" ] || [ ! -e "$target" ]; then
    install -m 0644 "$source_config" "$target"
    return 0
  fi

  if [ "$merge_ram_settings" = "1" ] && [ "$base_name" = "multicore-zip.conf" ]; then
    sync_missing_keys \
      "$source_config" \
      "$target" \
      NEMO_7Z_RAM_BUDGET_GIB \
      NEMO_7Z_THREADS \
      NEMO_7Z_DICT \
      NEMO_7Z_ESTIMATE_FACTOR \
      NEMO_TAR_MEMORY_MAX
  fi
}

install_tool() {
  local tool="$1"

  case "$tool" in
    extract-tar7z)
      install -m 0644 \
        "$actions_src/extract_tar7z_to_moar_space.nemo_action" \
        "$actions_dst/"
      install -m 0755 \
        "$scripts_src/nemo-extract-tar7z-here.sh" \
        "$bin_dst/"
      ;;
    multicore-zip)
      install -m 0644 \
        "$actions_src/multicore-zip.nemo_action" \
        "$actions_dst/"
      install -m 0755 \
        "$scripts_src/nemo-multicore-zip.sh" \
        "$bin_dst/"
      if [ "$install_config" = "1" ]; then
        install_config_file "multicore-zip.conf"
      fi
      ;;
    vaapi-whatsapp)
      install -m 0644 \
        "$actions_src/vaapi-whatsapp-180mb.nemo_action" \
        "$actions_dst/"
      install -m 0755 \
        "$scripts_src/nemo-vaapi-whatsapp-action.sh" \
        "$scripts_src/vaapi_whatsapp_180mb.sh" \
        "$bin_dst/"
      if [ "$install_config" = "1" ]; then
        install_config_file "vaapi-whatsapp-180mb.conf"
      fi
      ;;
    *)
      echo "Unknown tool: $tool" >&2
      exit 1
      ;;
  esac
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --all)
      select_all_tools
      ;;
    --extract-tar7z)
      add_tool "extract-tar7z"
      ;;
    --multicore-zip)
      add_tool "multicore-zip"
      ;;
    --vaapi-whatsapp)
      add_tool "vaapi-whatsapp"
      ;;
    --no-config)
      install_config=0
      ;;
    --overwrite-config)
      overwrite_config=1
      ;;
    --no-merge-ram)
      merge_ram_settings=0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if [ "${#selected_tools[@]}" -eq 0 ]; then
  usage
  exit 0
fi

mkdir -p "$actions_dst" "$bin_dst"
if [ "$install_config" = "1" ]; then
  mkdir -p "$config_dst"
fi

for tool in "${selected_tools[@]}"; do
  install_tool "$tool"
done

echo "Installierte Tools:"
for tool in "${selected_tools[@]}"; do
  echo "  $tool"
done
echo
echo "Installiert nach:"
echo "  $actions_dst"
echo "  $bin_dst"
if [ "$install_config" = "1" ]; then
  echo "  $config_dst"
fi
echo
echo "Nemo ggf. neu starten:"
echo "  nemo -q"
