// Windows backend: EnumWindows, Windows.Graphics.Capture, PostMessage and
// SendInput, UI Automation.
//
// NOT YET BUILT BY ANY SCRIPT, and never compiled: scripts/lib/natives.sh
// exempts cc_window on Windows until CI builds this file. To build it:
//   cl /nologo /std:c++20 /EHsc /O2 /LD /DUNICODE /D_UNICODE
//      cc_window_windows.cpp /Fe:cc_window.dll
//      user32.lib ole32.lib oleaut32.lib dwmapi.lib d3d11.lib dxgi.lib
//      windowscodecs.lib runtimeobject.lib shlwapi.lib
#include <windows.h>

#include <d3d11.h>
#include <dwmapi.h>
#include <dxgi1_2.h>
#include <inspectable.h>
#include <shlwapi.h>
#include <tlhelp32.h>
#include <uiautomation.h>
#include <wincodec.h>
#include <windows.graphics.capture.interop.h>
#include <windows.graphics.directx.direct3d11.interop.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Graphics.Capture.h>
#include <winrt/Windows.Graphics.DirectX.Direct3D11.h>
#include <winrt/Windows.Graphics.DirectX.h>

#include <algorithm>
#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <map>
#include <set>
#include <string>
#include <vector>

#include "cc_window.h"

namespace wgc = winrt::Windows::Graphics::Capture;
namespace wgd = winrt::Windows::Graphics::DirectX;

namespace {

int32_t Fail(char **out_error, int32_t code, const char *format, ...) {
  if (out_error != nullptr) {
    char buffer[512];
    va_list args;
    va_start(args, format);
    vsnprintf(buffer, sizeof(buffer), format, args);
    va_end(args);
    *out_error = _strdup(buffer);
  }
  return code;
}

std::string Utf8(const wchar_t *text, int length = -1) {
  int size = WideCharToMultiByte(CP_UTF8, 0, text, length, nullptr, 0, nullptr,
                                 nullptr);
  if (size <= 0) {
    return {};
  }
  std::string out(static_cast<size_t>(size), '\0');
  WideCharToMultiByte(CP_UTF8, 0, text, length, out.data(), size, nullptr,
                      nullptr);
  if (length < 0 && !out.empty()) {
    out.pop_back();
  }
  return out;
}

std::wstring Wide(const char *utf8) {
  int size = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8, -1,
                                 nullptr, 0);
  if (size <= 0) {
    return {};
  }
  std::wstring out(static_cast<size_t>(size), L'\0');
  MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8, -1, out.data(), size);
  out.pop_back();
  return out;
}

std::string JsonString(const std::string &value) {
  std::string out = "\"";
  for (unsigned char c : value) {
    if (c == '"' || c == '\\') {
      out += '\\';
      out += static_cast<char>(c);
    } else if (c < 0x20) {
      char escaped[8];
      snprintf(escaped, sizeof(escaped), "\\u%04x", c);
      out += escaped;
    } else {
      out += static_cast<char>(c);
    }
  }
  return out + "\"";
}

char *Copy(const std::string &value) { return _strdup(value.c_str()); }

// The caller's PIDs plus descendants. False for a root at the System processes,
// this process or an ancestor: those trees hold every other app, so ownership
// would mean nothing.
bool BuildTree(const int32_t *pids, int32_t count, std::set<DWORD> *tree) {
  HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if (snapshot == INVALID_HANDLE_VALUE) {
    return false;
  }
  std::map<DWORD, DWORD> parents;
  PROCESSENTRY32W entry{};
  entry.dwSize = sizeof(entry);
  for (BOOL more = Process32FirstW(snapshot, &entry); more;
       more = Process32NextW(snapshot, &entry)) {
    parents[entry.th32ProcessID] = entry.th32ParentProcessID;
  }
  CloseHandle(snapshot);
  for (int32_t i = 0; i < count; i++) {
    if (pids[i] <= 4) {
      return false;
    }
    tree->insert(static_cast<DWORD>(pids[i]));
  }
  // Bounded, because Windows parent PIDs go stale and can form a cycle.
  DWORD walk = GetCurrentProcessId();
  for (int depth = 0; depth < 64 && walk > 4; depth++) {
    if (tree->count(walk) != 0) {
      return false;
    }
    auto parent = parents.find(walk);
    if (parent == parents.end()) {
      break;
    }
    walk = parent->second;
  }
  for (bool grew = true; grew;) {
    grew = false;
    for (const auto &[pid, parent] : parents) {
      if (tree->count(pid) == 0 && tree->count(parent) != 0) {
        tree->insert(pid);
        grew = true;
      }
    }
  }
  return true;
}

// Physical pixels, so coordinates match Windows.Graphics.Capture's frames.
void BePerMonitorAware() {
  SetThreadDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
}

RECT VisibleBounds(HWND window) {
  RECT rect{};
  if (FAILED(DwmGetWindowAttribute(window, DWMWA_EXTENDED_FRAME_BOUNDS, &rect,
                                   sizeof(rect)))) {
    GetWindowRect(window, &rect);
  }
  return rect;
}

struct Owned {
  HWND window = nullptr;
  DWORD pid = 0;
  RECT bounds{};
  std::set<DWORD> tree;
  int Width() const { return bounds.right - bounds.left; }
  int Height() const { return bounds.bottom - bounds.top; }
};

