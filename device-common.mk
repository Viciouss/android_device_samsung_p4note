$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)

LOCAL_PATH := device/samsung/n8000
KERNEL_PATH := kernel/samsung/n80xx

PRODUCT_PACKAGES += \
    Dialer \
    Launcher3QuickStep \
    WallpaperPicker \

PRODUCT_MANUFACTURER := samsung
PRODUCT_BRAND := android
PRODUCT_PLATFORM := n8000

#### screen configuration
PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_PREF_CONFIG := 160dpi
PRODUCT_AAPT_PREBUILT_DPI := xhdpi hdpi

#### kernel
ifeq ($(TARGET_PREBUILT_KERNEL),)
    LOCAL_KERNEL := $(KERNEL_PATH)/zImage-dtb
else
    LOCAL_KERNEL := $(TARGET_PREBUILT_KERNEL)
endif
PRODUCT_COPY_FILES +=   $(LOCAL_KERNEL):kernel

#### file system

# we want to use dynamic partitions for vendor as the device doesn't have such a partition
# PRODUCT_USE_DYNAMIC_PARTITIONS := true
# PRODUCT_RETROFIT_DYNAMIC_PARTITIONS := true

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/fstab.$(PRODUCT_PLATFORM):$(TARGET_COPY_OUT_RAMDISK)/fstab.$(PRODUCT_PLATFORM)
    #$(LOCAL_PATH)/rootdir/fstab.$(PRODUCT_PLATFORM):$(TARGET_COPY_OUT_VENDOR)/etc/fstab.$(PRODUCT_PLATFORM)
    

