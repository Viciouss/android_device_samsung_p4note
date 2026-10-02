$(call inherit-product, $(LOCAL_PATH)/../device-common.mk)

PRODUCT_NAME := n8010
PRODUCT_DEVICE := n8010
PRODUCT_MODEL := GT-N8010

PRODUCT_COPY_FILES += \
	$(LOCAL_PATH)/../touchscreen/atmel_rev_5.cfg:$(TARGET_COPY_OUT_VENDOR)/lib/firmware/maxtouch.cfg