# Graphics
PRODUCT_SOONG_NAMESPACES += external/mesa3d

PRODUCT_PACKAGES += \
    android.hardware.graphics.allocator@4.0-service.minigbm \
    android.hardware.graphics.mapper@4.0-impl.minigbm \
    gralloc.minigbm \
    android.hardware.composer.hwc3-service.drm \
    libGLES_mesa \
    gallium_dri \
    libgbm_mesa \
    libglapi

PRODUCT_PROPERTY_OVERRIDES += \
    ro.hardware.gralloc=minigbm \
    ro.hwui.texture_cache_size=36 \
    ro.hwui.layer_cache_size=24 \
    ro.hwui.path_cache_size=16 \
    ro.hardware.egl=mesa \
    drm.gpu.vendor_name=lima \
    ro.opengles.version=131072 \
    ro.hardware.hwcomposer=drm \
    ro.vendor.hwc.use_overlay_planes=1 \
    vendor.hwc.drm.solid_color_planes=1 \
    vendor.hwc.drm.min_plane_width=128 \
    vendor.hwc.drm.scale_with_gpu=1 \
    debug.sf.latch_unsignaled=1 \
    debug.sf.use_phase_offsets_as_durations=1 \
    debug.sf.late.sf.duration=6000000 \
    debug.sf.late.app.duration=16666666 \
    debug.sf.early.sf.duration=6000000 \
    debug.sf.early.app.duration=16666666 \
    debug.sf.earlyGl.sf.duration=6000000 \
    debug.sf.earlyGl.app.duration=16666666
