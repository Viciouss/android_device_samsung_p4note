/*
 * Copyright (C) 2021 The Android Open Source Project
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

#define LOG_TAG "android.hardware.ir-service.p4note"

#include <aidl/android/hardware/ir/BnConsumerIr.h>
#include <aidl/android/hardware/ir/ConsumerIrFreqRange.h>
#include <android-base/file.h>
#include <android-base/logging.h>
#include <android-base/strings.h>
#include <android-base/unique_fd.h>
#include <android/binder_manager.h>
#include <android/binder_process.h>

#include <errno.h>
#include <fcntl.h>
#include <unistd.h>

#include <string>
#include <vector>

using ::aidl::android::hardware::ir::ConsumerIrFreqRange;

namespace {

// Exposed by drivers/misc/ir_remote_con_mc96.c (ABOV MC96FR).
constexpr char kIrSendPath[] = "/sys/class/sec/sec_ir/ir_send";
constexpr char kIrResultPath[] = "/sys/class/sec/sec_ir/ir_send_result";

// The driver takes "freq,pulse,pulse,..." with each pulse given in carrier
// cycles and sent to the chip as 16 bits. Its 2048 byte frame holds a 2 byte
// length, 3 bytes of frequency, 2 bytes per pulse and a 2 byte checksum.
constexpr int64_t kMaxPulseCycles = 0xffff;
constexpr size_t kMaxPulses = (2048 - 2 - 3 - 2) / 2;
// A sysfs store only ever sees one page.
constexpr size_t kMaxWriteLen = 4096 - 1;

constexpr int32_t kMinFreqHz = 30000;
constexpr int32_t kMaxFreqHz = 60000;

}  // namespace

namespace aidl::android::hardware::ir {

class ConsumerIr : public BnConsumerIr {
  private:
    ::ndk::ScopedAStatus getCarrierFreqs(std::vector<ConsumerIrFreqRange>* _aidl_return) override;
    ::ndk::ScopedAStatus transmit(int32_t in_carrierFreqHz,
                                  const std::vector<int32_t>& in_pattern) override;
};

::ndk::ScopedAStatus ConsumerIr::getCarrierFreqs(std::vector<ConsumerIrFreqRange>* _aidl_return) {
    ConsumerIrFreqRange range;
    range.minHz = kMinFreqHz;
    range.maxHz = kMaxFreqHz;
    *_aidl_return = {range};
    return ::ndk::ScopedAStatus::ok();
}

::ndk::ScopedAStatus ConsumerIr::transmit(int32_t in_carrierFreqHz,
                                          const std::vector<int32_t>& in_pattern) {
    if (in_carrierFreqHz < kMinFreqHz || in_carrierFreqHz > kMaxFreqHz) {
        return ::ndk::ScopedAStatus::fromExceptionCode(EX_UNSUPPORTED_OPERATION);
    }
    if (in_pattern.empty() || in_pattern.size() > kMaxPulses) {
        LOG(ERROR) << "unsupported pattern length " << in_pattern.size();
        return ::ndk::ScopedAStatus::fromExceptionCode(EX_ILLEGAL_ARGUMENT);
    }

    std::string cmd = std::to_string(in_carrierFreqHz) + ",";
    for (int32_t us : in_pattern) {
        if (us < 0) {
            return ::ndk::ScopedAStatus::fromExceptionCode(EX_ILLEGAL_ARGUMENT);
        }
        int64_t cycles = (static_cast<int64_t>(us) * in_carrierFreqHz + 500000) / 1000000;
        // a 0 terminates the pattern in the driver
        if (cycles < 1) cycles = 1;
        if (cycles > kMaxPulseCycles) {
            LOG(ERROR) << "pulse of " << us << "us too long at " << in_carrierFreqHz << "Hz";
            return ::ndk::ScopedAStatus::fromExceptionCode(EX_ILLEGAL_ARGUMENT);
        }
        cmd += std::to_string(cycles) + ",";
    }
    if (cmd.size() > kMaxWriteLen) {
        LOG(ERROR) << "pattern too long for sysfs (" << cmd.size() << " bytes)";
        return ::ndk::ScopedAStatus::fromExceptionCode(EX_ILLEGAL_ARGUMENT);
    }

    ::android::base::unique_fd fd(TEMP_FAILURE_RETRY(open(kIrSendPath, O_WRONLY | O_CLOEXEC)));
    if (fd < 0) {
        PLOG(ERROR) << "failed to open " << kIrSendPath;
        return ::ndk::ScopedAStatus::fromExceptionCode(EX_ILLEGAL_STATE);
    }

    // The driver blocks in the write until the chip has finished emitting.
    ssize_t ret = TEMP_FAILURE_RETRY(write(fd, cmd.data(), cmd.size()));
    if (ret != static_cast<ssize_t>(cmd.size())) {
        PLOG(ERROR) << "failed to write " << kIrSendPath;
        return ::ndk::ScopedAStatus::fromExceptionCode(EX_ILLEGAL_STATE);
    }

    std::string result;
    if (::android::base::ReadFileToString(kIrResultPath, &result) &&
        ::android::base::Trim(result) != "1") {
        LOG(WARNING) << "chip did not acknowledge the transmission";
    }

    return ::ndk::ScopedAStatus::ok();
}

}  // namespace aidl::android::hardware::ir

using aidl::android::hardware::ir::ConsumerIr;

int main() {
    auto binder = ::ndk::SharedRefBase::make<ConsumerIr>();
    const std::string name = std::string() + ConsumerIr::descriptor + "/default";
    CHECK_EQ(STATUS_OK, AServiceManager_addService(binder->asBinder().get(), name.c_str()))
            << "Failed to register " << name;

    ABinderProcess_setThreadPoolMaxThreadCount(0);
    ABinderProcess_joinThreadPool();

    return EXIT_FAILURE;  // should not be reached
}
