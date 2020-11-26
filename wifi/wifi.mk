
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/brcmfmac4334-sdio.bin:$(TARGET_COPY_OUT_VENDOR)/lib/firmware/brcm/brcmfmac4334-sdio.bin \
    $(LOCAL_PATH)/brcmfmac4334-sdio.samsung,n8010.txt:$(TARGET_COPY_OUT_VENDOR)/lib/firmware/brcm/brcmfmac4334-sdio.samsung,n8010.txt \
    frameworks/native/data/etc/android.hardware.wifi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.xml \
    $(LOCAL_PATH)/wpa_supplicant.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant.conf \
    $(LOCAL_PATH)/wpa_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant_overlay.conf \
    $(LOCAL_PATH)/p2p_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/p2p_supplicant_overlay.conf \
    $(LOCAL_PATH)/init.wifi.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.wifi.rc

PRODUCT_PACKAGES += libwpa_client wpa_supplicant hostapd wificond

PRODUCT_PROPERTY_OVERRIDES += \
    wifi.interface=wlan0 \
    wifi.supplicant_scan_interval=15
