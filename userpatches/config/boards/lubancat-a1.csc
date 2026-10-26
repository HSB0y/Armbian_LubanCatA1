# Allwinner H618 quad-core, AXP1530/AXP313a PMIC, LPDDR4, AIC8800 SDIO WiFi/BT
# Reference board: Orange Pi Zero3 (sun50iw9). Custom port for EmbedFire LubanCat-A1.
BOARD_NAME="LubanCat-A1"
BOARD_VENDOR="embedfire"
BOARDFAMILY="sun50iw9"
BOARD_MAINTAINER="lubancat"
INTRODUCED="2024"
BOOTCONFIG="lubancat_a1_defconfig"
BOOT_FDT_FILE="sun50i-h618-lubancat-a1.dtb"
BOOT_LOGO="desktop"
OVERLAY_PREFIX="sun50i-h616"
KERNEL_TARGET="current"
KERNEL_TEST_TARGET="current"
FORCE_BOOTSCRIPT_UPDATE="yes"

# Onboard AIC8800 SDIO WiFi/BT (SDIO WiFi + UART Bluetooth on ttyS1)
AIC8800_TYPE="sdio"
enable_extension "radxa-aic8800"
PACKAGE_LIST_BOARD="rfkill bluetooth bluez bluez-tools mesa-opencl-icd mesa-vulkan-drivers ocl-icd-libopencl1 clinfo"

# Enable the H616/H618 internal analog codec driver (3.5mm Line Out).
enable_extension "lubancat-a1-audio"
# Enable rusticl (Mesa OpenCL) on panfrost.
enable_extension "lubancat-a1-graphics"

# AIC8800 Wireless kernel-module options
function post_family_tweaks_bsp__aic8800_wireless() {
	display_alert "$BOARD" "Installing AIC8800 Tweaks" "info"
	mkdir -p "${destination}"/etc/modprobe.d
	mkdir -p "${destination}"/etc/modules-load.d
	# No aic_fw_path override: the driver's built-in default
	# (/lib/firmware/aic8800_fw/SDIO/<chip>) already carries the _u03 firmware.
	cat > "${destination}"/etc/modprobe.d/aic8800-wireless.conf <<- EOT
		options aic8800_fdrv_sdio aicwf_dbg_level=0 custregd=0 ps_on=0
	EOT
	# Bluetooth needs hidp/rfcomm/bnep plus the AIC8800 HCI bridge
	cat > "${destination}"/etc/modules-load.d/aic8800-btlpm.conf <<- EOT
		hidp
		rfcomm
		bnep
		aic8800_btlpm_sdio
	EOT
	# AIC8800 Bluetooth service and helper script
	if [[ -d "$SRC/packages/bsp/aic8800" ]]; then
		install -d -m 0755 "${destination}/usr/bin"
		install -m 0755 "$SRC/packages/bsp/aic8800/aic-bluetooth" "${destination}/usr/bin/aic-bluetooth"
		install -d -m 0755 "${destination}/usr/lib/systemd/system"
		install -m 0644 "$SRC/packages/bsp/aic8800/aic-bluetooth.service" "${destination}/usr/lib/systemd/system/aic-bluetooth.service"
	else
		display_alert "$BOARD" "Skipping AIC8800 BT assets (packages/bsp/aic8800 not found)" "warn"
	fi
}

# Enable the AIC8800 Bluetooth service
function post_family_tweaks__enable_aic8800_bluetooth_service() {
	display_alert "$BOARD" "Enabling AIC8800 Bluetooth Service" "info"
	if chroot_sdcard test -f /lib/systemd/system/aic-bluetooth.service || chroot_sdcard test -f /etc/systemd/system/aic-bluetooth.service; then
		chroot_sdcard systemctl --no-reload enable aic-bluetooth.service
	else
		display_alert "$BOARD" "aic-bluetooth.service not found in image; skipping enable" "warn"
	fi
}