// The chokepoint: every capture and input call resolves its window here.
int32_t Resolve(const int32_t *pids, int32_t count, uint64_t window_id,
                Owned *out, char **out_error) {
  if (pids == nullptr || count <= 0) {
    return Fail(out_error, CC_WINDOW_ERR_INVALID,
                "An empty process set owns no windows.");
  }
  BePerMonitorAware();
  if (!BuildTree(pids, count, &out->tree)) {
    return Fail(out_error, CC_WINDOW_ERR_INVALID,
                "The process set must name launched apps, not this server or "
                "anything above it.");
  }
  HWND window = reinterpret_cast<HWND>(static_cast<uintptr_t>(window_id));
  if (!IsWindow(window)) {
    return Fail(out_error, CC_WINDOW_ERR_NOT_FOUND,
                "Window %llu no longer exists.", window_id);
  }
  DWORD pid = 0;
  GetWindowThreadProcessId(window, &pid);
  if (out->tree.count(pid) == 0) {
    return Fail(out_error, CC_WINDOW_ERR_NOT_OWNED,
                "Window %llu does not belong to this app's processes.",
                window_id);
  }
  out->window = window;
  out->pid = pid;
  out->bounds = VisibleBounds(window);
  return CC_WINDOW_OK;
}

struct ListContext {
  const std::set<DWORD> *tree;
  std::string json;
};

BOOL CALLBACK Collect(HWND window, LPARAM parameter) {
  auto *context = reinterpret_cast<ListContext *>(parameter);
  DWORD pid = 0;
  GetWindowThreadProcessId(window, &pid);
  if (context->tree->count(pid) == 0 || !IsWindowVisible(window) ||
      (GetWindowLongPtrW(window, GWL_EXSTYLE) & WS_EX_TOOLWINDOW) != 0) {
    return TRUE;
  }
  DWORD cloaked = 0;
  DwmGetWindowAttribute(window, DWMWA_CLOAKED, &cloaked, sizeof(cloaked));
  RECT rect = VisibleBounds(window);
  int width = rect.right - rect.left, height = rect.bottom - rect.top;
  if (cloaked != 0 || width < 8 || height < 8) {
    return TRUE;
  }
  wchar_t title[512] = {};
  GetWindowTextW(window, title, 512);
  char head[160];
  snprintf(head, sizeof(head), "%s{\"id\":%llu,\"pid\":%lu,\"title\":",
           context->json.size() > 1 ? "," : "",
           static_cast<unsigned long long>(reinterpret_cast<uintptr_t>(window)),
           pid);
  char tail[160];
  snprintf(tail, sizeof(tail),
           ",\"x\":%ld,\"y\":%ld,\"width\":%d,\"height\":%d,\"on_screen\":%s}",
           rect.left, rect.top, width, height,
           IsIconic(window) ? "false" : "true");
  context->json += head + JsonString(Utf8(title)) + tail;
  return TRUE;
}

winrt::com_ptr<ID3D11Device> CreateDevice() {
  winrt::com_ptr<ID3D11Device> device;
  winrt::check_hresult(D3D11CreateDevice(
      nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr,
      D3D11_CREATE_DEVICE_BGRA_SUPPORT, nullptr, 0, D3D11_SDK_VERSION,
      device.put(), nullptr, nullptr));
  return device;
}

// Area-averaged BGRA to BGRA, never upscaling.
void Fit(int width, int height, int max_width, int max_height, int *out_width,
         int *out_height) {
  double fit = 1;
  if (max_width > 0 && width * fit > max_width) {
    fit = static_cast<double>(max_width) / width;
  }
  if (max_height > 0 && height * fit > max_height) {
    fit = static_cast<double>(max_height) / height;
  }
  *out_width = std::max(1, static_cast<int>(width * fit));
  *out_height = std::max(1, static_cast<int>(height * fit));
}

std::vector<uint8_t> Scale(const uint8_t *source, int stride, int width,
                           int height, int out_width, int out_height) {
  std::vector<uint8_t> out(static_cast<size_t>(out_width) * out_height * 4);
  for (int y = 0; y < out_height; y++) {
    int y0 = static_cast<int>(static_cast<long long>(y) * height / out_height);
    int y1 = std::max(
        y0 + 1,
        static_cast<int>(static_cast<long long>(y + 1) * height / out_height));
    for (int x = 0; x < out_width; x++) {
      int x0 = static_cast<int>(static_cast<long long>(x) * width / out_width);
      int x1 = std::max(
          x0 + 1,
          static_cast<int>(static_cast<long long>(x + 1) * width / out_width));
      unsigned sum[4] = {};
      unsigned count = 0;
      for (int sy = y0; sy < y1; sy++) {
        const uint8_t *row = source + static_cast<size_t>(sy) * stride;
        for (int sx = x0; sx < x1; sx++) {
          for (int c = 0; c < 4; c++) {
            sum[c] += row[static_cast<size_t>(sx) * 4 + c];
          }
          count++;
        }
      }
      uint8_t *pixel = &out[(static_cast<size_t>(y) * out_width + x) * 4];
      for (int c = 0; c < 4; c++) {
        pixel[c] = static_cast<uint8_t>(sum[c] / count);
      }
    }
  }
  return out;
}

