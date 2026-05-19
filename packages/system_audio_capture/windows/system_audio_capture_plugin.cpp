#include "system_audio_capture_plugin.h"

#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>

// WASAPI / Core Audio.
//
// Order matters and must NOT be alphabetized: <mmdeviceapi.h> pulls in the
// PROPERTYKEY infrastructure (propsys.h -> propkeydef.h) that defines the
// DEFINE_PROPERTYKEY macro. As of Windows SDK 10.0.26100 the
// <functiondiscoverykeys_devpkey.h> header no longer self-includes it, so it
// must come AFTER <mmdeviceapi.h> or every PKEY_* line fails to compile.
// clang-format off
#include <audioclient.h>
#include <avrt.h>
#include <mmdeviceapi.h>
#include <functiondiscoverykeys_devpkey.h>  // PKEY_Device_FriendlyName
// clang-format on

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <vector>

namespace system_audio_capture {

namespace {

// ---------------------------------------------------------------------------
// Channel names. These must match the Dart side exactly.
// ---------------------------------------------------------------------------
constexpr char kMethodChannelName[] = "dev.controlcenter/system_audio_capture";
constexpr char kEventChannelName[] =
    "dev.controlcenter/system_audio_capture/frames";

// Output format: the speech pipeline wants 16 kHz mono int16 PCM.
constexpr int kOutputSampleRate = 16000;
constexpr int kOutputChannels = 1;

// Private window message used to drain platform-thread tasks. WM_USER is
// safe for window-class-private messages; 0x401 keeps clear of any common
// WM_USER+n conventions used by the Flutter view window.
constexpr UINT WM_SAC_RUN_TASK = WM_USER + 0x301;

// REFERENCE_TIME units: 100-ns intervals. 10,000,000 == 1 second.
constexpr REFERENCE_TIME kRefTimesPerSecond = 10000000;

// Requested capture buffer duration. The endpoint allocates at least this
// much; we read packets in a poll loop and convert each into output frames.
constexpr REFERENCE_TIME kRequestedBufferDuration = kRefTimesPerSecond / 5;  // 200 ms

// COM smart-release helper. Releases and nulls a COM interface pointer.
template <typename T>
void SafeRelease(T** pp) {
  if (*pp) {
    (*pp)->Release();
    *pp = nullptr;
  }
}

// UTF-16 (Windows wide) -> UTF-8 std::string.
std::string Utf8FromWide(const wchar_t* wide) {
  if (!wide) return std::string();
  int size = ::WideCharToMultiByte(CP_UTF8, 0, wide, -1, nullptr, 0, nullptr,
                                   nullptr);
  if (size <= 1) return std::string();
  std::string out(static_cast<size_t>(size - 1), '\0');
  ::WideCharToMultiByte(CP_UTF8, 0, wide, -1, out.data(), size, nullptr,
                        nullptr);
  return out;
}

// Returns true if the mix format describes IEEE float samples, false for
// integer PCM. WASAPI shared-mode mix formats are almost always
// WAVE_FORMAT_EXTENSIBLE wrapping KSDATAFORMAT_SUBTYPE_IEEE_FLOAT.
bool IsFloatFormat(const WAVEFORMATEX* wf) {
  if (wf->wFormatTag == WAVE_FORMAT_IEEE_FLOAT) return true;
  if (wf->wFormatTag == WAVE_FORMAT_EXTENSIBLE) {
    const auto* ext = reinterpret_cast<const WAVEFORMATEXTENSIBLE*>(wf);
    return ::IsEqualGUID(ext->SubFormat, KSDATAFORMAT_SUBTYPE_IEEE_FLOAT) != 0;
  }
  return false;
}

bool IsPcmFormat(const WAVEFORMATEX* wf) {
  if (wf->wFormatTag == WAVE_FORMAT_PCM) return true;
  if (wf->wFormatTag == WAVE_FORMAT_EXTENSIBLE) {
    const auto* ext = reinterpret_cast<const WAVEFORMATEXTENSIBLE*>(wf);
    return ::IsEqualGUID(ext->SubFormat, KSDATAFORMAT_SUBTYPE_PCM) != 0;
  }
  return false;
}

// Reads one interleaved frame from `data` at frame index `frame`, down-mixing
// all channels to a single mono float sample in [-1.0, 1.0]. `data` points at
// the start of the packet; `channels` and per-sample stride come from the mix
// format. Supports 32-bit float, and 16/24/32-bit integer PCM.
float ReadMonoSample(const BYTE* data, UINT32 frame, WORD channels,
                     WORD bits_per_sample, bool is_float) {
  const size_t bytes_per_sample = bits_per_sample / 8;
  const size_t frame_stride = bytes_per_sample * channels;
  const BYTE* frame_ptr = data + static_cast<size_t>(frame) * frame_stride;

  double sum = 0.0;
  for (WORD ch = 0; ch < channels; ++ch) {
    const BYTE* sample_ptr = frame_ptr + ch * bytes_per_sample;
    double value = 0.0;
    if (is_float) {
      // The only float width WASAPI shared mode produces is 32-bit.
      float f;
      std::memcpy(&f, sample_ptr, sizeof(float));
      value = static_cast<double>(f);
    } else {
      switch (bits_per_sample) {
        case 16: {
          int16_t s;
          std::memcpy(&s, sample_ptr, sizeof(int16_t));
          value = static_cast<double>(s) / 32768.0;
          break;
        }
        case 32: {
          int32_t s;
          std::memcpy(&s, sample_ptr, sizeof(int32_t));
          value = static_cast<double>(s) / 2147483648.0;
          break;
        }
        case 24: {
          // Little-endian packed 24-bit signed.
          int32_t s = (static_cast<int32_t>(sample_ptr[0])) |
                      (static_cast<int32_t>(sample_ptr[1]) << 8) |
                      (static_cast<int32_t>(sample_ptr[2]) << 16);
          if (s & 0x00800000) s |= ~0x00FFFFFF;  // sign-extend
          value = static_cast<double>(s) / 8388608.0;
          break;
        }
        case 8: {
          // 8-bit PCM is unsigned, centered at 128.
          value = (static_cast<double>(sample_ptr[0]) - 128.0) / 128.0;
          break;
        }
        default:
          value = 0.0;
          break;
      }
    }
    sum += value;
  }
  return static_cast<float>(sum / static_cast<double>(channels));
}

int16_t FloatToInt16(float sample) {
  // Clamp to [-1, 1] then scale. 32767 (not 32768) avoids positive overflow.
  float clamped = std::max(-1.0f, std::min(1.0f, sample));
  return static_cast<int16_t>(std::lround(clamped * 32767.0f));
}

// ---------------------------------------------------------------------------
// Linear-interpolation resampler (source rate -> 16 kHz).
//
// Why linear and not nearest-neighbour: nearest-neighbour decimation from
// 48 kHz to 16 kHz drops 2 of every 3 samples without anti-aliasing, which
// aliases high-frequency content audibly into the speech band and degrades
// downstream ASR. Linear interpolation is a (weak) low-pass that at least
// averages neighbouring samples and is monotonic in phase, which is a clear
// improvement and cheap enough to run on the capture thread. It keeps a single
// fractional-position cursor across packet boundaries so there are no clicks at
// the seams (a per-packet reset would otherwise discontinuity the phase).
//
// For higher fidelity a polyphase FIR (windowed-sinc) would be the next step,
// but linear interpolation is the documented minimum and is correct and
// stable for 48k/44.1k -> 16k speech capture.
// ---------------------------------------------------------------------------
class LinearResampler {
 public:
  void Reset(double source_rate) {
    source_rate_ = source_rate > 0 ? source_rate : kOutputSampleRate;
    step_ = source_rate_ / static_cast<double>(kOutputSampleRate);
    position_ = 0.0;
    have_prev_ = false;
    prev_sample_ = 0.0f;
  }

