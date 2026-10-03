
# Copyright 2019 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# A/B updater
AB_OTA_UPDATER := false

## display setting
TARGET_SCREEN_HEIGHT := 720
TARGET_SCREEN_WIDTH := 1280

PRODUCT_CHARACTERISTICS := tablet

# must come before vendor/omni/config/common.mk, which sets ro.adb.secure=1
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += ro.adb.secure=0

# Inherit from our custom product configuration
$(call inherit-product, vendor/omni/config/common.mk)

# PRODUCT_DEVICE, PRODUCT_NAME and PRODUCT_MODEL are set by the per device makefiles
PRODUCT_BRAND := Samsung
PRODUCT_MANUFACTURER := Samsung

PRODUCT_SHIPPING_API_LEVEL := 28
