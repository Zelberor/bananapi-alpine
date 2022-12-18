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