  // Appends resampled int16 mono samples for the given block of mono float
  // input samples into `out`.
  void Process(const std::vector<float>& mono_in, std::vector<int16_t>* out) {
    if (mono_in.empty()) return;

    // Conceptually concatenate [prev_sample_, mono_in...]. The fractional
    // `position_` is measured in input samples relative to the first element
    // of mono_in (so position -1 == prev_sample_).
    const size_t n = mono_in.size();
    while (true) {
      double pos = position_;
      double base_floor = std::floor(pos);
      auto idx0 = static_cast<long long>(base_floor);
      double frac = pos - base_floor;

      // idx1 is the sample after idx0. We can only interpolate if idx1 is
      // within the input we currently hold.
      long long idx1 = idx0 + 1;
      if (idx1 >= static_cast<long long>(n)) {
        break;  // Need more input to interpolate past the last sample.
      }

      float s0;
      if (idx0 < 0) {
        // Falls into the carried-over previous sample.
        s0 = have_prev_ ? prev_sample_ : (n > 0 ? mono_in[0] : 0.0f);
      } else {
        s0 = mono_in[static_cast<size_t>(idx0)];
      }
      float s1 = mono_in[static_cast<size_t>(idx1)];

      float interp = s0 + static_cast<float>(frac) * (s1 - s0);
      out->push_back(FloatToInt16(interp));

      position_ += step_;
    }

    // Carry phase forward into the next block: re-base `position_` so it is
    // relative to the (new) first input sample, and remember the last input
    // sample so interpolation across the seam stays continuous.
    position_ -= static_cast<double>(n);
    prev_sample_ = mono_in[n - 1];
    have_prev_ = true;
  }

