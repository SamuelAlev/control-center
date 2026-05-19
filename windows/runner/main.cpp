#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

#include <string>
#include <vector>

// Reversed Google OAuth iOS client id used as the OAuth redirect URL scheme
// (com.googleusercontent.apps.<CLIENT_ID>). PUBLIC, not a secret; must match
// GOOGLE_OAUTH_CLIENT_ID in .env. Defined by windows/runner/CMakeLists.txt;
// the fallback keeps the file self-contained for ad-hoc builds.
#ifndef GOOGLE_REVERSED_CLIENT_ID
#define GOOGLE_REVERSED_CLIENT_ID \
  "com.googleusercontent.apps.806422936280-h53u9n27h9pmvrbs2ci86hisla0addqn"
#endif

namespace {

// Per-session name guarding single-instance: a protocol launch must hand its
// URL to the already-running instance, not start a second one.
constexpr const wchar_t kSingleInstanceMutex[] =
    L"Local\\com.alev.control-center.singleinstance";

// Must match kWindowClassName in win32_window.cpp and the title passed to
// Win32Window::Create below — matching both targets our main window rather than
// a plugin sub-window (e.g. the focus pill) that shares the generic class.
constexpr const wchar_t kWindowClassName[] = L"FLUTTER_RUNNER_WIN32_WINDOW";
constexpr const wchar_t kWindowTitle[] = L"Control Center";

std::string GetExecutablePath() {
  wchar_t buffer[MAX_PATH];
  GetModuleFileNameW(nullptr, buffer, MAX_PATH);
  return Utf8FromUtf16(buffer);
}

// Registers a single custom URL scheme under HKCU so Windows launches this exe
// (with the URL as argv[1]) when the scheme is opened. Idempotent.
void RegisterUriScheme(const std::wstring& scheme, const std::string& exe_path) {
  std::wstring w_exe_path(exe_path.begin(), exe_path.end());
  std::wstring base = L"Software\\Classes\\" + scheme;

  HKEY key;
  if (RegCreateKeyExW(HKEY_CURRENT_USER, base.c_str(), 0, nullptr,
                      REG_OPTION_NON_VOLATILE, KEY_WRITE, nullptr, &key,
                      nullptr) != ERROR_SUCCESS) {
    return;
  }
  const wchar_t* protocol_desc = L"URL:Control Center Protocol";
  RegSetValueExW(key, nullptr, 0, REG_SZ,
                 reinterpret_cast<const BYTE*>(protocol_desc),
                 static_cast<DWORD>((wcslen(protocol_desc) + 1) * sizeof(wchar_t)));
  RegSetValueExW(key, L"URL Protocol", 0, REG_SZ,
                 reinterpret_cast<const BYTE*>(L""), sizeof(wchar_t));
  RegCloseKey(key);

  std::wstring icon_key = base + L"\\DefaultIcon";
  if (RegCreateKeyExW(HKEY_CURRENT_USER, icon_key.c_str(), 0, nullptr,
                      REG_OPTION_NON_VOLATILE, KEY_WRITE, nullptr, &key,
                      nullptr) != ERROR_SUCCESS) {
    return;
  }
  std::wstring icon_value = w_exe_path + L",1";
  RegSetValueExW(key, nullptr, 0, REG_SZ,
                 reinterpret_cast<const BYTE*>(icon_value.c_str()),
                 static_cast<DWORD>((icon_value.size() + 1) * sizeof(wchar_t)));
  RegCloseKey(key);

  std::wstring command_key = base + L"\\shell\\open\\command";
  if (RegCreateKeyExW(HKEY_CURRENT_USER, command_key.c_str(), 0, nullptr,
                      REG_OPTION_NON_VOLATILE, KEY_WRITE, nullptr, &key,
                      nullptr) != ERROR_SUCCESS) {
    return;
  }
  std::wstring command_value = L"\"" + w_exe_path + L"\" \"%1\"";
  RegSetValueExW(key, nullptr, 0, REG_SZ,
                 reinterpret_cast<const BYTE*>(command_value.c_str()),
                 static_cast<DWORD>((command_value.size() + 1) * sizeof(wchar_t)));
  RegCloseKey(key);
}

// Widens an ASCII scheme literal (the reversed client id is ASCII-only).
std::wstring WidenAscii(const std::string& s) {
  return std::wstring(s.begin(), s.end());
}

std::string FindDeepLinkUrl(const std::vector<std::string>& args) {
  const std::string google_prefix = "com.googleusercontent.apps.";
  for (const auto& arg : args) {
    if (arg.rfind("control-center://", 0) == 0 ||
        arg.rfind(google_prefix, 0) == 0) {
      return arg;
    }
  }
  return "";
}

// Forwards a deep-link URL (UTF-8) to the running instance's main window via
// WM_COPYDATA; the system marshals the buffer across the process boundary.
void ForwardDeepLinkToPrimary(HWND primary, const std::string& url) {
  COPYDATASTRUCT cds{};
  cds.dwData = kDeepLinkCopyDataTag;
  cds.cbData = static_cast<DWORD>(url.size() + 1);  // include the NUL
  cds.lpData = const_cast<char*>(url.c_str());
  ::SendMessageW(primary, WM_COPYDATA, 0, reinterpret_cast<LPARAM>(&cds));
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  std::vector<std::string> command_line_arguments = GetCommandLineArguments();
  std::string deep_link_url = FindDeepLinkUrl(command_line_arguments);

  // Single-instance: if the app is already running, hand off our work (a
  // deep-link URL, or just a focus request) to it and exit. This is what routes
  // an OAuth redirect — opened by the OS in a fresh process — to the running
  // instance that is awaiting it.
  HANDLE instance_mutex = ::CreateMutexW(nullptr, TRUE, kSingleInstanceMutex);
  bool already_running =
      instance_mutex != nullptr && ::GetLastError() == ERROR_ALREADY_EXISTS;
  if (already_running) {
    HWND primary = nullptr;
    for (int i = 0; i < 50; ++i) {  // up to ~5s in case the window is coming up
      primary = ::FindWindowW(kWindowClassName, kWindowTitle);
      if (primary != nullptr) {
        break;
      }
      ::Sleep(100);
    }
    if (primary != nullptr) {
      if (!deep_link_url.empty()) {
        ForwardDeepLinkToPrimary(primary, deep_link_url);
      }
      ::SetForegroundWindow(primary);
    }
    if (instance_mutex != nullptr) {
      ::CloseHandle(instance_mutex);
    }
    ::CoUninitialize();
    return EXIT_SUCCESS;
  }

  // Primary instance.
  std::string exe_path = GetExecutablePath();
  RegisterUriScheme(L"control-center", exe_path);
  RegisterUriScheme(WidenAscii(GOOGLE_REVERSED_CLIENT_ID), exe_path);

  flutter::DartProject project(L"data");
  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  if (!deep_link_url.empty()) {
    window.SetPendingDeepLink(deep_link_url);
  }

  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(kWindowTitle, origin, size)) {
    if (instance_mutex != nullptr) {
      ::CloseHandle(instance_mutex);
    }
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  if (instance_mutex != nullptr) {
    ::CloseHandle(instance_mutex);
  }
  ::CoUninitialize();
  return EXIT_SUCCESS;
}
