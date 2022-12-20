#!/bin/sh

build_boot_cmd() {
	mkdir -p "${DESTDIR}"/boot

	local _f
	for _f in $kernel_flavors; do
		cat <<EOF >> "${DESTDIR}"/boot/boot.cmd

setenv bootargs console=\${console} ${kernel_cmdline}

if load \${devtype} \${devnum}:\${bootpart} \${kernel_addr_r} /vmlinuz-${_f}; then
else
  echo "Error loading kernel image!"
  exit 1
fi

if load \${devtype} \${devnum}:\${bootpart} \${ramdisk_addr_r} /initramfs-${_f}; then
else
  echo "Error loading initramfs image!"
  exit 1
fi
setenv _ramdisk_size \${filesize}

if load \${devtype} \${devnum}:\${bootpart} \${fdt_addr_r} /\${fdtfile}; then
  echo "Loaded device tree from /\${fdtfile}"
else
  if load \${devtype} \${devnum}:\${bootpart} \${fdt_addr_r} /dtbs-${_f}/\${fdtfile}; then
    echo "Loaded device tree from /dtbs-${_f}/\${fdtfile}"
  else
    echo "Error loading device tree file!"
    exit 1
  fi
fi

bootz \${kernel_addr_r} \${ramdisk_addr_r}:\${_ramdisk_size} \${fdt_addr_r}

EOF
	break # Only first kernel flavor
	done

	cat <<'EOF' >> "${DESTDIR}"/boot/update_boot_scr.sh
#!/bin/sh
if ! command -v mkimage &> /dev/null
then
    echo "Error: mkimage could not be found"
	echo "Please install u-boot-tools"
    exit 1
fi

SCRIPT=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "${SCRIPT}")

mkimage -A arm -O linux -T script -C none -a 0 -e 0 -d "${SCRIPT_DIR}/boot.cmd" "${SCRIPT_DIR}/boot.scr"

EOF

	mkimage -A arm -O linux -T script -C none -a 0 -e 0 -d "${DESTDIR}/boot/boot.cmd" "${DESTDIR}/boot/boot.scr"
}

section_boot_cmd() {
	build_section boot_cmd
}

profile_bananapi() {
	profile_base
	title="BananaPi"
	desc="Has default ARM kernel. Supports armv7"
	image_ext="tar.gz"
	arch="armv7"
	kernel_flavors="lts"
	kernel_cmdline=""
	initfs_features="base bootchart ext4 kms mmc nvme raid scsi squashfs usb brcmfmac dhcp https"
	apkovl="genapkovl-bananapi.sh"
	hostname="alpine"
	grub_mod=
}
