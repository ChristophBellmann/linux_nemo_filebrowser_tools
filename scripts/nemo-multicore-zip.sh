#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  nemo-multicore-zip.sh <path> [<path> ...]

Configuration:
  The script reads optional overrides from:
    $XDG_CONFIG_HOME/nemo-actions/multicore-zip.conf
  or:
    ~/.config/nemo-actions/multicore-zip.conf

Environment variables:
  NEMO_7Z_PRESET          safe | balanced | aggressive | legacy
  NEMO_7Z_RAM_BUDGET_GIB  Approximate compression memory target in GiB
  NEMO_7Z_THREADS         Explicit 7z thread count
  NEMO_7Z_DICT            7z dictionary size, e.g. 64m, 128m, 1g
  NEMO_7Z_LEVEL           Compression level 1..9
  NEMO_7Z_ESTIMATE_FACTOR Heuristic multiplier per encoder instance
  NEMO_TAR_MEMORY_MAX     Optional systemd-run MemoryMax for tar stage

Notes:
  The memory estimate is heuristic for 7z LZMA2 compression and should be
  treated as a planning aid, not a hard guarantee.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [ "$#" -lt 1 ]; then
  usage >&2
  exit 1
fi

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
config_file="${NEMO_7Z_CONFIG_FILE:-$config_home/nemo-actions/multicore-zip.conf}"
if [ -r "$config_file" ]; then
  # shellcheck disable=SC1090
  . "$config_file"
fi

require_positive_int() {
  local name="$1"
  local value="$2"

  if [[ ! "$value" =~ ^[0-9]+$ ]] || [ "$value" -le 0 ]; then
    echo "$name must be a positive integer, got: $value" >&2
    exit 1
  fi
}

parse_size_to_mib() {
  local raw="${1,,}"
  local number unit

  if [[ "$raw" =~ ^([0-9]+)([kmg])?$ ]]; then
    number="${BASH_REMATCH[1]}"
    unit="${BASH_REMATCH[2]}"
  else
    echo "Unsupported size value: $1" >&2
    exit 1
  fi

  case "$unit" in
    ""|m)
      echo "$number"
      ;;
    g)
      echo $((number * 1024))
      ;;
    k)
      echo $(((number + 1023) / 1024))
      ;;
    *)
      echo "Unsupported size unit in: $1" >&2
      exit 1
      ;;
  esac
}

format_gib() {
  awk -v mib="$1" 'BEGIN {printf "%.2f", mib / 1024}'
}

min_int() {
  if [ "$1" -le "$2" ]; then
    echo "$1"
  else
    echo "$2"
  fi
}

cpu_threads="$(nproc)"
preset="${NEMO_7Z_PRESET:-balanced}"
estimate_factor="${NEMO_7Z_ESTIMATE_FACTOR:-11}"
tar_memory_max="${NEMO_TAR_MEMORY_MAX:-2G}"

require_positive_int "NEMO_7Z_ESTIMATE_FACTOR" "$estimate_factor"

case "$preset" in
  safe)
    preset_level=7
    preset_dict=64m
    preset_threads_cap=4
    ;;
  balanced)
    preset_level=9
    preset_dict=128m
    preset_threads_cap=8
    ;;
  aggressive)
    preset_level=9
    preset_dict=256m
    preset_threads_cap=12
    ;;
  legacy)
    preset_level=9
    preset_dict=320m
    preset_threads_cap="$cpu_threads"
    ;;
  *)
    echo "Unknown preset: $preset" >&2
    exit 1
    ;;
esac

level="${NEMO_7Z_LEVEL:-$preset_level}"
dict="${NEMO_7Z_DICT:-$preset_dict}"

require_positive_int "NEMO_7Z_LEVEL" "$level"
dict_mib="$(parse_size_to_mib "$dict")"

threads_cap="$(min_int "$preset_threads_cap" "$cpu_threads")"
threads="${NEMO_7Z_THREADS:-}"
budget_warning=0

if [ -n "${NEMO_7Z_RAM_BUDGET_GIB:-}" ]; then
  require_positive_int "NEMO_7Z_RAM_BUDGET_GIB" "$NEMO_7Z_RAM_BUDGET_GIB"
  budget_mib="$((NEMO_7Z_RAM_BUDGET_GIB * 1024))"
  per_instance_mib="$((dict_mib * estimate_factor))"
  max_instances="$((budget_mib / per_instance_mib))"

  if [ -z "$threads" ]; then
    if [ "$max_instances" -lt 1 ]; then
      threads=1
      budget_warning=1
    else
      threads="$((max_instances * 2))"
      if [ "$threads" -gt "$threads_cap" ]; then
        threads="$threads_cap"
      fi
      if [ "$threads" -lt 1 ]; then
        threads=1
      fi
    fi
  fi
else
  budget_mib=""
fi

if [ -z "$threads" ]; then
  threads="$threads_cap"
fi

require_positive_int "NEMO_7Z_THREADS" "$threads"

effective_instances="$(((threads + 1) / 2))"
estimated_mib="$((effective_instances * dict_mib * estimate_factor))"
estimated_gib="$(format_gib "$estimated_mib")"

if [ -n "$budget_mib" ] && [ "$estimated_mib" -gt "$budget_mib" ]; then
  budget_warning=1
fi

echo "7z preset             : $preset"
echo "7z level              : -mx$level"
echo "7z dictionary         : -md$dict (${dict_mib} MiB)"
echo "7z threads            : -mmt$threads"
echo "Estimated 7z memory   : ~${estimated_gib} GiB"
if [ -n "$budget_mib" ]; then
  echo "Requested RAM budget  : ~$(format_gib "$budget_mib") GiB"
fi
if [ "$budget_warning" -eq 1 ]; then
  echo "Warning: configured budget is below the heuristic estimate for these settings." >&2
fi
echo

run_tar() {
  if command -v systemd-run >/dev/null 2>&1; then
    systemd-run --user --scope -p "MemoryMax=$tar_memory_max" "$@"
  else
    "$@"
  fi
}

for f in "$@"; do
  f="${f%/}"
  d="$(dirname "$f")"
  b="$(basename "$f")"
  out="$f.tar.7z"

  # Temp workspace on the same filesystem as source to avoid root/tmp bottlenecks.
  tmpdir="$(mktemp -d --tmpdir="$d" .nemo-multicore-zip.XXXXXX)"

  cleanup() {
    rm -rf "$tmpdir"
  }
  trap cleanup EXIT

  run_tar tar --xattrs --acls --selinux -cpf "$tmpdir/$b.tar" -C "$d" "$b"

  chmod 0644 "$tmpdir/$b.tar"

  (
    cd "$tmpdir"
    7z a -t7z -m0=lzma2 "-mx$level" "-md$dict" "-mmt$threads" -snl "$out" "$b.tar"
  )

  rm -rf "$tmpdir"
  trap - EXIT
  echo "Erstellt: $out"
done
