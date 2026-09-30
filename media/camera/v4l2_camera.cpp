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
#define LOG_TAG "V4L2Camera"

#include "v4l2_camera.h"

#include <chrono>
#include <cstdlib>
#include <fcntl.h>

#include <camera/CameraMetadata.h>
#include <hardware/camera3.h>
#include <linux/videodev2.h>
#include <sys/stat.h>
#include <sys/types.h>
#include "common.h"
#include "function_thread.h"
#include "metadata/metadata_common.h"
#include "stream_format.h"
#include "v4l2_metadata_factory.h"

#define ARRAY_SIZE(a) (sizeof(a) / sizeof(*(a)))

namespace v4l2_camera_hal {

V4L2Camera* V4L2Camera::NewV4L2Camera(
    int id, std::shared_ptr<MediaPipeline> pipeline) {
  HAL_LOG_ENTER();

  const std::string path = pipeline->capture_path();
  const uint8_t facing = pipeline->facing();
  std::string flash_led = pipeline->flash_led();
  std::shared_ptr<V4L2Wrapper> v4l2_wrapper(
      V4L2Wrapper::NewV4L2Wrapper(path, std::move(pipeline)));
  if (!v4l2_wrapper) {
    HAL_LOGE("Failed to initialize V4L2 wrapper.");
    return nullptr;
  }

  std::unique_ptr<Metadata> metadata;
  int res =
      GetV4L2Metadata(v4l2_wrapper, facing, !flash_led.empty(), &metadata);
  if (res) {
    HAL_LOGE("Failed to initialize V4L2 metadata: %d", res);
    return nullptr;
  }

  return new V4L2Camera(id, std::move(v4l2_wrapper), std::move(metadata),
                        std::move(flash_led));
}

V4L2Camera::V4L2Camera(int id,
                       std::shared_ptr<V4L2Wrapper> v4l2_wrapper,
                       std::unique_ptr<Metadata> metadata,
                       std::string flash_led)
    : default_camera_hal::Camera(id),
      device_(std::move(v4l2_wrapper)),
      metadata_(std::move(metadata)),
      id_(id),
      flash_led_(std::move(flash_led)),
      buffer_enqueuer_(new FunctionThread(
          std::bind(&V4L2Camera::enqueueRequestBuffers, this))),
      buffer_dequeuer_(new FunctionThread(
          std::bind(&V4L2Camera::dequeueRequestBuffers, this))),
      max_input_streams_(0),
      max_output_streams_({{0, 0, 0}}) {
  HAL_LOG_ENTER();
}

V4L2Camera::~V4L2Camera() {
  HAL_LOG_ENTER();
}

void V4L2Camera::SetConflictingDevices(const std::vector<int>& camera_ids) {
  conflicting_ids_.clear();
  for (int id : camera_ids) {
    conflicting_ids_.push_back(std::to_string(id));
  }
  // The strings aren't modified, and |conflicting_ids_| isn't touched again,
  // so these stay valid for as long as the camera info is used.
  conflicting_devices_.clear();
  for (const std::string& id : conflicting_ids_) {
    conflicting_devices_.push_back(const_cast<char*>(id.c_str()));
  }
}

void V4L2Camera::SetOpenListener(
    std::function<void(int id, bool open)> listener) {
  open_listener_ = std::move(listener);
}

int V4L2Camera::connect() {
  HAL_LOG_ENTER();

  if (connection_) {
    HAL_LOGE("Already connected. Please disconnect and try again.");
    return -EIO;
  }

  // Before powering the sensor up, so a torch that is on goes off first.
  if (open_listener_) {
    open_listener_(id_, true);
  }

  connection_.reset(new V4L2Wrapper::Connection(device_));
  if (connection_->status()) {
    HAL_LOGE("Failed to connect to device.");
    int res = connection_->status();
    connection_.reset();
    if (open_listener_) {
      open_listener_(id_, false);
    }
    return res;
  }

  // TODO(b/29185945): confirm this is a supported device.
  // This is checked by the HAL, but the device at |device_|'s path may
  // not be the same one that was there when the HAL was loaded.
  // (Alternatively, better hotplugging support may make this unecessary
  // by disabling cameras that get disconnected and checking newly connected
  // cameras, so connect() is never called on an unsupported camera)
  return 0;
}

void V4L2Camera::disconnect() {
  HAL_LOG_ENTER();

  connection_.reset();

  if (open_listener_) {
    open_listener_(id_, false);
  }
}

int V4L2Camera::flushBuffers() {
  HAL_LOG_ENTER();
  // Waits for the dequeue thread to finish the frame it may be filling, so
  // no buffer is written after the flush has returned it.
  std::lock_guard<std::mutex> guard(in_flight_lock_);
  return device_->StreamOff();
}

int V4L2Camera::initStaticInfo(android::CameraMetadata* out) {
  HAL_LOG_ENTER();

  int res = metadata_->FillStaticMetadata(out);
  if (res) {
    HAL_LOGE("Failed to get static metadata.");
    return res;
  }

  // Extract max streams for use in verifying stream configs.
  res = SingleTagValue(
      *out, ANDROID_REQUEST_MAX_NUM_INPUT_STREAMS, &max_input_streams_);
  if (res) {
    HAL_LOGE("Failed to get max num input streams from static metadata.");
    return res;
  }
  res = SingleTagValue(
      *out, ANDROID_REQUEST_MAX_NUM_OUTPUT_STREAMS, &max_output_streams_);
  if (res) {
    HAL_LOGE("Failed to get max num output streams from static metadata.");
    return res;
  }

  return 0;
}

int V4L2Camera::initTemplate(int type, android::CameraMetadata* out) {
  HAL_LOG_ENTER();

  return metadata_->GetRequestTemplate(type, out);
}

void V4L2Camera::initDeviceInfo(camera_info_t* info) {
  HAL_LOG_ENTER();

  // TODO(b/31044975): move this into device interface.
  // For now, just constants.
  info->resource_cost = 100;
  info->conflicting_devices =
      conflicting_devices_.empty() ? nullptr : conflicting_devices_.data();
  info->conflicting_devices_length = conflicting_devices_.size();
}

int V4L2Camera::initDevice() {
  HAL_LOG_ENTER();

  // Start the buffer enqueue/dequeue threads if they're not already running.
  if (!buffer_enqueuer_->isRunning()) {
    android::status_t res = buffer_enqueuer_->run("Enqueue buffers");
    if (res != android::OK) {
      HAL_LOGE("Failed to start buffer enqueue thread: %d", res);
      return -ENODEV;
    }
  }
  if (!buffer_dequeuer_->isRunning()) {
    android::status_t res = buffer_dequeuer_->run("Dequeue buffers");
    if (res != android::OK) {
      HAL_LOGE("Failed to start buffer dequeue thread: %d", res);
      return -ENODEV;
    }
  }

  return 0;
}

int V4L2Camera::enqueueRequest(
    std::shared_ptr<default_camera_hal::CaptureRequest> request) {
  HAL_LOG_ENTER();

  // Assume request validated before calling this function.
  // (For now, always exactly 1 output buffer, no inputs).
  {
    std::lock_guard<std::mutex> guard(request_queue_lock_);
    request_queue_.push(request);
    requests_available_.notify_one();
  }

  return 0;
}

std::shared_ptr<default_camera_hal::CaptureRequest>
V4L2Camera::dequeueRequest() {
  std::unique_lock<std::mutex> lock(request_queue_lock_);
  while (request_queue_.empty()) {
    requests_available_.wait(lock);
  }

  std::shared_ptr<default_camera_hal::CaptureRequest> request =
      request_queue_.front();
  request_queue_.pop();
  return request;
}

bool V4L2Camera::enqueueRequestBuffers() {
  // Get a request from the queue (blocks this thread until one is available).
  std::shared_ptr<default_camera_hal::CaptureRequest> request =
      dequeueRequest();

  // Assume request validated before being added to the queue
  // (For now, always exactly 1 output buffer, no inputs).

  // Setting and getting settings are best effort here,
  // since there's no way to know through V4L2 exactly what
  // settings are used for a buffer unless we were to enqueue them
  // one at a time, which would be too slow.

  // Set the requested settings
  int res = metadata_->SetRequestSettings(request->settings);
  if (res) {
    HAL_LOGE("Failed to set settings.");
    completeRequest(request, res);
    return true;
  }

  // Replace the requested settings with a snapshot of
  // the used settings/state immediately before enqueue.
  res = metadata_->FillResultMetadata(&request->settings);
  if (res) {
    // Note: since request is a shared pointer, this may happen if another
    // thread has already decided to complete the request (e.g. via flushing),
    // since that locks the metadata (in that case, this failing is fine,
    // and completeRequest will simply do nothing).
    HAL_LOGE("Failed to fill result metadata.");
    completeRequest(request, res);
    return true;
  }

  // Actually enqueue the buffer for capture.
  res = device_->EnqueueRequest(request);
  if (res) {
    HAL_LOGE("Device failed to enqueue buffer.");
    completeRequest(request, res);
    return true;
  }

  // Make sure the stream is on (no effect if already on).
  res = device_->StreamOn();
  if (res) {
    HAL_LOGE("Device failed to turn on stream.");
    // Don't really want to send an error for only the request here,
    // since this is a full device error.
    // TODO: Should trigger full flush.
    return true;
  }

  // Wake the dequeue thread, which idles while the stream is off.
  buffers_in_flight_.notify_one();
  return true;
}

bool V4L2Camera::dequeueRequestBuffers() {
  std::shared_ptr<default_camera_hal::CaptureRequest> request;
  int res;

  {
    // Held while the device buffers are used, so setupStreams() can't
    // reallocate them underneath.
    std::unique_lock<std::mutex> lock(in_flight_lock_);
    if (!device_->streaming()) {
      // Nothing to dequeue until the enqueue thread turns the stream on.
      buffers_in_flight_.wait_for(lock, std::chrono::milliseconds(100));
      return true;
    }
    // Keeps recycling frames even when no request is waiting: the device
    // has to get its buffers back to keep capturing.
    res = device_->DequeueRequest(&request);
  }

  if (!res) {
    if (request) {
      completeRequest(request, 0);
    }
  } else if (res != -EAGAIN) {
    HAL_LOGW("Device failed to dequeue buffer: %d", res);
    // Back off instead of spinning on a device that keeps failing.
    std::unique_lock<std::mutex> lock(in_flight_lock_);
    buffers_in_flight_.wait_for(lock, std::chrono::milliseconds(100));
  }
  return true;
}

bool V4L2Camera::validateDataspacesAndRotations(
    const camera3_stream_configuration_t* stream_config) {
  HAL_LOG_ENTER();

  for (uint32_t i = 0; i < stream_config->num_streams; ++i) {
    if (stream_config->streams[i]->rotation != CAMERA3_STREAM_ROTATION_0) {
      HAL_LOGV("Rotation %d for stream %d not supported",
               stream_config->streams[i]->rotation,
               i);
      return false;
    }
    // Accept all dataspaces, as it will just be overwritten below anyways.
  }
  return true;
}

int V4L2Camera::setupStreams(camera3_stream_configuration_t* stream_config) {
  HAL_LOG_ENTER();

  std::lock_guard<std::mutex> guard(in_flight_lock_);
  // The framework should be enforcing this, but doesn't hurt to be safe.
  if (device_->GetInFlightBufferCount() != 0) {
    HAL_LOGE("Can't set device format while frames are in flight.");
    return -EINVAL;
  }

  // stream_config should have been validated; assume at least 1 stream.
  // The device produces one frame size at a time, and every stream is made
  // from that frame. Capture at the size of the video encoder stream, which
  // is the one converted every frame (a recording often comes with a larger
  // JPEG stream for snapshots), otherwise at the largest size. The other
  // streams are scaled in software, cropped to keep their aspect ratio.
  camera3_stream_t* stream = stream_config->streams[0];
  for (uint32_t i = 1; i < stream_config->num_streams; ++i) {
    camera3_stream_t* candidate = stream_config->streams[i];
    if (stream->usage & GRALLOC_USAGE_HW_VIDEO_ENCODER) {
      break;
    }
    if ((candidate->usage & GRALLOC_USAGE_HW_VIDEO_ENCODER) ||
        candidate->width * candidate->height > stream->width * stream->height) {
      stream = candidate;
    }
  }
  int format = stream->format;
  uint32_t width = stream->width;
  uint32_t height = stream->height;

  // Ensure the stream is off.
  int res = device_->StreamOff();
  if (res) {
    HAL_LOGE("Device failed to turn off stream for reconfiguration: %d.", res);
    return -ENODEV;
  }

  StreamFormat stream_format(format, width, height);
  uint32_t max_buffers = 0;
  res = device_->SetFormat(stream_format, &max_buffers);
  if (res) {
    HAL_LOGE("Failed to set device to correct format for stream: %d.", res);
    return -ENODEV;
  }

  // Sanity check.
  if (max_buffers < 1) {
    HAL_LOGE("Setting format resulted in an invalid maximum of %u buffers.",
             max_buffers);
    return -ENODEV;
  }

  // Set all the streams dataspaces, usages, and max buffers.
  for (uint32_t i = 0; i < stream_config->num_streams; ++i) {
    stream = stream_config->streams[i];

    // Override HAL_PIXEL_FORMAT_IMPLEMENTATION_DEFINED format. Video encoder
    // surfaces get YUV: the software encoders take it as is, but convert RGBA
    // back to YUV in plain C, which caps 720p recording at ~3 fps.
    if (stream->format == HAL_PIXEL_FORMAT_IMPLEMENTATION_DEFINED) {
      stream->format = (stream->usage & GRALLOC_USAGE_HW_VIDEO_ENCODER)
                           ? HAL_PIXEL_FORMAT_YCbCr_420_888
                           : HAL_PIXEL_FORMAT_RGBA_8888;
    }

    // Max buffers as reported by the device.
    stream->max_buffers = max_buffers;

    // Usage: currently using sw graphics.
    switch (stream->stream_type) {
      case CAMERA3_STREAM_INPUT:
        stream->usage = GRALLOC_USAGE_SW_READ_OFTEN;
        break;
      case CAMERA3_STREAM_OUTPUT:
        stream->usage = GRALLOC_USAGE_SW_WRITE_OFTEN;
        break;
      case CAMERA3_STREAM_BIDIRECTIONAL:
        stream->usage =
            GRALLOC_USAGE_SW_READ_OFTEN | GRALLOC_USAGE_SW_WRITE_OFTEN;
        break;
      default:
        // nothing to do.
        break;
    }

    // Doesn't matter what was requested, we always use dataspace V0_JFIF.
    // Note: according to camera3.h, this isn't allowed, but the camera
    // framework team claims it's underdocumented; the implementation lets the
    // HAL overwrite it. If this is changed, change the validation above.
    stream->data_space = HAL_DATASPACE_V0_JFIF;
  }

  return 0;
}

bool V4L2Camera::isValidRequestSettings(
    const android::CameraMetadata& settings) {
  if (!metadata_->IsValidRequest(settings)) {
    HAL_LOGE("Invalid request settings.");
    return false;
  }
  return true;
}

}  // namespace v4l2_camera_hal
