#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

#include <string>
#include <vector>

static std::string GetExecutablePath() {
  wchar_t buffer[MAX_PATH];
  GetModuleFileNameW(nullptr, buffer, MAX_PATH);
  return Utf8FromUtf16(buffer);
}

static void RegisterUriScheme(const std::string& exe_path) {
  HKEY key;
  std::wstring scheme = L"control-center";

  std::wstring w_exe_path(exe_path.begin(), exe_path.end());

  if (RegCreateKeyExW(HKEY_CURRENT_USER,
                      L"Software\\Classes\\control-center", 0, nullptr,
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

  if (RegCreateKeyExW(HKEY_CURRENT_USER,
                      L"Software\\Classes\\control-center\\DefaultIcon", 0,
                      nullptr, REG_OPTION_NON_VOLATILE, KEY_WRITE, nullptr,
                      &key, nullptr) != ERROR_SUCCESS) {
    return;
  }
  std::wstring icon_value = w_exe_path + L",1";
  RegSetValueExW(key, nullptr, 0, REG_SZ,
                 reinterpret_cast<const BYTE*>(icon_value.c_str()),
                 static_cast<DWORD>((icon_value.size() + 1) * sizeof(wchar_t)));
  RegCloseKey(key);

  if (RegCreateKeyExW(
          HKEY_CURRENT_USER,
          L"Software\\Classes\\control-center\\shell\\open\\command", 0,
          nullptr, REG_OPTION_NON_VOLATILE, KEY_WRITE, nullptr, &key,
          nullptr) != ERROR_SUCCESS) {
    return;
  }
  std::wstring command_value = L"\"" + w_exe_path + L"\" \"%1\"";
  RegSetValueExW(key, nullptr, 0, REG_SZ,
                 reinterpret_cast<const BYTE*>(command_value.c_str()),
                 static_cast<DWORD>((command_value.size() + 1) * sizeof(wchar_t)));
  RegCloseKey(key);
}

static std::string FindDeepLinkUrl(const std::vector<std::string>& args) {
  for (const auto& arg : args) {
    if (arg.find("control-center://") == 0) {
      return arg;
    }
  }
  return "";
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  RegisterUriScheme(GetExecutablePath());

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  std::string deep_link_url = FindDeepLinkUrl(command_line_arguments);

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  if (!deep_link_url.empty()) {
    window.SetPendingDeepLink(deep_link_url);
  }

  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"Control Center", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
