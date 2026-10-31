include $(TOPDIR)/rules.mk

LUCI_TITLE:=TCP congestion and queue discipline
LUCI_DEPENDS:=+kmod-tcp-bbr +kmod-sched +kmod-sched-cake +kmod-sched-fq-pie +tc-tiny
LUCI_PKGARCH:=all

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