void EncodePng(const uint8_t *bgra, int width, int height, uint8_t **out_png,
               int64_t *out_length) {
  winrt::com_ptr<IWICImagingFactory> factory;
  winrt::check_hresult(CoCreateInstance(CLSID_WICImagingFactory, nullptr,
                                        CLSCTX_INPROC_SERVER,
                                        IID_PPV_ARGS(factory.put())));
  winrt::com_ptr<IStream> stream;
  stream.attach(SHCreateMemStream(nullptr, 0));
  winrt::com_ptr<IWICBitmapEncoder> encoder;
  winrt::check_hresult(
      factory->CreateEncoder(GUID_ContainerFormatPng, nullptr, encoder.put()));
  winrt::check_hresult(encoder->Initialize(stream.get(), WICBitmapEncoderNoCache));
  winrt::com_ptr<IWICBitmapFrameEncode> frame;
  winrt::check_hresult(encoder->CreateNewFrame(frame.put(), nullptr));
  winrt::check_hresult(frame->Initialize(nullptr));
  winrt::check_hresult(frame->SetSize(width, height));
  WICPixelFormatGUID format = GUID_WICPixelFormat32bppBGRA;
  winrt::check_hresult(frame->SetPixelFormat(&format));
  UINT stride = static_cast<UINT>(width) * 4;
  winrt::check_hresult(frame->WritePixels(height, stride, stride * height,
                                          const_cast<BYTE *>(bgra)));
  winrt::check_hresult(frame->Commit());
  winrt::check_hresult(encoder->Commit());
  STATSTG stat{};
  winrt::check_hresult(stream->Stat(&stat, STATFLAG_NONAME));
  LARGE_INTEGER zero{};
  winrt::check_hresult(stream->Seek(zero, STREAM_SEEK_SET, nullptr));
  auto length = static_cast<ULONG>(stat.cbSize.QuadPart);
  auto *bytes = static_cast<uint8_t *>(malloc(length));
  ULONG read = 0;
  if (bytes == nullptr ||
      FAILED(stream->Read(bytes, length, &read)) || read != length) {
    free(bytes);
    winrt::throw_hresult(E_FAIL);
  }
  *out_png = bytes;
  *out_length = length;
}

int32_t Capture(const Owned &owned, int32_t max_width, int32_t max_height,
                uint8_t **out_png, int64_t *out_len, int32_t *out_width,
                int32_t *out_height, char **out_error) {
  if (!wgc::GraphicsCaptureSession::IsSupported()) {
    return Fail(out_error, CC_WINDOW_ERR_UNSUPPORTED,
                "Windows.Graphics.Capture is not available on this host.");
  }
  auto device = CreateDevice();
  auto dxgi = device.as<IDXGIDevice>();
  winrt::com_ptr<IInspectable> inspectable;
  winrt::check_hresult(
      CreateDirect3D11DeviceFromDXGIDevice(dxgi.get(), inspectable.put()));
  auto direct3d =
      inspectable
          .as<winrt::Windows::Graphics::DirectX::Direct3D11::IDirect3DDevice>();
  auto interop = winrt::get_activation_factory<wgc::GraphicsCaptureItem,
                                               IGraphicsCaptureItemInterop>();
  wgc::GraphicsCaptureItem item{nullptr};
  winrt::check_hresult(interop->CreateForWindow(
      owned.window, winrt::guid_of<wgc::GraphicsCaptureItem>(),
      winrt::put_abi(item)));
  auto size = item.Size();
  auto pool = wgc::Direct3D11CaptureFramePool::CreateFreeThreaded(
      direct3d, wgd::DirectXPixelFormat::B8G8R8A8UIntNormalized, 1, size);
  auto session = pool.CreateCaptureSession(item);
  session.IsCursorCaptureEnabled(false);
  HANDLE arrived = CreateEventW(nullptr, TRUE, FALSE, nullptr);
  auto token = pool.FrameArrived(
      [arrived](auto const &, auto const &) { SetEvent(arrived); });
  session.StartCapture();
  DWORD waited = WaitForSingleObject(arrived, 3000);
  CloseHandle(arrived);
  auto finish = [&] {
    pool.FrameArrived(token);
    session.Close();
    pool.Close();
  };
  if (waited != WAIT_OBJECT_0) {
    finish();
    return Fail(out_error, CC_WINDOW_ERR_TIMEOUT,
                "No frame arrived from the window in time.");
  }
  auto frame = pool.TryGetNextFrame();
  if (frame == nullptr) {
    finish();
    return Fail(out_error, CC_WINDOW_ERR_FAILED, "The capture had no frame.");
  }
  auto access =
      frame.Surface()
          .as<::Windows::Graphics::DirectX::Direct3D11::
                  IDirect3DDxgiInterfaceAccess>();
  winrt::com_ptr<ID3D11Texture2D> texture;
  winrt::check_hresult(access->GetInterface(IID_PPV_ARGS(texture.put())));
  D3D11_TEXTURE2D_DESC description{};
  texture->GetDesc(&description);
  description.Usage = D3D11_USAGE_STAGING;
  description.BindFlags = 0;
  description.MiscFlags = 0;
  description.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
  winrt::com_ptr<ID3D11Texture2D> staging;
  winrt::check_hresult(
      device->CreateTexture2D(&description, nullptr, staging.put()));
  winrt::com_ptr<ID3D11DeviceContext> context;
  device->GetImmediateContext(context.put());
  context->CopyResource(staging.get(), texture.get());
  D3D11_MAPPED_SUBRESOURCE mapped{};
  winrt::check_hresult(context->Map(staging.get(), 0, D3D11_MAP_READ, 0, &mapped));
  int width = static_cast<int>(description.Width);
  int height = static_cast<int>(description.Height);
  int fit_width = 0, fit_height = 0;
  Fit(width, height, max_width, max_height, &fit_width, &fit_height);
  auto pixels = Scale(static_cast<const uint8_t *>(mapped.pData),
                      static_cast<int>(mapped.RowPitch), width, height,
                      fit_width, fit_height);
  context->Unmap(staging.get(), 0);
  frame.Close();
  finish();
  EncodePng(pixels.data(), fit_width, fit_height, out_png, out_len);
  if (out_width != nullptr) {
    *out_width = fit_width;
  }
  if (out_height != nullptr) {
    *out_height = fit_height;
  }
  return CC_WINDOW_OK;
}

