PRODUCT_PACKAGES += \
    gralloc.gbm \
	gralloc.minigbm \
    hwcomposer.drm \
	libGLES_mesa

PRODUCT_PROPERTY_OVERRIDES += \
    ro.hardware.egl=mesa \
    ro.opengles.version=131072 \
    ro.hardware.gralloc=gbm \
    ro.hardware.hwcomposer=drm \
    hwc.drm.device=/dev/dri/card1 \
    hwc.drm.use_overlay_planes=1 \
    debug.drm.mode.force=1280x800 \
    gralloc.gbm.device=/dev/dri/card1 \
    gralloc.drm.device=/dev/dri/renderD129 \

