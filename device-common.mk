$(call inherit-product, $(SRC_TARGET_DIR)/product/aosp_base.mk)

PRODUCT_PROPERTY_OVERRIDES += \
    ro.config.ringtone=Ring_Synth_04.ogg \
    ro.com.android.dataroaming=true

PRODUCT_PACKAGES += \
    PhotoTable \
    Dialer \
    Launcher3QuickStep \
    WallpaperPicker

### common things start

## general

LOCAL_PATH := device/samsung/p4note
KERNEL_PATH := kernel/samsung/n80xx

PRODUCT_MANUFACTURER := samsung
PRODUCT_BRAND := android
PRODUCT_PLATFORM := smdk4x12

PRODUCT_CHARACTERISTICS := tablet

DEVICE_MANIFEST_FILE := $(LOCAL_PATH)/manifest.xml

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
    $(LOCAL_PATH)/rootdir/fstab.smdk4x12:root/fstab.smdk4x12 \
    $(LOCAL_PATH)/rootdir/fstab.smdk4x12:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.smdk4x12 \

## display setting
TARGET_SCREEN_HEIGHT := 1280
TARGET_SCREEN_WIDTH := 720

PRODUCT_PROPERTY_OVERRIDES += \
    ro.sf.lcd_density=160

## audio
PRODUCT_PACKAGES += \
    audio.primary.smdk4x12 \
    audio.r_submix.default \
    audio.usb.default \
    tinyplay \

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_configuration.xml \
    frameworks/av/media/libeffects/data/audio_effects.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_effects.xml \
    frameworks/av/services/audiopolicy/config/a2dp_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/a2dp_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/r_submix_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/r_submix_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/usb_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/usb_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/default_volume_tables.xml \
    frameworks/av/services/audiopolicy/config/audio_policy_volumes.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_volumes.xml \
    
## gatekeeper
PRODUCT_PACKAGES += \
	gatekeeper.default \

## init
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/init.$(PRODUCT_PLATFORM).rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.$(PRODUCT_PLATFORM).rc \
    $(LOCAL_PATH)/rootdir/init.$(PRODUCT_PLATFORM).usb.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.$(PRODUCT_PLATFORM).usb.rc \
    frameworks/native/data/etc/android.hardware.wifi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.software.app_widgets.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.app_widgets.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_audio.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_audio.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_telephony.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_telephony.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_video.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_video.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_tv.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_tv.xml \

## hardware configs
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/android.hardware.screen.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.screen.xml \
    $(LOCAL_PATH)/configs/android.software.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.xml \

# Get root on the serial console for -eng builds
# This can help debugging early boot issues
ifeq ($(TARGET_BUILD_VARIANT),eng)
PRODUCT_COPY_FILES += $(LOCAL_PATH)/temporary/console.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/console.rc
endif

# HACK: prevent the device to go in suspend because it's annoying during early
# development. Remove afterward as it consume way more energy this way.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/temporary/prevent_suspend.sh:$(TARGET_COPY_OUT_VENDOR)/bin/prevent_suspend.sh \
    $(LOCAL_PATH)/temporary/prevent_suspend.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/prevent_suspend.rc \
    $(LOCAL_PATH)/temporary/logger.sh:$(TARGET_COPY_OUT_VENDOR)/bin/logger.sh \
    $(LOCAL_PATH)/temporary/logger.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/logger.rc \

# ADB support
PRODUCT_PROPERTY_OVERRIDES += \
    persist.service.adb.enable=1 \
    persist.sys.usb.config=adb \

# Use the default charger mode images
PRODUCT_PACKAGES += \
    charger_res_images \

## wifi
# PRODUCT_PACKAGES += libwpa_client wpa_supplicant hostapd wificond
# PRODUCT_PROPERTY_OVERRIDES += \
    wifi.interface=wlan0 \
    wifi.supplicant_scan_interval=15

## testing
PRODUCT_SHIPPING_API_LEVEL := 28

## treble
PRODUCT_PACKAGES += \
	vndk_package \


# local includes
$(call inherit-product,$(LOCAL_PATH)/treble.mk)
$(call inherit-product,$(LOCAL_PATH)/mesa.mk)
$(call inherit-product,$(LOCAL_PATH)/wifi.mk)
$(call inherit-product,$(LOCAL_PATH)/touch.mk)

# hardware
# $(call inherit-product-if-exists,hardware/libsensors/sensors.mk)

# framework stuff
$(call inherit-product,frameworks/native/build/tablet-10in-xhdpi-2048-dalvik-heap.mk)