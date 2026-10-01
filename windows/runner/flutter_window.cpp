#include "flutter_window.h"

#include <cwchar>
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

  // This window hosts the implicit view, which the app never draws into: every
  // window it shows is a windowing-API window (lib/app/app_windows.dart), and
  // each of those shows itself on its own first frame. So this one stays
  // hidden. Showing it on the engine's next frame, as Flutter's template does,
  // put an empty white window beside the app's own (Linux's runner hides its
  // implicit window for the same reason). It still exists for the plugins that
  // want a view, the app channel, and the single-instance handoff (main.cpp).

  return true;
}

void FlutterWindow::RaiseAppWindows() {
  // The windowing-API windows live on this thread, as top-level windows of
  // the engine's class. Only the app's main windows are raised, never the
  // floating HUDs: the titles are lib/app/window_chrome.dart's, and the main
  // ones (`isMainWindowTitle`) all start with the app's name, where the HUDs
  // end with it.
  ::EnumThreadWindows(
      ::GetCurrentThreadId(),
      [](HWND hwnd, LPARAM) -> BOOL {
        constexpr wchar_t kHostWindowClass[] = L"FLUTTER_HOST_WINDOW";
        constexpr wchar_t kMainTitlePrefix[] = L"Control Center";
        wchar_t class_name[64];
        wchar_t title[64];
        if (!::IsWindowVisible(hwnd) ||
            ::GetClassNameW(hwnd, class_name, 64) == 0 ||
            wcscmp(class_name, kHostWindowClass) != 0 ||
            ::GetWindowTextW(hwnd, title, 64) == 0 ||
            wcsncmp(title, kMainTitlePrefix, wcslen(kMainTitlePrefix)) != 0) {
          return TRUE;
        }
        if (::IsIconic(hwnd)) {
          ::ShowWindow(hwnd, SW_RESTORE);
        }
        ::SetForegroundWindow(hwnd);
        return TRUE;
      },
      0);
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
        RaiseAppWindows();
        return TRUE;
      }
      break;
    }

    case kRaiseAppWindowsMessage:
      // A second launch with nothing to hand over: bring the app forward.
      RaiseAppWindows();
      return 0;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
