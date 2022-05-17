$(call inherit-product, $(LOCAL_PATH)/../device-common.mk)

PRODUCT_RELEASE_NAME := n8013

PRODUCT_NAME := lineage_n8013
PRODUCT_DEVICE := n8013
PRODUCT_MODEL := GT-N8013
TARGET_DEVICE_RO := p4notewifi

# Set build fingerprint / ID / Product Name etc.
PRODUCT_BUILD_PROP_OVERRIDES += \
		PRODUCT_NAME=p4notewifiue \
		TARGET_DEVICE=p4notewifi \
		PRIVATE_BUILD_DESC="p4notewifiue-user 4.1.2 JZO54K N8013UEUCOI1 release-keys"

BUILD_FINGERPRINT := samsung/p4notewifiue/p4notewifi:4.1.2/JZO54K/N8013UEUCOI1:user/release-keys

PRODUCT_PROPERTY_OVERRIDES += \
    ro.vendor.product.name=p4notewifiue \
    ro.vendor.product.device=p4notewifi