// ── Input ──────────────────────────────────────────────────────────────────

bool PointIsOwned(POINT point, const std::set<DWORD> &tree) {
  HWND top = WindowFromPoint(point);
  DWORD pid = 0;
  if (top != nullptr) {
    GetWindowThreadProcessId(top, &pid);
  }
  return tree.count(pid) != 0;
}

bool ForegroundIsOwned(const std::set<DWORD> &tree) {
  DWORD pid = 0;
  HWND foreground = GetForegroundWindow();
  if (foreground != nullptr) {
    GetWindowThreadProcessId(foreground, &pid);
  }
  return tree.count(pid) != 0;
}

// Windows refuses SetForegroundWindow from a background process unless it holds
// the input lock, so the result is checked rather than assumed.
template <typename Ready>
bool RaiseUntil(const Owned &owned, Ready ready) {
  if (ready()) {
    return true;
  }
  SetForegroundWindow(owned.window);
  BringWindowToTop(owned.window);
  for (int attempt = 0; attempt < 10; attempt++) {
    Sleep(50);
    if (ready()) {
      return true;
    }
  }
  return false;
}

int32_t Aim(const Owned &owned, int32_t mode, double x, double y, POINT *out,
            char **out_error) {
  if (!(x >= 0 && y >= 0 && x < owned.Width() && y < owned.Height())) {
    return Fail(out_error, CC_WINDOW_ERR_OUT_OF_BOUNDS,
                "(%.0f, %.0f) is outside the %dx%d window.", x, y, owned.Width(),
                owned.Height());
  }
  POINT point{owned.bounds.left + static_cast<LONG>(x),
              owned.bounds.top + static_cast<LONG>(y)};
  if (mode == CC_WINDOW_MODE_FOREGROUND &&
      !RaiseUntil(owned, [&] { return PointIsOwned(point, owned.tree); })) {
    return Fail(out_error, CC_WINDOW_ERR_NOT_OWNED,
                "Another app's window covers (%.0f, %.0f), so foreground input "
                "would land on it.",
                x, y);
  }
  *out = point;
  return CC_WINDOW_OK;
}

// The deepest child at a screen point, with the point in its client space.
HWND Target(HWND window, POINT screen, POINT *client) {
  HWND current = window;
  for (int depth = 0; depth < 16; depth++) {
    POINT local = screen;
    ScreenToClient(current, &local);
    HWND child = ChildWindowFromPointEx(
        current, local, CWP_SKIPINVISIBLE | CWP_SKIPTRANSPARENT);
    if (child == nullptr || child == current) {
      break;
    }
    current = child;
  }
  *client = screen;
  ScreenToClient(current, client);
  return current;
}

WPARAM MouseKeys(int32_t held_button, uint32_t modifiers) {
  WPARAM keys = 0;
  if (modifiers & CC_WINDOW_MOD_SHIFT) keys |= MK_SHIFT;
  if (modifiers & CC_WINDOW_MOD_CTRL) keys |= MK_CONTROL;
  if (held_button == CC_WINDOW_BUTTON_LEFT) keys |= MK_LBUTTON;
  if (held_button == CC_WINDOW_BUTTON_RIGHT) keys |= MK_RBUTTON;
  if (held_button == CC_WINDOW_BUTTON_MIDDLE) keys |= MK_MBUTTON;
  return keys;
}

void SendAbsolute(POINT point, DWORD flags, int data = 0) {
  int left = GetSystemMetrics(SM_XVIRTUALSCREEN);
  int top = GetSystemMetrics(SM_YVIRTUALSCREEN);
  int width = GetSystemMetrics(SM_CXVIRTUALSCREEN);
  int height = GetSystemMetrics(SM_CYVIRTUALSCREEN);
  INPUT input{};
  input.type = INPUT_MOUSE;
  input.mi.dx = static_cast<LONG>((point.x - left) * 65535.0 / (width - 1));
  input.mi.dy = static_cast<LONG>((point.y - top) * 65535.0 / (height - 1));
  input.mi.mouseData = static_cast<DWORD>(data);
  input.mi.dwFlags =
      flags | MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_VIRTUALDESK | MOUSEEVENTF_MOVE;
  SendInput(1, &input, sizeof(input));
}

