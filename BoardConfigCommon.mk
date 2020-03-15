## arch settings
TARGET_ARCH := arm
TARGET_ARCH_VARIANT := armv7-a-neon
TARGET_CPU_ABI := armeabi-v7a
TARGET_CPU_ABI2 := armeabi
TARGET_CPU_VARIANT := cortex-a9
ARCH_ARM_HAVE_NEON := true

## binder
TARGET_USES_64_BIT_BINDER := true
TARGET_SUPPORTS_32_BIT_APPS := true
TARGET_SUPPORTS_64_BIT_APPS := false

## platform
TARGET_BOARD_PLATFORM := exynos4
TARGET_SOC := exynos4x12
TARGET_BOOTLOADER_BOARD_NAME := smdk4x12
TARGET_NO_BOOTLOADER := true

## filesystem
BOARD_BUILD_SYSTEM_ROOT_IMAGE := true

BOARD_SYSTEMIMAGE_PARTITION_SIZE := 1444888576
BOARD_BOOTIMAGE_PARTITION_SIZE := 8388608
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 52388608
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

BOARD_KERNEL_BASE := 0x40000000
# we need to set the cmd line in the kernel for now
# BOARD_KERNEL_CMDLINE := androidboot.hardware=smdk4x12 androidboot.selinux=permissive printk.devkmsg=on enforcing=0
BOARD_KERNEL_PAGESIZE := 2048

VENDOR_LKM_DIR := $(KERNEL_PATH)/modules
## kernel modules (temporary solution)
BOARD_VENDOR_KERNEL_MODULES := \
    $(VENDOR_LKM_DIR)/atmel_mxt_ts.ko \
    $(VENDOR_LKM_DIR)/bluetooth.ko \
    $(VENDOR_LKM_DIR)/brcmfmac.ko \
    $(VENDOR_LKM_DIR)/brcmutil.ko \
    $(VENDOR_LKM_DIR)/cfg80211.ko \
    $(VENDOR_LKM_DIR)/cpufreq_conservative.ko \
    $(VENDOR_LKM_DIR)/cpufreq_powersave.ko \
    $(VENDOR_LKM_DIR)/cpufreq_userspace.ko \
    $(VENDOR_LKM_DIR)/hci_uart.ko \
    $(VENDOR_LKM_DIR)/mac80211.ko \
    $(VENDOR_LKM_DIR)/rfkill-gpio.ko \
    $(VENDOR_LKM_DIR)/rfkill.ko \

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
BOARD_GPU_DRIVERS := lima kmsro
BUILD_EMULATOR_OPENGL := true
TARGET_SCREEN_DENSITY := 160
USE_OPENGL_RENDERER := true
BOARD_USE_LEGACY_UI := true

## audio
BOARD_USES_GENERIC_AUDIO := false
BOARD_USES_ALSA_AUDIO := true
USE_XML_AUDIO_POLICY_CONF := 1

## wifi
WPA_SUPPLICANT_VERSION := VER_0_8_X
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
BOARD_HOSTAPD_DRIVER := NL80211

## SELinux
BOARD_SEPOLICY_DIRS := device/samsung/p4note/sepolicy

## recovery
ifeq ($(WITH_TWRP),true)
TARGET_RECOVERY_FSTAB := $(LOCAL_DIR)/rootdir/fstab.smdk4x12
TARGET_RECOVERY_PIXEL_FORMAT := BGRA_8888

TW_HAS_NO_RECOVERY_PARTITION := true
TW_HAS_NO_BOOT_PARTITION := true
TW_NO_LEGACY_PROPS := true

TARGET_RECOVERY_INITRC := $(LOCAL_DIR)/rootdir/init.recovery.rc
endif

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
