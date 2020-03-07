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

#PRODUCT_PROPERTY_OVERRIDES +=
#    ro.config.low_ram=true

## screen configuration
PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_PREF_CONFIG := 160dpi
PRODUCT_AAPT_PREBUILT_DPI := xhdpi hdpi

## kernel
ifeq ($(TARGET_PREBUILT_KERNEL),)
    LOCAL_KERNEL := $(KERNEL_PATH)/zImage-dtb
else
    LOCAL_KERNEL := $(TARGET_PREBUILT_KERNEL)
endif

PRODUCT_COPY_FILES += $(LOCAL_KERNEL):kernel

## file system
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/fstab.smdk4x12:root/fstab.smdk4x12

## kernel modules (temporary solution)
PRODUCT_COPY_FILES += \
    $(KERNEL_PATH)/modules/aes-arm-bs.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/aes-arm-bs.ko \
    $(KERNEL_PATH)/modules/af_alg.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/af_alg.ko \
    $(KERNEL_PATH)/modules/algif_aead.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/algif_aead.ko \
    $(KERNEL_PATH)/modules/algif_hash.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/algif_hash.ko \
    $(KERNEL_PATH)/modules/algif_rng.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/algif_rng.ko \
    $(KERNEL_PATH)/modules/algif_skcipher.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/algif_skcipher.ko \
    $(KERNEL_PATH)/modules/atmel_mxt_ts.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/atmel_mxt_ts.ko \
    $(KERNEL_PATH)/modules/bluetooth.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/bluetooth.ko \
    $(KERNEL_PATH)/modules/brcmfmac.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/brcmfmac.ko \
    $(KERNEL_PATH)/modules/brcmutil.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/brcmutil.ko \
    $(KERNEL_PATH)/modules/btbcm.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/btbcm.ko \
    $(KERNEL_PATH)/modules/cdc-acm.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/cdc-acm.ko \
    $(KERNEL_PATH)/modules/cdc-wdm.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/cdc-wdm.ko \
    $(KERNEL_PATH)/modules/cfg80211.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/cfg80211.ko \
    $(KERNEL_PATH)/modules/chacha_generic.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/chacha_generic.ko \
    $(KERNEL_PATH)/modules/chacha-neon.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/chacha-neon.ko \
    $(KERNEL_PATH)/modules/cordic.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/cordic.ko \
    $(KERNEL_PATH)/modules/cpufreq_conservative.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/cpufreq_conservative.ko \
    $(KERNEL_PATH)/modules/cpufreq_powersave.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/cpufreq_powersave.ko \
    $(KERNEL_PATH)/modules/cpufreq_userspace.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/cpufreq_userspace.ko \
    $(KERNEL_PATH)/modules/crypto_user.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/crypto_user.ko \
    $(KERNEL_PATH)/modules/dh_generic.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/dh_generic.ko \
    $(KERNEL_PATH)/modules/ecc.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/ecc.ko \
    $(KERNEL_PATH)/modules/ecdh_generic.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/ecdh_generic.ko \
    $(KERNEL_PATH)/modules/exynos4-is-common.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/exynos4-is-common.ko \
    $(KERNEL_PATH)/modules/exynos-fimc-is.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/exynos-fimc-is.ko \
    $(KERNEL_PATH)/modules/exynos-fimc-lite.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/exynos-fimc-lite.ko \
    $(KERNEL_PATH)/modules/exynos-gsc.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/exynos-gsc.ko \
    $(KERNEL_PATH)/modules/font.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/font.ko \
    $(KERNEL_PATH)/modules/gspca_main.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/gspca_main.ko \
    $(KERNEL_PATH)/modules/hci_uart.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/hci_uart.ko \
    $(KERNEL_PATH)/modules/lrw.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/lrw.ko \
    $(KERNEL_PATH)/modules/lz4_compress.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/lz4_compress.ko \
    $(KERNEL_PATH)/modules/lz4.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/lz4.ko \
    $(KERNEL_PATH)/modules/lzo_compress.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/lzo_compress.ko \
    $(KERNEL_PATH)/modules/lzo.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/lzo.ko \
    $(KERNEL_PATH)/modules/lzo-rle.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/lzo-rle.ko \
    $(KERNEL_PATH)/modules/mac80211.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/mac80211.ko \
    $(KERNEL_PATH)/modules/microchip.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/microchip.ko \
    $(KERNEL_PATH)/modules/rfkill-gpio.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/rfkill-gpio.ko \
    $(KERNEL_PATH)/modules/rfkill.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/rfkill.ko \
    $(KERNEL_PATH)/modules/s5p-cec.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/s5p-cec.ko \
    $(KERNEL_PATH)/modules/s5p-csis.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/s5p-csis.ko \
    $(KERNEL_PATH)/modules/s5p-fimc.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/s5p-fimc.ko \
    $(KERNEL_PATH)/modules/s5p-jpeg.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/s5p-jpeg.ko \
    $(KERNEL_PATH)/modules/s5p-mfc.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/s5p-mfc.ko \
    $(KERNEL_PATH)/modules/salsa20_generic.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/salsa20_generic.ko \
    $(KERNEL_PATH)/modules/sha1-arm.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/sha1-arm.ko \
    $(KERNEL_PATH)/modules/sha1-arm-neon.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/sha1-arm-neon.ko \
    $(KERNEL_PATH)/modules/sha3_generic.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/sha3_generic.ko \
    $(KERNEL_PATH)/modules/sha512-arm.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/sha512-arm.ko \
    $(KERNEL_PATH)/modules/usblp.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/usblp.ko \
    $(KERNEL_PATH)/modules/usbtmc.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/usbtmc.ko \
    $(KERNEL_PATH)/modules/uvcvideo.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/uvcvideo.ko \
    $(KERNEL_PATH)/modules/v4l2-fwnode.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/v4l2-fwnode.ko \
    $(KERNEL_PATH)/modules/v4l2-mem2mem.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/v4l2-mem2mem.ko \
    $(KERNEL_PATH)/modules/v4l2-tpg.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/v4l2-tpg.ko \
    $(KERNEL_PATH)/modules/videobuf2-common.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/videobuf2-common.ko \
    $(KERNEL_PATH)/modules/videobuf2-dma-contig.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/videobuf2-dma-contig.ko \
    $(KERNEL_PATH)/modules/videobuf2-memops.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/videobuf2-memops.ko \
    $(KERNEL_PATH)/modules/videobuf2-v4l2.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/videobuf2-v4l2.ko \
    $(KERNEL_PATH)/modules/videobuf2-vmalloc.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/videobuf2-vmalloc.ko \
    $(KERNEL_PATH)/modules/vivid.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/vivid.ko \
    $(KERNEL_PATH)/modules/xts.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/xts.ko \


