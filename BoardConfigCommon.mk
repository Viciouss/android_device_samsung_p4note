DEVICE_PATH := device/samsung/p4note

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

BOARD_KERNEL_BASE := 0x40000000
BOARD_KERNEL_PAGESIZE := 2048
    
## boot image
BOARD_KERNEL_TAGS_OFFSET 	:= 0x00000100
BOARD_KERNEL_OFFSET		    := 0x00008000
BOARD_RAMDISK_OFFSET     	:= 0x02000000
# version 0 means that the device launched before android 9
BOARD_BOOT_HEADER_VERSION 	:= 0

BOARD_MKBOOTIMG_ARGS := --kernel_offset $(BOARD_KERNEL_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
#BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)

## other file system options
TARGET_USERIMAGES_USE_F2FS := true

## SELinux
#BOARD_SEPOLICY_DIRS := device/samsung/p4note/sepolicy

## recovery
BOARD_HAS_NO_REAL_SDCARD := true
RECOVERY_SDCARD_ON_DATA := true
RECOVERY_FSTAB_VERSION := 2
TARGET_RECOVERY_FSTAB := device/samsung/p4note/recovery.fstab
# common recovery/root first, then the per device one (touchscreen config)
TARGET_RECOVERY_DEVICE_DIRS += $(DEVICE_PATH) $(DEVICE_PATH)/$(TARGET_DEVICE)
TARGET_SYSTEM_PROP := $(DEVICE_PATH)/system.prop
TARGET_RECOVERY_PIXEL_FORMAT := BGRA_8888
TARGET_RECOVERY_DENSITY := mdpi
TW_EXCLUDE_TZDATA := true
TW_EXCLUDE_ENCRYPTED_BACKUPS := true
TW_THEME := landscape_hdpi
TW_INCLUDE_CRYPTO := true
TW_NO_REBOOT_BOOTLOADER := true
TW_HAS_DOWNLOAD_MODE := true
TW_THEME := landscape_mdpi
TW_NO_HAPTICS := true
TW_USE_TOOLBOX := true
TW_DEFAULT_BRIGHTNESS := 4
TW_USE_NEW_MINADBD := true
TW_NO_SCREEN_TIMEOUT := true
TW_MTP_DEVICE := /dev/usb-ffs/mtp
LZMA_RAMDISK_TARGETS := recovery
# core/Makefile assigns this unconditionally, hence the override.
# The kernel needs CONFIG_RD_XZ and CONFIG_XZ_DEC_ARMTHUMB.
override RECOVERY_RAMDISK_COMPRESSOR := xz --check=crc32 --armthumb --lzma2=preset=9e,dict=32MiB -f -c
RECOVERY_GRAPHICS_FORCE_SINGLE_BUFFER := true
TW_EXCLUDE_NANO := true
TW_EXCLUDE_BASH := true
TW_EXCLUDE_PYTHON := true
TW_NO_EXFAT_FUSE := true
TW_NO_EXFAT := true

TW_CUSTOM_BATTERY_PATH := /sys/class/power_supply/max170xx_battery

# charger is never started in recovery (init.recovery.hlthchrg.rc is not imported),
# nothing in the ramdisk links against the ubsan runtime, and the vibrator
# HAL libs are only pulled in by the FBE file list (unused with TW_NO_HAPTICS)
# UI languages: English only
BOARD_RECOVERY_IMAGE_PREPARE = \
    rm -f $(TARGET_RECOVERY_ROOT_OUT)/sbin/charger \
          $(TARGET_RECOVERY_ROOT_OUT)/charger \
          $(TARGET_RECOVERY_ROOT_OUT)/init.recovery.hlthchrg.rc \
          $(TARGET_RECOVERY_ROOT_OUT)/sbin/libclang_rt.ubsan_standalone-arm-android.so \
          $(TARGET_RECOVERY_ROOT_OUT)/sbin/android.hardware.vibrator@1.*.so; \
    find $(TARGET_RECOVERY_ROOT_OUT)/twres/languages -type f ! -name en.xml -delete;

## vndk
PRODUCT_FULL_TREBLE_OVERRIDE := true
BOARD_VNDK_RUNTIME_DISABLE := true
PRODUCT_USE_VNDK_OVERRIDE := true
BOARD_VNDK_VERSION := current

BOARD_USES_GRALLOC_HANDLE := true

## build
BUILD_BROKEN_USES_BUILD_HOST_STATIC_LIBRARY := true