/* Copyright 2017 The Chromium OS Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE file.
 */

#include "arc/frame_buffer.h"

#include <utility>

#include <HandleImporter.h>
#include <hardware/camera3.h>
#include <sync/sync.h>
#include <sys/mman.h>
#include <ui/GraphicBufferMapper.h>
#include <unistd.h>
#include "arc/common.h"
#include "arc/image_processor.h"

namespace arc {

FrameBuffer::FrameBuffer()
    : data_(nullptr),
      data_size_(0),
      buffer_size_(0),
      width_(0),
      height_(0),
      fourcc_(0) {}

FrameBuffer::~FrameBuffer() {}

int FrameBuffer::SetDataSize(size_t data_size) {
  if (data_size > buffer_size_) {
    LOGF(ERROR) << "Buffer overflow: Buffer only has " << buffer_size_
                << ", but data needs " << data_size;
    return -EINVAL;
  }
  data_size_ = data_size;
  return 0;
}

AllocatedFrameBuffer::AllocatedFrameBuffer(int buffer_size) {
  buffer_.reset(new uint8_t[buffer_size]);
  buffer_size_ = buffer_size;
  data_ = buffer_.get();
}

AllocatedFrameBuffer::AllocatedFrameBuffer(uint8_t* buffer, int buffer_size) {
  buffer_.reset(buffer);
  buffer_size_ = buffer_size;
  data_ = buffer_.get();
}

AllocatedFrameBuffer::~AllocatedFrameBuffer() {}

int AllocatedFrameBuffer::SetDataSize(size_t size) {
  if (size > buffer_size_) {
    buffer_.reset(new uint8_t[size]);
    buffer_size_ = size;
    data_ = buffer_.get();
  }
  data_size_ = size;
  return 0;
}

void AllocatedFrameBuffer::Reset() { memset(data_, 0, buffer_size_); }

MappedFrameBuffer::MappedFrameBuffer(uint8_t* data, size_t buffer_size,
                                     size_t data_size, uint32_t width,
                                     uint32_t height, uint32_t fourcc) {
  data_ = data;
  buffer_size_ = buffer_size;
  data_size_ = data_size;
  width_ = width;
  height_ = height;
  fourcc_ = fourcc;
}

MappedFrameBuffer::~MappedFrameBuffer() {}

V4L2FrameBuffer::V4L2FrameBuffer(android::base::unique_fd fd, int buffer_size,
                                 uint32_t width, uint32_t height,
                                 uint32_t fourcc)
    : fd_(std::move(fd)), is_mapped_(false) {
  buffer_size_ = buffer_size;
  width_ = width;
  height_ = height;
  fourcc_ = fourcc;
}

V4L2FrameBuffer::~V4L2FrameBuffer() {
  if (Unmap()) {
    LOGF(ERROR) << "Unmap failed";
  }
}

int V4L2FrameBuffer::Map() {
  std::lock_guard<std::mutex> l(lock_);
  if (is_mapped_) {
    LOGF(ERROR) << "The buffer is already mapped";
    return -EINVAL;
  }
  void* addr = mmap(NULL, buffer_size_, PROT_READ, MAP_SHARED, fd_.get(), 0);
  if (addr == MAP_FAILED) {
    LOGF(ERROR) << "mmap() failed: " << strerror(errno);
    return -EINVAL;
  }
  data_ = static_cast<uint8_t*>(addr);
  is_mapped_ = true;
  return 0;
}

int V4L2FrameBuffer::Unmap() {
  std::lock_guard<std::mutex> l(lock_);
  if (is_mapped_ && munmap(data_, buffer_size_)) {
    LOGF(ERROR) << "mummap() failed: " << strerror(errno);
    return -EINVAL;
  }
  is_mapped_ = false;
  return 0;
}

namespace {

using android::hardware::camera::common::helper::HandleImporter;

// All frame buffers share one importer, which does the locking through the
// graphics mapper HAL of the device.
HandleImporter& Importer() {
  static HandleImporter importer;
  return importer;
}

}  // namespace

GrallocFrameBuffer::GrallocFrameBuffer(buffer_handle_t buffer, uint32_t width,
                                       uint32_t height, uint32_t fourcc,
                                       uint32_t stream_usage)
    : buffer_(buffer),
      is_mapped_(false),
      has_ycbcr_(false),
      stride_(0),
      blob_size_(0),
      stream_usage_(stream_usage) {
  memset(&ycbcr_, 0, sizeof(ycbcr_));
  width_ = width;
  height_ = height;
  fourcc_ = fourcc;
}

GrallocFrameBuffer::~GrallocFrameBuffer() {
  if (Unmap()) {
    LOGF(ERROR) << "Unmap failed";
  }
}

int GrallocFrameBuffer::Map() {
  std::lock_guard<std::mutex> l(lock_);
  if (is_mapped_) {
    LOGF(ERROR) << "The buffer is already mapped";
    return -EINVAL;
  }

  HandleImporter& importer = Importer();
  const android::Rect region(width_, height_);
  void* addr = nullptr;
  switch (fourcc_) {
    case V4L2_PIX_FMT_YUV420:
    case V4L2_PIX_FMT_YVU420:
    case V4L2_PIX_FMT_NV21: {
      android_ycbcr layout =
          importer.lockYCbCr(buffer_, stream_usage_, region);
      if (!layout.y) {
        LOGF(ERROR) << "Failed to gralloc lock YCbCr buffer";
        return -EINVAL;
      }
      ycbcr_ = layout;
      has_ycbcr_ = true;
      addr = layout.y;
      break;
    }
    case V4L2_PIX_FMT_YUYV:
    case V4L2_PIX_FMT_BGR32:
    case V4L2_PIX_FMT_RGB32: {
      addr = importer.lock(buffer_, stream_usage_, region);
      if (!addr) {
        LOGF(ERROR) << "Failed to gralloc lock buffer";
        return -EINVAL;
      }
      uint32_t stride = 0;
      if (importer.getMonoPlanarStrideBytes(buffer_, &stride) == android::OK) {
        stride_ = stride;
      }
      break;
    }
    case V4L2_PIX_FMT_JPEG: {
      // A BLOB buffer is one row as wide as the buffer is large.
      uint64_t blob_size = 0;
      if (android::GraphicBufferMapper::get().getWidth(buffer_, &blob_size) !=
              android::OK ||
          blob_size <= sizeof(camera3_jpeg_blob_t)) {
        LOGF(ERROR) << "Failed to get the size of the BLOB buffer";
        return -EINVAL;
      }
      addr = importer.lock(buffer_, stream_usage_,
                           static_cast<size_t>(blob_size));
      if (!addr) {
        LOGF(ERROR) << "Failed to gralloc lock BLOB buffer";
        return -EINVAL;
      }
      blob_size_ = blob_size;
      break;
    }
    default:
      return -EINVAL;
  }

  data_ = static_cast<uint8_t*>(addr);
  if (fourcc_ == V4L2_PIX_FMT_YVU420 || fourcc_ == V4L2_PIX_FMT_YUV420 ||
      fourcc_ == V4L2_PIX_FMT_NV21 || fourcc_ == V4L2_PIX_FMT_RGB32 ||
      fourcc_ == V4L2_PIX_FMT_BGR32) {
    buffer_size_ = ImageProcessor::GetConvertedSize(fourcc_, width_, height_);
  } else if (fourcc_ == V4L2_PIX_FMT_YUYV) {
    buffer_size_ = (stride_ ? stride_ : width_ * 2) * height_;
  } else if (fourcc_ == V4L2_PIX_FMT_JPEG) {
    // What is left for the JPEG once the transport header is in place.
    buffer_size_ = blob_size_ - sizeof(camera3_jpeg_blob_t);
  }

  is_mapped_ = true;
  return 0;
}

int GrallocFrameBuffer::Unmap() {
  std::lock_guard<std::mutex> l(lock_);
  if (!is_mapped_) {
    return 0;
  }
  // The CPU access is done once unlock returns, the fence is only for the
  // release of any device writes.
  int release_fence = Importer().unlock(buffer_);
  if (release_fence >= 0) {
    sync_wait(release_fence, -1);
    close(release_fence);
  }
  is_mapped_ = false;
  has_ycbcr_ = false;
  return 0;
}

int GrallocFrameBuffer::FinishJpeg() {
  std::lock_guard<std::mutex> l(lock_);
  if (!is_mapped_ || fourcc_ != V4L2_PIX_FMT_JPEG ||
      data_size_ > blob_size_ - sizeof(camera3_jpeg_blob_t)) {
    return -EINVAL;
  }
  camera3_jpeg_blob_t header;
  memset(&header, 0, sizeof(header));
  header.jpeg_blob_id = CAMERA3_JPEG_BLOB_ID;
  header.jpeg_size = data_size_;
  memcpy(data_ + blob_size_ - sizeof(header), &header, sizeof(header));
  return 0;
}

}  // namespace arc
