$(call inherit-product, $(LOCAL_PATH)/../device-common.mk)

PRODUCT_NAME := n8010
PRODUCT_DEVICE := n8010
PRODUCT_MODEL := GT-N8010

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/../wifi/brcmfmac4334-sdio-n8010.txt:$(TARGET_COPY_OUT_VENDOR)/lib/firmware/brcm/brcmfmac4334-sdio.txt \
	$(LOCAL_PATH)/../touchscreen/atmel_rev_5.cfg:$(TARGET_COPY_OUT_VENDOR)/lib/firmware/maxtouch.cfg