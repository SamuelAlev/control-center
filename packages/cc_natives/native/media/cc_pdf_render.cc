#include <algorithm>
#include <cerrno>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <limits>
#include <vector>

#ifdef _WIN32
// windows.h otherwise defines min/max macros that break std::min/std::max
// and std::numeric_limits<int>::max().
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <fcntl.h>
#include <io.h>
#include <string>
#include <windows.h>
#endif

#include "fpdfview.h"

namespace {

int fail(const char* message) {
  std::fprintf(stderr, "cc_pdf_render: %s\n", message);
  return 1;
}

const char* pdf_error(unsigned long error) {
  switch (error) {
    case FPDF_ERR_FILE: return "cannot open PDF";
    case FPDF_ERR_FORMAT: return "invalid or corrupt PDF";
    case FPDF_ERR_PASSWORD: return "encrypted PDF requires a password";
    case FPDF_ERR_SECURITY: return "PDF security restrictions prevent opening";
    case FPDF_ERR_PAGE: return "invalid PDF page";
    default: return "cannot load PDF";
  }
}

bool parse_positive(const char* text, int* value) {
  if (!text || !*text || *text == '+' || *text == '-') return false;
  char* end = nullptr;
  errno = 0;
  const long parsed = std::strtol(text, &end, 10);
  if (errno == ERANGE || *end || parsed < 1 ||
      parsed > std::numeric_limits<int>::max()) return false;
  *value = static_cast<int>(parsed);
  return true;
}

}  // namespace

