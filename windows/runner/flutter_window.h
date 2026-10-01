#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>

#include "win32_window.h"

// Tag identifying a WM_COPYDATA payload that carries a deep-link URL (a
// NUL-terminated UTF-8 string) forwarded from a second app instance to the
// running one. Shared by main.cpp (sender) and flutter_window.cpp (receiver).
constexpr ULONG_PTR kDeepLinkCopyDataTag = 0x6363646CUL;  // 'ccdl'

// Posted by a second app instance that has no deep link to hand over: the
// running instance raises its windows. Private to this window's class, so a
// WM_APP value cannot collide. Shared like kDeepLinkCopyDataTag.
constexpr UINT kRaiseAppWindowsMessage = WM_APP + 1;

class FlutterWindow : public Win32Window {
 public:
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

  void SetPendingDeepLink(const std::string& url);

 protected:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // Brings the app's visible main windows to the front. This window is never
  // shown, so raising it (rather than them) would do nothing.
  static void RaiseAppWindows();

  flutter::DartProject project_;
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
  std::string pending_deep_link_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      app_channel_;
};

#endif
