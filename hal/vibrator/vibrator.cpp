/*
 * SPDX-License-Identifier: Apache-2.0
 *
 * IVibrator on top of the ISA1200 force-feedback input device
 * (drivers/input/misc/isa1200.c). The kernel driver only knows on/off
 * rumble, so this HAL exposes on()/off() with completion callbacks and
 * leaves effects to the framework's fallback waveforms.
 */

#include <algorithm>
#include <chrono>
#include <condition_variable>
#include <mutex>
#include <string>
#include <thread>

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>

#include <linux/input.h>
#include <sys/ioctl.h>

#include <aidl/android/hardware/vibrator/BnVibrator.h>
#include <android-base/logging.h>
#include <android-base/unique_fd.h>
#include <android/binder_manager.h>
#include <android/binder_process.h>

using ::aidl::android::hardware::vibrator::BnVibrator;
using ::aidl::android::hardware::vibrator::Braking;
using ::aidl::android::hardware::vibrator::CompositeEffect;
using ::aidl::android::hardware::vibrator::CompositePrimitive;
using ::aidl::android::hardware::vibrator::Effect;
using ::aidl::android::hardware::vibrator::EffectStrength;
using ::aidl::android::hardware::vibrator::IVibrator;
using ::aidl::android::hardware::vibrator::IVibratorCallback;
using ::aidl::android::hardware::vibrator::PrimitivePwle;
using ::android::base::unique_fd;
using ::ndk::ScopedAStatus;
using ::ndk::SharedRefBase;

static const char* const INPUT_DIR = "/dev/input";
static const char* const FF_DEVICE_NAME = "isa1200-haptic";

static ScopedAStatus unsupported() {
    return ScopedAStatus::fromExceptionCode(EX_UNSUPPORTED_OPERATION);
}

static unique_fd open_ff_device() {
    std::unique_ptr<DIR, decltype(&closedir)> dir(opendir(INPUT_DIR), closedir);
    if (!dir) {
        PLOG(ERROR) << "opendir " << INPUT_DIR;
        return unique_fd();
    }

    struct dirent* entry;
    while ((entry = readdir(dir.get())) != nullptr) {
        if (strncmp(entry->d_name, "event", 5) != 0) continue;

        std::string path = std::string(INPUT_DIR) + "/" + entry->d_name;
        unique_fd fd(open(path.c_str(), O_RDWR | O_CLOEXEC));
        if (fd < 0) continue;

        char name[64] = {};
        if (ioctl(fd, EVIOCGNAME(sizeof(name) - 1), name) < 0) continue;
        if (strcmp(name, FF_DEVICE_NAME) != 0) continue;

        LOG(INFO) << "using " << path << " (" << name << ")";
        return fd;
    }

    LOG(ERROR) << "no input device named " << FF_DEVICE_NAME;
    return unique_fd();
}

class Vibrator : public BnVibrator {
  private:
    unique_fd mFd;
    int16_t mEffectId = -1;

    // Serialises FF ioctls and guards the completion bookkeeping below.
    std::mutex mLock;
    std::condition_variable mCancel;
    uint64_t mGeneration = 0;

    int play(bool on) {
        struct input_event ev = {};
        ev.type = EV_FF;
        ev.code = mEffectId;
        ev.value = on ? 1 : 0;
        return write(mFd, &ev, sizeof(ev)) == sizeof(ev) ? 0 : -errno;
    }

    // Uploads (or updates) a full-strength rumble for timeoutMs.
    // ff-memless stops it on its own after replay.length; 0 means forever.
    int upload(int32_t timeoutMs) {
        struct ff_effect effect = {};
        effect.type = FF_RUMBLE;
        effect.id = mEffectId;
        effect.u.rumble.strong_magnitude = 0xffff;
        effect.replay.length = timeoutMs > 0xffff ? 0 : timeoutMs;

        if (ioctl(mFd, EVIOCSFF, &effect) < 0) return -errno;
        mEffectId = effect.id;
        return 0;
    }

    void notifyWhenDone(uint64_t generation, int32_t timeoutMs,
                        const std::shared_ptr<IVibratorCallback>& callback) {
        std::thread([this, generation, timeoutMs, callback] {
            std::unique_lock<std::mutex> lock(mLock);
            auto deadline = std::chrono::steady_clock::now() +
                            std::chrono::milliseconds(timeoutMs);
            bool cancelled = mCancel.wait_until(lock, deadline, [&] {
                return mGeneration != generation;
            });
            lock.unlock();
            if (!cancelled) callback->onComplete();
        }).detach();
    }

  public:
    Vibrator() : mFd(open_ff_device()) {}

