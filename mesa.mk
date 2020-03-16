PRODUCT_PACKAGES += \
    gralloc.gbm \
    hwcomposer.drm \
	libGLES_mesa \
    libEGL_swiftshader \
    libGLESv2_swiftshader \

PRODUCT_PROPERTY_OVERRIDES += \
    ro.hardware.egl=mesa \
    ro.opengles.version=131072 \
    ro.hardware.gralloc=gbm \
    ro.hardware.hwcomposer=drm \
    hwc.drm.device=/dev/dri/card0 \
    gralloc.gbm.device=/dev/dri/card0 \
    hwc.drm.use_overlay_planes=1 \
