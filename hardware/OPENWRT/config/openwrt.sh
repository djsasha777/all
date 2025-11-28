#Flashing bananna pi r3 mini router to immortalwrt with resize production partition

# boot from NAND
# download all firmware packages to local disc or flash drive, rename packages to need format

# you need 5 files in this format

### immortalwrt-mediatek-filogic-bananapi_bpi-r3-mini-emmc-gpt.bin
### immortalwrt-mediatek-filogic-bananapi_bpi-r3-mini-emmc-preloader.bin
### immortalwrt-mediatek-filogic-bananapi_bpi-r3-mini-emmc-bl31-uboot.fip
### immortalwrt-mediatek-filogic-bananapi_bpi-r3-mini-initramfs-recovery.itb
### immortalwrt-mediatek-filogic-bananapi_bpi-r3-mini-squashfs-sysupgrade.itb

opkg update
opkg install parted
cd /mnt/myflashwheremyfileslisted

# this block flash bootloader, recovery and production system on EMMC
dd if=immortalwrt-mediatek-filogic-bananapi_bpi-r3-mini-emmc-gpt.bin of=/dev/mmcblk0 bs=512 seek=0 count=34 conv=fsync
echo 0 > /sys/block/mmcblk0boot0/force_ro
dd if=/dev/zero of=/dev/mmcblk0boot0 bs=512 count=8192 conv=fsync
dd if=immortalwrt-mediatek-filogic-bananapi_bpi-r3-mini-emmc-preloader.bin of=/dev/mmcblk0boot0 bs=512 conv=fsync
dd if=/dev/zero of=/dev/mmcblk0 bs=512 seek=13312 count=8192 conv=fsync
dd if=immortalwrt-mediatek-filogic-bananapi_bpi-r3-mini-emmc-bl31-uboot.fip of=/dev/mmcblk0 bs=512 seek=13312 conv=fsync
dd if=immortalwrt-mediatek-filogic-bananapi_bpi-r3-mini-initramfs-recovery.itb of=/dev/mmcblk0p4 bs=512 conv=fsync
dd if=immortalwrt-mediatek-filogic-bananapi_bpi-r3-mini-squashfs-sysupgrade.itb of=/dev/mmcblk0p5 bs=512 conv=fsync

parted /dev/mmcblk0
# inside parted cli
#if parted want fix disk - do it
p
# list app parts
resizepart 5 100%
p
# look to modified part
q
poweroff

# if everything is ok, you will boot to production system
# change wifi settings, ip address, root pass, and chineese openwrt mirrors
