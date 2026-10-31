#!/bin/sh
# Merge this recipe onto the revisions in versions.lock.
# By default the tree is cloned next to this repo, under ../build/.
# Set BUILD_DIR to place it somewhere else. GitHub Actions uses .build/.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
WORK=$(CDPATH= cd -- "$ROOT/.." && pwd)
# shellcheck disable=SC1091
. "$ROOT/versions.lock"

BUILD="${BUILD_DIR:-$WORK/build/immortalwrt-mt798x-rebase}"
THEME_DIR="$BUILD/package/luci-theme-aurora"
MANIFEST="$(dirname "$BUILD")/build-manifest.txt"

sync_repo() {
	dir=$1
	url=$2
	rev=$3
	mkdir -p "$(dirname "$dir")"
	if [ ! -d "$dir/.git" ]; then
		git init "$dir"
		git -C "$dir" remote add origin "$url"
	fi
	if ! git -C "$dir" cat-file -e "${rev}^{commit}" 2>/dev/null; then
		git -C "$dir" fetch --depth 1 origin "$rev"
	fi
	git -C "$dir" checkout --force --detach "$rev"
}

mkdir -p "$(dirname "$BUILD")"
sync_repo "$BUILD" "$UPSTREAM_REPO" "$UPSTREAM_REV"
sync_repo "$THEME_DIR" "$THEME_REPO" "$THEME_REV"

MT76_SRC="$(dirname "$BUILD")/openwrt-mt76"
if [ ! -d "$MT76_SRC/.git" ]; then
	git init "$MT76_SRC"
	git -C "$MT76_SRC" remote add origin "$MT76_REPO"
	git -C "$MT76_SRC" sparse-checkout init --cone
	git -C "$MT76_SRC" sparse-checkout set package/kernel/mt76
fi
if ! git -C "$MT76_SRC" cat-file -e "${MT76_REV}^{commit}" 2>/dev/null; then
	git -C "$MT76_SRC" fetch --depth 1 origin "$MT76_REV"
fi
git -C "$MT76_SRC" checkout --force --detach "$MT76_REV"
rm -rf "$BUILD/package/kernel/mt76"
mkdir -p "$BUILD/package/kernel"
cp -a "$MT76_SRC/package/kernel/mt76" "$BUILD/package/kernel/mt76"

rm -rf "$BUILD/package/luci-app-qdisc"
cp -a "$ROOT/package/luci-app-qdisc" "$BUILD/package/luci-app-qdisc"

if [ -n "${DL_CACHE:-}" ]; then
	mkdir -p "$DL_CACHE"
	rm -rf "$BUILD/dl"
	ln -s "$DL_CACHE" "$BUILD/dl"
fi

cat > "$BUILD/feeds.conf" <<EOF
src-git packages ${FEED_packages_URL}^${FEED_packages_REV}
src-git luci ${FEED_luci_URL}^${FEED_luci_REV}
src-git routing ${FEED_routing_URL}^${FEED_routing_REV}
src-git telephony ${FEED_telephony_URL}^${FEED_telephony_REV}
src-git video ${FEED_video_URL}^${FEED_video_REV}
EOF

for patch_file in "$ROOT"/patches/*.patch; do
	[ -f "$patch_file" ] || continue
	patch -d "$BUILD" -p1 --forward --batch < "$patch_file"
done

rm -rf "$BUILD/files"
mkdir -p "$BUILD/files"
cp -a "$ROOT/files/." "$BUILD/files/"

awk '
	/^CONFIG_TARGET_MULTI_PROFILE=/ { next }
	/^# CONFIG_TARGET_MULTI_PROFILE is not set/ { next }
	/^CONFIG_TARGET_PER_DEVICE_ROOTFS=/ { next }
	/^# CONFIG_TARGET_PER_DEVICE_ROOTFS is not set/ { next }
	/^CONFIG_TARGET_DEVICE_/ { next }
	/^# CONFIG_MTK_MULTI_PROFILE_SUPPORT is not set$/ { next }
	/^CONFIG_MTK_MULTI_PROFILE_SUPPORT=/ { next }
	{ print }
' "$BUILD/defconfig/mt7981-ax3000.config" > "$BUILD/.config"
printf '\n' >> "$BUILD/.config"
cat "$ROOT/seed.config" >> "$BUILD/.config"
if [ "${USE_CCACHE:-}" = "1" ]; then
	ccache_dir=${CCACHE_DIR:-$BUILD/.ccache}
	mkdir -p "$ccache_dir"
	printf '\nCONFIG_CCACHE=y\nCONFIG_CCACHE_DIR="%s"\n' "$ccache_dir" >> "$BUILD/.config"
fi

{
	echo "UPSTREAM_REV=$UPSTREAM_REV"
	echo "THEME_REV=$THEME_REV"
	echo "FEED_packages_REV=$FEED_packages_REV"
	echo "FEED_luci_REV=$FEED_luci_REV"
	echo "FEED_routing_REV=$FEED_routing_REV"
	echo "FEED_telephony_REV=$FEED_telephony_REV"
	echo "FEED_video_REV=$FEED_video_REV"
	echo "MT76_REV=$MT76_REV"
	if git -C "$ROOT" rev-parse HEAD >/dev/null 2>&1; then
		echo "RECIPE_REV=$(git -C "$ROOT" rev-parse HEAD)"
	fi
} > "$MANIFEST"

if [ "$(uname -s)" != "Linux" ]; then
	echo "Wrote $BUILD/.config"
	echo "KERNEL_DEBUG_INFO_BTF cannot be resolved on macOS. On Linux run scripts/build.sh."
	exit 0
fi

(
	cd "$BUILD"
	./scripts/feeds update -a
	./scripts/feeds install -a
	make defconfig
)

"$ROOT/scripts/check-config.sh"

echo "Ready: $BUILD"
echo "Image target: mediatek/filogic cudy_tr3000-v1-mtkuboot"
