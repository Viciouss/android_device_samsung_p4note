/*
 * Copyright 2016 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// <camera/CameraMetadata.h> comes from libcamera_client, which is a framework
// library that vendor modules can't link against. The camera HAL helpers
// carry a copy of the class with the same interface, so alias it back to
// android::CameraMetadata, where the HAL sources expect it.

#ifndef V4L2_CAMERA_HAL_COMPAT_CAMERA_CAMERAMETADATA_H_
#define V4L2_CAMERA_HAL_COMPAT_CAMERA_CAMERAMETADATA_H_

// From android.hardware.camera.common-helper (hardware/interfaces/camera).
#include <CameraMetadata.h>

namespace android {
using CameraMetadata = hardware::camera::common::helper::CameraMetadata;
}  // namespace android

#endif  // V4L2_CAMERA_HAL_COMPAT_CAMERA_CAMERAMETADATA_H_
