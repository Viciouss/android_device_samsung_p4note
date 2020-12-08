PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/sensors.p4note.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/sensors.p4note.rc \

PRODUCT_PACKAGES += \
    sensors.iio \
    android.hardware.sensors@1.0-impl \
    android.hardware.sensors@1.0-service \

DEVICE_MANIFEST_FILE += \
    $(LOCAL_PATH)/manifest.xml