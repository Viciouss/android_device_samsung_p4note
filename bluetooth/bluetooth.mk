
PRODUCT_COPY_FILES += \
    frameworks/av/services/audiopolicy/config/bluetooth_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/bluetooth_audio_policy_configuration.xml \

PRODUCT_PACKAGES += \
    android.hardware.bluetooth-service.default \
    audio.bluetooth.default \
    android.hardware.bluetooth.audio@2.1-impl \
    android.hardware.bluetooth.audio-impl

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/BCM.hcd:$(TARGET_COPY_OUT_VENDOR)/lib/firmware/brcm/BCM.hcd

DEVICE_MANIFEST_FILE += $(LOCAL_PATH)/manifest.xml