PRODUCT_COPY_FILES += \
    $(KERNEL_PATH)/modules/aes-arm-bs.ko:root/lib/modules/aes-arm-bs.ko \
    $(KERNEL_PATH)/modules/af_alg.ko:root/lib/modules/af_alg.ko \
    $(KERNEL_PATH)/modules/algif_aead.ko:root/lib/modules/algif_aead.ko \
    $(KERNEL_PATH)/modules/algif_hash.ko:root/lib/modules/algif_hash.ko \
    $(KERNEL_PATH)/modules/algif_rng.ko:root/lib/modules/algif_rng.ko \
    $(KERNEL_PATH)/modules/algif_skcipher.ko:root/lib/modules/algif_skcipher.ko \
    $(KERNEL_PATH)/modules/atmel_mxt_ts.ko:root/lib/modules/atmel_mxt_ts.ko \
    $(KERNEL_PATH)/modules/bluetooth.ko:root/lib/modules/bluetooth.ko \
    $(KERNEL_PATH)/modules/brcmfmac.ko:root/lib/modules/brcmfmac.ko \
    $(KERNEL_PATH)/modules/brcmutil.ko:root/lib/modules/brcmutil.ko \
    $(KERNEL_PATH)/modules/btbcm.ko:root/lib/modules/btbcm.ko \
    $(KERNEL_PATH)/modules/cdc-acm.ko:root/lib/modules/cdc-acm.ko \
    $(KERNEL_PATH)/modules/cdc-wdm.ko:root/lib/modules/cdc-wdm.ko \
    $(KERNEL_PATH)/modules/cfg80211.ko:root/lib/modules/cfg80211.ko \
    $(KERNEL_PATH)/modules/chacha_generic.ko:root/lib/modules/chacha_generic.ko \
    $(KERNEL_PATH)/modules/chacha-neon.ko:root/lib/modules/chacha-neon.ko \
    $(KERNEL_PATH)/modules/cordic.ko:root/lib/modules/cordic.ko \
    $(KERNEL_PATH)/modules/cpufreq_conservative.ko:root/lib/modules/cpufreq_conservative.ko \
    $(KERNEL_PATH)/modules/cpufreq_powersave.ko:root/lib/modules/cpufreq_powersave.ko \
    $(KERNEL_PATH)/modules/cpufreq_userspace.ko:root/lib/modules/cpufreq_userspace.ko \
    $(KERNEL_PATH)/modules/crypto_user.ko:root/lib/modules/crypto_user.ko \
    $(KERNEL_PATH)/modules/dh_generic.ko:root/lib/modules/dh_generic.ko \
    $(KERNEL_PATH)/modules/ecc.ko:root/lib/modules/ecc.ko \
    $(KERNEL_PATH)/modules/ecdh_generic.ko:root/lib/modules/ecdh_generic.ko \
    $(KERNEL_PATH)/modules/exynos4-is-common.ko:root/lib/modules/exynos4-is-common.ko \
    $(KERNEL_PATH)/modules/exynos-fimc-is.ko:root/lib/modules/exynos-fimc-is.ko \
    $(KERNEL_PATH)/modules/exynos-fimc-lite.ko:root/lib/modules/exynos-fimc-lite.ko \
    $(KERNEL_PATH)/modules/exynos-gsc.ko:root/lib/modules/exynos-gsc.ko \
    $(KERNEL_PATH)/modules/font.ko:root/lib/modules/font.ko \
    $(KERNEL_PATH)/modules/gpu-sched.ko:root/lib/modules/gpu-sched.ko \
    $(KERNEL_PATH)/modules/gspca_main.ko:root/lib/modules/gspca_main.ko \
    $(KERNEL_PATH)/modules/hci_uart.ko:root/lib/modules/hci_uart.ko \
    $(KERNEL_PATH)/modules/lima.ko:root/lib/modules/lima.ko \
    $(KERNEL_PATH)/modules/lrw.ko:root/lib/modules/lrw.ko \
    $(KERNEL_PATH)/modules/lz4_compress.ko:root/lib/modules/lz4_compress.ko \
    $(KERNEL_PATH)/modules/lz4.ko:root/lib/modules/lz4.ko \
    $(KERNEL_PATH)/modules/lzo_compress.ko:root/lib/modules/lzo_compress.ko \
    $(KERNEL_PATH)/modules/lzo.ko:root/lib/modules/lzo.ko \
    $(KERNEL_PATH)/modules/lzo-rle.ko:root/lib/modules/lzo-rle.ko \
    $(KERNEL_PATH)/modules/mac80211.ko:root/lib/modules/mac80211.ko \
    $(KERNEL_PATH)/modules/microchip.ko:root/lib/modules/microchip.ko \
    $(KERNEL_PATH)/modules/rfkill-gpio.ko:root/lib/modules/rfkill-gpio.ko \
    $(KERNEL_PATH)/modules/rfkill.ko:root/lib/modules/rfkill.ko \
    $(KERNEL_PATH)/modules/s5p-cec.ko:root/lib/modules/s5p-cec.ko \
    $(KERNEL_PATH)/modules/s5p-csis.ko:root/lib/modules/s5p-csis.ko \
    $(KERNEL_PATH)/modules/s5p-fimc.ko:root/lib/modules/s5p-fimc.ko \
    $(KERNEL_PATH)/modules/s5p-jpeg.ko:root/lib/modules/s5p-jpeg.ko \
    $(KERNEL_PATH)/modules/s5p-mfc.ko:root/lib/modules/s5p-mfc.ko \
    $(KERNEL_PATH)/modules/salsa20_generic.ko:root/lib/modules/salsa20_generic.ko \
    $(KERNEL_PATH)/modules/sha1-arm.ko:root/lib/modules/sha1-arm.ko \
    $(KERNEL_PATH)/modules/sha1-arm-neon.ko:root/lib/modules/sha1-arm-neon.ko \
    $(KERNEL_PATH)/modules/sha3_generic.ko:root/lib/modules/sha3_generic.ko \
    $(KERNEL_PATH)/modules/sha512-arm.ko:root/lib/modules/sha512-arm.ko \
    $(KERNEL_PATH)/modules/snd-soc-midas-wm1811.ko:root/lib/modules/snd-soc-midas-wm1811.ko \
    $(KERNEL_PATH)/modules/snd-soc-wm8994.ko:root/lib/modules/snd-soc-wm8994.ko \
    $(KERNEL_PATH)/modules/snd-soc-wm-hubs.ko:root/lib/modules/snd-soc-wm-hubs.ko \
    $(KERNEL_PATH)/modules/usblp.ko:root/lib/modules/usblp.ko \
    $(KERNEL_PATH)/modules/usbtmc.ko:root/lib/modules/usbtmc.ko \
    $(KERNEL_PATH)/modules/uvcvideo.ko:root/lib/modules/uvcvideo.ko \
    $(KERNEL_PATH)/modules/v4l2-fwnode.ko:root/lib/modules/v4l2-fwnode.ko \
    $(KERNEL_PATH)/modules/v4l2-mem2mem.ko:root/lib/modules/v4l2-mem2mem.ko \
    $(KERNEL_PATH)/modules/v4l2-tpg.ko:root/lib/modules/v4l2-tpg.ko \
    $(KERNEL_PATH)/modules/videobuf2-common.ko:root/lib/modules/videobuf2-common.ko \
    $(KERNEL_PATH)/modules/videobuf2-dma-contig.ko:root/lib/modules/videobuf2-dma-contig.ko \
    $(KERNEL_PATH)/modules/videobuf2-memops.ko:root/lib/modules/videobuf2-memops.ko \
    $(KERNEL_PATH)/modules/videobuf2-v4l2.ko:root/lib/modules/videobuf2-v4l2.ko \
    $(KERNEL_PATH)/modules/videobuf2-vmalloc.ko:root/lib/modules/videobuf2-vmalloc.ko \
    $(KERNEL_PATH)/modules/vivid.ko:root/lib/modules/vivid.ko \
    $(KERNEL_PATH)/modules/xts.ko:root/lib/modules/xts.ko \


