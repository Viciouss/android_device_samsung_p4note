$(call inherit-product, $(LOCAL_PATH)/../device-common.mk)

PRODUCT_RELEASE_NAME := n8020

PRODUCT_NAME := lineage_n8020
PRODUCT_DEVICE := n8020
PRODUCT_MODEL := GT-N8020

# Set build fingerprint / ID / Product Name etc.
PRODUCT_BUILD_PROP_OVERRIDES += \
		PRODUCT_NAME=p4noteltexx \
		TARGET_DEVICE=p4notelte \
		PRIVATE_BUILD_DESC="p4noteltexx-user 4.4.2 KOT49H N8020XXUDOL1 release-keys"

BUILD_FINGERPRINT := samsung/p4noteltexx/p4notelte:4.4.2/KOT49H/N8020XXUDOL1:user/release-keys

PRODUCT_PROPERTY_OVERRIDES += \
    ro.vendor.product.name=p4noteltexx \
    ro.vendor.product.device=p4notelte
