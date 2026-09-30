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

// The media pipelines of the p4note cameras. Camera ids follow the order of
// this table.
//
// The frame sizes are what FIMC.1 captures from the negotiated pipeline
// format. More sizes (FIMC can scale) can be added, but the HAL fails the
// stream configuration if the driver doesn't accept one, so add them one by
// one.

#include <linux/media-bus-format.h>
#include <system/camera_metadata.h>

#include "media_pipeline.h"

namespace v4l2_camera_hal {

const std::vector<PipelineConfig>& GetPipelineConfigs() {
  static const std::vector<PipelineConfig> kConfigs = {
      // Rear: ISX012 -> s5p-mipi-csis.0 -> FIMC.1
      //
      // The ISX012 has its own ISP and sends YUV over CSI-2, so the frames
      // go straight into FIMC.1's camera input without touching FIMC-IS.
      // Its ISP scales to any of the sizes below by itself (the stock
      // driver only wrote them to HSIZE_MONI/VSIZE_MONI), so the sensor
      // outputs each stream size natively with its full field of view.
      {
          "ISX012 (rear)",
          "fimc.1.capture",
          ANDROID_LENS_FACING_BACK,
          {{1280, 720}, {640, 480}},
          33333333,   // 30 fps
          100000000,  // 10 fps
          {
              // FIMC.1 takes one input at a time: drop the FIMC-IS output
              // (front camera) before claiming the camera input.
              {"FIMC-IS-ISP", 1, "FIMC.1", 1, false},
              {"s5p-mipi-csis.0", 1, "FIMC.1", 0, true},
          },
          {
              {"ISX012", 0, MEDIA_BUS_FMT_VYUY8_2X8, 640, 480, false,
               /*use_stream_size=*/true},
              {"s5p-mipi-csis.0", 0, MEDIA_BUS_FMT_VYUY8_2X8, 0, 0, true},
              {"s5p-mipi-csis.0", 1, MEDIA_BUS_FMT_VYUY8_2X8, 0, 0, true},
              {"FIMC.1", 0, MEDIA_BUS_FMT_VYUY8_2X8, 0, 0, true},
          },
          false,
          // SGM3140 (leds-sgm3140). Its brightness switches torch mode,
          // which has no timeout, unlike the flash strobe.
          "/sys/class/leds/white:flash",
      },
      // Front: S5K6A3 -> s5p-mipi-csis.1 -> FIMC-LITE.1 -> FIMC-IS-ISP
      //        -> FIMC.1
      //
      // The S5K6A3 sends raw Bayer, which the FIMC-IS ISP turns into YUV.
      {
          "S5K6A3 (front)",
          "fimc.1.capture",
          ANDROID_LENS_FACING_FRONT,
          // 640x480 is the stock recording size; FIMC.1 crops the 4:3 middle
          // of the 16:9 frame and scales it down in hardware.
          {{1280, 720}, {640, 480}},
          33333333,   // 30 fps
          100000000,  // 10 fps
          {
              // FIMC.1 takes one input at a time: drop the direct camera
              // input (rear camera) before claiming the FIMC-IS output.
              {"s5p-mipi-csis.0", 1, "FIMC.1", 0, false},
              {"s5p-mipi-csis.1", 1, "FIMC-LITE.1", 0, true},
              {"FIMC-LITE.1", 2, "FIMC-IS-ISP", 0, true},
              {"FIMC-IS-ISP", 1, "FIMC.1", 1, true},
          },
          {
              {"S5K6A3", 0, MEDIA_BUS_FMT_SGRBG10_1X10, 1296, 732, false},
              {"s5p-mipi-csis.1", 0, MEDIA_BUS_FMT_SGRBG10_1X10, 1296, 732, false},
              {"s5p-mipi-csis.1", 1, MEDIA_BUS_FMT_SGRBG10_1X10, 1296, 732, false},
              {"FIMC-LITE.1", 0, MEDIA_BUS_FMT_SGRBG10_1X10, 1296, 732, false},
              {"FIMC-LITE.1", 2, MEDIA_BUS_FMT_SGRBG10_1X10, 1296, 732, false},
              {"FIMC-IS-ISP", 0, MEDIA_BUS_FMT_SGRBG10_1X10, 1296, 732, false},
              // The driver crops a fixed 16x12 margin off this pad (1280x720
              // for the size above); FIMC.1's sink has to match that.
              {"FIMC-IS-ISP", 1, MEDIA_BUS_FMT_YUV10_1X30, 1296, 732, false},
              {"FIMC.1", 1, MEDIA_BUS_FMT_YUV10_1X30, 0, 0, true},
          },
          // FIMC.1 stops getting frames from the FIMC-IS ISP after a
          // STREAMOFF/STREAMON within one open (it hangs inside a frame, the
          // picture shifted and wrapped); closing the node resets it.
          true,
      },
  };
  return kConfigs;
}

}  // namespace v4l2_camera_hal