void SendVirtualKey(WORD key, bool down) {
  INPUT input{};
  input.type = INPUT_KEYBOARD;
  input.ki.wVk = key;
  input.ki.dwFlags = down ? 0 : KEYEVENTF_KEYUP;
  SendInput(1, &input, sizeof(input));
}

const struct {
  uint32_t bit;
  WORD key;
} kModifiers[] = {{CC_WINDOW_MOD_SHIFT, VK_SHIFT},
                  {CC_WINDOW_MOD_CTRL, VK_CONTROL},
                  {CC_WINDOW_MOD_ALT, VK_MENU},
                  {CC_WINDOW_MOD_META, VK_LWIN}};

void SendModifiers(uint32_t modifiers, bool down) {
  for (const auto &modifier : kModifiers) {
    if (modifiers & modifier.bit) {
      SendVirtualKey(modifier.key, down);
    }
  }
}

const std::map<std::string, WORD> &Keys() {
  static const std::map<std::string, WORD> keys = {
      {"ret", VK_RETURN},        {"kp_enter", VK_RETURN},
      {"tab", VK_TAB},           {"esc", VK_ESCAPE},
      {"spc", VK_SPACE},         {"backspace", VK_BACK},
      {"delete", VK_DELETE},     {"insert", VK_INSERT},
      {"home", VK_HOME},         {"end", VK_END},
      {"pgup", VK_PRIOR},        {"pgdn", VK_NEXT},
      {"left", VK_LEFT},         {"up", VK_UP},
      {"right", VK_RIGHT},       {"down", VK_DOWN},
      {"menu", VK_APPS},         {"print", VK_SNAPSHOT},
      {"pause", VK_PAUSE},       {"scroll_lock", VK_SCROLL},
      {"caps_lock", VK_CAPITAL}, {"num_lock", VK_NUMLOCK},
      {"minus", VK_OEM_MINUS},   {"equal", VK_OEM_PLUS},
      {"bracket_left", VK_OEM_4}, {"bracket_right", VK_OEM_6},
      {"backslash", VK_OEM_5},   {"semicolon", VK_OEM_1},
      {"apostrophe", VK_OEM_7},  {"grave_accent", VK_OEM_3},
      {"comma", VK_OEM_COMMA},   {"dot", VK_OEM_PERIOD},
      {"slash", VK_OEM_2},       {"shift", VK_LSHIFT},
      {"shift_r", VK_RSHIFT},    {"ctrl", VK_LCONTROL},
      {"ctrl_r", VK_RCONTROL},   {"alt", VK_LMENU},
      {"alt_r", VK_RMENU},       {"meta_l", VK_LWIN},
      {"meta_r", VK_RWIN},
  };
  return keys;
}

WORD VirtualKey(const char *name) {
  if (name[0] != 0 && name[1] == 0) {
    if (name[0] >= 'a' && name[0] <= 'z') {
      return static_cast<WORD>(name[0] - 'a' + 'A');
    }
    if (name[0] >= '0' && name[0] <= '9') {
      return static_cast<WORD>(name[0]);
    }
  }
  if (name[0] == 'f' && name[1] >= '0' && name[1] <= '9') {
    int n = atoi(name + 1);
    return n >= 1 && n <= 12 ? static_cast<WORD>(VK_F1 + n - 1) : 0;
  }
  auto found = Keys().find(name);
  return found == Keys().end() ? 0 : found->second;
}

bool ModeOk(int32_t mode) {
  return mode == CC_WINDOW_MODE_BACKGROUND || mode == CC_WINDOW_MODE_FOREGROUND;
}

// ── UI Automation ──────────────────────────────────────────────────────────

struct UiWalk {
  winrt::com_ptr<IUIAutomationTreeWalker> walker;
  RECT origin{};
  int remaining = 0;
  bool truncated = false;
};

std::string BstrField(const char *key, BSTR value) {
  std::string out;
  if (value != nullptr) {
    if (SysStringLen(value) > 0) {
      out = std::string(",\"") + key + "\":" + JsonString(Utf8(value));
    }
    SysFreeString(value);
  }
  return out;
}

