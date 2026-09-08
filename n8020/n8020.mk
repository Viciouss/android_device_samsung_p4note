$(call inherit-product, $(LOCAL_PATH)/../device-common.mk)

PRODUCT_NAME := n8020
PRODUCT_DEVICE := n8020
PRODUCT_MODEL := GT-N8020

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/../wifi/brcmfmac4334-sdio-n8020.txt:$(TARGET_COPY_OUT_VENDOR)/lib/firmware/brcm/brcmfmac4334-sdio.txt