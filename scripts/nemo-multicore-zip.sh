#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <path> [<path> ...]" >&2
  exit 1
fi

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

  systemd-run --user --scope -p MemoryMax=34G \
    tar --xattrs --acls --selinux -cpf "$tmpdir/$b.tar" -C "$d" "$b"

  chmod 0644 "$tmpdir/$b.tar"

  (
    cd "$tmpdir"
    7z a -t7z -m0=lzma2 -mx=9 -md=320m -mmt"$(nproc)" -snl "$out" "$b.tar"
  )

  rm -rf "$tmpdir"
  trap - EXIT
  echo "Erstellt: $out"
done
