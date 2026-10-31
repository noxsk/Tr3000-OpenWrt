#!/bin/sh
# Rewrite versions.lock from the current branch tips. This is separate from a build.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
# shellcheck disable=SC1091
. "$ROOT/versions.lock"

tip() {
	git ls-remote "$1" "refs/heads/$2" | awk '{print $1}'
}

UPSTREAM_REV=$(tip "$UPSTREAM_REPO" "$UPSTREAM_BRANCH")
THEME_REV=$(tip "$THEME_REPO" "$THEME_BRANCH")
FEED_packages_REV=$(tip "$FEED_packages_URL" openwrt-25.12)
FEED_luci_REV=$(tip "$FEED_luci_URL" openwrt-25.12)
FEED_routing_REV=$(tip "$FEED_routing_URL" openwrt-25.12)
FEED_telephony_REV=$(tip "$FEED_telephony_URL" openwrt-25.12)
FEED_video_REV=$(tip "$FEED_video_URL" openwrt-25.12)

cat > "$ROOT/versions.lock" <<EOF
# Checked out by scripts/prepare.sh. Refresh with scripts/update-deps.sh.
UPSTREAM_REPO=$UPSTREAM_REPO
UPSTREAM_BRANCH=$UPSTREAM_BRANCH
UPSTREAM_REV=$UPSTREAM_REV

THEME_REPO=$THEME_REPO
THEME_BRANCH=$THEME_BRANCH
THEME_REV=$THEME_REV

FEED_packages_URL=$FEED_packages_URL
FEED_packages_REV=$FEED_packages_REV
FEED_luci_URL=$FEED_luci_URL
FEED_luci_REV=$FEED_luci_REV
FEED_routing_URL=$FEED_routing_URL
FEED_routing_REV=$FEED_routing_REV
FEED_telephony_URL=$FEED_telephony_URL
FEED_telephony_REV=$FEED_telephony_REV
FEED_video_URL=$FEED_video_URL
FEED_video_REV=$FEED_video_REV
EOF

echo "updated $ROOT/versions.lock"
