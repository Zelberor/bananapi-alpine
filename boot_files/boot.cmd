setenv bootargs console=${console} modules=loop,squashfs,sd-mod,usb-storage

if load ${devtype} ${devnum}:${bootpart} ${kernel_addr_r} /vmlinuz-lts; then
else
  echo "Error loading kernel image!"
  exit 1
fi

if load ${devtype} ${devnum}:${bootpart} ${ramdisk_addr_r} /initramfs-lts; then
else
  echo "Error loading initramfs image!"
  exit 1
fi
setenv _ramdisk_size ${filesize}

if load ${devtype} ${devnum}:${bootpart} ${fdt_addr_r} /${fdtfile}; then
else
  if load ${devtype} ${devnum}:${bootpart} ${fdt_addr_r} /dtbs-lts/${fdtfile}; then
  else
    echo "Error loading device tree file!"
    exit 1
  fi
fi

bootz ${kernel_addr_r} ${ramdisk_addr_r}:${_ramdisk_size} ${fdt_addr_r}