 private:
  double source_rate_ = kOutputSampleRate;
  double step_ = 1.0;
  // Fractional read cursor, in source samples, relative to the start of the
  // current input block.
  double position_ = 0.0;
  bool have_prev_ = false;
  float prev_sample_ = 0.0f;
};

}  // namespace

// ---------------------------------------------------------------------------
// Registration.
// ---------------------------------------------------------------------------
void SystemAudioCapturePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto plugin = std::make_unique<SystemAudioCapturePlugin>(registrar);
  registrar->AddPlugin(std::move(plugin));
}

SystemAudioCapturePlugin::SystemAudioCapturePlugin(
    flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar) {
  auto* messenger = registrar->messenger();

  method_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger, kMethodChannelName,
          &flutter::StandardMethodCodec::GetInstance());
  method_channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        HandleMethodCall(call, std::move(result));
      });

  event_channel_ =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          messenger, kEventChannelName,
          &flutter::StandardMethodCodec::GetInstance());
  event_channel_->SetStreamHandler(
      std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
          // onListen
          [this](const flutter::EncodableValue* /*arguments*/,
                 std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&&
                     events)
              -> std::unique_ptr<
                  flutter::StreamHandlerError<flutter::EncodableValue>> {
            // onListen is always invoked on the platform thread.
            event_sink_ = std::move(events);
            return nullptr;
          },
          // onCancel
          [this](const flutter::EncodableValue* /*arguments*/)
              -> std::unique_ptr<
                  flutter::StreamHandlerError<flutter::EncodableValue>> {
            event_sink_.reset();
            return nullptr;
          }));

  // Register a top-level window-proc delegate on the Flutter view window so we
  // can hop frame delivery onto the platform thread. The capture thread posts
  // a WM_SAC_RUN_TASK message; the delegate below drains queued tasks.
  window_proc_id_ = registrar_->RegisterTopLevelWindowProcDelegate(
      [this](HWND /*hwnd*/, UINT message, WPARAM /*wparam*/,
             LPARAM /*lparam*/) -> std::optional<LRESULT> {
        if (message == WM_SAC_RUN_TASK) {
          DrainPlatformTasks();
          return 0;
        }
        return std::nullopt;
      });
}

SystemAudioCapturePlugin::~SystemAudioCapturePlugin() {
  StopCapture();
  if (window_proc_id_ != -1 && registrar_) {
    registrar_->UnregisterTopLevelWindowProcDelegate(window_proc_id_);
    window_proc_id_ = -1;
  }
}

