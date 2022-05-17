# Graphics
PRODUCT_PACKAGES += \
    android.hardware.graphics.allocator@4.0-service.minigbm_gbm_mesa \
    android.hardware.graphics.mapper@4.0-impl.minigbm_gbm_mesa \
    android.hardware.graphics.composer@2.4-impl \
    android.hardware.graphics.composer@2.4-service \

PRODUCT_PACKAGES += \
    hwcomposer.drm \
    libEGL_mesa \
    libGLESv1_CM_mesa \
    libGLESv2_mesa \
    libGLES_android \
    libgallium_dri \
    libglapi \
    libgbm \

PRODUCT_PROPERTY_OVERRIDES += \
    ro.hardware.egl=mesa \
    ro.opengles.version=131072 \
    ro.hardware.hwcomposer=drm \