std::string UiNode(IUIAutomationElement *element, UiWalk *walk, int depth) {
  walk->remaining--;
  BSTR role = nullptr, name = nullptr, help = nullptr;
  element->get_CurrentLocalizedControlType(&role);
  element->get_CurrentName(&name);
  element->get_CurrentHelpText(&help);
  std::string node =
      "{\"role\":" + JsonString(role != nullptr ? Utf8(role) : std::string());
  SysFreeString(role);
  node += BstrField("title", name);
  node += BstrField("description", help);
  BOOL password = FALSE;
  element->get_CurrentIsPassword(&password);
  if (!password) {
    VARIANT value;
    VariantInit(&value);
    if (SUCCEEDED(element->GetCurrentPropertyValue(UIA_ValueValuePropertyId,
                                                   &value)) &&
        value.vt == VT_BSTR) {
      node += BstrField("value", SysAllocString(value.bstrVal));
    }
    VariantClear(&value);
  }
  BOOL enabled = TRUE, focused = FALSE;
  element->get_CurrentIsEnabled(&enabled);
  element->get_CurrentHasKeyboardFocus(&focused);
  RECT rect{};
  element->get_CurrentBoundingRectangle(&rect);
  char geometry[160];
  snprintf(geometry, sizeof(geometry),
           ",\"enabled\":%s,\"focused\":%s,\"x\":%ld,\"y\":%ld,\"width\":%ld,"
           "\"height\":%ld",
           enabled ? "true" : "false", focused ? "true" : "false",
           rect.left - walk->origin.left, rect.top - walk->origin.top,
           rect.right - rect.left, rect.bottom - rect.top);
  node += geometry;
  winrt::com_ptr<IUIAutomationElement> child;
  walk->walker->GetFirstChildElement(element, child.put());
  if (child) {
    node += ",\"children\":[";
    bool first = true;
    while (child) {
      if (walk->remaining <= 0 || depth >= 48) {
        walk->truncated = true;
        break;
      }
      if (!first) {
        node += ",";
      }
      first = false;
      node += UiNode(child.get(), walk, depth + 1);
      winrt::com_ptr<IUIAutomationElement> next;
      walk->walker->GetNextSiblingElement(child.get(), next.put());
      child = next;
    }
    node += "]";
  }
  return node + "}";
}

// Every capture and UI call is COM; the calling thread is a Dart worker's.
struct ComScope {
  ComScope() { CoInitializeEx(nullptr, COINIT_MULTITHREADED); }
  ~ComScope() { CoUninitialize(); }
};

}  // namespace

