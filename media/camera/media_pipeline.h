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

// Media controller pipeline setup (the equivalent of a media-ctl script) for
// capture devices that are not a single self-contained /dev/video node, like
// the Exynos4 FIMC / FIMC-LITE / FIMC-IS chain.

#ifndef V4L2_CAMERA_HAL_MEDIA_PIPELINE_H_
#define V4L2_CAMERA_HAL_MEDIA_PIPELINE_H_

#include <stdint.h>

#include <memory>
#include <string>
#include <vector>

#include <android-base/unique_fd.h>
#include <linux/media.h>

#include "common.h"

namespace v4l2_camera_hal {

// A media link to enable or disable.
struct PipelineLink {
  std::string source;
  uint32_t source_pad;
  std::string sink;
  uint32_t sink_pad;
  bool enabled;
};

// The active format of one subdevice pad.
struct PipelineFormat {
  std::string entity;
  uint32_t pad;
  uint32_t mbus_code;
  uint32_t width;
  uint32_t height;
  // Use the size the previous format ended up with instead of width/height.
  // Drivers may adjust the size they are given (the FIMC-IS ISP crops a fixed
  // margin), and the next pad has to match what was actually negotiated.
  bool use_previous_size;
};

// A frame size of the capture node.
struct PipelineSize {
  uint32_t width;
  uint32_t height;
};

// Everything needed to bring up the capture path of one camera sensor.
struct PipelineConfig {
  // For logging only.
  std::string name;
  // Media entity of the video node the frames are captured from.
  std::string capture_entity;
  // ANDROID_LENS_FACING_* value reported for this camera.
  uint8_t facing;
  // The frame sizes the capture node produces, and the range of frame
  // durations (in ns) of the sensor. Capture nodes behind the media
  // controller can't enumerate either through V4L2.
  std::vector<PipelineSize> frame_sizes;
  int64_t min_frame_duration_ns;
  int64_t max_frame_duration_ns;
  // Applied in order; disable links that are in the way before enabling new
  // ones.
  std::vector<PipelineLink> links;
  // Applied in order, after the links.
  std::vector<PipelineFormat> formats;
};

// The cameras of this device, in camera id order (see pipeline_configs.cpp).
const std::vector<PipelineConfig>& GetPipelineConfigs();

class MediaPipeline {
 public:
  // Look up the media device that has |config|'s entities. Returns nullptr if
  // there is none, or if an entity the config refers to is missing (e.g. the
  // sensor did not probe), so no camera is exposed for it.
  static std::shared_ptr<MediaPipeline> Create(const PipelineConfig& config);

  // Enable the links and negotiate the formats of this pipeline. This changes
  // links other pipelines depend on, so it must not be called while another
  // pipeline sharing entities is streaming. Returns 0 or a negative errno.
  int Apply();

  const std::string& name() const { return config_.name; }
  // Path of the video node to capture from, e.g. /dev/video4.
  const std::string& capture_path() const { return capture_path_; }
  uint8_t facing() const { return config_.facing; }
  const std::vector<PipelineSize>& frame_sizes() const {
    return config_.frame_sizes;
  }
  int64_t min_frame_duration_ns() const { return config_.min_frame_duration_ns; }
  int64_t max_frame_duration_ns() const { return config_.max_frame_duration_ns; }

 private:
  struct Entity {
    uint32_t id;
    std::string name;
    // Empty for entities without a device node.
    std::string devnode;
  };

  explicit MediaPipeline(const PipelineConfig& config) : config_(config) {}

  // Open |path| and read its entities. Returns false if it can't be used.
  bool Open(const std::string& path);
  // Exact name match, or a match on "<name> <bus id>" for entities like
  // "S5K6A3 2-0010" whose i2c adapter number changes between boots.
  const Entity* FindEntity(const std::string& name) const;
  int SetLink(const PipelineLink& link);
  int SetFormat(const PipelineFormat& format,
                uint32_t* result_width,
                uint32_t* result_height);

  const PipelineConfig config_;
  android::base::unique_fd media_fd_;
  std::vector<Entity> entities_;
  std::string capture_path_;

  MediaPipeline(const MediaPipeline&) = delete;
  MediaPipeline& operator=(const MediaPipeline&) = delete;
};

}  // namespace v4l2_camera_hal

#endif  // V4L2_CAMERA_HAL_MEDIA_PIPELINE_H_
