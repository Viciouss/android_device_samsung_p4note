# Keymaster
PRODUCT_PACKAGES += \
    android.hardware.security.keymint-service \

# Power
PRODUCT_SOONG_NAMESPACES += \
    hardware/google/interfaces \
    hardware/google/pixel \
    hardware/lineage/interfaces/power-libperfmgr

PRODUCT_PACKAGES += \
    android.hardware.power-service.lineage-libperfmgr

PRODUCT_COPY_FILES += \
    device/samsung/p4note/configs/powerhint.json:$(TARGET_COPY_OUT_VENDOR)/etc/powerhint.json

# No display idle_state node: boost directly on INTERACTION, held for
# 500 ms after the last user activity (the default minimum is 1400 ms)
PRODUCT_VENDOR_PROPERTIES += \
    vendor.powerhal.disp.idle_support=false \
    vendor.powerhal.interaction.min=500 \
    vendor.powerhal.interaction.offset=500

# DRM
PRODUCT_PACKAGES += \
    android.hardware.drm@1.3-impl \
    android.hardware.drm@1.3-service \

# Health
PRODUCT_PACKAGES += \
    android.hardware.health@2.1-service \
    android.hardware.health@2.1-impl-p4note \
    android.hardware.health@2.1-impl-p4note.recovery \

# ConsumerIr
PRODUCT_PACKAGES += \
    android.hardware.ir-service.p4note \

# Lights
PRODUCT_PACKAGES += \
    android.hardware.lights-service.p4note \

# Vibrator
PRODUCT_PACKAGES += \
    android.hardware.vibrator-service.p4note \

# Gatekeeper
PRODUCT_PACKAGES += \
    android.hardware.gatekeeper@1.0-service.software \

PRODUCT_PACKAGES += \
    android.hardware.usb@1.0-service-p4note \
    android.hardware.usb.gadget@1.1-service-p4note

# Identity Credential HAL
PRODUCT_PACKAGES += \
    android.hardware.identity-service.example
