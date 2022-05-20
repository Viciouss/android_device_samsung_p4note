# Keymaster
PRODUCT_PACKAGES += \
    android.hardware.security.keymint-service \

# Power
PRODUCT_PACKAGES += \
    android.hardware.power-service.example

# DRM
PRODUCT_PACKAGES += \
    android.hardware.drm@1.3-impl \
    android.hardware.drm@1.3-service \

# Health
PRODUCT_PACKAGES += \
    android.hardware.health@2.1-service \
    android.hardware.health@2.1-impl-p4note \
    android.hardware.health@2.1-impl-p4note.recovery \

# Lights
PRODUCT_PACKAGES += \
    android.hardware.lights-service.p4note \

# Gatekeeper
PRODUCT_PACKAGES += \
    android.hardware.gatekeeper@1.0-service.software \

PRODUCT_PACKAGES += \
    android.hardware.usb@1.0-service-p4note \
    android.hardware.usb.gadget@1.1-service-p4note

# Identity Credential HAL
PRODUCT_PACKAGES += \
    android.hardware.identity-service.example
