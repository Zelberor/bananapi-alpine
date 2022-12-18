#!/bin/sh

#build_fstab() {
#	mkdir -p "${DESTDIR}"/etc
#	cat <<'EOF' >> "${DESTDIR}"/etc/fstab
#LABEL=ALPINE_BOOT      /boot                ext4     defaults,rw,noatime,discard,errors=remount-ro  0 2
#LABEL=ALPINE_DATA      /media/alpine_data   ext4     defaults,rw,noatime,discard,nofail             0 1
#EOF
#}
#
#section_fstab() {
#	build_section fstab
#}

profile_bananapi() {
	profile_base
	title="BananaPi"
	desc="Has default ARM kernel. Supports armv7"
	image_ext="tar.gz"
	arch="armv7"
	kernel_flavors="lts"
	kernel_addons="xtables-addons"
	initfs_features="base bootchart ext4 kms mmc nvme raid scsi squashfs usb"
	apkovl="genapkovl-bananapi.sh"
	hostname="alpine"
	grub_mod=
}
