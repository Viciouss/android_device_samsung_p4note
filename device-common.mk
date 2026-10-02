$(call inherit-product, $(SRC_TARGET_DIR)/product/aosp_base.mk)

PRODUCT_PROPERTY_OVERRIDES += \
    ro.config.ringtone=Ring_Synth_04.ogg \
    ro.com.android.dataroaming=true

PRODUCT_PACKAGES += \
    PhotoTable \
    Dialer \
    Launcher3QuickStep \
    WallpaperPicker2 \
    Gallery2 \
    Contacts \
    Email \
    HTMLViewer \
    Music

### common things start

## general

LOCAL_PATH := device/samsung/p4note

PRODUCT_MANUFACTURER := samsung
PRODUCT_BRAND := samsung
PRODUCT_PLATFORM := smdk4x12

PRODUCT_CHARACTERISTICS := tablet

DEVICE_MANIFEST_FILE := $(LOCAL_PATH)/manifest.xml

AB_OTA_UPDATER := false

## screen configuration
PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_PREF_CONFIG := 160dpi
PRODUCT_AAPT_PREBUILT_DPI := xhdpi

## file system
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/fstab.smdk4x12:$(TARGET_COPY_OUT_RAMDISK)/fstab.smdk4x12 \
    $(LOCAL_PATH)/rootdir/fstab.smdk4x12:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.smdk4x12 \

## display setting
TARGET_SCREEN_HEIGHT := 800
TARGET_SCREEN_WIDTH := 1280

PRODUCT_PROPERTY_OVERRIDES += \
    ro.sf.lcd_density=160

## init
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/init.$(PRODUCT_PLATFORM).rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.$(PRODUCT_PLATFORM).rc \
    $(LOCAL_PATH)/rootdir/init.$(PRODUCT_PLATFORM).usb.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.$(PRODUCT_PLATFORM).usb.rc \

## overlay
DEVICE_PACKAGE_OVERLAYS += \
    $(LOCAL_PATH)/overlay-common \

## ueventd
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/ueventd.common.rc:$(TARGET_COPY_OUT_VENDOR)/ueventd.rc \

## hardware configs
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/android.hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.xml \
    $(LOCAL_PATH)/configs/android.software.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.xml \

## permissions
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/permissions/permissions-system_ext-p4note.xml:$(TARGET_COPY_OUT_SYSTEM_EXT)/etc/permissions/permissions-system_ext-p4note.xml \

# Use the default charger mode images
PRODUCT_PACKAGES += \
    charger_res_images \

## performance tuning
# keep dex2oat in check so it doesn't stall the whole system
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    dalvik.vm.dex2oat-threads=1 \
    dalvik.vm.image-dex2oat-threads=1

# Not a low_ram device: keep only lmkd's low_ram tuning
PRODUCT_PROPERTY_OVERRIDES += \
    ro.config.per_app_memcg=true \
    ro.lmk.psi_partial_stall_ms=200 \
    ro.lmk.thrashing_limit=30 \
    ro.lmk.thrashing_limit_decay=50

## other properties
PRODUCT_SHIPPING_API_LEVEL := 31

## treble
PRODUCT_PACKAGES += \
	vndk_package \

# local includes
$(call inherit-product,$(LOCAL_PATH)/audio/audio.mk)
$(call inherit-product,$(LOCAL_PATH)/bluetooth/bluetooth.mk)
$(call inherit-product,$(LOCAL_PATH)/keyboard/keyboard.mk)
$(call inherit-product,$(LOCAL_PATH)/media/media.mk)
$(call inherit-product,$(LOCAL_PATH)/mesa.mk)
$(call inherit-product,$(LOCAL_PATH)/sensors/sensors.mk)
$(call inherit-product,$(LOCAL_PATH)/touchscreen/touch.mk)
$(call inherit-product,$(LOCAL_PATH)/treble.mk)
$(call inherit-product,$(LOCAL_PATH)/wifi/wifi.mk)

# framework stuff
$(call inherit-product,frameworks/native/build/tablet-10in-xhdpi-2048-dalvik-heap.mk)
$(call inherit-product,$(SRC_TARGET_DIR)/product/large_screen_common.mk)

# Settings ships no dexpreopt profile and falls back to verify-only;
# its Compose (SPA) pages are UI-thread-bound in the interpreter/JIT.
PRODUCT_DEXPREOPT_SPEED_APPS += \
    Settings

PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false

$(call inherit-product, vendor/lineage/config/common_full_phone.mk)