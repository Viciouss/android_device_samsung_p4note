PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/wifi/brcmfmac4334-sdio.bin:$(TARGET_COPY_OUT_VENDOR)/lib/firmware/brcm/brcmfmac4334-sdio.bin \
    $(LOCAL_PATH)/wifi/brcmfmac4334-sdio.samsung,n8000.txt:$(TARGET_COPY_OUT_VENDOR)/lib/firmware/brcm/brcmfmac4334-sdio.samsung,n8000.txt \

PRODUCT_PACKAGES += libwpa_client wpa_supplicant hostapd wificond

PRODUCT_PROPERTY_OVERRIDES += \
    wifi.interface=wlan0 \
    wifi.supplicant_scan_interval=15
