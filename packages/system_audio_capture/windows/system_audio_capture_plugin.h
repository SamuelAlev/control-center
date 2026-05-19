#ifndef FLUTTER_PLUGIN_SYSTEM_AUDIO_CAPTURE_PLUGIN_H_
#define FLUTTER_PLUGIN_SYSTEM_AUDIO_CAPTURE_PLUGIN_H_

#include <flutter/encodable_value.h>
#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <windows.h>

#include <atomic>
#include <functional>
#include <memory>
#include <mutex>
#include <queue>
#include <string>
#include <thread>

namespace system_audio_capture {

// Captures system output audio (loopback) on Windows using WASAPI
// (IAudioClient initialized with AUDCLNT_STREAMFLAGS_LOOPBACK). This is
// driver-free and needs no permission prompt: any process can open a
// shared-mode loopback stream on a render endpoint.
//
// The plugin emits raw 16 kHz / mono / signed-16-bit little-endian PCM frames
// over an EventChannel as Dart `Uint8List` values. The endpoint mix format is
// resampled and down-mixed from whatever the device reports (commonly 48 kHz
// stereo 32-bit float).
class SystemAudioCapturePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(
      flutter::PluginRegistrarWindows* registrar);

  explicit SystemAudioCapturePlugin(
      flutter::PluginRegistrarWindows* registrar);

  ~SystemAudioCapturePlugin() override;

  // Disallow copy and assign.
  SystemAudioCapturePlugin(const SystemAudioCapturePlugin&) = delete;
  SystemAudioCapturePlugin& operator=(const SystemAudioCapturePlugin&) = delete;

 private:
  // MethodChannel dispatch.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Method implementations.
  flutter::EncodableValue ListSources();
  bool StartCapture(const std::string& source_id, std::string* error_out);
  void StopCapture();

  // The capture loop body, run on a dedicated thread. `source_id` selects the
  // render endpoint ("" / "system" = default eRender/eConsole endpoint).
  void CaptureThreadMain(std::string source_id);

  // EventChannel plumbing. The sink is only ever touched on the platform
  // thread (set from OnListen/OnCancel, read from drained main-thread tasks).
  void EmitFrame(std::vector<uint8_t> pcm16);

  // Posts `task` to run on the Flutter platform (UI) thread. The capture
  // thread must never touch the EventSink directly; it enqueues frame
  // delivery here and a window-proc message drains the queue on the main
  // thread. Returns immediately.
  void RunOnPlatformThread(std::function<void()> task);
  void DrainPlatformTasks();

  flutter::PluginRegistrarWindows* registrar_ = nullptr;

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      method_channel_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>>
      event_channel_;

  // Owned by the plugin; the sink is non-null only while Dart is listening.
  // Touched exclusively on the platform thread.
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_;

  // Window-proc delegate registration id, used to drain platform-thread tasks.
  int window_proc_id_ = -1;

  // Platform-thread task queue (producer: capture thread; consumer: main
  // thread via WM_SAC_RUN_TASK).
  std::queue<std::function<void()>> platform_tasks_;
  std::mutex platform_tasks_mutex_;

  // Capture thread + lifecycle.
  std::thread capture_thread_;
  std::atomic<bool> capturing_{false};
  std::atomic<bool> stop_requested_{false};
};

}  // namespace system_audio_capture

#endif  // FLUTTER_PLUGIN_SYSTEM_AUDIO_CAPTURE_PLUGIN_H_
