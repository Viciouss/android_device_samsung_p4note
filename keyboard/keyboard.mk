PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/sec_keyboard.idc:$(TARGET_COPY_OUT_VENDOR)/usr/idc/sec_keyboard.idc \
    $(LOCAL_PATH)/sec_keyboard.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/sec_keyboard.kl \

# show/hide keyboard and search keys, see keyhandler/
PRODUCT_PACKAGES += \
    P4noteKeyHandler \
