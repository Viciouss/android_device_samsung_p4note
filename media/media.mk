PRODUCT_PACKAGES += \
    android.hardware.media.c2@1.2-service-v4l2

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/media_codecs.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs.xml \
    $(LOCAL_PATH)/media_codecs_v4l2.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_v4l2.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_c2_video.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_c2_video.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_c2_audio.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_c2_audio.xml \
    $(LOCAL_PATH)/media_profiles_V1_0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_profiles_V1_0.xml \

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/mediaswcodec.policy:$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy/mediaswcodec.policy \
    $(LOCAL_PATH)/mediacodec.policy:$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy/mediacodec.policy \
    $(LOCAL_PATH)/codec2.vendor.ext.policy:$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy/android.hardware.media.c2-extended-seccomp_policy \

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/s5p-mfc.fw:$(TARGET_COPY_OUT_VENDOR)/lib/firmware/s5p-mfc.fw \
    $(LOCAL_PATH)/fimc_is_fw.bin:$(TARGET_COPY_OUT_VENDOR)/lib/firmware/exynos4_fimc_is_fw.bin \
    $(LOCAL_PATH)/setfile.bin:$(TARGET_COPY_OUT_VENDOR)/lib/firmware/exynos4_s5k6a3_setfile.bin

# Create input surface on the framework side
PRODUCT_VENDOR_PROPERTIES += \
    debug.stagefright.c2inputsurface=-1 \

# Camera
# camera.v4l2_custom (media/camera) is the V4L2 HAL that sets up the media
# pipeline of each sensor. The vendor provider loads it as camera.<this value>.
PRODUCT_PROPERTY_OVERRIDES += ro.hardware.camera=v4l2_custom

PRODUCT_PACKAGES += \
    camera.v4l2_custom \
    android.hardware.camera.provider@2.4-impl \
    android.hardware.camera.provider@2.4-service

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.camera.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.xml \
    frameworks/native/data/etc/android.hardware.camera.front.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.front.xml

DEVICE_MANIFEST_FILE += $(LOCAL_PATH)/manifest.xml