PRODUCT_PACKAGES += \
    gralloc.gbm \
    hwcomposer.drm \
	libGLES_mesa \
    libGLES_android

PRODUCT_PROPERTY_OVERRIDES += \
    ro.hardware.egl=mesa \
    ro.opengles.version=131072 \
    ro.hardware.gralloc=gbm \
    ro.hardware.hwcomposer=drm \
    hwc.drm.device=/dev/dri/card1 \
    gralloc.gbm.device=/dev/dri/card0 \
    vendor.hwc.drm.use_overlay_planes=1 \