## display setting
TARGET_SCREEN_HEIGHT := 1280
TARGET_SCREEN_WIDTH := 720

PRODUCT_PROPERTY_OVERRIDES += \
    ro.sf.lcd_density=160

## media
PRODUCT_PACKAGES += \
    android.hardware.media.c2@1.0-service \
    android.hardware.media.omx@1.0-service \
    
PRODUCT_COPY_FILES += \
    frameworks/av/media/libstagefright/data/media_codecs_google_c2.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_c2_video.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_c2_video.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_c2_audio.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_c2_audio.xml \
    $(LOCAL_PATH)/configs/media_profiles_V1_0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_profiles_V1_0.xml \

## audio
PRODUCT_PACKAGES += \
    audio.primary.smdk4x12 \
    audio.r_submix.default \
    audio.usb.default \
    tinyplay

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
    $(LOCAL_PATH)/rootdir/init.$(PRODUCT_PLATFORM).rc:root/init.$(PRODUCT_PLATFORM).rc \
    $(LOCAL_PATH)/rootdir/init.$(PRODUCT_PLATFORM).usb.rc:root/init.$(PRODUCT_PLATFORM).usb.rc \
    frameworks/native/data/etc/android.hardware.wifi.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.software.app_widgets.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/android.software.app_widgets.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_audio.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/media_codecs_google_audio.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_telephony.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/media_codecs_google_telephony.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_video.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/media_codecs_google_video.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_tv.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/media_codecs_google_tv.xml 

## hardware configs
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/android.hardware.screen.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.screen.xml \
    $(LOCAL_PATH)/configs/android.software.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.xml \
    frameworks/native/data/etc/android.software.cts.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.cts.xml \
    frameworks/native/data/etc/android.software.app_widgets.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.app_widgets.xml \
    frameworks/native/data/etc/android.software.backup.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.backup.xml \
    frameworks/native/data/etc/android.software.voice_recognizers.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.voice_recognizers.xml \
    frameworks/native/data/etc/android.hardware.ethernet.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.ethernet.xml \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.host.xml \
    frameworks/native/data/etc/android.software.device_admin.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.device_admin.xml


## temporary stuff
# logging some stuff
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/temporary/logger.sh:root/logger.sh

# Get root on the serial console for -eng builds
# This can help debugging early boot issues
ifeq ($(TARGET_BUILD_VARIANT),eng)
PRODUCT_COPY_FILES += $(LOCAL_PATH)/temporary/console.rc:$(TARGET_COPY_OUT_SYSTEM)/etc/init/console.rc
endif

# HACK: prevent the device to go in suspend because it's annoying during early
# development. Remove afterward as it consume way more energy this way.
PRODUCT_COPY_FILES += $(LOCAL_PATH)/temporary/prevent_suspend.sh:$(TARGET_COPY_OUT_SYSTEM)/bin/prevent_suspend.sh
PRODUCT_COPY_FILES += $(LOCAL_PATH)/temporary/prevent_suspend.rc:$(TARGET_COPY_OUT_SYSTEM)/etc/init/prevent_suspend.rc

# ADB support
PRODUCT_PROPERTY_OVERRIDES += \
    persist.service.adb.enable=1 \
    persist.sys.usb.config=adb

# Use the default charger mode images
PRODUCT_PACKAGES += \
    charger_res_images

## wifi
# PRODUCT_PACKAGES += libwpa_client wpa_supplicant hostapd wificond
# PRODUCT_PROPERTY_OVERRIDES += \
    wifi.interface=wlan0 \
    wifi.supplicant_scan_interval=15

## testing
PRODUCT_SHIPPING_API_LEVEL := 29

## treble
PRODUCT_PACKAGES += \
	vndk_package


# local includes
$(call inherit-product,$(LOCAL_PATH)/treble.mk)
$(call inherit-product,$(LOCAL_PATH)/mesa.mk)
$(call inherit-product,$(LOCAL_PATH)/wifi.mk)
$(call inherit-product,$(LOCAL_PATH)/touch.mk)

# hardware
# $(call inherit-product-if-exists,hardware/libsensors/sensors.mk)

# framework stuff
$(call inherit-product,frameworks/native/build/tablet-10in-xhdpi-2048-dalvik-heap.mk)