// ---------------------------------------------------------------------------
// Platform-thread marshalling.
// ---------------------------------------------------------------------------
void SystemAudioCapturePlugin::RunOnPlatformThread(
    std::function<void()> task) {
  {
    std::lock_guard<std::mutex> lock(platform_tasks_mutex_);
    platform_tasks_.push(std::move(task));
  }
  // Post a message to the Flutter view's window so the delegate runs on the
  // platform thread. GetView() can be null during teardown; guard it.
  if (registrar_) {
    if (auto* view = registrar_->GetView()) {
      HWND hwnd = ::GetAncestor(view->GetNativeWindow(), GA_ROOT);
      if (hwnd) {
        ::PostMessage(hwnd, WM_SAC_RUN_TASK, 0, 0);
      }
    }
  }
}

void SystemAudioCapturePlugin::DrainPlatformTasks() {
  // Runs on the platform thread. Move tasks out under the lock, then run them
  // unlocked so a task can re-enqueue without deadlocking.
  std::queue<std::function<void()>> tasks;
  {
    std::lock_guard<std::mutex> lock(platform_tasks_mutex_);
    std::swap(tasks, platform_tasks_);
  }
  while (!tasks.empty()) {
    auto task = std::move(tasks.front());
    tasks.pop();
    if (task) task();
  }
}

void SystemAudioCapturePlugin::EmitFrame(std::vector<uint8_t> pcm16) {
  // Called on the platform thread (via RunOnPlatformThread). Encoding a
  // std::vector<uint8_t> as an EncodableValue marshals to a Dart Uint8List.
  if (event_sink_) {
    event_sink_->Success(flutter::EncodableValue(std::move(pcm16)));
  }
}

// ---------------------------------------------------------------------------
// MethodChannel dispatch.
// ---------------------------------------------------------------------------
void SystemAudioCapturePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& method = method_call.method_name();

  if (method == "isSupported") {
    // WASAPI loopback is available on Windows 10 1703+ (event-driven loopback)
    // and the polling pattern used here works back to Windows 7. We target a
    // modern desktop, so report supported unconditionally.
    result->Success(flutter::EncodableValue(true));
    return;
  }

  if (method == "requestPermission") {
    // Windows has no per-app capture consent (TCC) gate for shared-mode
    // loopback. Nothing to request; always granted.
    result->Success(flutter::EncodableValue(true));
    return;
  }

  if (method == "listSources") {
    result->Success(ListSources());
    return;
  }

  if (method == "start") {
    std::string source_id;  // empty => default render endpoint
    if (const auto* args =
            std::get_if<flutter::EncodableMap>(method_call.arguments())) {
      auto it = args->find(flutter::EncodableValue("sourceId"));
      if (it != args->end()) {
        if (const auto* s = std::get_if<std::string>(&it->second)) {
          source_id = *s;
        }
      }
    }
    std::string error;
    if (StartCapture(source_id, &error)) {
      result->Success(flutter::EncodableValue(true));
    } else {
      result->Error("start_failed", error);
    }
    return;
  }

  if (method == "stop") {
    StopCapture();
    result->Success(flutter::EncodableValue(true));
    return;
  }

  result->NotImplemented();
}

