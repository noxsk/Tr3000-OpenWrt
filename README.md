# Tr3000-OpenWrt

Cudy TR3000 128MB（MTK U-Boot，112MiB UBI）的固件配方。基座是 [chasey-dev/immortalwrt-mt798x-rebase](https://github.com/chasey-dev/immortalwrt-mt798x-rebase) 的 `25.12` 分支。

内核和驱动随镜像带齐。代理、异地组网、Samba/Ksmbd、dae 不预装，需要的软件以后用 apk 或独立二进制安装。

## 机型

只编译 `cudy_tr3000-v1-mtkuboot`。

- UBI：`0x5c0000` 起，长度 `0x7000000`（112MiB）
- 镜像上限：114688k
- 产物：`bin/targets/mediatek/filogic/*cudy_tr3000-v1-mtkuboot*sysupgrade*`

路由器需要已经在跑这套 112M MTK U-Boot。本配方不生成 BL2/FIP。

## 目录

本目录只放要提交的配方。源码和编译输出在上一级的 `build/`：

```text
Tr3000_dev/build/immortalwrt-mt798x-rebase/
Tr3000-OpenWrt/
  seed.config
  files/etc/hotplug.d/net/99-usbwan
  scripts/prepare.sh
  scripts/build.sh
```

## 镜像里有什么

无线使用开源 mt76（`kmod-mt7915e` 与 `kmod-mt7981-firmware`，包来自 OpenWrt，版本在 `versions.lock` 的 `MT76_REV`）。用 LuCI 的普通无线页面配置。同一张 5G 射频可以同时开多个 AP 和多个 Client，这些 Client 必须工作在同一个信道上。MAC 用接口里的 MAC 地址选项。802.11k/v/r 和 802.11w 由 hostapd 提供。闭源 `mt_wifi`、warp 不进这版镜像。基座把 WED 节点改成了闭源驱动的 compatible，mt76 的硬件卸载不会启用。

另外打开：

- `CONFIG_KERNEL_DEBUG_INFO_BTF`、`CONFIG_KERNEL_CGROUP_BPF`、`CONFIG_KERNEL_XDP_SOCKETS`、`kmod-nft-tproxy`
- iOS（`kmod-usb-net-ipheth`、`usbmuxd`）、Android RNDIS/CDC-NCM、QMI/MBIM/Option 内核驱动
- `kmod-usb3` 与 `automount`（ext4、ntfs3、exfat、vfat，外接盘挂到 `/mnt/sd*`）
- `kmod-mtd-rw`、`kmod-tun`
- LuCI 页面「队列算法」：拥塞控制可选 CUBIC / BBR，队列规则可选 FQ / CAKE / FQ-PIE。默认是 BBR + FQ
- LuCI 与中文语言包。默认主题是 [luci-theme-aurora](https://github.com/eamonxg/luci-theme-aurora)，版本记在 `versions.lock`。`bootstrap-mod` 仍留在镜像里，可在 LuCI 里切换

手机 USB 网络共享（RNDIS、CDC-NCM、ipheth）插入后，若还没有 `usbwan`，会创建 DHCP 接口并加入防火墙 `wan` 区，默认关闭 IPv6。之后只更新绑定的网卡，协议、DNS、metric、IPv6 保持原样。已有网卡在线时不会被另一台设备抢走。拔出后只下线，不删除配置。QMI/MBIM 不自动改成 DHCP。

内核模块和普通软件分开。镜像只带日常驱动。同一次编译还会归档 `kmod-*`，后装内核模块要用这批包，不要用 ImmortalWrt 滚动源里的 kmod。用户态程序仍可按需用 apk 安装。

## 编译

`versions.lock` 固定基座、mt76、主题和 feeds。日常编译按这个文件检出。要追新依赖时单独运行 `scripts/update-deps.sh`，再提交锁文件。

GitHub Actions 每天 02:00（UTC+8）按锁定版本编译，也可以手动触发。产物在 Artifacts 里，包含 sysupgrade、构建版本记录和同批次 kmod，保留 14 天。推送和 pull request 只做脚本语法和补丁检查，不完整编译。

本机 Linux 执行 `./scripts/build.sh`。基座克隆到上一级的 `build/`。`KERNEL_DEBUG_INFO_BTF` 在 macOS 上会被 Kconfig 关掉，所以不要在 macOS 上执行 `make defconfig` 或 `make`。

## 刷入之后

解锁 MTD 只读（确认分区再写）：

```sh
insmod mtd-rw i_want_a_brick=1
```

QMI/MBIM 拨号工具不在镜像里。需要时用 apk 安装 `uqmi` 或 `umbim`，并在接口上选择对应协议。内核模块请用同一次编译归档的 kmod。

有线 HNAT（`kmod-mediatek_hnat`）仍随基座打开。TR3000 的 GMAC 走 phy-handle，千兆有线需要在实机上确认加速是否生效。
