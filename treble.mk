# Keymaster
PRODUCT_PACKAGES += \
    android.hardware.security.keymint-service \

# Memtrack
PRODUCT_PACKAGES += \
    android.hardware.memtrack@1.0-impl \
    android.hardware.memtrack@1.0-service \
    memtrack.default \

# Power
PRODUCT_PACKAGES += \
    power.default \
    android.hardware.power@1.0-impl \
    android.hardware.power@1.0-service \

# DRM
PRODUCT_PACKAGES += \
    android.hardware.drm@1.0-impl \
    android.hardware.drm@1.0-service \

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

PRODUCT_PACKAGES += \
    android.hardware.power-service.example \

# Identity Credential HAL
PRODUCT_PACKAGES += \
    android.hardware.identity-service.example
