#!/bin/sh
# Assert the resolved .config still selects this firmware.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
WORK=$(CDPATH= cd -- "$ROOT/.." && pwd)
BUILD="${BUILD_DIR:-$WORK/build/immortalwrt-mt798x-rebase}"
cfg="$BUILD/.config"

need() {
	if ! grep -qx "$1" "$cfg"; then
		echo "config check failed: $1" >&2
		exit 1
	fi
}

need "CONFIG_TARGET_mediatek_filogic_DEVICE_cudy_tr3000-v1-mtkuboot=y"
need "CONFIG_KERNEL_DEBUG_INFO_BTF=y"
need "CONFIG_PACKAGE_luci-theme-aurora=y"
need "CONFIG_PACKAGE_kmod-mtd-rw=y"
need "CONFIG_PACKAGE_kmod-nft-tproxy=y"
need "CONFIG_PACKAGE_kmod-mt7915e=y"
need "CONFIG_PACKAGE_kmod-mt7981-firmware=y"
if grep -qx "CONFIG_PACKAGE_kmod-mt_wifi=y" "$cfg"; then
	echo "config check failed: proprietary mt_wifi is still selected" >&2
	exit 1
fi
need "CONFIG_PACKAGE_luci-app-qdisc=y"
need "CONFIG_PACKAGE_kmod-tcp-bbr=y"
need "CONFIG_PACKAGE_kmod-sched-cake=y"
need "CONFIG_PACKAGE_kmod-sched-fq-pie=y"

echo "config check ok"
