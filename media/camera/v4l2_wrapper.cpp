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
#define LOG_TAG "V4L2Wrapper"

#include "v4l2_wrapper.h"

#include <algorithm>
#include <fcntl.h>
#include <poll.h>
#include <limits>

#include <android-base/unique_fd.h>
#include <linux/videodev2.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include "arc/cached_frame.h"

namespace v4l2_camera_hal {

using arc::AllocatedFrameBuffer;
using arc::SupportedFormat;
using arc::SupportedFormats;
using default_camera_hal::CaptureRequest;

// Number of buffers requested from the device. It may grant more or fewer.
// Streaming needs a few in flight so the sensor isn't starved between frames.
const uint32_t kNumDeviceBuffers = 4;

// How long DequeueRequest() waits for a frame before returning -EAGAIN.
const int kDequeueTimeoutMs = 200;

const int32_t kStandardSizes[][2] = {
  {4096, 2160}, // 4KDCI (for USB camera)
  {3840, 2160}, // 4KUHD (for USB camera)
  {3280, 2464}, // 8MP
  {2560, 1440}, // QHD
  {1920, 1080}, // HD1080
  {1640, 1232}, // 2MP
  {1280,  720}, // HD
  {1024,  768}, // XGA
  { 640,  480}, // VGA
  { 320,  240}, // QVGA
  { 176,  144}  // QCIF
};

V4L2Wrapper* V4L2Wrapper::NewV4L2Wrapper(
    const std::string device_path, std::shared_ptr<MediaPipeline> pipeline) {
  return new V4L2Wrapper(device_path, std::move(pipeline));
}

V4L2Wrapper::V4L2Wrapper(const std::string device_path,
                         std::shared_ptr<MediaPipeline> pipeline)
    : device_path_(std::move(device_path)),
      pipeline_(std::move(pipeline)),
      connection_count_(0) {}

V4L2Wrapper::~V4L2Wrapper() {}

int V4L2Wrapper::Connect() {
  HAL_LOG_ENTER();
  std::lock_guard<std::mutex> lock(connection_lock_);

  if (connected()) {
    HAL_LOGV("Camera device %s is already connected.", device_path_.c_str());
    ++connection_count_;
    return 0;
  }

  // Other cameras may have reconfigured the shared media pipeline since the
  // last connection, so set it up again for this one.
  if (pipeline_) {
    int res = pipeline_->Apply();
    if (res) {
      HAL_LOGE("Failed to set up the media pipeline of %s: %d",
               pipeline_->name().c_str(),
               res);
      return res;
    }
  }

  // Open in nonblocking mode (DQBUF may return EAGAIN).
  int fd = TEMP_FAILURE_RETRY(open(device_path_.c_str(), O_RDWR | O_NONBLOCK));
  if (fd < 0) {
    HAL_LOGE("failed to open %s (%s)", device_path_.c_str(), strerror(errno));
    return -ENODEV;
  }
  device_fd_.reset(fd);
  ++connection_count_;

  // Check if this connection has the extended control query capability.
  v4l2_query_ext_ctrl query;
  query.id = V4L2_CTRL_FLAG_NEXT_CTRL | V4L2_CTRL_FLAG_NEXT_COMPOUND;
  extended_query_supported_ = (IoctlLocked(VIDIOC_QUERY_EXT_CTRL, &query) == 0);

  // TODO(b/29185945): confirm this is a supported device.
  // This is checked by the HAL, but the device at device_path_ may
  // not be the same one that was there when the HAL was loaded.
  // (Alternatively, better hotplugging support may make this unecessary
  // by disabling cameras that get disconnected and checking newly connected
  // cameras, so Connect() is never called on an unsupported camera)

  supported_formats_ = GetSupportedFormats();
  qualified_formats_ = StreamFormat::GetQualifiedFormats(supported_formats_);

  return 0;
}

void V4L2Wrapper::Disconnect() {
  HAL_LOG_ENTER();
  std::lock_guard<std::mutex> lock(connection_lock_);

  if (connection_count_ == 0) {
    // Not connected.
    HAL_LOGE("Camera device %s is not connected, cannot disconnect.",
             device_path_.c_str());
    return;
  }

  --connection_count_;
  if (connection_count_ > 0) {
    HAL_LOGV("Disconnected from camera device %s. %d connections remain.",
             device_path_.c_str(), connection_count_);
    return;
  }

  device_fd_.reset(-1);  // Includes close().
  streaming_ = false;
  format_.reset();
  {
    std::lock_guard<std::mutex> pending_lock(pending_lock_);
    pending_requests_.clear();
  }
  {
    std::lock_guard<std::mutex> buffer_lock(buffer_queue_lock_);
    UnmapBuffers();
    buffers_.clear();
  }
}

// Helper function. Should be used instead of ioctl throughout this class.
template <typename T>
int V4L2Wrapper::IoctlLocked(unsigned long request, T data) {
  // Potentially called so many times logging entry is a bad idea.
  std::lock_guard<std::mutex> lock(device_lock_);

  if (!connected()) {
    HAL_LOGE("Device %s not connected.", device_path_.c_str());
    return -ENODEV;
  }
  return TEMP_FAILURE_RETRY(ioctl(device_fd_.get(), request, data));
}

int V4L2Wrapper::StreamOn() {
  if (!format_) {
    HAL_LOGE("Stream format must be set before turning on stream.");
    return -EINVAL;
  }

  if (streaming_) {
    return 0;
  }

  int res = QueueFreeBuffers();
  if (res) {
    return res;
  }

  int32_t type = format_->type();
  if (IoctlLocked(VIDIOC_STREAMON, &type) < 0) {
    HAL_LOGE("STREAMON fails (%d): %s", errno, strerror(errno));
    return -ENODEV;
  }

  streaming_ = true;
  HAL_LOGV("Stream turned on.");
  return 0;
}

int V4L2Wrapper::StreamOff() {
  if (!format_) {
    // Can't have turned on the stream without format being set,
    // so nothing to turn off here.
    return 0;
  }

  int32_t type = format_->type();
  int res = IoctlLocked(VIDIOC_STREAMOFF, &type);
  // Calling STREAMOFF releases all queued buffers back to the user.
  // No buffers in flight.
  if (res < 0) {
    HAL_LOGE("STREAMOFF fails: %s", strerror(errno));
    return -ENODEV;
  }
  streaming_ = false;
  {
    std::lock_guard<std::mutex> lock(buffer_queue_lock_);
    for (auto& buffer : buffers_) {
      buffer.active = false;
    }
  }
  // Requests still waiting for a frame have been completed with an error by
  // the flush that turned the stream off, or were drained before it.
  std::lock_guard<std::mutex> pending_lock(pending_lock_);
  pending_requests_.clear();
  HAL_LOGV("Stream turned off.");
  return 0;
}

int V4L2Wrapper::QueryControl(uint32_t control_id,
                              v4l2_query_ext_ctrl* result) {
  int res;

  memset(result, 0, sizeof(*result));

  if (extended_query_supported_) {
    result->id = control_id;
    res = IoctlLocked(VIDIOC_QUERY_EXT_CTRL, result);
    // Assuming the operation was supported (not ENOTTY), no more to do.
    if (errno != ENOTTY) {
      if (res) {
        HAL_LOGE("QUERY_EXT_CTRL fails: %s", strerror(errno));
        return -ENODEV;
      }
      return 0;
    }
  }

  // Extended control querying not supported, fall back to basic control query.
  v4l2_queryctrl query;
  query.id = control_id;
  if (IoctlLocked(VIDIOC_QUERYCTRL, &query)) {
    HAL_LOGE("QUERYCTRL fails: %s", strerror(errno));
    return -ENODEV;
  }

  // Convert the basic result to the extended result.
  result->id = query.id;
  result->type = query.type;
  memcpy(result->name, query.name, sizeof(query.name));
  result->minimum = query.minimum;
  if (query.type == V4L2_CTRL_TYPE_BITMASK) {
    // According to the V4L2 documentation, when type is BITMASK,
    // max and default should be interpreted as __u32. Practically,
    // this means the conversion from 32 bit to 64 will pad with 0s not 1s.
    result->maximum = static_cast<uint32_t>(query.maximum);
    result->default_value = static_cast<uint32_t>(query.default_value);
  } else {
    result->maximum = query.maximum;
    result->default_value = query.default_value;
  }
  result->step = static_cast<uint32_t>(query.step);
  result->flags = query.flags;
  result->elems = 1;
  switch (result->type) {
    case V4L2_CTRL_TYPE_INTEGER64:
      result->elem_size = sizeof(int64_t);
      break;
    case V4L2_CTRL_TYPE_STRING:
      result->elem_size = result->maximum + 1;
      break;
    default:
      result->elem_size = sizeof(int32_t);
      break;
  }

  return 0;
}

int V4L2Wrapper::GetControl(uint32_t control_id, int32_t* value) {
  // For extended controls (any control class other than "user"),
  // G_EXT_CTRL must be used instead of G_CTRL.
  if (V4L2_CTRL_ID2CLASS(control_id) != V4L2_CTRL_CLASS_USER) {
    v4l2_ext_control control;
    v4l2_ext_controls controls;
    memset(&control, 0, sizeof(control));
    memset(&controls, 0, sizeof(controls));

    control.id = control_id;
    controls.ctrl_class = V4L2_CTRL_ID2CLASS(control_id);
    controls.count = 1;
    controls.controls = &control;

    if (IoctlLocked(VIDIOC_G_EXT_CTRLS, &controls) < 0) {
      HAL_LOGE("G_EXT_CTRLS fails: %s", strerror(errno));
      return -ENODEV;
    }
    *value = control.value;
  } else {
    v4l2_control control{control_id, 0};
    if (IoctlLocked(VIDIOC_G_CTRL, &control) < 0) {
      HAL_LOGE("G_CTRL fails: %s", strerror(errno));
      return -ENODEV;
    }
    *value = control.value;
  }
  return 0;
}

int V4L2Wrapper::SetControl(uint32_t control_id,
                            int32_t desired,
                            int32_t* result) {
  int32_t result_value = 0;

  // TODO(b/29334616): When async, this may need to check if the stream
  // is on, and if so, lock it off while setting format. Need to look
  // into if V4L2 supports adjusting controls while the stream is on.

  // For extended controls (any control class other than "user"),
  // S_EXT_CTRL must be used instead of S_CTRL.
  if (V4L2_CTRL_ID2CLASS(control_id) != V4L2_CTRL_CLASS_USER) {
    v4l2_ext_control control;
    v4l2_ext_controls controls;
    memset(&control, 0, sizeof(control));
    memset(&controls, 0, sizeof(controls));

    control.id = control_id;
    control.value = desired;
    controls.ctrl_class = V4L2_CTRL_ID2CLASS(control_id);
    controls.count = 1;
    controls.controls = &control;

    if (IoctlLocked(VIDIOC_S_EXT_CTRLS, &controls) < 0) {
      HAL_LOGE("S_EXT_CTRLS fails: %s", strerror(errno));
      return -ENODEV;
    }
    result_value = control.value;
  } else {
    v4l2_control control{control_id, desired};
    if (IoctlLocked(VIDIOC_S_CTRL, &control) < 0) {
      HAL_LOGE("S_CTRL fails: %s", strerror(errno));
      return -ENODEV;
    }
    result_value = control.value;
  }

  // If the caller wants to know the result, pass it back.
  if (result != nullptr) {
    *result = result_value;
  }
  return 0;
}

const SupportedFormats V4L2Wrapper::GetSupportedFormats() {
  SupportedFormats formats;
  std::set<uint32_t> pixel_formats;
  int res = GetFormats(&pixel_formats);
  if (res) {
    HAL_LOGE("Failed to get device formats.");
    return formats;
  }

  arc::SupportedFormat supported_format;
  std::set<std::array<int32_t, 2>> frame_sizes;

  for (auto pixel_format : pixel_formats) {
    supported_format.fourcc = pixel_format;

    frame_sizes.clear();
    res = GetFormatFrameSizes(pixel_format, &frame_sizes);
    if (res) {
      HAL_LOGE("Failed to get frame sizes for format: 0x%x", pixel_format);
      continue;
    }
    for (auto frame_size : frame_sizes) {
      supported_format.width = frame_size[0];
      supported_format.height = frame_size[1];
      formats.push_back(supported_format);
    }
  }
  return formats;
}

int V4L2Wrapper::GetFormats(std::set<uint32_t>* v4l2_formats) {
  HAL_LOG_ENTER();

  v4l2_fmtdesc format_query;
  memset(&format_query, 0, sizeof(format_query));
  format_query.type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
  while (IoctlLocked(VIDIOC_ENUM_FMT, &format_query) >= 0) {
    // The capture nodes behind a media pipeline convert to many formats in
    // hardware, with their own plane layouts. Only YUYV is used: everything
    // else is converted from it in software, where the layouts are known.
    if (!pipeline_ || format_query.pixelformat == V4L2_PIX_FMT_YUYV) {
      v4l2_formats->insert(format_query.pixelformat);
    }
    ++format_query.index;
  }

  if (errno != EINVAL) {
    HAL_LOGE(
        "ENUM_FMT fails at index %d: %s", format_query.index, strerror(errno));
    return -ENODEV;
  }
  return 0;
}

int V4L2Wrapper::GetQualifiedFormats(std::vector<uint32_t>* v4l2_formats) {
  HAL_LOG_ENTER();
  if (!connected()) {
    HAL_LOGE(
        "Device is not connected, qualified formats may not have been set.");
    return -EINVAL;
  }
  v4l2_formats->clear();
  std::set<uint32_t> unique_fourccs;
  for (auto& format : qualified_formats_) {
    unique_fourccs.insert(format.fourcc);
  }
  v4l2_formats->assign(unique_fourccs.begin(), unique_fourccs.end());
  return 0;
}

int V4L2Wrapper::GetFormatFrameSizes(uint32_t v4l2_format,
                                     std::set<std::array<int32_t, 2>>* sizes) {
  if (pipeline_ && !pipeline_->frame_sizes().empty()) {
    // The capture node behind the media pipeline can't enumerate its sizes.
    for (const auto& size : pipeline_->frame_sizes()) {
      sizes->insert({{{static_cast<int32_t>(size.width),
                       static_cast<int32_t>(size.height)}}});
    }
    return 0;
  }

  v4l2_frmsizeenum size_query;
  memset(&size_query, 0, sizeof(size_query));
  size_query.pixel_format = v4l2_format;
  if (IoctlLocked(VIDIOC_ENUM_FRAMESIZES, &size_query) < 0) {
    HAL_LOGE("ENUM_FRAMESIZES failed: %s", strerror(errno));
    return -ENODEV;
  }
  if (size_query.type == V4L2_FRMSIZE_TYPE_DISCRETE) {
    // Discrete: enumerate all sizes using VIDIOC_ENUM_FRAMESIZES.
    // Assuming that a driver with discrete frame sizes has a reasonable number
    // of them.
    do {
      sizes->insert({{{static_cast<int32_t>(size_query.discrete.width),
                       static_cast<int32_t>(size_query.discrete.height)}}});
      ++size_query.index;
    } while (IoctlLocked(VIDIOC_ENUM_FRAMESIZES, &size_query) >= 0);
    if (errno != EINVAL) {
      HAL_LOGE("ENUM_FRAMESIZES fails at index %d: %s",
               size_query.index,
               strerror(errno));
      return -ENODEV;
    }
  } else {
    // Continuous/Step-wise: based on the stepwise struct returned by the query.
    // Fully listing all possible sizes, with large enough range/small enough
    // step size, may produce far too many potential sizes. Instead, find the
    // closest to a set of standard sizes.
    for (const auto size : kStandardSizes) {
      // Find the closest size, rounding up.
      uint32_t desired_width = size[0];
      uint32_t desired_height = size[1];
      if (desired_width < size_query.stepwise.min_width ||
          desired_height < size_query.stepwise.min_height) {
        HAL_LOGV("Standard size %u x %u is too small for format %d",
                 desired_width,
                 desired_height,
                 v4l2_format);
        continue;
      } else if (desired_width > size_query.stepwise.max_width ||
                 desired_height > size_query.stepwise.max_height) {
        HAL_LOGV("Standard size %u x %u is too big for format %d",
                 desired_width,
                 desired_height,
                 v4l2_format);
        continue;
      }

      // Round up.
      uint32_t width_steps = (desired_width - size_query.stepwise.min_width +
                              size_query.stepwise.step_width - 1) /
                             size_query.stepwise.step_width;
      uint32_t height_steps = (desired_height - size_query.stepwise.min_height +
                               size_query.stepwise.step_height - 1) /
                              size_query.stepwise.step_height;
      sizes->insert(
          {{{static_cast<int32_t>(size_query.stepwise.min_width +
                                  width_steps * size_query.stepwise.step_width),
             static_cast<int32_t>(size_query.stepwise.min_height +
                                  height_steps *
                                      size_query.stepwise.step_height)}}});
    }
  }
  return 0;
}

// Converts a v4l2_fract with units of seconds to an int64_t with units of ns.
inline int64_t FractToNs(const v4l2_fract& fract) {
  return (1000000000LL * fract.numerator) / fract.denominator;
}

int V4L2Wrapper::GetFormatFrameDurationRange(
    uint32_t v4l2_format,
    const std::array<int32_t, 2>& size,
    std::array<int64_t, 2>* duration_range) {
  // Potentially called so many times logging entry is a bad idea.

  if (pipeline_) {
    // The capture node behind the media pipeline can't enumerate intervals.
    (*duration_range)[0] = pipeline_->min_frame_duration_ns();
    (*duration_range)[1] = pipeline_->max_frame_duration_ns();
    return 0;
  }

  v4l2_frmivalenum duration_query;
  memset(&duration_query, 0, sizeof(duration_query));
  duration_query.pixel_format = v4l2_format;
  duration_query.width = size[0];
  duration_query.height = size[1];
  if (IoctlLocked(VIDIOC_ENUM_FRAMEINTERVALS, &duration_query) < 0) {
    HAL_LOGE("ENUM_FRAMEINTERVALS failed: %s", strerror(errno));
    return -ENODEV;
  }

  int64_t min = std::numeric_limits<int64_t>::max();
  int64_t max = std::numeric_limits<int64_t>::min();
  if (duration_query.type == V4L2_FRMSIZE_TYPE_DISCRETE) {
    // Discrete: enumerate all durations using VIDIOC_ENUM_FRAMEINTERVALS.
    do {
      min = std::min(min, FractToNs(duration_query.discrete));
      max = std::max(max, FractToNs(duration_query.discrete));
      ++duration_query.index;
    } while (IoctlLocked(VIDIOC_ENUM_FRAMEINTERVALS, &duration_query) >= 0);
    if (errno != EINVAL) {
      HAL_LOGE("ENUM_FRAMEINTERVALS fails at index %d: %s",
               duration_query.index,
               strerror(errno));
      return -ENODEV;
    }
  } else {
    // Continuous/Step-wise: simply convert the given min and max.
    min = FractToNs(duration_query.stepwise.min);
    max = FractToNs(duration_query.stepwise.max);
  }
  (*duration_range)[0] = min;
  (*duration_range)[1] = max;
  return 0;
}

int V4L2Wrapper::SetFormat(const StreamFormat& desired_format,
                           uint32_t* result_max_buffers) {
  HAL_LOG_ENTER();

  if (format_ && desired_format == *format_) {
    HAL_LOGV("Already in correct format, skipping format setting.");
    *result_max_buffers = buffers_.size();
    return 0;
  }

  if (format_) {
    // If we had an old format, first request 0 buffers to inform the device
    // we're no longer using any previously "allocated" buffers from the old
    // format. This seems like it shouldn't be necessary for USERPTR memory,
    // and/or should happen from turning the stream off, but the driver
    // complained. May be a driver issue, or may be intended behavior.
    int res = RequestBuffers(0);
    if (res) {
      return res;
    }
  }

  // Select the matching format, or if not available, select a qualified format
  // we can convert from.
  SupportedFormat format;
  if (!StreamFormat::FindBestFitFormat(supported_formats_, qualified_formats_,
                                       desired_format.v4l2_pixel_format(),
                                       desired_format.width(),
                                       desired_format.height(), &format)) {
    HAL_LOGE(
        "Unable to find supported resolution in list, "
        "width: %d, height: %d",
        desired_format.width(), desired_format.height());
    return -EINVAL;
  }

  // Set the camera to the new format.
  v4l2_format new_format;
  const StreamFormat resolved_format(format);
  resolved_format.FillFormatRequest(&new_format);

  // TODO(b/29334616): When async, this will need to check if the stream
  // is on, and if so, lock it off while setting format.
  if (IoctlLocked(VIDIOC_S_FMT, &new_format) < 0) {
    HAL_LOGE("S_FMT failed: %s", strerror(errno));
    return -ENODEV;
  }

  // Check that the driver actually set to the requested values.
  if (resolved_format != new_format) {
    HAL_LOGE("Device doesn't support desired stream configuration.");
    return -EINVAL;
  }

  // The conversions assume one plane, with rows not padded for YUYV.
  const StreamFormat set_format(new_format);
  if (set_format.num_planes() != 1 ||
      (set_format.v4l2_pixel_format() == V4L2_PIX_FMT_YUYV &&
       set_format.bytes_per_line() != set_format.width() * 2)) {
    HAL_LOGE("Unsupported plane layout: %u planes, %u bytes per line for %u px.",
             set_format.num_planes(),
             set_format.bytes_per_line(),
             set_format.width());
    return -EINVAL;
  }

  // Keep track of our new format.
  format_.reset(new StreamFormat(new_format));

  // Format changed, request new buffers.
  int res = RequestBuffers(kNumDeviceBuffers);
  if (res) {
    HAL_LOGE("Requesting buffers for new format failed.");
    return res;
  }
  *result_max_buffers = buffers_.size();
  return 0;
}

int V4L2Wrapper::RequestBuffers(uint32_t num_requested) {
  {
    // The device can't release buffers that are still mapped.
    std::lock_guard<std::mutex> guard(buffer_queue_lock_);
    UnmapBuffers();
    buffers_.clear();
  }

  v4l2_requestbuffers req_buffers;
  memset(&req_buffers, 0, sizeof(req_buffers));
  req_buffers.type = format_->type();
  req_buffers.memory = V4L2_MEMORY_MMAP;
  req_buffers.count = num_requested;

  int res = IoctlLocked(VIDIOC_REQBUFS, &req_buffers);
  // Calling REQBUFS releases all queued buffers back to the user.
  if (res < 0) {
    HAL_LOGE("REQBUFS failed: %s", strerror(errno));
    return -ENODEV;
  }

  // V4L2 will set req_buffers.count to a number of buffers it can handle.
  if (num_requested > 0 && req_buffers.count < 1) {
    HAL_LOGE("REQBUFS claims it can't handle any buffers.");
    return -ENODEV;
  }
  {
    std::lock_guard<std::mutex> guard(buffer_queue_lock_);
    buffers_.resize(req_buffers.count);
  }
  if (req_buffers.count > 0) {
    res = MapBuffers();
    if (res) {
      std::lock_guard<std::mutex> guard(buffer_queue_lock_);
      UnmapBuffers();
      buffers_.clear();
      return res;
    }
  }
  return 0;
}

int V4L2Wrapper::MapBuffers() {
  std::lock_guard<std::mutex> guard(buffer_queue_lock_);
  for (size_t i = 0; i < buffers_.size(); ++i) {
    v4l2_plane plane;
    memset(&plane, 0, sizeof(plane));
    v4l2_buffer device_buffer;
    memset(&device_buffer, 0, sizeof(device_buffer));
    device_buffer.type = format_->type();
    device_buffer.memory = V4L2_MEMORY_MMAP;
    device_buffer.index = i;
    device_buffer.m.planes = &plane;
    device_buffer.length = 1;  // Number of planes.
    if (IoctlLocked(VIDIOC_QUERYBUF, &device_buffer) < 0) {
      HAL_LOGE("QUERYBUF of buffer %zu fails: %s", i, strerror(errno));
      return -ENODEV;
    }

    void* addr = mmap(nullptr,
                      plane.length,
                      PROT_READ | PROT_WRITE,
                      MAP_SHARED,
                      device_fd_.get(),
                      plane.m.mem_offset);
    if (addr == MAP_FAILED) {
      HAL_LOGE("mmap of buffer %zu fails: %s", i, strerror(errno));
      return -ENOMEM;
    }
    buffers_[i].mapping = static_cast<uint8_t*>(addr);
    buffers_[i].mapping_length = plane.length;
  }
  return 0;
}

void V4L2Wrapper::UnmapBuffers() {
  for (auto& buffer : buffers_) {
    if (buffer.mapping) {
      munmap(buffer.mapping, buffer.mapping_length);
      buffer.mapping = nullptr;
      buffer.mapping_length = 0;
    }
  }
}

int V4L2Wrapper::QueueBufferLocked(uint32_t index) {
  v4l2_plane plane;
  memset(&plane, 0, sizeof(plane));
  v4l2_buffer device_buffer;
  memset(&device_buffer, 0, sizeof(device_buffer));
  device_buffer.type = format_->type();
  device_buffer.memory = V4L2_MEMORY_MMAP;
  device_buffer.index = index;
  device_buffer.m.planes = &plane;
  device_buffer.length = 1;  // Number of planes.
  if (IoctlLocked(VIDIOC_QBUF, &device_buffer) < 0) {
    HAL_LOGE("QBUF of buffer %u fails: %s", index, strerror(errno));
    return -ENODEV;
  }
  buffers_[index].active = true;
  return 0;
}

int V4L2Wrapper::QueueFreeBuffers() {
  std::lock_guard<std::mutex> guard(buffer_queue_lock_);
  for (size_t i = 0; i < buffers_.size(); ++i) {
    // Ask the device which buffers it holds instead of trusting |active|:
    // the dequeue thread may requeue the frame it was working on while the
    // stream was being turned off, which leaves the flag behind.
    v4l2_plane plane;
    memset(&plane, 0, sizeof(plane));
    v4l2_buffer device_buffer;
    memset(&device_buffer, 0, sizeof(device_buffer));
    device_buffer.type = format_->type();
    device_buffer.memory = V4L2_MEMORY_MMAP;
    device_buffer.index = i;
    device_buffer.m.planes = &plane;
    device_buffer.length = 1;  // Number of planes.
    if (IoctlLocked(VIDIOC_QUERYBUF, &device_buffer) < 0) {
      HAL_LOGE("QUERYBUF of buffer %zu fails: %s", i, strerror(errno));
      return -ENODEV;
    }
    if (device_buffer.flags & (V4L2_BUF_FLAG_QUEUED | V4L2_BUF_FLAG_DONE)) {
      buffers_[i].active = true;
      continue;
    }
    int res = QueueBufferLocked(i);
    if (res) {
      return res;
    }
  }
  return 0;
}

int V4L2Wrapper::EnqueueRequest(
    std::shared_ptr<default_camera_hal::CaptureRequest> request) {
  if (!format_) {
    HAL_LOGE("Stream format must be set before enqueuing buffers.");
    return -ENODEV;
  }

  std::lock_guard<std::mutex> pending_lock(pending_lock_);
  pending_requests_.push_back(std::move(request));
  return 0;
}

int V4L2Wrapper::DequeueRequest(std::shared_ptr<CaptureRequest>* request) {
  if (!format_) {
    HAL_LOGV(
        "Format not set, so stream can't be on, "
        "so no buffers available for dequeueing");
    return -EAGAIN;
  }
  if (!streaming_) {
    return -EAGAIN;
  }

  // Wait for a frame without holding |device_lock_|, so controls and
  // formats can still be set meanwhile.
  int fd;
  {
    std::lock_guard<std::mutex> lock(device_lock_);
    fd = device_fd_.get();
  }
  pollfd poll_fd = {fd, POLLIN, 0};
  int ready = TEMP_FAILURE_RETRY(poll(&poll_fd, 1, kDequeueTimeoutMs));
  if (ready <= 0 || !(poll_fd.revents & POLLIN)) {
    return -EAGAIN;
  }

  v4l2_plane plane;
  memset(&plane, 0, sizeof(plane));
  v4l2_buffer buffer;
  memset(&buffer, 0, sizeof(buffer));
  buffer.type = format_->type();
  buffer.memory = V4L2_MEMORY_MMAP;
  buffer.m.planes = &plane;
  buffer.length = 1;  // Number of planes.
  int res = IoctlLocked(VIDIOC_DQBUF, &buffer);
  if (res) {
    if (errno == EAGAIN) {
      // Expected failure.
      return -EAGAIN;
    } else {
      // Unexpected failure.
      HAL_LOGE("DQBUF fails: %s", strerror(errno));
      return -ENODEV;
    }
  }

  std::lock_guard<std::mutex> guard(buffer_queue_lock_);
  if (buffer.index >= buffers_.size()) {
    HAL_LOGE("DQBUF returned unknown buffer %u.", buffer.index);
    return -ENODEV;
  }
  RequestContext* request_context = &buffers_[buffer.index];
  request_context->active = false;

  // The oldest request waiting for a frame gets this one. Without one, the
  // frame is dropped and the buffer goes straight back to the device.
  std::shared_ptr<CaptureRequest> frame_request;
  {
    std::lock_guard<std::mutex> pending_lock(pending_lock_);
    if (!pending_requests_.empty()) {
      frame_request = pending_requests_.front();
      pending_requests_.pop_front();
    }
  }
  if (!frame_request) {
    QueueBufferLocked(buffer.index);
    return -EAGAIN;
  }

  // The frame as the device delivered it, in the buffer mapped from it.
  size_t frame_size = plane.bytesused ? plane.bytesused : plane.length;
  frame_size = std::min(frame_size, request_context->mapping_length);
  arc::MappedFrameBuffer camera_frame(request_context->mapping,
                                      request_context->mapping_length,
                                      frame_size,
                                      format_->width(),
                                      format_->height(),
                                      format_->v4l2_pixel_format());

  // Every output buffer of the request (one per stream) gets the frame, in the
  // format of its stream. The frame is converted to YU12 once, on demand, and
  // all the conversions and scalings start from that.
  arc::CachedFrame cached_frame;
  bool cached_frame_ready = false;
  for (camera3_stream_buffer_t& stream_buffer :
       frame_request->output_buffers) {
    uint32_t fourcc =
        StreamFormat::HalToV4L2PixelFormat(stream_buffer.stream->format);

    // Lock the camera stream buffer for painting.
    arc::GrallocFrameBuffer output_frame(
        *stream_buffer.buffer, stream_buffer.stream->width,
        stream_buffer.stream->height, fourcc, stream_buffer.stream->usage);
    if (output_frame.Map()) {
      HAL_LOGE("Failed to map output frame.");
      stream_buffer.status = CAMERA3_BUFFER_STATUS_ERROR;
      continue;
    }

    if (camera_frame.GetFourcc() == fourcc &&
        camera_frame.GetWidth() == stream_buffer.stream->width &&
        camera_frame.GetHeight() == stream_buffer.stream->height &&
        !output_frame.GetYCbCr()) {
      // If no format conversion needs to be applied, directly copy the data
      // over, row by row when the output rows are padded. (Buffers with plane
      // layouts of their own go through the conversion, which follows the
      // layout.)
      const size_t src_stride = format_->bytes_per_line();
      const size_t dst_stride = output_frame.GetStride();
      if (dst_stride == 0 || dst_stride == src_stride) {
        memcpy(output_frame.GetData(), camera_frame.GetData(),
               camera_frame.GetDataSize());
      } else {
        const size_t row_bytes = std::min(src_stride, dst_stride);
        for (uint32_t row = 0; row < camera_frame.GetHeight(); ++row) {
          memcpy(output_frame.GetData() + row * dst_stride,
                 camera_frame.GetData() + row * src_stride, row_bytes);
        }
      }
    } else {
      // Perform the format conversion.
      if (!cached_frame_ready) {
        cached_frame.SetSource(&camera_frame, 0);
        cached_frame_ready = true;
      }
      int res = cached_frame.Convert(frame_request->settings,
                                     &output_frame);
      if (res) {
        HAL_LOGE("Failed to convert the frame: %d", res);
        stream_buffer.status = CAMERA3_BUFFER_STATUS_ERROR;
      }
    }
    if (fourcc == V4L2_PIX_FMT_JPEG && output_frame.FinishJpeg()) {
      HAL_LOGE("Failed to finish the JPEG blob.");
      stream_buffer.status = CAMERA3_BUFFER_STATUS_ERROR;
    }
  }

  // The frame has been copied out; give the buffer back to the device.
  QueueBufferLocked(buffer.index);

  if (request) {
    *request = frame_request;
  }
  return 0;
}

int V4L2Wrapper::GetInFlightBufferCount() {
  std::lock_guard<std::mutex> pending_lock(pending_lock_);
  return pending_requests_.size();
}

}  // namespace v4l2_camera_hal
