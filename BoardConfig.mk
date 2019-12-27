LOCAL_PATH := device/samsung/n8000

################
# architecture #
################

TARGET_ARCH := arm
TARGET_ARCH_VARIANT := armv7-a-neon
TARGET_CPU_ABI := armeabi-v7a
TARGET_CPU_ABI2 := armeabi
TARGET_CPU_VARIANT := cortex-a9
ARCH_ARM_HAVE_NEON := true

# Binder
TARGET_USES_64_BIT_BINDER := true


############
# platform #
############

TARGET_BOARD_PLATFORM := exynos4
TARGET_SOC := exynos4412
TARGET_BOOTLOADER_BOARD_NAME := n8000
TARGET_NO_BOOTLOADER := true


##############
# filesystem #
##############

BOARD_BUILD_SYSTEM_ROOT_IMAGE := false

# the former system partition is now used as dynamic partition
#BOARD_SUPER_PARTITION_SIZE := 1444888576
#BOARD_SUPER_PARTITION_METADATA_DEVICE := system
#BOARD_SUPER_PARTITION_BLOCK_DEVICES := system
#BOARD_SUPER_PARTITION_SYSTEM_DEVICE_SIZE := 1444888576

#BOARD_SUPER_PARTITION_GROUPS := note_dynamic_partitions
# super partition size minus 8 MiB
#BOARD_NOTE_DYNAMIC_PARTITIONS_SIZE := 1436499968
#BOARD_NOTE_DYNAMIC_PARTITIONS_PARTITION_LIST := system vendor

#BOARD_SUPER_PARTITION_VENDOR_DEVICE_SIZE := 134217728

BOARD_SYSTEMIMAGE_PARTITION_SIZE := 1444888576
BOARD_BOOTIMAGE_PARTITION_SIZE := 8388608
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 52388608
BOARD_USERDATAIMAGE_PARTITION_SIZE := 12620578816
BOARD_CACHEIMAGE_PARTITION_SIZE := 825638912
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := f2fs
BOARD_FLASH_BLOCK_SIZE := 2048
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USES_MKE2FS := true

# we do have a vendor partition
BOARD_USES_VENDORIMAGE := false


#################
# kernel config #
#################

TARGET_NO_KERNEL := false 

BOARD_KERNEL_BASE := 0x40000000
BOARD_KERNEL_CMDLINE := androidboot.hardware=n8000 androidboot.selinux=permissive printk.devkmsg=on
BOARD_KERNEL_PAGESIZE := 2048

#BOARD_VENDOR_KERNEL_MODULES += \
#    $(wildcard device/samsung/n80xx/modules/*.ko)

##############
# boot image #
##############

BOARD_KERNEL_TAGS_OFFSET 	:= 0x00000100
BOARD_KERNEL_OFFSET			:= 0x00008000
BOARD_RAMDISK_OFFSET     	:= 0x02000000
# version 0 means that the device launched before android 9
BOARD_BOOT_HEADER_VERSION 	:= 0

BOARD_MKBOOTIMG_ARGS := --kernel_offset $(BOARD_KERNEL_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)


############
# graphics #
############

BOARD_GPU_DRIVERS := lima swrast
TARGET_SCREEN_DENSITY := 160
USE_OPENGL_RENDERER := true
TARGET_HARDWARE_3D := true
TARGET_USES_HWC2 := true

#########
# audio #
#########

BOARD_USES_ALSA_AUDIO := true
USE_XML_AUDIO_POLICY_CONF := 1

################
# generic wifi #
################

WPA_SUPPLICANT_VERSION := VER_0_8_X
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
BOARD_HOSTAPD_DRIVER := NL80211


############
# Recovery #
############
ifeq ($(WITH_TWRP),true)
TARGET_RECOVERY_FSTAB := $(LOCAL_PATH)/rootdir/fstab.n8000
TARGET_RECOVERY_PIXEL_FORMAT := BGRA_8888

TW_HAS_NO_RECOVERY_PARTITION := true
TW_HAS_NO_BOOT_PARTITION := true
TW_NO_LEGACY_PROPS := true

TARGET_RECOVERY_INITRC := $(LOCAL_PATH)/rootdir/init.recovery.rc
endif


##########
# treble #
##########

# BOARD_PROPERTY_OVERRIDES_SPLIT_ENABLED := true
PRODUCT_FULL_TREBLE_OVERRIDE := true
# FIXME: mesa/gbm-gralloc (which are SP-HALs) depend on libexpat (which is non-SP only)
#BOARD_VNDK_RUNTIME_DISABLE := true
BOARD_VNDK_VERSION := current