    ScopedAStatus getCapabilities(int32_t* _aidl_return) override {
        *_aidl_return = IVibrator::CAP_ON_CALLBACK;
        return ScopedAStatus::ok();
    }

    ScopedAStatus off() override {
        std::lock_guard<std::mutex> lock(mLock);
        mGeneration++;
        mCancel.notify_all();

        if (mFd < 0 || mEffectId < 0) return ScopedAStatus::ok();

        int ret = play(false);
        if (ret) {
            LOG(ERROR) << "stop failed: " << strerror(-ret);
            return ScopedAStatus::fromExceptionCode(EX_SERVICE_SPECIFIC);
        }
        return ScopedAStatus::ok();
    }

    ScopedAStatus on(int32_t timeoutMs,
                     const std::shared_ptr<IVibratorCallback>& callback) override {
        if (timeoutMs <= 0) return ScopedAStatus::fromExceptionCode(EX_ILLEGAL_ARGUMENT);

        uint64_t generation;
        {
            std::lock_guard<std::mutex> lock(mLock);
            mGeneration++;
            mCancel.notify_all();
            generation = mGeneration;

            if (mFd < 0) return ScopedAStatus::fromExceptionCode(EX_SERVICE_SPECIFIC);

            int ret = upload(timeoutMs);
            if (!ret) ret = play(true);
            if (ret) {
                LOG(ERROR) << "start failed: " << strerror(-ret);
                return ScopedAStatus::fromExceptionCode(EX_SERVICE_SPECIFIC);
            }
        }

        if (callback) notifyWhenDone(generation, timeoutMs, callback);
        return ScopedAStatus::ok();
    }

    ScopedAStatus perform(Effect, EffectStrength, const std::shared_ptr<IVibratorCallback>&,
                          int32_t*) override {
        return unsupported();
    }

    ScopedAStatus getSupportedEffects(std::vector<Effect>* _aidl_return) override {
        _aidl_return->clear();
        return ScopedAStatus::ok();
    }

    ScopedAStatus setAmplitude(float) override { return unsupported(); }
    ScopedAStatus setExternalControl(bool) override { return unsupported(); }
    ScopedAStatus getCompositionDelayMax(int32_t*) override { return unsupported(); }
    ScopedAStatus getCompositionSizeMax(int32_t*) override { return unsupported(); }

    ScopedAStatus getSupportedPrimitives(std::vector<CompositePrimitive>* _aidl_return) override {
        _aidl_return->clear();
        return ScopedAStatus::ok();
    }

    ScopedAStatus getPrimitiveDuration(CompositePrimitive, int32_t*) override {
        return unsupported();
    }

    ScopedAStatus compose(const std::vector<CompositeEffect>&,
                          const std::shared_ptr<IVibratorCallback>&) override {
        return unsupported();
    }

    ScopedAStatus getSupportedAlwaysOnEffects(std::vector<Effect>* _aidl_return) override {
        _aidl_return->clear();
        return ScopedAStatus::ok();
    }

    ScopedAStatus alwaysOnEnable(int32_t, Effect, EffectStrength) override {
        return unsupported();
    }
    ScopedAStatus alwaysOnDisable(int32_t) override { return unsupported(); }
    ScopedAStatus getResonantFrequency(float*) override { return unsupported(); }
    ScopedAStatus getQFactor(float*) override { return unsupported(); }
    ScopedAStatus getFrequencyResolution(float*) override { return unsupported(); }
    ScopedAStatus getFrequencyMinimum(float*) override { return unsupported(); }
    ScopedAStatus getBandwidthAmplitudeMap(std::vector<float>*) override { return unsupported(); }
    ScopedAStatus getPwlePrimitiveDurationMax(int32_t*) override { return unsupported(); }
    ScopedAStatus getPwleCompositionSizeMax(int32_t*) override { return unsupported(); }

    ScopedAStatus getSupportedBraking(std::vector<Braking>* _aidl_return) override {
        _aidl_return->clear();
        return ScopedAStatus::ok();
    }

    ScopedAStatus composePwle(const std::vector<PrimitivePwle>&,
                              const std::shared_ptr<IVibratorCallback>&) override {
        return unsupported();
    }
};

int main() {
    ABinderProcess_setThreadPoolMaxThreadCount(0);

    std::shared_ptr<Vibrator> vibrator = SharedRefBase::make<Vibrator>();

    const std::string instance = std::string() + Vibrator::descriptor + "/default";
    binder_status_t status =
            AServiceManager_addService(vibrator->asBinder().get(), instance.c_str());
    CHECK_EQ(status, STATUS_OK);

    ABinderProcess_joinThreadPool();
    return EXIT_FAILURE;  // should not reach
}
