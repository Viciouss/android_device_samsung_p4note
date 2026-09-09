# Graphics
PRODUCT_SOONG_NAMESPACES += external/mesa3d

PRODUCT_PACKAGES += \
    android.hardware.graphics.allocator@4.0-service.minigbm \
    android.hardware.graphics.mapper@4.0-impl.minigbm \
    android.hardware.graphics.composer@2.4-impl \
    android.hardware.graphics.composer@2.4-service \
    hwcomposer.drm \
    libGLES_mesa \
    gallium_dri \
    libgbm_mesa \
    libglapi

PRODUCT_PROPERTY_OVERRIDES += \
    ro.hardware.egl=mesa \
    drm.gpu.vendor_name=lima \
    ro.opengles.version=131072 \
    ro.hardware.hwcomposer=drm \
    vendor.hwc.drm.use_overlay_planes=1 \
    vendor.hwc.drm.use_cursor_plane=1 \
    vendor.hwc.drm.scale_with_gpu=1 \
    debug.sf.latch_unsignaled=1 \
    debug.sf.use_phase_offsets_as_durations=1 \
    debug.sf.late.sf.duration=6000000 \
    debug.sf.late.app.duration=16666666 \
    debug.sf.early.sf.duration=6000000 \
    debug.sf.early.app.duration=16666666 \
    debug.sf.earlyGl.sf.duration=6000000 \
    debug.sf.earlyGl.app.duration=16666666
