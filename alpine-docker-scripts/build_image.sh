#!/bin/sh

set -e

apk update
apk add alpine-sdk build-base apk-tools alpine-conf busybox fakeroot git syslinux xorriso squashfs-tools sudo u-boot-tools

abuild-keygen -i -a -n

git clone -b 3.17-stable --depth=1 https://gitlab.alpinelinux.org/alpine/aports.git /aports

# Copy keys
cp -f /aports/main/alpine-keys/* /etc/apk/keys/

# Copy scripts
APORTS_SCRIPTS_DIR=/aports/scripts
DOCKER_SCRIPTS_DIR=/scripts
cp ${DOCKER_SCRIPTS_DIR}/mkimg.*.sh ${APORTS_SCRIPTS_DIR}/
cp ${DOCKER_SCRIPTS_DIR}/genapkovl-*.sh ${APORTS_SCRIPTS_DIR}/

TAG=v3.17
IMG_OUT_DIR=/img_out
cd /aports/scripts
sh mkimage.sh --tag ${TAG} \
	--outdir ${IMG_OUT_DIR} \
	--arch armv7 \
	--repository http://dl-cdn.alpinelinux.org/alpine/${TAG}/main \
	--profile bananapi