extern "C" {

int32_t cc_window_abi_version(void) { return CC_WINDOW_ABI; }

void cc_window_free(void *ptr) { free(ptr); }

int32_t cc_window_list(const int32_t *pids, int32_t pid_count,
                       const char *display, char **out_json, char **out_error) {
  (void)display;
  if (pids == nullptr || pid_count <= 0 || out_json == nullptr) {
    return Fail(out_error, CC_WINDOW_ERR_INVALID,
                "An empty process set owns no windows.");
  }
  BePerMonitorAware();
  std::set<DWORD> tree;
  if (!BuildTree(pids, pid_count, &tree)) {
    return Fail(out_error, CC_WINDOW_ERR_INVALID,
                "The process set must name launched apps, not this server or "
                "anything above it.");
  }
  ListContext context{&tree, "["};
  EnumWindows(Collect, reinterpret_cast<LPARAM>(&context));
  context.json += "]";
  *out_json = Copy(context.json);
  return CC_WINDOW_OK;
}

int32_t cc_window_capture(const int32_t *pids, int32_t pid_count,
                          const char *display, uint64_t window_id,
                          int32_t max_width, int32_t max_height,
                          uint8_t **out_png, int64_t *out_len,
                          int32_t *out_width, int32_t *out_height,
                          char **out_error) {
  (void)display;
  if (out_png == nullptr || out_len == nullptr) {
    return Fail(out_error, CC_WINDOW_ERR_INVALID,
                "Capture needs an output buffer.");
  }
  Owned owned;
  int32_t status = Resolve(pids, pid_count, window_id, &owned, out_error);
  if (status != CC_WINDOW_OK) {
    return status;
  }
  if (IsIconic(owned.window)) {
    return Fail(out_error, CC_WINDOW_ERR_OFF_DISPLAY,
                "The window is minimized, so it cannot be captured.");
  }
  ComScope com;
  try {
    return Capture(owned, max_width, max_height, out_png, out_len, out_width,
                   out_height, out_error);
  } catch (const winrt::hresult_error &error) {
    return Fail(out_error, CC_WINDOW_ERR_FAILED, "Capture failed: 0x%08x",
                static_cast<unsigned>(error.code().value));
  }
}

int32_t cc_window_mouse(const int32_t *pids, int32_t pid_count,
                        const char *display, uint64_t window_id, int32_t mode,
                        int32_t phase, int32_t button, double x, double y,
                        int32_t click_count, uint32_t modifiers,
                        char **out_error) {
  (void)display;
  if (!ModeOk(mode)) {
    return Fail(out_error, CC_WINDOW_ERR_INVALID, "Unknown input mode %d.", mode);
  }
  Owned owned;
  int32_t status = Resolve(pids, pid_count, window_id, &owned, out_error);
  if (status != CC_WINDOW_OK) {
    return status;
  }
  POINT point{};
  status = Aim(owned, mode, x, y, &point, out_error);
  if (status != CC_WINDOW_OK) {
    return status;
  }
  if (mode == CC_WINDOW_MODE_FOREGROUND) {
    DWORD down = button == CC_WINDOW_BUTTON_RIGHT    ? MOUSEEVENTF_RIGHTDOWN
                 : button == CC_WINDOW_BUTTON_MIDDLE ? MOUSEEVENTF_MIDDLEDOWN
                                                     : MOUSEEVENTF_LEFTDOWN;
    DWORD up = button == CC_WINDOW_BUTTON_RIGHT    ? MOUSEEVENTF_RIGHTUP
               : button == CC_WINDOW_BUTTON_MIDDLE ? MOUSEEVENTF_MIDDLEUP
                                                   : MOUSEEVENTF_LEFTUP;
    if (phase == CC_WINDOW_POINTER_DOWN) {
      SendModifiers(modifiers, true);
      SendAbsolute(point, down);
    } else if (phase == CC_WINDOW_POINTER_UP) {
      SendAbsolute(point, up);
      SendModifiers(modifiers, false);
    } else {
      SendAbsolute(point, 0);
    }
    return CC_WINDOW_OK;
  }
  POINT client{};
  HWND target = Target(owned.window, point, &client);
  LPARAM position = MAKELPARAM(client.x, client.y);
  UINT down = button == CC_WINDOW_BUTTON_RIGHT    ? WM_RBUTTONDOWN
              : button == CC_WINDOW_BUTTON_MIDDLE ? WM_MBUTTONDOWN
                                                  : WM_LBUTTONDOWN;
  UINT up = button == CC_WINDOW_BUTTON_RIGHT    ? WM_RBUTTONUP
            : button == CC_WINDOW_BUTTON_MIDDLE ? WM_MBUTTONUP
                                                : WM_LBUTTONUP;
  UINT double_click = button == CC_WINDOW_BUTTON_RIGHT    ? WM_RBUTTONDBLCLK
                      : button == CC_WINDOW_BUTTON_MIDDLE ? WM_MBUTTONDBLCLK
                                                          : WM_LBUTTONDBLCLK;
  switch (phase) {
    case CC_WINDOW_POINTER_MOVE:
      PostMessageW(target, WM_MOUSEMOVE, MouseKeys(-1, modifiers), position);
      break;
    case CC_WINDOW_POINTER_DRAG:
      PostMessageW(target, WM_MOUSEMOVE, MouseKeys(button, modifiers), position);
      break;
    case CC_WINDOW_POINTER_DOWN:
      PostMessageW(target, click_count == 2 ? double_click : down,
                   MouseKeys(button, modifiers), position);
      break;
    case CC_WINDOW_POINTER_UP:
      PostMessageW(target, up, MouseKeys(-1, modifiers), position);
      break;
    default:
      return Fail(out_error, CC_WINDOW_ERR_INVALID, "Unknown pointer phase %d.",
                  phase);
  }
  return CC_WINDOW_OK;
}

int32_t cc_window_scroll(const int32_t *pids, int32_t pid_count,
                         const char *display, uint64_t window_id, int32_t mode,
                         double x, double y, int32_t dx, int32_t dy,
                         uint32_t modifiers, char **out_error) {
  (void)display;
  if (!ModeOk(mode)) {
    return Fail(out_error, CC_WINDOW_ERR_INVALID, "Unknown input mode %d.", mode);
  }
  Owned owned;
  int32_t status = Resolve(pids, pid_count, window_id, &owned, out_error);
  if (status != CC_WINDOW_OK) {
    return status;
  }
  POINT point{};
  status = Aim(owned, mode, x, y, &point, out_error);
  if (status != CC_WINDOW_OK) {
    return status;
  }
  if (mode == CC_WINDOW_MODE_FOREGROUND) {
    SendModifiers(modifiers, true);
    if (dy != 0) {
      SendAbsolute(point, MOUSEEVENTF_WHEEL, dy * WHEEL_DELTA);
    }
    if (dx != 0) {
      SendAbsolute(point, MOUSEEVENTF_HWHEEL, -dx * WHEEL_DELTA);
    }
    SendModifiers(modifiers, false);
    return CC_WINDOW_OK;
  }
  // Wheel messages carry SCREEN coordinates, unlike every other mouse message.
  LPARAM position = MAKELPARAM(point.x, point.y);
  POINT client{};
  HWND target = Target(owned.window, point, &client);
  WORD keys = static_cast<WORD>(MouseKeys(-1, modifiers));
  if (dy != 0) {
    PostMessageW(target, WM_MOUSEWHEEL,
                 MAKEWPARAM(keys, static_cast<short>(dy * WHEEL_DELTA)), position);
  }
  if (dx != 0) {
    PostMessageW(target, WM_MOUSEHWHEEL,
                 MAKEWPARAM(keys, static_cast<short>(-dx * WHEEL_DELTA)),
                 position);
  }
  return CC_WINDOW_OK;
}

int32_t cc_window_key(const int32_t *pids, int32_t pid_count,
                      const char *display, uint64_t window_id, int32_t mode,
                      const char *key, int32_t action, uint32_t modifiers,
                      char **out_error) {
  (void)display;
  if (!ModeOk(mode) || key == nullptr) {
    return Fail(out_error, CC_WINDOW_ERR_INVALID, "Invalid key event.");
  }
  WORD code = VirtualKey(key);
  if (code == 0) {
    return Fail(out_error, CC_WINDOW_ERR_INVALID, "Unknown key \"%s\".", key);
  }
  Owned owned;
  int32_t status = Resolve(pids, pid_count, window_id, &owned, out_error);
  if (status != CC_WINDOW_OK) {
    return status;
  }
  if (mode == CC_WINDOW_MODE_FOREGROUND) {
    if (!RaiseUntil(owned, [&] { return ForegroundIsOwned(owned.tree); })) {
      return Fail(out_error, CC_WINDOW_ERR_NOT_OWNED,
                  "This app did not take keyboard focus, so foreground input "
                  "would reach another app.");
    }
    if (action != CC_WINDOW_KEY_UP) {
      SendModifiers(modifiers, true);
      SendVirtualKey(code, true);
    }
    if (action != CC_WINDOW_KEY_DOWN) {
      SendVirtualKey(code, false);
      SendModifiers(modifiers, false);
    }
    return CC_WINDOW_OK;
  }
  // Apps read modifiers with GetKeyState, which a posted message cannot set, so
  // a background ctrl+s would type "s" and report success.
  if (modifiers != 0) {
    return Fail(out_error, CC_WINDOW_ERR_UNSUPPORTED,
                "Background input cannot hold modifiers on Windows. Use "
                "foreground input for key combinations.");
  }
  if (action != CC_WINDOW_KEY_UP) {
    PostMessageW(owned.window, WM_KEYDOWN, code, 1);
  }
  if (action != CC_WINDOW_KEY_DOWN) {
    PostMessageW(owned.window, WM_KEYUP, code, 0xC0000001);
  }
  return CC_WINDOW_OK;
}

int32_t cc_window_text(const int32_t *pids, int32_t pid_count,
                       const char *display, uint64_t window_id, int32_t mode,
                       const char *utf8, char **out_error) {
  (void)display;
  if (!ModeOk(mode) || utf8 == nullptr) {
    return Fail(out_error, CC_WINDOW_ERR_INVALID, "Invalid text event.");
  }
  std::wstring text = Wide(utf8);
  if (text.empty() && utf8[0] != 0) {
    return Fail(out_error, CC_WINDOW_ERR_INVALID, "Text must be valid UTF-8.");
  }
  Owned owned;
  int32_t status = Resolve(pids, pid_count, window_id, &owned, out_error);
  if (status != CC_WINDOW_OK) {
    return status;
  }
  if (mode == CC_WINDOW_MODE_FOREGROUND &&
      !RaiseUntil(owned, [&] { return ForegroundIsOwned(owned.tree); })) {
    return Fail(out_error, CC_WINDOW_ERR_NOT_OWNED,
                "This app did not take keyboard focus, so foreground input "
                "would reach another app.");
  }
  for (wchar_t unit : text) {
    if (mode == CC_WINDOW_MODE_BACKGROUND) {
      PostMessageW(owned.window, WM_CHAR, unit, 1);
      continue;
    }
    // Focus can move mid-string, and the rest of the text would land in the
    // operator's foreground app.
    if (!ForegroundIsOwned(owned.tree)) {
      return Fail(out_error, CC_WINDOW_ERR_NOT_OWNED,
                  "Keyboard focus left this app while typing, so the rest of "
                  "the text was not sent.");
    }
    INPUT input[2] = {};
    input[0].type = input[1].type = INPUT_KEYBOARD;
    input[0].ki.wScan = input[1].ki.wScan = unit;
    input[0].ki.dwFlags = KEYEVENTF_UNICODE;
    input[1].ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP;
    SendInput(2, input, sizeof(INPUT));
  }
  return CC_WINDOW_OK;
}

int32_t cc_window_read_ui(const int32_t *pids, int32_t pid_count,
                          const char *display, uint64_t window_id,
                          int32_t max_nodes, char **out_json,
                          char **out_error) {
  (void)display;
  if (out_json == nullptr) {
    return Fail(out_error, CC_WINDOW_ERR_INVALID,
                "read_ui needs an output string.");
  }
  Owned owned;
  int32_t status = Resolve(pids, pid_count, window_id, &owned, out_error);
  if (status != CC_WINDOW_OK) {
    return status;
  }
  ComScope com;
  winrt::com_ptr<IUIAutomation> automation;
  winrt::com_ptr<IUIAutomationElement> root;
  UiWalk walk;
  if (FAILED(CoCreateInstance(__uuidof(CUIAutomation), nullptr,
                              CLSCTX_INPROC_SERVER,
                              IID_PPV_ARGS(automation.put()))) ||
      FAILED(automation->ElementFromHandle(owned.window, root.put())) ||
      FAILED(automation->get_RawViewWalker(walk.walker.put())) || !root) {
    return Fail(out_error, CC_WINDOW_ERR_UNSUPPORTED,
                "This window exposes no accessibility tree. Use screenshots "
                "instead.");
  }
  walk.origin = owned.bounds;
  walk.remaining = max_nodes > 0 ? max_nodes : 500;
  std::string json = "{\"root\":" + UiNode(root.get(), &walk, 0);
  json += walk.truncated ? ",\"truncated\":true}" : ",\"truncated\":false}";
  *out_json = Copy(json);
  return CC_WINDOW_OK;
}

int32_t cc_window_permissions(char **out_json, char **out_error) {
  if (out_json == nullptr) {
    return Fail(out_error, CC_WINDOW_ERR_INVALID,
                "permissions needs an output string.");
  }
  *out_json = Copy(
      "{\"screen_capture\":\"not_required\",\"input\":\"not_required\","
      "\"accessibility\":\"not_required\"}");
  return CC_WINDOW_OK;
}

int32_t cc_window_open_settings(int32_t pane, char **out_error) {
  (void)pane;
  return Fail(out_error, CC_WINDOW_ERR_UNSUPPORTED,
              "Windows needs no permission for app windows.");
}

}  // extern "C"
