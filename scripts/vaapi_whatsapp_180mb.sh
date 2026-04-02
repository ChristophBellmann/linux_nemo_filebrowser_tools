#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  vaapi_whatsapp_180mb.sh <input> [output.mp4] [target_mb]

Examples:
  vaapi_whatsapp_180mb.sh files/2026-03-25_16-36-38.mkv
  vaapi_whatsapp_180mb.sh input.mkv output.mp4 180

Environment overrides:
  VAAPI_DEVICE   (default: /dev/dri/renderD128 or first /dev/dri/renderD*)
  AUDIO_KBPS     (default: 128)
  MAX_WIDTH      (default: 1920)
  MAX_HEIGHT     (default: 1080)
  SAFETY_FACTOR  (default: 0.94, keeps output safely below target)
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -lt 1 || $# -gt 3 ]]; then
  usage >&2
  exit 1
fi

INPUT="$1"
OUTPUT="${2:-${INPUT%.*}_whatsapp.mp4}"
TARGET_MB="${3:-180}"
AUDIO_KBPS="${AUDIO_KBPS:-128}"
MAX_WIDTH="${MAX_WIDTH:-1920}"
MAX_HEIGHT="${MAX_HEIGHT:-1080}"
SAFETY_FACTOR="${SAFETY_FACTOR:-0.94}"

if [[ ! -f "$INPUT" ]]; then
  echo "Input file not found: $INPUT" >&2
  exit 1
fi

VAAPI_DEVICE="${VAAPI_DEVICE:-/dev/dri/renderD128}"
if [[ ! -e "$VAAPI_DEVICE" ]]; then
  VAAPI_DEVICE="$(ls /dev/dri/renderD* 2>/dev/null | head -n1 || true)"
fi
if [[ -z "$VAAPI_DEVICE" || ! -e "$VAAPI_DEVICE" ]]; then
  echo "No VA-API render device found under /dev/dri." >&2
  exit 1
fi

if ! ffmpeg -hide_banner -encoders 2>/dev/null | grep -i 'h264_vaapi' >/dev/null; then
  echo "ffmpeg does not provide h264_vaapi on this system." >&2
  exit 1
fi

DURATION="$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$INPUT")"
if [[ -z "$DURATION" ]]; then
  echo "Could not read duration from input file." >&2
  exit 1
fi

TOTAL_BITS="$(awk -v mb="$TARGET_MB" 'BEGIN {printf "%.0f", mb * 1000000 * 8}')"
VIDEO_KBPS="$(awk -v bits="$TOTAL_BITS" -v dur="$DURATION" -v a="$AUDIO_KBPS" -v sf="$SAFETY_FACTOR" \
  'BEGIN {v=((bits/dur)/1000 - a) * sf; if (v < 600) v=600; printf "%.0f", v}')"
BUF_KBPS="$((VIDEO_KBPS * 2))"

echo "Input       : $INPUT"
echo "Output      : $OUTPUT"
echo "Duration    : ${DURATION}s"
echo "Target size : ${TARGET_MB} MB"
echo "Video kbps  : ${VIDEO_KBPS}k (VA-API H.264)"
echo "Audio kbps  : ${AUDIO_KBPS}k (AAC)"
echo "VAAPI device: $VAAPI_DEVICE"

ffmpeg -y \
  -vaapi_device "$VAAPI_DEVICE" \
  -i "$INPUT" \
  -map 0:v:0 -map 0:a:0? \
  -vf "format=nv12,hwupload,scale_vaapi=w=${MAX_WIDTH}:h=${MAX_HEIGHT}:force_original_aspect_ratio=decrease" \
  -c:v h264_vaapi \
  -profile:v high -level:v 4.1 \
  -b:v "${VIDEO_KBPS}k" -maxrate "${VIDEO_KBPS}k" -bufsize "${BUF_KBPS}k" \
  -c:a aac -b:a "${AUDIO_KBPS}k" \
  -movflags +faststart \
  "$OUTPUT"

OUT_BYTES="$(stat -c%s "$OUTPUT")"
OUT_MB="$(awk -v b="$OUT_BYTES" 'BEGIN {printf "%.2f", b / 1000000}')"
echo "Done        : $OUTPUT (${OUT_MB} MB)"

if awk -v out="$OUT_BYTES" -v target="$TARGET_MB" 'BEGIN {exit !(out > target*1000000)}'; then
  echo "Warning: output is above target. Lower SAFETY_FACTOR (e.g. 0.90) and run again." >&2
fi
