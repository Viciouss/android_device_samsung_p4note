LOCAL_PATH := $(call my-dir)

ifneq ($(filter n8000 n8010 n8020,$(TARGET_DEVICE)),)

ifeq ($(BOARD_VENDOR_KERNEL_MODULES_LOAD),)

# build modules.load file for kernel module loading
P4NOTE_MODULES_LOAD := $(TARGET_OUT_VENDOR)/lib/modules/modules.load

# $(PRODUCT_OUT)/kernel is installed by the same kernel.mk recipe that installs
# the modules, so depending on it orders this after modules.dep is in place.
$(P4NOTE_MODULES_LOAD): $(PRODUCT_OUT)/kernel
	@echo "Generating vendor modules.load"
	$(hide) sed -e 's|:.*||' -e 's|^.*/||' $(dir $@)modules.dep > $@

$(PRODUCT_OUT)/vendor.img: $(P4NOTE_MODULES_LOAD)

endif
endif