int run(int argc, char** argv) {
  const bool info = argc == 3 && std::strcmp(argv[1], "info") == 0;
  const bool render = argc == 5 && std::strcmp(argv[1], "render") == 0;
  if (!info && !render)
    return fail("usage: cc_pdf_render info ABSOLUTE_PDF_PATH | render ABSOLUTE_PDF_PATH ONE_BASED_PAGE MAX_DIMENSION");

  // The server confines the path; this guard prevents accidental relative access
  // when this helper is invoked outside the server.
  const char* path = argv[2];
#ifdef _WIN32
  const size_t path_length = std::strlen(path);
  const bool drive_path = path_length >= 3 &&
                          (((path[0] >= 'A' && path[0] <= 'Z') ||
                            (path[0] >= 'a' && path[0] <= 'z')) &&
                           path[1] == ':' &&
                           (path[2] == '\\' || path[2] == '/'));
  const bool unc_path = path_length >= 2 &&
                        path[0] == '\\' && path[1] == '\\';
  const bool absolute = drive_path || unc_path;
#else
  const bool absolute = path[0] == '/';
#endif
  if (!absolute) return fail("PDF path must be absolute");

  int page_number = 0;
  int max_dimension = 0;
  if (render && (!parse_positive(argv[3], &page_number) ||
                 !parse_positive(argv[4], &max_dimension) || max_dimension > 2048))
    return fail("page and max dimension must be positive integers (max dimension <= 2048)");

  FPDF_InitLibrary();
  FPDF_DOCUMENT document = FPDF_LoadDocument(path, nullptr);
  if (!document) {
    const char* message = pdf_error(FPDF_GetLastError());
    FPDF_DestroyLibrary();
    return fail(message);
  }
  const int count = FPDF_GetPageCount(document);
  if (count <= 0) {
    FPDF_CloseDocument(document);
    FPDF_DestroyLibrary();
    return fail("PDF contains no pages");
  }
  if (info) {
    std::printf("{\"page_count\":%d}\n", count);
  } else if (page_number > count) {
    FPDF_CloseDocument(document);
    FPDF_DestroyLibrary();
    return fail("page number exceeds PDF page count");
  } else {
    FPDF_PAGE page = FPDF_LoadPage(document, page_number - 1);
    if (!page) {
      FPDF_CloseDocument(document);
      FPDF_DestroyLibrary();
      return fail("failed to load PDF page");
    }
    // PDFium page dimensions and FPDF_RenderPageBitmap already account for the
    // page's intrinsic /Rotate. A second rotation would undo or double it.
    const double width = FPDF_GetPageWidthF(page);
    const double height = FPDF_GetPageHeightF(page);
    if (!std::isfinite(width) || !std::isfinite(height) || width <= 0 || height <= 0) {
      FPDF_ClosePage(page);
      FPDF_CloseDocument(document);
      FPDF_DestroyLibrary();
      return fail("PDF page has invalid dimensions");
    }
    const double scale = static_cast<double>(max_dimension) / std::max(width, height);
    const int w = std::max(1, std::min(max_dimension, static_cast<int>(std::round(width * scale))));
    const int h = std::max(1, std::min(max_dimension, static_cast<int>(std::round(height * scale))));
    FPDF_BITMAP bitmap = FPDFBitmap_Create(w, h, 1);
    if (!bitmap) {
      FPDF_ClosePage(page);
      FPDF_CloseDocument(document);
      FPDF_DestroyLibrary();
      return fail("cannot allocate PDF bitmap");
    }
    FPDFBitmap_FillRect(bitmap, 0, 0, w, h, 0xFFFFFFFF);
    FPDF_RenderPageBitmap(bitmap, page, 0, 0, w, h, 0, FPDF_ANNOT);
    const unsigned char* pixels = static_cast<const unsigned char*>(FPDFBitmap_GetBuffer(bitmap));
    const int stride = FPDFBitmap_GetStride(bitmap);
    if (!pixels || stride < w * 4) {
      FPDFBitmap_Destroy(bitmap);
      FPDF_ClosePage(page);
      FPDF_CloseDocument(document);
      FPDF_DestroyLibrary();
      return fail("PDFium returned an invalid bitmap");
    }
#ifdef _WIN32
    if (_setmode(_fileno(stdout), _O_BINARY) == -1) {
      FPDFBitmap_Destroy(bitmap);
      FPDF_ClosePage(page);
      FPDF_CloseDocument(document);
      FPDF_DestroyLibrary();
      return fail("cannot enable binary stdout");
    }
#endif
    std::printf("P6\n%d %d\n255\n", w, h);
    std::vector<unsigned char> rgb(static_cast<size_t>(w) * 3);
    bool success = true;
    for (int y = 0; y < h && success; ++y) {
      const unsigned char* row = pixels + static_cast<size_t>(y) * stride;
      for (int x = 0; x < w; ++x) {
        rgb[static_cast<size_t>(x) * 3] = row[static_cast<size_t>(x) * 4 + 2];
        rgb[static_cast<size_t>(x) * 3 + 1] = row[static_cast<size_t>(x) * 4 + 1];
        rgb[static_cast<size_t>(x) * 3 + 2] = row[static_cast<size_t>(x) * 4];
      }
      success = std::fwrite(rgb.data(), 1, rgb.size(), stdout) == rgb.size();
    }
    success = std::fflush(stdout) == 0 && success;
    FPDFBitmap_Destroy(bitmap);
    FPDF_ClosePage(page);
    if (!success) {
      FPDF_CloseDocument(document);
      FPDF_DestroyLibrary();
      return fail("failed writing PPM to stdout");
    }
  }
  FPDF_CloseDocument(document);
  FPDF_DestroyLibrary();
  return 0;
}

#ifdef _WIN32
int wmain(int argc, wchar_t** argv) {
  // The Windows CRT's narrow argv uses the active ANSI code page, corrupting
  // non-ASCII PDF paths. PDFium's path API expects UTF-8, not UTF-16.
  std::string utf8[5];
  char* args[5] = {};
  if (argc == 3 || argc == 5) {
    for (int i = 1; i < argc; ++i) {
      const int size = WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS,
                                           argv[i], -1, nullptr, 0, nullptr, nullptr);
      if (size == 0) return fail("invalid UTF-16 command-line argument");
      utf8[i].resize(static_cast<size_t>(size));
      if (WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, argv[i], -1,
                              utf8[i].data(), size, nullptr, nullptr) == 0)
        return fail("cannot convert command-line argument to UTF-8");
      utf8[i].pop_back();  // Exclude the terminating NUL from the string.
      args[i] = utf8[i].data();
    }
  }
  return run(argc, args);
}
#else
int main(int argc, char** argv) { return run(argc, argv); }
#endif