#### display setting
TARGET_SCREEN_HEIGHT := 1280
TARGET_SCREEN_WIDTH := 720

PRODUCT_PROPERTY_OVERRIDES += \
    ro.sf.lcd_density=160


#### graphics
PRODUCT_PACKAGES += \
	android.hardware.graphics.allocator@2.0-impl \
    android.hardware.graphics.allocator@2.0-service \
    android.hardware.graphics.composer@2.1-impl \
    android.hardware.graphics.composer@2.1-service \
    android.hardware.graphics.mapper@2.0-impl \
	gralloc.gbm \
	hwcomposer.drm \
	libGLES_mesa \
	libstdc++.vendor

PRODUCT_PACKAGES += \
    android.hardware.drm@1.0-impl \
    android.hardware.drm@1.0-service \
    android.hardware.drm@1.2-service.clearkey \
    android.hardware.drm@1.2-service.widevine \
    libdrm.exynos

PRODUCT_PROPERTY_OVERRIDES += \
	debug.drm.mode.force=1280x800 \
    gralloc.drm.device=/dev/dri/renderD128 \
	ro.opengles.version=131072


#### init
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/init.target.rc:root/init.target.rc


#### wifi
PRODUCT_PACKAGES += libwpa_client wpa_supplicant hostapd wificond
PRODUCT_PROPERTY_OVERRIDES += wifi.interface=wlan0 \
                              wifi.supplicant_scan_interval=15


#### testing
PRODUCT_SHIPPING_API_LEVEL := 25


#### development helpers
PRODUCT_PACKAGES += ssh sftp scp sshd ssh-keygen sshd_config start-ssh


#### treble
PRODUCT_PACKAGES += \
	vndk_package \

DEVICE_MANIFEST_FILE := $(LOCAL_PATH)/manifest.xml

PRODUCT_CHARACTERISTICS := tablet

#PRODUCT_PROPERTY_OVERRIDES += \
#    ro.config.low_ram=true