PRODUCT_PACKAGES += \
	gralloc.gbm \
    hwcomposer.drm \
    libGLES_mesa


PRODUCT_PROPERTY_OVERRIDES += \
    ro.hardware.egl=mesa \
    ro.opengles.version=131072 \
    ro.hardware.gralloc=gbm \
    ro.hardware.hwcomposer=drm \
    hwc.drm.device=/dev/dri/card0 \
    hwc.drm.use_overlay_planes=1 \
    debug.drm.mode.force=1280x800 \
    gralloc.gbm.device=/dev/dri/renderD128 \
