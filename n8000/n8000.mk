$(call inherit-product, $(LOCAL_PATH)/../device-common.mk)

PRODUCT_NAME := n8000
PRODUCT_DEVICE := n8000
PRODUCT_MODEL := GT-N8000

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/../wifi/brcmfmac4334-sdio-n8000.txt:$(TARGET_COPY_OUT_VENDOR)/lib/firmware/brcm/brcmfmac4334-sdio.txt \
    $(LOCAL_PATH)/../touchscreen/atmel_rev_6_to_8.cfg:$(TARGET_COPY_OUT_VENDOR)/lib/firmware/maxtouch.cfg