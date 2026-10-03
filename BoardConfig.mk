DEVICE_PATH := device/samsung/p4noterf

## arch settings
TARGET_ARCH := arm
TARGET_ARCH_VARIANT := armv7-a-neon
TARGET_CPU_ABI := armeabi-v7a
TARGET_CPU_ABI2 := armeabi
TARGET_CPU_VARIANT := cortex-a9
ARCH_ARM_HAVE_NEON := true

## binder
TARGET_USES_64_BIT_BINDER := true

## platform
TARGET_BOARD_PLATFORM := exynos4
TARGET_SOC := exynos4x12
TARGET_BOOTLOADER_BOARD_NAME := smdk4x12
TARGET_NO_BOOTLOADER := true

BOARD_BUILD_SYSTEM_ROOT_IMAGE := true

BOARD_SYSTEMIMAGE_PARTITION_SIZE := 1444888576
BOARD_BOOTIMAGE_PARTITION_SIZE := 8388608
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 8388608
BOARD_USERDATAIMAGE_PARTITION_SIZE := 12620578816
BOARD_VENDORIMAGE_PARTITION_SIZE := 825638912
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_FLASH_BLOCK_SIZE := 2048
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USES_MKE2FS := true
BOARD_USES_VENDORIMAGE := true
TARGET_COPY_OUT_VENDOR := vendor

## kernel config
TARGET_NO_KERNEL := false 

TARGET_KERNEL_SOURCE := kernel/samsung/p4note
TARGET_KERNEL_CONFIG := p4note_recovery_defconfig
BOARD_KERNEL_IMAGE_NAME := zImage-dtb
# GCC gives a ~160 KB smaller zImage than clang-r416183b1
TARGET_KERNEL_CLANG_COMPILE := false
KERNEL_TOOLCHAIN := /usr/bin
TARGET_KERNEL_CROSS_COMPILE_PREFIX := arm-linux-gnueabihf-
# CONFIG_KERNEL_XZ needs xz with the ARM BCJ filter, the prebuilts/build-tools one lacks it
TARGET_KERNEL_ADDITIONAL_FLAGS := XZ=/usr/bin/xz

BOARD_KERNEL_BASE := 0x40000000
BOARD_KERNEL_PAGESIZE := 2048

## kernel modules (temporary solution)
BOARD_VENDOR_KERNEL_MODULES := \
    $(wildcard $(DEVICE_PATH)/prebuilt/modules/*.ko)
    
## boot image
BOARD_KERNEL_TAGS_OFFSET 	:= 0x00000100
BOARD_KERNEL_OFFSET		:= 0x00008000
BOARD_RAMDISK_OFFSET     	:= 0x02000000
# version 0 means that the device launched before android 9
BOARD_BOOT_HEADER_VERSION 	:= 0

BOARD_MKBOOTIMG_ARGS := --kernel_offset $(BOARD_KERNEL_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
#BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)

## SELinux
#BOARD_SEPOLICY_DIRS := device/samsung/p4noterf/sepolicy

## recovery
BOARD_HAS_NO_REAL_SDCARD := true
RECOVERY_SDCARD_ON_DATA := true
RECOVERY_FSTAB_VERSION := 2
TARGET_RECOVERY_FSTAB := device/samsung/p4noterf/recovery.fstab
TARGET_RECOVERY_DEVICE_DIRS += $(DEVICE_PATH)
TARGET_RECOVERY_PIXEL_FORMAT := BGRA_8888
TARGET_RECOVERY_DENSITY := mdpi
TW_EXCLUDE_TZDATA := true
TW_THEME := landscape_hdpi
TW_NO_REBOOT_BOOTLOADER := true
TW_HAS_DOWNLOAD_MODE := true
TW_THEME := landscape_mdpi
TW_NO_HAPTICS := true
TW_USE_TOOLBOX := true
TW_DEFAULT_BRIGHTNESS := 4
TW_USE_NEW_MINADBD := true
TW_NO_SCREEN_TIMEOUT := true
TW_MTP_DEVICE := /dev/usb-ffs/mtp
TW_EXCLUDE_DEFAULT_USB_INIT := true
BOARD_RAMDISK_USE_XZ := true
# build/make uses $(XZ) for BOARD_RAMDISK_USE_XZ but never defines it
XZ := prebuilts/build-tools/linux-x86/bin/xz
RECOVERY_GRAPHICS_FORCE_SINGLE_BUFFER := true
TW_EXCLUDE_NANO := true
TW_EXCLUDE_BASH := true
TW_EXCLUDE_ZIP := true
TW_EXCLUDE_LIBXML2 := true
TW_EXCLUDE_MTP := true
TW_NO_EXFAT_FUSE := true
TW_NO_EXFAT := true
TW_EXCLUDE_APEX := true
TW_EXCLUDE_UBSAN := true
TW_EXCLUDE_BC := true
TW_EXCLUDE_HEALTH_SERVICES := true

# Runs after the recovery root is staged, right before it is packed:
# strip what soong installs with keep_symbols, keep English only, drop the
# AOSP recovery UI animation and charger.recovery (from base_vendor.mk),
# then regenerate the file lists twrpRepacker verifies against.
BOARD_RECOVERY_IMAGE_PREPARE = \
    $(LLVM_STRIP) --strip-all $(TARGET_RECOVERY_ROOT_OUT)/system/bin/linker \
        $(TARGET_RECOVERY_ROOT_OUT)/system/bin/adbd $(TARGET_RECOVERY_ROOT_OUT)/system/lib/libc.so && \
    find $(TARGET_RECOVERY_ROOT_OUT)/twres/languages -name '*.xml' ! -name en.xml -delete && \
    rm -f $(TARGET_RECOVERY_ROOT_OUT)/res/images/loop*.png $(TARGET_RECOVERY_ROOT_OUT)/res/images/fastbootd.png \
        $(TARGET_RECOVERY_ROOT_OUT)/system/bin/charger && \
    cd $(TARGET_RECOVERY_ROOT_OUT) && \
    find . | sed "s/.\///" | sed "/lib\/modules\//d" > ramdisk-files.txt && \
    find -type f | sed "s/.\/ramdisk-files.sha256sum//" | sed "/lib\/modules/d" | sed "/prop.default/d" | xargs sha256sum > ramdisk-files.sha256sum

TW_CUSTOM_BATTERY_PATH := /sys/class/power_supply/max170xx_battery

## vndk
PRODUCT_FULL_TREBLE_OVERRIDE := true
PRODUCT_USE_VNDK_OVERRIDE := true
BOARD_VNDK_VERSION := current

BOARD_USES_GRALLOC_HANDLE := true

## build
BUILD_BROKEN_USES_BUILD_HOST_STATIC_LIBRARY := true