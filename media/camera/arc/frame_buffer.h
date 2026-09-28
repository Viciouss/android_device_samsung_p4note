/* Copyright 2017 The Chromium OS Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE file.
 */

#ifndef HAL_USB_FRAME_BUFFER_H_
#define HAL_USB_FRAME_BUFFER_H_

#include <cstdint>
#include <memory>

#include <mutex>

#include <android-base/unique_fd.h>
#include <hardware/gralloc.h>

namespace arc {

class FrameBuffer {
 public:
  FrameBuffer();
  virtual ~FrameBuffer();

  // If mapped successfully, the address will be assigned to |data_| and return
  // 0. Otherwise, returns -EINVAL.
  virtual int Map() = 0;

  // Unmaps the mapped address. Returns 0 for success.
  virtual int Unmap() = 0;

  uint8_t* GetData() const { return data_; }
  size_t GetDataSize() const { return data_size_; }
  size_t GetBufferSize() const { return buffer_size_; }
  uint32_t GetWidth() const { return width_; }
  uint32_t GetHeight() const { return height_; }
  uint32_t GetFourcc() const { return fourcc_; }

  void SetFourcc(uint32_t fourcc) { fourcc_ = fourcc; }
  virtual int SetDataSize(size_t data_size);

  // Memory layout of buffers whose rows and planes aren't packed. Packed
  // buffers return nullptr / 0.
  //
  // For YUV 4:2:0 buffers, the plane pointers and strides (in bytes).
  virtual const android_ycbcr* GetYCbCr() const { return nullptr; }
  // For single plane buffers, the bytes per row.
  virtual size_t GetStride() const { return 0; }

 protected:
  uint8_t* data_;

  // The number of bytes used in the buffer.
  size_t data_size_;

  // The number of bytes allocated in the buffer.
  size_t buffer_size_;

  // Frame resolution.
  uint32_t width_;
  uint32_t height_;

  // This is V4L2_PIX_FMT_* in linux/videodev2.h.
  uint32_t fourcc_;
};

// AllocatedFrameBuffer is used for the buffer from hal malloc-ed. User should
// be aware to manage the memory.
class AllocatedFrameBuffer : public FrameBuffer {
 public:
  explicit AllocatedFrameBuffer(int buffer_size);
  explicit AllocatedFrameBuffer(uint8_t* buffer, int buffer_size);
  ~AllocatedFrameBuffer() override;

  // No-op for the two functions.
  int Map() override { return 0; }
  int Unmap() override { return 0; }

  void SetWidth(uint32_t width) { width_ = width; }
  void SetHeight(uint32_t height) { height_ = height; }
  int SetDataSize(size_t data_size) override;
  void Reset();

 private:
  std::unique_ptr<uint8_t[]> buffer_;
};

// MappedFrameBuffer wraps memory owned by someone else, like a device buffer
// that is mmap-ed. The memory has to outlive the object.
class MappedFrameBuffer : public FrameBuffer {
 public:
  MappedFrameBuffer(uint8_t* data, size_t buffer_size, size_t data_size,
                    uint32_t width, uint32_t height, uint32_t fourcc);
  ~MappedFrameBuffer() override;

  // No-op for the two functions.
  int Map() override { return 0; }
  int Unmap() override { return 0; }
};

// V4L2FrameBuffer is used for the buffer from V4L2CameraDevice. Maps the fd
// in constructor. Unmaps and closes the fd in destructor.
class V4L2FrameBuffer : public FrameBuffer {
 public:
  V4L2FrameBuffer(android::base::unique_fd fd, int buffer_size,
                  uint32_t width, uint32_t height, uint32_t fourcc);
  // Unmaps |data_| and closes |fd_|.
  ~V4L2FrameBuffer();

  int Map() override;
  int Unmap() override;
  int GetFd() const { return fd_.get(); }

 private:
  // File descriptor of V4L2 frame buffer.
  android::base::unique_fd fd_;

  bool is_mapped_;

  // Lock to guard |is_mapped_|.
  std::mutex lock_;
};

// GrallocFrameBuffer is used for the buffer from Android framework. Locks and
// unlocks the buffer through the graphics mapper (the buffer has to be
// imported already, which the camera provider does).
class GrallocFrameBuffer : public FrameBuffer {
 public:
  GrallocFrameBuffer(buffer_handle_t buffer, uint32_t width, uint32_t height,
                     uint32_t fourcc, uint32_t stream_usage);
  ~GrallocFrameBuffer();

  int Map() override;
  int Unmap() override;

  const android_ycbcr* GetYCbCr() const override {
    return has_ycbcr_ ? &ycbcr_ : nullptr;
  }
  size_t GetStride() const override { return stride_; }

  // For V4L2_PIX_FMT_JPEG buffers (camera3 BLOBs): append the transport header
  // the camera service uses to find the size of the JPEG in the buffer. Call
  // after the JPEG has been written and its size set with SetDataSize().
  int FinishJpeg();

 private:
  // The buffer to lock.
  buffer_handle_t buffer_;

  bool is_mapped_;

  // Layout of the locked buffer, for YUV 4:2:0 buffers.
  android_ycbcr ycbcr_;
  bool has_ycbcr_;

  // Bytes per row of the locked buffer, for single plane buffers.
  size_t stride_;

  // Size in bytes of the whole BLOB buffer, for JPEG.
  size_t blob_size_;

  // Lock to guard |is_mapped_|.
  std::mutex lock_;

  // Camera stream context.
  uint32_t stream_usage_;
};

}  // namespace arc

#endif  // HAL_USB_FRAME_BUFFER_H_
