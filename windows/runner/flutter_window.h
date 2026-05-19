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
  flutter::DartProject project_;
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
  std::string pending_deep_link_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      app_channel_;
};

#endif