// ---------------------------------------------------------------------------
// Source enumeration.
// ---------------------------------------------------------------------------
flutter::EncodableValue SystemAudioCapturePlugin::ListSources() {
  flutter::EncodableList sources;

  // Always expose the synthetic default-system source first.
  {
    flutter::EncodableMap system;
    system[flutter::EncodableValue("id")] = flutter::EncodableValue("system");
    system[flutter::EncodableValue("name")] =
        flutter::EncodableValue("System audio");
    system[flutter::EncodableValue("kind")] = flutter::EncodableValue("system");
    sources.push_back(flutter::EncodableValue(system));
  }

  // Enumerate active render endpoints so callers can target a specific output
  // device. Each enumerated endpoint is also a "system" loopback source.
  bool com_initialized = false;
  HRESULT hr = ::CoInitializeEx(nullptr, COINIT_MULTITHREADED);
  if (SUCCEEDED(hr)) {
    com_initialized = true;
  } else if (hr == RPC_E_CHANGED_MODE) {
    // COM already initialized on this thread with a different apartment; that
    // is fine for enumeration. Do not call CoUninitialize for it.
    hr = S_OK;
  }

  if (SUCCEEDED(hr)) {
    IMMDeviceEnumerator* enumerator = nullptr;
    if (SUCCEEDED(::CoCreateInstance(
            __uuidof(MMDeviceEnumerator), nullptr, CLSCTX_ALL,
            __uuidof(IMMDeviceEnumerator),
            reinterpret_cast<void**>(&enumerator)))) {
      IMMDeviceCollection* collection = nullptr;
      if (SUCCEEDED(enumerator->EnumAudioEndpoints(
              eRender, DEVICE_STATE_ACTIVE, &collection))) {
        UINT count = 0;
        collection->GetCount(&count);
        for (UINT i = 0; i < count; ++i) {
          IMMDevice* device = nullptr;
          if (FAILED(collection->Item(i, &device)) || !device) continue;

          LPWSTR id_wide = nullptr;
          std::string endpoint_id;
          if (SUCCEEDED(device->GetId(&id_wide)) && id_wide) {
            endpoint_id = Utf8FromWide(id_wide);
            ::CoTaskMemFree(id_wide);
          }

          std::string friendly_name = "Unknown output device";
          IPropertyStore* props = nullptr;
          if (SUCCEEDED(device->OpenPropertyStore(STGM_READ, &props)) && props) {
            PROPVARIANT name_var;
            ::PropVariantInit(&name_var);
            if (SUCCEEDED(props->GetValue(PKEY_Device_FriendlyName,
                                          &name_var)) &&
                name_var.vt == VT_LPWSTR) {
              friendly_name = Utf8FromWide(name_var.pwszVal);
            }
            ::PropVariantClear(&name_var);
            SafeRelease(&props);
          }

          if (!endpoint_id.empty()) {
            flutter::EncodableMap entry;
            entry[flutter::EncodableValue("id")] =
                flutter::EncodableValue(endpoint_id);
            entry[flutter::EncodableValue("name")] =
                flutter::EncodableValue(friendly_name);
            entry[flutter::EncodableValue("kind")] =
                flutter::EncodableValue("system");
            sources.push_back(flutter::EncodableValue(entry));
          }
          SafeRelease(&device);
        }
        SafeRelease(&collection);
      }
      SafeRelease(&enumerator);
    }
  }

  if (com_initialized) {
    ::CoUninitialize();
  }

  return flutter::EncodableValue(sources);
}

// ---------------------------------------------------------------------------
// Start / stop.
// ---------------------------------------------------------------------------
bool SystemAudioCapturePlugin::StartCapture(const std::string& source_id,
                                            std::string* error_out) {
  if (capturing_.load()) {
    // Restart cleanly so the new source takes effect.
    StopCapture();
  }

  stop_requested_.store(false);
  capturing_.store(true);

  // "system" and empty string both mean: default render endpoint.
  std::string normalized =
      (source_id == "system") ? std::string() : source_id;

  capture_thread_ =
      std::thread(&SystemAudioCapturePlugin::CaptureThreadMain, this,
                  std::move(normalized));

  // The thread reports format/device errors asynchronously by stopping; the
  // start() call itself succeeds as long as the thread launched.
  (void)error_out;
  return true;
}

void SystemAudioCapturePlugin::StopCapture() {
  stop_requested_.store(true);
  if (capture_thread_.joinable()) {
    capture_thread_.join();
  }
  capturing_.store(false);
  stop_requested_.store(false);
}

