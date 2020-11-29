$(call inherit-product, $(SRC_TARGET_DIR)/product/aosp_base.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

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
    Camera2 \
    Email \
    HTMLViewer \
    Music

### common things start

## general

LOCAL_PATH := device/samsung/p4note
KERNEL_PATH := kernel/samsung/n80xx

PRODUCT_MANUFACTURER := samsung
PRODUCT_BRAND := android
PRODUCT_PLATFORM := smdk4x12

PRODUCT_CHARACTERISTICS := tablet

DEVICE_MANIFEST_FILE := $(LOCAL_PATH)/manifest.xml

AB_OTA_UPDATER := false

# Build and run only ART
PRODUCT_RUNTIMES := runtime_libart_default

#PRODUCT_PROPERTY_OVERRIDES +=
#    ro.config.low_ram=true

## screen configuration
PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_PREF_CONFIG := 160dpi
PRODUCT_AAPT_PREBUILT_DPI := xhdpi

## kernel
ifeq ($(TARGET_PREBUILT_KERNEL),)
    LOCAL_KERNEL := $(KERNEL_PATH)/zImage-dtb
else
    LOCAL_KERNEL := $(TARGET_PREBUILT_KERNEL)
endif

PRODUCT_COPY_FILES += $(LOCAL_KERNEL):$(PRODUCT_OUT)/kernel

## file system
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/fstab.smdk4x12:$(TARGET_COPY_OUT_ROOT)/fstab.smdk4x12 \
    $(LOCAL_PATH)/rootdir/fstab.smdk4x12:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.smdk4x12 \

## display setting
TARGET_SCREEN_HEIGHT := 1280
TARGET_SCREEN_WIDTH := 720

PRODUCT_PROPERTY_OVERRIDES += \
    ro.sf.lcd_density=160
    
## gatekeeper
PRODUCT_PACKAGES += \
	android.hardware.gatekeeper@1.0-service.software \

## init
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/init.$(PRODUCT_PLATFORM).rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.$(PRODUCT_PLATFORM).rc \
    $(LOCAL_PATH)/rootdir/init.$(PRODUCT_PLATFORM).usb.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.$(PRODUCT_PLATFORM).usb.rc \

## permissions
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.software.cts.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.cts.xml \
    frameworks/native/data/etc/android.software.app_widgets.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.app_widgets.xml \
    frameworks/native/data/etc/android.software.backup.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.backup.xml \
    frameworks/native/data/etc/android.software.voice_recognizers.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.voice_recognizers.xml \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.host.xml \
    frameworks/native/data/etc/android.software.device_admin.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.device_admin.xml

## media
PRODUCT_PACKAGES += \
    android.hardware.media.c2@1.0-service-v4l2 \
    android.hardware.media.omx@1.0-service \

PRODUCT_COPY_FILES += \
    frameworks/av/media/libstagefright/data/media_codecs_google_c2.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_c2_video.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_c2_video.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_c2_audio.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_c2_audio.xml \

## overlay
DEVICE_PACKAGE_OVERLAYS := $(LOCAL_PATH)/overlay-common \

## ueventd
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/ueventd.common.rc:$(TARGET_COPY_OUT_VENDOR)/ueventd.rc \

## hardware configs
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/android.hardware.screen.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.screen.xml \
    $(LOCAL_PATH)/configs/android.software.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.xml \

# ADB support
PRODUCT_PROPERTY_OVERRIDES += \
    persist.service.adb.enable=1 \
    persist.sys.usb.config=adb \

# Use the default charger mode images
PRODUCT_PACKAGES += \
    charger_res_images \

## other properties
PRODUCT_SHIPPING_API_LEVEL := 29

## treble
PRODUCT_PACKAGES += \
	vndk_package \

# local includes
# $(call inherit-product,$(LOCAL_PATH)/bluetooth/bluetooth.mk)
$(call inherit-product,$(LOCAL_PATH)/audio/audio.mk)
$(call inherit-product,$(LOCAL_PATH)/mesa.mk)
$(call inherit-product,$(LOCAL_PATH)/touchscreen/touch.mk)
$(call inherit-product,$(LOCAL_PATH)/treble.mk)
$(call inherit-product,$(LOCAL_PATH)/wifi/wifi.mk)

# hardware
# $(call inherit-product-if-exists,hardware/libsensors/sensors.mk)

# framework stuff
$(call inherit-product,frameworks/native/build/tablet-10in-xhdpi-2048-dalvik-heap.mk)

PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false