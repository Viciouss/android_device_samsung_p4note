$(call inherit-product, $(LOCAL_PATH)/../device-common.mk)

PRODUCT_RELEASE_NAME := n8000

PRODUCT_NAME := lineage_n8000
PRODUCT_DEVICE := n8000
PRODUCT_MODEL := GT-N8000
TARGET_DEVICE_RO := p4noterf

# Set build fingerprint / ID / Product Name etc.
PRODUCT_BUILD_PROP_OVERRIDES += \
		PRODUCT_NAME=p4noterfxx \
		TARGET_DEVICE=p4noterf \
		PRIVATE_BUILD_DESC="p4noterfxx-user 4.4.2 KOT49H N8000XXUDPB1 release-keys"

BUILD_FINGERPRINT := samsung/p4noterfxx/p4noterf:4.4.2/KOT49H/N8000XXUDPB1:user/release-keys

PRODUCT_PROPERTY_OVERRIDES += \
    ro.vendor.product.name=p4noterfxx \
    ro.vendor.product.device=p4noterf
