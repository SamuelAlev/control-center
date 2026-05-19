#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

void FlutterWindow::SetPendingDeepLink(const std::string& url) {
  pending_deep_link_ = url;
}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  app_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "com.controlcenter/app",
          &flutter::StandardMethodCodec::GetInstance());

  if (!pending_deep_link_.empty()) {
    std::string url = pending_deep_link_;
    app_channel_->InvokeMethod(
        "openUrl",
        std::make_unique<flutter::EncodableValue>(flutter::EncodableValue(url)));
    pending_deep_link_.clear();
  }

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  app_channel_.reset();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;

    case WM_COPYDATA: {
      // A second instance forwarded a deep-link URL (e.g. the Google OAuth
      // redirect opened by the OS in a fresh process). Hand it to Dart on the
      // same channel as the cold-start path and raise the window.
      auto* cds = reinterpret_cast<COPYDATASTRUCT*>(lparam);
      if (cds != nullptr && cds->dwData == kDeepLinkCopyDataTag &&
          cds->lpData != nullptr && cds->cbData > 0) {
        std::string url(reinterpret_cast<const char*>(cds->lpData),
                        cds->cbData - 1);  // drop the trailing NUL
        if (app_channel_ != nullptr && !url.empty()) {
          app_channel_->InvokeMethod(
              "openUrl",
              std::make_unique<flutter::EncodableValue>(url));
        }
        ::SetForegroundWindow(hwnd);
        return TRUE;
      }
      break;
    }
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