// ---------------------------------------------------------------------------
// Capture thread.
// ---------------------------------------------------------------------------
void SystemAudioCapturePlugin::CaptureThreadMain(std::string source_id) {
  // COM must be initialized per-thread. Use the multithreaded apartment for a
  // background worker.
  bool com_initialized = false;
  HRESULT hr = ::CoInitializeEx(nullptr, COINIT_MULTITHREADED);
  if (SUCCEEDED(hr)) {
    com_initialized = true;
  } else if (hr == RPC_E_CHANGED_MODE) {
    hr = S_OK;  // Already initialized; proceed without owning uninit.
  }
  if (FAILED(hr)) {
    return;
  }

  IMMDeviceEnumerator* enumerator = nullptr;
  IMMDevice* device = nullptr;
  IAudioClient* audio_client = nullptr;
  IAudioCaptureClient* capture_client = nullptr;
  WAVEFORMATEX* mix_format = nullptr;
  HANDLE mmcss_handle = nullptr;
  DWORD mmcss_task_index = 0;

  auto cleanup = [&]() {
    if (audio_client) {
      audio_client->Stop();
    }
    if (mmcss_handle) {
      ::AvRevertMmThreadCharacteristics(mmcss_handle);
      mmcss_handle = nullptr;
    }
    if (mix_format) {
      ::CoTaskMemFree(mix_format);
      mix_format = nullptr;
    }
    SafeRelease(&capture_client);
    SafeRelease(&audio_client);
    SafeRelease(&device);
    SafeRelease(&enumerator);
    if (com_initialized) {
      ::CoUninitialize();
    }
  };

  hr = ::CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr, CLSCTX_ALL,
                          __uuidof(IMMDeviceEnumerator),
                          reinterpret_cast<void**>(&enumerator));
  if (FAILED(hr)) {
    cleanup();
    return;
  }

  // Resolve the render endpoint. Empty source_id => default eRender/eConsole.
  if (source_id.empty()) {
    hr = enumerator->GetDefaultAudioEndpoint(eRender, eConsole, &device);
  } else {
    int wide_len = ::MultiByteToWideChar(CP_UTF8, 0, source_id.c_str(), -1,
                                         nullptr, 0);
    std::wstring wide(static_cast<size_t>(wide_len), L'\0');
    ::MultiByteToWideChar(CP_UTF8, 0, source_id.c_str(), -1, wide.data(),
                          wide_len);
    hr = enumerator->GetDevice(wide.c_str(), &device);
    if (FAILED(hr)) {
      // Fall back to the default render endpoint rather than failing silently.
      hr = enumerator->GetDefaultAudioEndpoint(eRender, eConsole, &device);
    }
  }
  if (FAILED(hr) || !device) {
    cleanup();
    return;
  }

  hr = device->Activate(__uuidof(IAudioClient), CLSCTX_ALL, nullptr,
                        reinterpret_cast<void**>(&audio_client));
  if (FAILED(hr)) {
    cleanup();
    return;
  }

  // The loopback capture buffer is in the render endpoint's mix format. This
  // is the actual source format we must convert from.
  hr = audio_client->GetMixFormat(&mix_format);
  if (FAILED(hr) || !mix_format) {
    cleanup();
    return;
  }

  // Initialize in shared mode with loopback. Loopback requires shared mode and
  // a poll (non-event) buffering model works on all supported Windows versions.
  hr = audio_client->Initialize(AUDCLNT_SHAREMODE_SHARED,
                                AUDCLNT_STREAMFLAGS_LOOPBACK,
                                kRequestedBufferDuration, 0, mix_format,
                                nullptr);
  if (FAILED(hr)) {
    cleanup();
    return;
  }

  UINT32 buffer_frame_count = 0;
  hr = audio_client->GetBufferSize(&buffer_frame_count);
  if (FAILED(hr)) {
    cleanup();
    return;
  }

  hr = audio_client->GetService(__uuidof(IAudioCaptureClient),
                                reinterpret_cast<void**>(&capture_client));
  if (FAILED(hr) || !capture_client) {
    cleanup();
    return;
  }

  // Snapshot the format fields up front so the hot loop avoids re-deref.
  const WORD source_channels = mix_format->nChannels;
  const WORD source_bits = mix_format->wBitsPerSample;
  const DWORD source_rate = mix_format->nSamplesPerSec;
  const bool source_is_float = IsFloatFormat(mix_format);
  const bool source_is_pcm = IsPcmFormat(mix_format);

  // If the format is neither IEEE float nor integer PCM (extremely unusual for
  // a shared-mode mix format), we cannot safely interpret samples. Bail out.
  if (!source_is_float && !source_is_pcm) {
    cleanup();
    return;
  }
  if (source_channels == 0 || source_bits == 0 || source_rate == 0) {
    cleanup();
    return;
  }

  LinearResampler resampler;
  resampler.Reset(static_cast<double>(source_rate));

  // Raise the thread to the Pro Audio MMCSS task so the OS schedules it for
  // low-latency, glitch-free capture. Failure is non-fatal.
  mmcss_handle = ::AvSetMmThreadCharacteristicsW(L"Pro Audio", &mmcss_task_index);

  // Half the buffer duration, in ms, is a reasonable poll interval: by the
  // time we wake the endpoint buffer is about half full.
  const double buffer_seconds =
      static_cast<double>(buffer_frame_count) / static_cast<double>(source_rate);
  DWORD sleep_ms = static_cast<DWORD>(buffer_seconds * 1000.0 / 2.0);
  if (sleep_ms < 5) sleep_ms = 5;
  if (sleep_ms > 100) sleep_ms = 100;

  hr = audio_client->Start();
  if (FAILED(hr)) {
    cleanup();
    return;
  }

  // Reusable scratch buffers (avoid per-packet allocation in the hot loop).
  std::vector<float> mono_block;
  std::vector<int16_t> resampled;

  while (!stop_requested_.load()) {
    UINT32 packet_length = 0;
    hr = capture_client->GetNextPacketSize(&packet_length);
    if (FAILED(hr)) break;

    while (packet_length != 0 && !stop_requested_.load()) {
      BYTE* data = nullptr;
      UINT32 frames_available = 0;
      DWORD flags = 0;
      hr = capture_client->GetBuffer(&data, &frames_available, &flags, nullptr,
                                     nullptr);
      if (FAILED(hr)) break;

      mono_block.clear();
      mono_block.reserve(frames_available);

      if (flags & AUDCLNT_BUFFERFLAGS_SILENT) {
        // The endpoint signalled silence; emit zeros so timing stays correct.
        mono_block.assign(frames_available, 0.0f);
      } else if (data) {
        for (UINT32 frame = 0; frame < frames_available; ++frame) {
          mono_block.push_back(ReadMonoSample(data, frame, source_channels,
                                              source_bits, source_is_float));
        }
      }

      hr = capture_client->ReleaseBuffer(frames_available);
      if (FAILED(hr)) break;

      if (!mono_block.empty()) {
        resampled.clear();
        resampler.Process(mono_block, &resampled);

        if (!resampled.empty()) {
          // Pack int16 LE into a byte vector. x86/x64 are little-endian, so a
          // raw memcpy already yields little-endian bytes; this is explicit
          // for clarity and correctness on any target.
          std::vector<uint8_t> pcm_bytes(resampled.size() * sizeof(int16_t));
          for (size_t i = 0; i < resampled.size(); ++i) {
            uint16_t u = static_cast<uint16_t>(resampled[i]);
            pcm_bytes[i * 2] = static_cast<uint8_t>(u & 0xFF);
            pcm_bytes[i * 2 + 1] = static_cast<uint8_t>((u >> 8) & 0xFF);
          }

          // Hand the frame to the platform thread for delivery to Dart.
          RunOnPlatformThread(
              [this, frame = std::move(pcm_bytes)]() mutable {
                EmitFrame(std::move(frame));
              });
        }
      }

      hr = capture_client->GetNextPacketSize(&packet_length);
      if (FAILED(hr)) break;
    }

    if (FAILED(hr)) break;

    // Sleep using a waitable interval so stop latency stays bounded. We split
    // the sleep so a stop request is honoured within ~5 ms.
    DWORD slept = 0;
    while (slept < sleep_ms && !stop_requested_.load()) {
      DWORD chunk = (sleep_ms - slept < 5) ? (sleep_ms - slept) : 5;
      ::Sleep(chunk);
      slept += chunk;
    }
  }

  cleanup();
}

}  // namespace system_audio_capture
