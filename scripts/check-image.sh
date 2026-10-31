#!/bin/sh
# Require the TR3000 sysupgrade image, then collect it with build records and kmods.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
WORK=$(CDPATH= cd -- "$ROOT/.." && pwd)
BUILD="${BUILD_DIR:-$WORK/build/immortalwrt-mt798x-rebase}"
bin="$BUILD/bin/targets/mediatek/filogic"
dest="$(dirname "$BUILD")/artifact"

found=
for image in "$bin"/*cudy_tr3000-v1-mtkuboot*sysupgrade*; do
	if [ -s "$image" ]; then
		found=$image
		break
	fi
done

if [ -z "$found" ]; then
	echo "sysupgrade image for cudy_tr3000-v1-mtkuboot was not produced" >&2
	exit 1
fi

rm -rf "$dest"
mkdir -p "$dest/kmods"
cp "$found" "$dest/"
for extra in sha256sums profiles.json; do
	if [ -f "$bin/$extra" ]; then
		cp "$bin/$extra" "$dest/"
	fi
done
find "$bin" -maxdepth 1 -name '*.buildinfo' -exec cp {} "$dest/" \;
if [ -f "$(dirname "$BUILD")/build-manifest.txt" ]; then
	cp "$(dirname "$BUILD")/build-manifest.txt" "$dest/"
fi
if [ -f "$BUILD/.config" ]; then
	cp "$BUILD/.config" "$dest/config.buildinfo"
fi

find "$BUILD/bin" -type d -name kmods | while read -r kdir; do
	cp -a "$kdir/." "$dest/kmods/"
done

echo "image check ok: $found"
