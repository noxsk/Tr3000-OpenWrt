#!/bin/sh
# Compile the firmware. OpenWrt BTF builds require a Linux host.

set -eu

if [ "$(uname -s)" != "Linux" ]; then
	echo "This build host is $(uname -s). Compile on Linux so BTF stays enabled." >&2
	exit 1
fi

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
WORK=$(CDPATH= cd -- "$ROOT/.." && pwd)
BUILD="${BUILD_DIR:-$WORK/build/immortalwrt-mt798x-rebase}"

"$ROOT/scripts/prepare.sh"
if [ "${USE_CCACHE:-}" = "1" ]; then
	ccache -s || true
fi
make -C "$BUILD" -j"$(nproc)"
if [ "${USE_CCACHE:-}" = "1" ]; then
	ccache -s || true
fi
"$ROOT/scripts/check-image.sh"
