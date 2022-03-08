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

## filesystem
BOARD_BUILD_SYSTEM_ROOT_IMAGE := false

BOARD_SYSTEMIMAGE_PARTITION_SIZE := 1468006400
BOARD_BOOTIMAGE_PARTITION_SIZE := 8388608
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 52388608
BOARD_USERDATAIMAGE_PARTITION_SIZE := 12620578816
BOARD_VENDORIMAGE_PARTITION_SIZE := 524288000 # this is the HIDDEN partition
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_CACHEIMAGE_PARTITION_SIZE := 825638912
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_FLASH_BLOCK_SIZE := 2048
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USES_MKE2FS := true
BOARD_USES_VENDORIMAGE := true
TARGET_COPY_OUT_VENDOR := vendor

## kernel config
TARGET_NO_KERNEL := false 

KERNEL_PATH := kernel/samsung/p4note
TARGET_PREBUILT_KERNEL := $(KERNEL_PATH)/zImage-dtb

BOARD_KERNEL_BASE := 0x40000000
BOARD_KERNEL_PAGESIZE := 2048

## kernel modules (temporary solution)
BOARD_VENDOR_KERNEL_MODULES := \
    $(wildcard $(KERNEL_PATH)/modules/*.ko)
    
## boot image
BOARD_KERNEL_TAGS_OFFSET 	:= 0x00000100
BOARD_KERNEL_OFFSET			:= 0x00008000
BOARD_RAMDISK_OFFSET     	:= 0x02000000
# version 0 means that the device launched before android 9
BOARD_BOOT_HEADER_VERSION 	:= 0

BOARD_MKBOOTIMG_ARGS := --kernel_offset $(BOARD_KERNEL_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)

## graphics
BOARD_MESA3D_USES_MESON_BUILD := true
BOARD_MESA3D_GALLIUM_DRIVERS := lima

TARGET_SCREEN_DENSITY := 160
USE_OPENGL_RENDERER := true

## audio
BOARD_USES_TINYHAL_AUDIO := true
TINYALSA_NO_ADD_NEW_CTRLS := true
TINYALSA_NO_CTL_GET_ID := true

## bluetooth
BOARD_HAVE_BLUETOOTH := true
BOARD_BLUETOOTH_BDROID_BUILDCFG_INCLUDE_DIR := device/samsung/p4note/bluetooth
BOARD_CUSTOM_BT_CONFIG := $(LOCAL_DIR)/bluetooth/vnd_smdk4x12.txt

## wifi
WPA_SUPPLICANT_VERSION := VER_0_8_X
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
BOARD_HOSTAPD_DRIVER := NL80211
WIFI_HIDL_UNIFIED_SUPPLICANT_SERVICE_RC_ENTRY := true

## SELinux
BOARD_SEPOLICY_DIRS := device/samsung/p4note/sepolicy

## recovery
TARGET_RECOVERY_FSTAB := device/samsung/p4note/rootdir/fstab.smdk4x12
TARGET_RECOVERY_PIXEL_FORMAT := BGRA_8888
TARGET_RECOVERY_INITRC := device/samsung/p4note/rootdir/init.recovery.rc

## vndk
PRODUCT_FULL_TREBLE_OVERRIDE := true
BOARD_VNDK_RUNTIME_DISABLE := true
PRODUCT_USE_VNDK_OVERRIDE := true
BOARD_VNDK_VERSION := current

## optimizations
# Enable dex-preoptimization to speed up first boot sequence
ifeq ($(HOST_OS),linux)
    WITH_DEXPREOPT := true
	DEX_PREOPT_DEFAULT := nostripping
endif

BOARD_USES_GRALLOC_HANDLE := true