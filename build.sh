#!/bin/bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
WORKDIR=${SCRIPT_DIR}/workdir
OUTDIR=${SCRIPT_DIR}/output

echo "Downloading uboot and dtb files..."
# TODO: Download uboot and dtb
UBOOT_DTBS_ZIP_PATH=${WORKDIR}/uboot-and-dtbs.zip
UBOOT_DTBS_DIR=${WORKDIR}/uboot-and-dtbs
mkdir -p "${UBOOT_DTBS_DIR}"
unzip -q -o -d "${UBOOT_DTBS_DIR}" "${UBOOT_DTBS_ZIP_PATH}"

echo "Building alpine files..."
ALPINE_FILES_OUT_DIR=${WORKDIR}/alpine_files
mkdir -p "${ALPINE_FILES_OUT_DIR}"
#docker run --rm \
#	-v "${SCRIPT_DIR}/alpine-docker-scripts":/scripts \
#	-v "${ALPINE_FILES_OUT_DIR}":/img_out \
#	alpine:3.17 \
#	/scripts/build_image.sh

archive_zips=( "${ALPINE_FILES_OUT_DIR}/"*tar.gz ) # Should only be one entry
ALPINE_ARCHIVE_PATH=${archive_zips[0]}

mount_loop_img () {
	local image_path=$1
	if [ -z "${image_path}" ]; then
		echo "mount_loop_img: image_path argument required"
		exit 1
	fi
	losetup -fP "${image_path}"
	LOOPDEVICE=$(losetup --raw -j "${image_path}" | grep -o '^/dev/loop[[:digit:]]*')
	echo "Mounted ${image_path} at ${LOOPDEVICE}"
}

echo "Building base image..."
BASE_IMG_BUILD_PATH=${WORKDIR}/base-alpine.img
dd if=/dev/zero of="${BASE_IMG_BUILD_PATH}" bs=1M count=200
mount_loop_img "${BASE_IMG_BUILD_PATH}"

echo "	Creating partitions..."
sfdisk "${LOOPDEVICE}" <<EOF
label: dos
,+,L
EOF

echo "	Formatting..."
BOOTPART_DEV=${LOOPDEVICE}p1
BOOTPART_LABEL=ALPINE_BOOT

mkfs.ext4 -O ^64bit -L ${BOOTPART_LABEL} "${BOOTPART_DEV}"

echo "	Mounting partitions..."
MOUNT_DIR=${WORKDIR}/mnt
mkdir -p "${MOUNT_DIR}"
mount "${BOOTPART_DEV}" "${MOUNT_DIR}"

echo "	Extracting files to partitions..."
bsdtar -xp -f "${ALPINE_ARCHIVE_PATH}" -C "${MOUNT_DIR}"
mv "${MOUNT_DIR}"/boot/* -t "${MOUNT_DIR}/"
rm -d "${MOUNT_DIR}/boot"

echo "	Unmounting..."
umount -f "${BOOTPART_DEV}"
losetup -d "${LOOPDEVICE}"

# for BOARD in $(find "${UBOOT_DTBS_DIR}" -maxdepth 1 -mindepth 1 -type d -printf '%f '); do
for BOARD in bpi-m2z ; do
	echo "Building image for ${BOARD}..."

	uboot_bins=( "${UBOOT_DTBS_DIR}/${BOARD}/"*.bin ) # Should only be one entry
	UBOOT_BIN_PATH=${uboot_bins[0]}

	dtbs=( "${UBOOT_DTBS_DIR}/${BOARD}/"*.dtb ) # Should only be one entry
	DTB_SRC_PATH=${dtbs[0]}

	IMG_WORKDIR=${WORKDIR}/images/${BOARD}
	mkdir -p "${IMG_WORKDIR}"
	IMG_NAME=${BOARD}-alpine.img
	IMG_BUILD_PATH=${IMG_WORKDIR}/${IMG_NAME}

	echo "	Copying base image..."
	cp -f "${BASE_IMG_BUILD_PATH}" "${IMG_BUILD_PATH}"

	echo "	Mounting image..."
	mount_loop_img "${IMG_BUILD_PATH}"
	BOOTPART_DEV=${LOOPDEVICE}p1

	MOUNT_DIR=${IMG_WORKDIR}/mnt
	mkdir -p "${MOUNT_DIR}"
	mount "${BOOTPART_DEV}" "${MOUNT_DIR}"

	echo "	Copying device specific files..."
	DTB_FILE=${MOUNT_DIR}/$(basename "${DTB_SRC_PATH}")
	cp -f "${DTB_SRC_PATH}" "${DTB_FILE}"
	chown 0:0 "${DTB_FILE}"
	chmod 755 "${DTB_FILE}"

	echo "	Unmounting image..."
	umount -f "${BOOTPART_DEV}"
	losetup -d "${LOOPDEVICE}"

	echo "	Adding u-boot..."
	dd if="${UBOOT_BIN_PATH}" of="${IMG_BUILD_PATH}" bs=1024 seek=8 conv=notrunc

	# Mv img to output
	IMG_OUTPUT_DIR=${OUTDIR}/${BOARD}
	mkdir -p "${IMG_OUTPUT_DIR}"
	mv "${IMG_BUILD_PATH}" "${IMG_OUTPUT_DIR}/"

	echo "	Done. Image file was moved to ${IMG_OUTPUT_DIR}/${IMG_NAME}"
done
