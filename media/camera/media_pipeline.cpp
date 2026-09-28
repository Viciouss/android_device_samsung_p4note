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

//#define LOG_NDEBUG 0
#define LOG_TAG "MediaPipeline"

#include "media_pipeline.h"

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

#include <mutex>

#include <linux/v4l2-subdev.h>
#include <linux/videodev2.h>

namespace v4l2_camera_hal {

namespace {

// Highest /dev/media<N> to look at.
const int kMaxMediaDevices = 16;

// Serializes link/format changes. Cameras share entities (they all end in the
// same FIMC), so two of them must not reconfigure the pipeline at once.
std::mutex gPipelineLock;

// Resolve a device number to its /dev node, like udev would.
std::string DevNodePath(uint32_t major, uint32_t minor) {
  if (major == 0 && minor == 0) {
    return "";
  }
  char syspath[64];
  snprintf(syspath, sizeof(syspath), "/sys/dev/char/%u:%u", major, minor);
  char link[256];
  ssize_t len = readlink(syspath, link, sizeof(link) - 1);
  if (len < 0) {
    HAL_LOGE("readlink(%s) failed: %s", syspath, strerror(errno));
    return "";
  }
  link[len] = '\0';
  const char* base = strrchr(link, '/');
  return std::string("/dev/") + (base ? base + 1 : link);
}

}  // namespace

std::shared_ptr<MediaPipeline> MediaPipeline::Create(
    const PipelineConfig& config) {
  HAL_LOG_ENTER();

  std::shared_ptr<MediaPipeline> pipeline(new MediaPipeline(config));
  for (int i = 0; i < kMaxMediaDevices; ++i) {
    if (!pipeline->Open("/dev/media" + std::to_string(i))) {
      continue;
    }

    // Every entity the pipeline touches has to be there, otherwise the camera
    // is not usable (typically the sensor driver failed to probe).
    const Entity* capture = pipeline->FindEntity(config.capture_entity);
    if (!capture || capture->devnode.empty()) {
      continue;
    }
    bool complete = true;
    auto require = [&](const std::string& name) {
      if (!pipeline->FindEntity(name)) {
        HAL_LOGE("%s: media entity '%s' not found.",
                 config.name.c_str(),
                 name.c_str());
        complete = false;
      }
    };
    for (const auto& link : config.links) {
      require(link.source);
      require(link.sink);
    }
    for (const auto& format : config.formats) {
      require(format.entity);
    }
    if (!complete) {
      return nullptr;
    }

    pipeline->capture_path_ = capture->devnode;
    HAL_LOGI("%s: capturing from %s (media device /dev/media%d).",
             config.name.c_str(),
             pipeline->capture_path_.c_str(),
             i);
    return pipeline;
  }

  HAL_LOGE("%s: no media device with entity '%s'.",
           config.name.c_str(),
           config.capture_entity.c_str());
  return nullptr;
}

bool MediaPipeline::Open(const std::string& path) {
  int fd = TEMP_FAILURE_RETRY(open(path.c_str(), O_RDWR));
  if (fd < 0) {
    return false;
  }
  media_fd_.reset(fd);
  entities_.clear();

  media_entity_desc desc;
  memset(&desc, 0, sizeof(desc));
  desc.id = MEDIA_ENT_ID_FLAG_NEXT;
  while (ioctl(media_fd_.get(), MEDIA_IOC_ENUM_ENTITIES, &desc) == 0) {
    Entity entity;
    entity.id = desc.id;
    entity.name = std::string(desc.name, strnlen(desc.name, sizeof(desc.name)));
    entity.devnode = DevNodePath(desc.dev.major, desc.dev.minor);
    entities_.push_back(std::move(entity));
    desc.id |= MEDIA_ENT_ID_FLAG_NEXT;
  }
  return !entities_.empty();
}

const MediaPipeline::Entity* MediaPipeline::FindEntity(
    const std::string& name) const {
  for (const auto& entity : entities_) {
    if (entity.name == name) {
      return &entity;
    }
  }
  const std::string prefix = name + " ";
  for (const auto& entity : entities_) {
    if (entity.name.compare(0, prefix.size(), prefix) == 0) {
      return &entity;
    }
  }
  return nullptr;
}

int MediaPipeline::Apply() {
  HAL_LOG_ENTER();
  std::lock_guard<std::mutex> lock(gPipelineLock);

  for (const auto& link : config_.links) {
    int res = SetLink(link);
    if (res) {
      return res;
    }
  }

  uint32_t width = 0;
  uint32_t height = 0;
  for (const auto& format : config_.formats) {
    PipelineFormat requested = format;
    if (requested.use_previous_size) {
      requested.width = width;
      requested.height = height;
    }
    int res = SetFormat(requested, &width, &height);
    if (res) {
      return res;
    }
  }

  HAL_LOGI("%s: pipeline set up.", config_.name.c_str());
  return 0;
}

int MediaPipeline::SetLink(const PipelineLink& link) {
  const Entity* source = FindEntity(link.source);
  const Entity* sink = FindEntity(link.sink);
  if (!source || !sink) {
    return -ENODEV;
  }

  media_link_desc desc;
  memset(&desc, 0, sizeof(desc));
  desc.source.entity = source->id;
  desc.source.index = link.source_pad;
  desc.sink.entity = sink->id;
  desc.sink.index = link.sink_pad;
  desc.flags = link.enabled ? MEDIA_LNK_FL_ENABLED : 0;
  if (TEMP_FAILURE_RETRY(ioctl(media_fd_.get(), MEDIA_IOC_SETUP_LINK, &desc)) <
      0) {
    int err = errno;
    HAL_LOGE("%s: %s '%s':%u -> '%s':%u failed: %s",
             config_.name.c_str(),
             link.enabled ? "enabling" : "disabling",
             source->name.c_str(),
             link.source_pad,
             sink->name.c_str(),
             link.sink_pad,
             strerror(err));
    return -err;
  }
  HAL_LOGV("%s '%s':%u -> '%s':%u",
           link.enabled ? "enabled" : "disabled",
           source->name.c_str(),
           link.source_pad,
           sink->name.c_str(),
           link.sink_pad);
  return 0;
}

int MediaPipeline::SetFormat(const PipelineFormat& format,
                             uint32_t* result_width,
                             uint32_t* result_height) {
  const Entity* entity = FindEntity(format.entity);
  if (!entity || entity->devnode.empty()) {
    HAL_LOGE("%s: '%s' has no subdevice node.",
             config_.name.c_str(),
             format.entity.c_str());
    return -ENODEV;
  }

  android::base::unique_fd fd(
      TEMP_FAILURE_RETRY(open(entity->devnode.c_str(), O_RDWR)));
  if (fd.get() < 0) {
    int err = errno;
    HAL_LOGE("%s: open(%s) for '%s' failed: %s",
             config_.name.c_str(),
             entity->devnode.c_str(),
             entity->name.c_str(),
             strerror(err));
    return -err;
  }

  v4l2_subdev_format fmt;
  memset(&fmt, 0, sizeof(fmt));
  fmt.which = V4L2_SUBDEV_FORMAT_ACTIVE;
  fmt.pad = format.pad;
  fmt.format.width = format.width;
  fmt.format.height = format.height;
  fmt.format.code = format.mbus_code;
  fmt.format.field = V4L2_FIELD_NONE;
  if (TEMP_FAILURE_RETRY(ioctl(fd.get(), VIDIOC_SUBDEV_S_FMT, &fmt)) < 0) {
    int err = errno;
    HAL_LOGE("%s: VIDIOC_SUBDEV_S_FMT '%s':%u (%s) failed: %s",
             config_.name.c_str(),
             entity->name.c_str(),
             format.pad,
             entity->devnode.c_str(),
             strerror(err));
    return -err;
  }
  HAL_LOGV("'%s':%u set to code 0x%x %ux%u, driver returned code 0x%x %ux%u",
           entity->name.c_str(),
           format.pad,
           format.mbus_code,
           format.width,
           format.height,
           fmt.format.code,
           fmt.format.width,
           fmt.format.height);
  *result_width = fmt.format.width;
  *result_height = fmt.format.height;
  return 0;
}

}  // namespace v4l2_camera_hal
