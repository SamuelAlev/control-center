/*
 * Linux backend: X11 with XTEST, normally on a private Xvfb per app.
 *
 * libX11, libXtst, zlib and AT-SPI are loaded on first use, and their ABI is
 * declared here rather than included. The library has to load on a headless
 * server image with none of them, because the boot preflight dlopens it; only
 * an attempt to USE a window there fails, with a reason. The layouts below are
 * stable X11 ABI.
 *
 * Xvfb has no input focus to steal and no operator on it, so the two input
 * modes behave alike. The hit test and the focus check still run: `display` may
 * be a real one.
 */
#define _GNU_SOURCE
#include <ctype.h>
#include <dirent.h>
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <pthread.h>
#include <setjmp.h>
#include <signal.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/resource.h>
#include <sys/wait.h>
#include <unistd.h>

#include "cc_window.h"

/* ── X11 ABI ────────────────────────────────────────────────────────────── */

typedef struct _XDisplay Display;
typedef unsigned long XWindow;
typedef unsigned long XAtom;
typedef unsigned long XKeySym;
typedef unsigned char XKeyCode;

typedef struct _XImage {
  int width, height, xoffset, format;
  char *data;
  int byte_order, bitmap_unit, bitmap_bit_order, bitmap_pad, depth;
  int bytes_per_line, bits_per_pixel;
  unsigned long red_mask, green_mask, blue_mask;
  char *obdata;
  struct {
    void *create_image;
    int (*destroy_image)(struct _XImage *);
    void *get_pixel, *put_pixel, *sub_image, *add_pixel;
  } f;
} XImage;

typedef struct {
  int x, y, width, height, border_width, depth;
  void *visual;
  XWindow root;
  int class_, bit_gravity, win_gravity, backing_store;
  unsigned long backing_planes, backing_pixel;
  int save_under;
  unsigned long colormap;
  int map_installed, map_state;
  long all_event_masks, your_event_mask, do_not_propagate_mask;
  int override_redirect;
  void *screen;
} XWindowAttributes;

enum {
  kIsViewable = 2,
  kZPixmap = 2,
  kRevertToParent = 2,
  kXaCardinal = 6,
  kPointerRoot = 1, /* X focus below this is None or PointerRoot, not a window */
};

static struct {
  Display *(*OpenDisplay)(const char *);
  int (*CloseDisplay)(Display *);
  XWindow (*DefaultRootWindow)(Display *);
  int (*QueryTree)(Display *, XWindow, XWindow *, XWindow *, XWindow **,
                   unsigned *);
  int (*Free)(void *);
  XAtom (*InternAtom)(Display *, const char *, int);
  int (*GetWindowProperty)(Display *, XWindow, XAtom, long, long, int, XAtom,
                           XAtom *, int *, unsigned long *, unsigned long *,
                           unsigned char **);
  int (*GetWindowAttributes)(Display *, XWindow, XWindowAttributes *);
  int (*TranslateCoordinates)(Display *, XWindow, XWindow, int, int, int *,
                              int *, XWindow *);
  XImage *(*GetImage)(Display *, XWindow, int, int, unsigned, unsigned,
                      unsigned long, int);
  int (*Sync)(Display *, int);
  int (*Flush)(Display *);
  void *(*SetErrorHandler)(int (*)(Display *, void *));
  void *(*SetIOErrorHandler)(int (*)(Display *));
  XKeyCode (*KeysymToKeycode)(Display *, XKeySym);
  int (*DisplayKeycodes)(Display *, int *, int *);
  XKeySym *(*GetKeyboardMapping)(Display *, XKeyCode, int, int *);
  int (*ChangeKeyboardMapping)(Display *, int, int, XKeySym *, int);
  int (*SetInputFocus)(Display *, XWindow, int, unsigned long);
  int (*GetInputFocus)(Display *, XWindow *, int *);
  int (*RaiseWindow)(Display *, XWindow);
  int (*TestFakeMotionEvent)(Display *, int, int, int, unsigned long);
  int (*TestFakeButtonEvent)(Display *, unsigned, int, unsigned long);
  int (*TestFakeKeyEvent)(Display *, unsigned, int, unsigned long);
} X;

static bool cc_load_x11(void) {
  static bool loaded = false;
  if (loaded) {
    return true;
  }
  void *x11 = dlopen("libX11.so.6", RTLD_NOW | RTLD_LOCAL);
  void *xtst = dlopen("libXtst.so.6", RTLD_NOW | RTLD_LOCAL);
  if (x11 == NULL || xtst == NULL) {
    return false;
  }
#define CC_SYM(lib, field, name)                       \
  *(void **)(&X.field) = dlsym(lib, name);             \
  if (X.field == NULL) {                               \
    return false;                                      \
  }
  CC_SYM(x11, OpenDisplay, "XOpenDisplay")
  CC_SYM(x11, CloseDisplay, "XCloseDisplay")
  CC_SYM(x11, DefaultRootWindow, "XDefaultRootWindow")
  CC_SYM(x11, QueryTree, "XQueryTree")
  CC_SYM(x11, Free, "XFree")
  CC_SYM(x11, InternAtom, "XInternAtom")
  CC_SYM(x11, GetWindowProperty, "XGetWindowProperty")
  CC_SYM(x11, GetWindowAttributes, "XGetWindowAttributes")
  CC_SYM(x11, TranslateCoordinates, "XTranslateCoordinates")
  CC_SYM(x11, GetImage, "XGetImage")
  CC_SYM(x11, Sync, "XSync")
  CC_SYM(x11, Flush, "XFlush")
  CC_SYM(x11, SetErrorHandler, "XSetErrorHandler")
  CC_SYM(x11, SetIOErrorHandler, "XSetIOErrorHandler")
  CC_SYM(x11, KeysymToKeycode, "XKeysymToKeycode")
  CC_SYM(x11, DisplayKeycodes, "XDisplayKeycodes")
  CC_SYM(x11, GetKeyboardMapping, "XGetKeyboardMapping")
  CC_SYM(x11, ChangeKeyboardMapping, "XChangeKeyboardMapping")
  CC_SYM(x11, SetInputFocus, "XSetInputFocus")
  CC_SYM(x11, GetInputFocus, "XGetInputFocus")
  CC_SYM(x11, RaiseWindow, "XRaiseWindow")
  CC_SYM(xtst, TestFakeMotionEvent, "XTestFakeMotionEvent")
  CC_SYM(xtst, TestFakeButtonEvent, "XTestFakeButtonEvent")
  CC_SYM(xtst, TestFakeKeyEvent, "XTestFakeKeyEvent")
#undef CC_SYM
  loaded = true;
  return true;
}

/* ── Errors and strings ─────────────────────────────────────────────────── */

static int32_t cc_fail(char **out_error, int32_t code, const char *format, ...) {
  if (out_error != NULL) {
    va_list args;
    va_start(args, format);
    char *message = NULL;
    if (vasprintf(&message, format, args) >= 0) {
      *out_error = message;
    }
    va_end(args);
  }
  return code;
}

typedef struct {
  char *data;
  size_t length, capacity;
} CcText;

static void cc_put(CcText *text, const char *bytes, size_t length) {
  if (text->length + length + 1 > text->capacity) {
    size_t capacity = (text->length + length + 1) * 2;
    char *grown = realloc(text->data, capacity);
    if (grown == NULL) {
      return;
    }
    text->data = grown;
    text->capacity = capacity;
  }
  memcpy(text->data + text->length, bytes, length);
  text->length += length;
  text->data[text->length] = '\0';
}

static void cc_putf(CcText *text, const char *format, ...) {
  char buffer[128];
  va_list args;
  va_start(args, format);
  int written = vsnprintf(buffer, sizeof(buffer), format, args);
  va_end(args);
  if (written > 0) {
    cc_put(text, buffer, (size_t)written < sizeof(buffer) ? (size_t)written
                                                          : sizeof(buffer) - 1);
  }
}

static void cc_put_json_string(CcText *text, const char *value) {
  cc_put(text, "\"", 1);
  for (const unsigned char *c = (const unsigned char *)value; *c != 0; c++) {
    if (*c == '"' || *c == '\\') {
      cc_putf(text, "\\%c", *c);
    } else if (*c < 0x20) {
      cc_putf(text, "\\u%04x", *c);
    } else {
      cc_put(text, (const char *)c, 1);
    }
  }
  cc_put(text, "\"", 1);
}

/* ── The process tree ───────────────────────────────────────────────────── */

typedef struct {
  int pid, ppid;
} CcProc;

typedef struct {
  int *pids;
  size_t count;
} CcTree;

static size_t cc_read_procs(CcProc **out) {
  DIR *dir = opendir("/proc");
  if (dir == NULL) {
    return 0;
  }
  size_t count = 0, capacity = 512;
  CcProc *procs = malloc(capacity * sizeof(CcProc));
  struct dirent *entry;
  while (procs != NULL && (entry = readdir(dir)) != NULL) {
    if (!isdigit((unsigned char)entry->d_name[0])) {
      continue;
    }
    char path[300], line[512];
    snprintf(path, sizeof(path), "/proc/%s/stat", entry->d_name);
    FILE *file = fopen(path, "r");
    if (file == NULL) {
      continue;
    }
    size_t got = fread(line, 1, sizeof(line) - 1, file);
    fclose(file);
    line[got] = '\0';
    /* comm may hold spaces and parentheses, so parse after the LAST ')'. */
    char *close = strrchr(line, ')');
    int ppid = 0;
    if (close == NULL || sscanf(close + 1, " %*c %d", &ppid) != 1) {
      continue;
    }
    if (count == capacity) {
      capacity *= 2;
      CcProc *grown = realloc(procs, capacity * sizeof(CcProc));
      if (grown == NULL) {
        break;
      }
      procs = grown;
    }
    procs[count].pid = atoi(entry->d_name);
    procs[count].ppid = ppid;
    count++;
  }
  closedir(dir);
  *out = procs;
  return count;
}

static bool cc_tree_has(const CcTree *tree, int pid) {
  for (size_t i = 0; i < tree->count; i++) {
    if (tree->pids[i] == pid) {
      return true;
    }
  }
  return false;
}

/* `pids` plus descendants. False for a root at PID 1, this process or an
 * ancestor: those trees hold every other app, so ownership would mean nothing. */
static bool cc_tree_build(const int32_t *pids, int32_t count, CcTree *tree) {
  CcProc *procs = NULL;
  size_t total = cc_read_procs(&procs);
  if (procs == NULL || total == 0) {
    free(procs);
    return false;
  }
  tree->pids = malloc((total + (size_t)count) * sizeof(int));
  tree->count = 0;
  if (tree->pids == NULL) {
    free(procs);
    return false;
  }
  for (int32_t i = 0; i < count; i++) {
    if (pids[i] <= 1) {
      goto refused;
    }
    tree->pids[tree->count++] = pids[i];
  }
  for (int walk = getpid(); walk > 1;) {
    if (cc_tree_has(tree, walk)) {
      goto refused;
    }
    int parent = 0;
    for (size_t i = 0; i < total; i++) {
      if (procs[i].pid == walk) {
        parent = procs[i].ppid;
        break;
      }
    }
    walk = parent;
  }
  for (bool grew = true; grew;) {
    grew = false;
    for (size_t i = 0; i < total; i++) {
      if (!cc_tree_has(tree, procs[i].pid) &&
          cc_tree_has(tree, procs[i].ppid)) {
        tree->pids[tree->count++] = procs[i].pid;
        grew = true;
      }
    }
  }
  free(procs);
  return true;
refused:
  free(procs);
  free(tree->pids);
  tree->pids = NULL;
  return false;
}

/* ── Sessions ───────────────────────────────────────────────────────────── */

typedef struct {
  Display *dpy;
  XWindow root;
  CcTree tree;
  XAtom wm_pid;
  XWindow window;
  int x, y, width, height; /* the window, root-relative */
  char **out_error;
} CcSession;

typedef int32_t (*CcOperation)(CcSession *, void *);

/* Xlib's default handlers exit the process, which here is the whole server. A
 * protocol error is expected (a window can vanish mid-call); a lost connection
 * unwinds to cc_run. Handlers are process-global, so calls are serialized. */
static pthread_mutex_t cc_lock = PTHREAD_MUTEX_INITIALIZER;
static jmp_buf cc_connection_lost;

static int cc_on_x_error(Display *dpy, void *event) {
  (void)dpy;
  (void)event;
  return 0;
}

static int cc_on_x_io_error(Display *dpy) {
  (void)dpy;
  longjmp(cc_connection_lost, 1);
  return 0;
}

static int cc_window_pid(CcSession *s, XWindow window) {
  XAtom type = 0;
  int format = 0;
  unsigned long items = 0, after = 0;
  unsigned char *data = NULL;
  int pid = 0;
  if (X.GetWindowProperty(s->dpy, window, s->wm_pid, 0, 1, 0, kXaCardinal, &type,
                          &format, &items, &after, &data) == 0 &&
      data != NULL) {
    if (items == 1 && format == 32) {
      pid = (int)*(unsigned long *)data;
    }
    X.Free(data);
  }
  return pid;
}

static bool cc_read_geometry(CcSession *s, XWindow window, XWindowAttributes *a,
                             int *x, int *y) {
  XWindow child;
  return X.GetWindowAttributes(s->dpy, window, a) != 0 &&
         X.TranslateCoordinates(s->dpy, window, s->root, 0, 0, x, y, &child) != 0;
}

/* The chokepoint: every capture and input call resolves its window here. */
static int32_t cc_resolve(CcSession *s, uint64_t window_id) {
  XWindowAttributes attributes;
  if (window_id == 0 ||
      !cc_read_geometry(s, (XWindow)window_id, &attributes, &s->x, &s->y)) {
    return cc_fail(s->out_error, CC_WINDOW_ERR_NOT_FOUND,
                   "Window %llu no longer exists.",
                   (unsigned long long)window_id);
  }
  int pid = cc_window_pid(s, (XWindow)window_id);
  if (pid == 0 || !cc_tree_has(&s->tree, pid)) {
    return cc_fail(s->out_error, CC_WINDOW_ERR_NOT_OWNED,
                   "Window %llu does not belong to this app's processes.",
                   (unsigned long long)window_id);
  }
  s->window = (XWindow)window_id;
  s->width = attributes.width;
  s->height = attributes.height;
  return CC_WINDOW_OK;
}

static int32_t cc_run(const int32_t *pids, int32_t count, const char *display,
                      uint64_t window_id, CcOperation operation, void *argument,
                      char **out_error) {
  if (pids == NULL || count <= 0) {
    return cc_fail(out_error, CC_WINDOW_ERR_INVALID,
                   "An empty process set owns no windows.");
  }
  pthread_mutex_lock(&cc_lock);
  int32_t status;
  CcSession s;
  memset(&s, 0, sizeof(s));
  s.out_error = out_error;
  if (!cc_load_x11()) {
    status = cc_fail(out_error, CC_WINDOW_ERR_UNSUPPORTED,
                     "Desktop apps need libX11 and libXtst on this host.");
    goto unlock;
  }
  if (!cc_tree_build(pids, count, &s.tree)) {
    status = cc_fail(out_error, CC_WINDOW_ERR_INVALID,
                     "The process set must name launched apps, not this "
                     "server or anything above it.");
    goto unlock;
  }
  X.SetErrorHandler(cc_on_x_error);
  X.SetIOErrorHandler(cc_on_x_io_error);
  s.dpy = X.OpenDisplay(display);
  if (s.dpy == NULL) {
    status = cc_fail(out_error, CC_WINDOW_ERR_UNSUPPORTED,
                     "Cannot open X display \"%s\". Desktop apps need a GUI "
                     "session or a private Xvfb.",
                     display != NULL ? display : "(unset)");
    goto free_tree;
  }
  if (setjmp(cc_connection_lost) != 0) {
    /* The connection is gone and Xlib's state with it: close nothing. */
    status = cc_fail(out_error, CC_WINDOW_ERR_NOT_FOUND,
                     "The X server went away.");
    goto free_tree;
  }
  s.root = X.DefaultRootWindow(s.dpy);
  s.wm_pid = X.InternAtom(s.dpy, "_NET_WM_PID", 0);
  status = window_id == 0 ? CC_WINDOW_OK : cc_resolve(&s, window_id);
  if (status == CC_WINDOW_OK) {
    status = operation(&s, argument);
  }
  X.Sync(s.dpy, 0);
  X.CloseDisplay(s.dpy);
free_tree:
  free(s.tree.pids);
unlock:
  pthread_mutex_unlock(&cc_lock);
  return status;
}

int32_t cc_window_abi_version(void) { return CC_WINDOW_ABI; }

void cc_window_free(void *ptr) { free(ptr); }

/* ── Listing ────────────────────────────────────────────────────────────── */

static void cc_put_title(CcSession *s, CcText *json, XWindow window) {
  static const char *const names[] = {"_NET_WM_NAME", "WM_NAME"};
  for (size_t i = 0; i < 2; i++) {
    XAtom type = 0;
    int format = 0;
    unsigned long items = 0, after = 0;
    unsigned char *data = NULL;
    XAtom name = X.InternAtom(s->dpy, names[i], 0);
    /* AnyPropertyType: _NET_WM_NAME is UTF8_STRING, WM_NAME is STRING. */
    if (X.GetWindowProperty(s->dpy, window, name, 0, 1024, 0, 0, &type, &format,
                            &items, &after, &data) == 0 &&
        data != NULL) {
      bool usable = format == 8 && items > 0;
      if (usable) {
        cc_put_json_string(json, (const char *)data);
      }
      X.Free(data);
      if (usable) {
        return;
      }
    }
  }
  cc_put(json, "\"\"", 2);
}

/* Top first: XQueryTree answers bottom to top. A reparenting window manager
 * nests clients inside frames, so an unowned window is searched, not skipped. */
static void cc_collect(CcSession *s, XWindow parent, int depth, CcText *json,
                       bool *first) {
  XWindow root, up, *children = NULL;
  unsigned count = 0;
  if (depth > 4 ||
      X.QueryTree(s->dpy, parent, &root, &up, &children, &count) == 0) {
    return;
  }
  for (unsigned i = count; i-- > 0;) {
    XWindow window = children[i];
    int pid = cc_window_pid(s, window);
    XWindowAttributes a;
    int x = 0, y = 0;
    if (pid == 0 || !cc_tree_has(&s->tree, pid)) {
      cc_collect(s, window, depth + 1, json, first);
      continue;
    }
    if (!cc_read_geometry(s, window, &a, &x, &y) || a.width < 8 ||
        a.height < 8) {
      continue;
    }
    cc_putf(json, "%s{\"id\":%lu,\"pid\":%d,\"title\":", *first ? "" : ",",
            window, pid);
    cc_put_title(s, json, window);
    cc_putf(json, ",\"x\":%d,\"y\":%d,\"width\":%d,\"height\":%d", x, y, a.width,
            a.height);
    cc_putf(json, ",\"on_screen\":%s}",
            a.map_state == kIsViewable ? "true" : "false");
    *first = false;
  }
  if (children != NULL) {
    X.Free(children);
  }
}

static int32_t cc_list(CcSession *s, void *argument) {
  CcText *json = argument;
  bool first = true;
  cc_put(json, "[", 1);
  cc_collect(s, s->root, 0, json, &first);
  cc_put(json, "]", 1);
  return CC_WINDOW_OK;
}

int32_t cc_window_list(const int32_t *pids, int32_t pid_count,
                       const char *display, char **out_json, char **out_error) {
  if (out_json == NULL) {
    return cc_fail(out_error, CC_WINDOW_ERR_INVALID,
                   "list needs an output string.");
  }
  CcText json = {0};
  int32_t status =
      cc_run(pids, pid_count, display, 0, cc_list, &json, out_error);
  if (status == CC_WINDOW_OK) {
    *out_json = json.data;
  } else {
    free(json.data);
  }
  return status;
}

/* ── Capture ────────────────────────────────────────────────────────────── */

static uint32_t cc_crc_table[256];

static uint32_t cc_crc(uint32_t crc, const uint8_t *bytes, size_t length) {
  if (cc_crc_table[1] == 0) {
    for (uint32_t n = 0; n < 256; n++) {
      uint32_t c = n;
      for (int k = 0; k < 8; k++) {
        c = (c & 1) ? 0xedb88320u ^ (c >> 1) : c >> 1;
      }
      cc_crc_table[n] = c;
    }
  }
  for (size_t i = 0; i < length; i++) {
    crc = cc_crc_table[(crc ^ bytes[i]) & 0xff] ^ (crc >> 8);
  }
  return crc;
}

static void cc_be32(uint8_t *out, uint32_t value) {
  out[0] = (uint8_t)(value >> 24);
  out[1] = (uint8_t)(value >> 16);
  out[2] = (uint8_t)(value >> 8);
  out[3] = (uint8_t)value;
}

static uint8_t *cc_chunk(uint8_t *out, const char *type, const uint8_t *data,
                         uint32_t length) {
  cc_be32(out, length);
  memcpy(out + 4, type, 4);
  if (length > 0) {
    memcpy(out + 8, data, length);
  }
  cc_be32(out + 8 + length, ~cc_crc(0xffffffffu, out + 4, length + 4));
  return out + 12 + length;
}

/* zlib stream of `raw`: deflated when libz is present, stored blocks when not.
 * Stored is valid PNG, only larger, and libz is on any system with a desktop. */
static uint8_t *cc_zlib(const uint8_t *raw, size_t length, size_t *out_length) {
  static int (*compress2)(uint8_t *, unsigned long *, const uint8_t *,
                          unsigned long, int) = NULL;
  static unsigned long (*compress_bound)(unsigned long) = NULL;
  static bool tried = false;
  if (!tried) {
    tried = true;
    void *z = dlopen("libz.so.1", RTLD_NOW | RTLD_LOCAL);
    if (z != NULL) {
      *(void **)(&compress2) = dlsym(z, "compress2");
      *(void **)(&compress_bound) = dlsym(z, "compressBound");
    }
  }
  if (compress2 != NULL && compress_bound != NULL) {
    unsigned long bound = compress_bound(length);
    uint8_t *out = malloc(bound);
    if (out != NULL && compress2(out, &bound, raw, length, 3) == 0) {
      *out_length = bound;
      return out;
    }
    free(out);
  }
  size_t blocks = length / 65535 + 1;
  uint8_t *out = malloc(length + blocks * 5 + 6);
  if (out == NULL) {
    return NULL;
  }
  uint8_t *cursor = out;
  *cursor++ = 0x78;
  *cursor++ = 0x01;
  uint32_t a = 1, b = 0;
  for (size_t i = 0; i < length; i++) {
    a = (a + raw[i]) % 65521;
    b = (b + a) % 65521;
  }
  size_t offset = 0;
  do {
    size_t take = length - offset > 65535 ? 65535 : length - offset;
    *cursor++ = offset + take == length ? 1 : 0;
    *cursor++ = (uint8_t)take;
    *cursor++ = (uint8_t)(take >> 8);
    *cursor++ = (uint8_t)~take;
    *cursor++ = (uint8_t)(~take >> 8);
    memcpy(cursor, raw + offset, take);
    cursor += take;
    offset += take;
  } while (offset < length);
  cc_be32(cursor, (b << 16) | a);
  *out_length = (size_t)(cursor + 4 - out);
  return out;
}

/* 8-bit RGB PNG, with the Up filter: UI rows repeat, so it compresses well. */
static uint8_t *cc_png(const uint8_t *rgb, int width, int height,
                       int64_t *out_length) {
  size_t stride = (size_t)width * 3;
  uint8_t *filtered = malloc((stride + 1) * (size_t)height);
  if (filtered == NULL) {
    return NULL;
  }
  for (int y = 0; y < height; y++) {
    uint8_t *row = filtered + (size_t)y * (stride + 1);
    const uint8_t *current = rgb + (size_t)y * stride;
    row[0] = y == 0 ? 0 : 2;
    for (size_t i = 0; i < stride; i++) {
      row[1 + i] =
          y == 0 ? current[i] : (uint8_t)(current[i] - current[i - stride]);
    }
  }
  size_t packed_length = 0;
  uint8_t *packed =
      cc_zlib(filtered, (stride + 1) * (size_t)height, &packed_length);
  free(filtered);
  if (packed == NULL) {
    return NULL;
  }
  uint8_t *png = malloc(packed_length + 57);
  if (png != NULL) {
    static const uint8_t signature[8] = {0x89, 'P',  'N',  'G',
                                         0x0d, 0x0a, 0x1a, 0x0a};
    uint8_t header[13];
    cc_be32(header, (uint32_t)width);
    cc_be32(header + 4, (uint32_t)height);
    header[8] = 8;
    header[9] = 2;
    header[10] = header[11] = header[12] = 0;
    memcpy(png, signature, 8);
    uint8_t *cursor = cc_chunk(png + 8, "IHDR", header, 13);
    cursor = cc_chunk(cursor, "IDAT", packed, (uint32_t)packed_length);
    cursor = cc_chunk(cursor, "IEND", NULL, 0);
    *out_length = (int64_t)(cursor - png);
  }
  free(packed);
  return png;
}

static int cc_mask_shift(unsigned long mask) {
  int shift = 0;
  while (mask != 0 && (mask & 1) == 0) {
    mask >>= 1;
    shift++;
  }
  return shift;
}

typedef struct {
  int32_t max_width, max_height, width, height;
  uint8_t *png;
  int64_t length;
} CcCapture;

static int32_t cc_capture(CcSession *s, void *argument) {
  CcCapture *capture = argument;
  XImage *image = X.GetImage(s->dpy, s->window, 0, 0, (unsigned)s->width,
                             (unsigned)s->height, ~0UL, kZPixmap);
  if (image == NULL) {
    return cc_fail(s->out_error, CC_WINDOW_ERR_OFF_DISPLAY,
                   "The window is unmapped or off the display, so it cannot "
                   "be captured.");
  }
  if (image->bits_per_pixel != 32 && image->bits_per_pixel != 24) {
    int bits = image->bits_per_pixel;
    image->f.destroy_image(image);
    return cc_fail(s->out_error, CC_WINDOW_ERR_UNSUPPORTED,
                   "%d-bit X visuals are not supported.", bits);
  }
  double fit = 1;
  if (capture->max_width > 0 && s->width * fit > capture->max_width) {
    fit = (double)capture->max_width / s->width;
  }
  if (capture->max_height > 0 && s->height * fit > capture->max_height) {
    fit = (double)capture->max_height / s->height;
  }
  int width = (int)(s->width * fit), height = (int)(s->height * fit);
  width = width < 1 ? 1 : width;
  height = height < 1 ? 1 : height;
  uint8_t *rgb = malloc((size_t)width * (size_t)height * 3);
  if (rgb == NULL) {
    image->f.destroy_image(image);
    return cc_fail(s->out_error, CC_WINDOW_ERR_FAILED, "Out of memory.");
  }
  int red = cc_mask_shift(image->red_mask);
  int green = cc_mask_shift(image->green_mask);
  int blue = cc_mask_shift(image->blue_mask);
  int bytes = image->bits_per_pixel / 8;
  /* Area average: nearest-neighbour drops the 1px strokes text is made of. */
  for (int y = 0; y < height; y++) {
    int y0 = (int)((long)y * s->height / height);
    int y1 = (int)((long)(y + 1) * s->height / height);
    y1 = y1 <= y0 ? y0 + 1 : y1;
    for (int x = 0; x < width; x++) {
      int x0 = (int)((long)x * s->width / width);
      int x1 = (int)((long)(x + 1) * s->width / width);
      x1 = x1 <= x0 ? x0 + 1 : x1;
      unsigned long r = 0, g = 0, b = 0, n = 0;
      for (int sy = y0; sy < y1; sy++) {
        const uint8_t *row =
            (const uint8_t *)image->data + (size_t)sy * image->bytes_per_line;
        for (int sx = x0; sx < x1; sx++) {
          uint32_t pixel = 0;
          memcpy(&pixel, row + (size_t)sx * bytes, (size_t)bytes);
          r += (pixel >> red) & 0xff;
          g += (pixel >> green) & 0xff;
          b += (pixel >> blue) & 0xff;
          n++;
        }
      }
      uint8_t *out = rgb + ((size_t)y * width + x) * 3;
      out[0] = (uint8_t)(r / n);
      out[1] = (uint8_t)(g / n);
      out[2] = (uint8_t)(b / n);
    }
  }
  image->f.destroy_image(image);
  capture->png = cc_png(rgb, width, height, &capture->length);
  free(rgb);
  if (capture->png == NULL) {
    return cc_fail(s->out_error, CC_WINDOW_ERR_FAILED,
                   "Could not encode the window as PNG.");
  }
  capture->width = width;
  capture->height = height;
  return CC_WINDOW_OK;
}

int32_t cc_window_capture(const int32_t *pids, int32_t pid_count,
                          const char *display, uint64_t window_id,
                          int32_t max_width, int32_t max_height,
                          uint8_t **out_png, int64_t *out_len,
                          int32_t *out_width, int32_t *out_height,
                          char **out_error) {
  if (out_png == NULL || out_len == NULL || window_id == 0) {
    return cc_fail(out_error, CC_WINDOW_ERR_INVALID,
                   "Capture needs a window and an output buffer.");
  }
  CcCapture capture = {.max_width = max_width, .max_height = max_height};
  int32_t status = cc_run(pids, pid_count, display, window_id, cc_capture,
                          &capture, out_error);
  if (status == CC_WINDOW_OK) {
    *out_png = capture.png;
    *out_len = capture.length;
    if (out_width != NULL) {
      *out_width = capture.width;
    }
    if (out_height != NULL) {
      *out_height = capture.height;
    }
  }
  return status;
}

/* ── Input ──────────────────────────────────────────────────────────────── */

/* Whether the topmost window at a root point belongs to the tree. XTEST input
 * goes to whatever is on top, so that, not the target, is what must be owned. */
static bool cc_point_is_owned(CcSession *s, int x, int y) {
  XWindow current = s->root;
  bool owned = false;
  for (int depth = 0; depth < 8; depth++) {
    XWindow child = 0;
    int cx = 0, cy = 0;
    if (X.TranslateCoordinates(s->dpy, s->root, current, x, y, &cx, &cy,
                               &child) == 0 ||
        child == 0) {
      break;
    }
    int pid = cc_window_pid(s, child);
    if (pid != 0) {
      owned = cc_tree_has(&s->tree, pid);
    }
    current = child;
  }
  return owned;
}

static const struct {
  uint32_t bit;
  XKeySym keysym;
} kCcModifiers[] = {
    {CC_WINDOW_MOD_SHIFT, 0xffe1},
    {CC_WINDOW_MOD_CTRL, 0xffe3},
    {CC_WINDOW_MOD_ALT, 0xffe9},
    {CC_WINDOW_MOD_META, 0xffeb},
};

static void cc_press_modifiers(CcSession *s, uint32_t modifiers, int down) {
  for (size_t i = 0; i < 4; i++) {
    if (modifiers & kCcModifiers[i].bit) {
      XKeyCode code = X.KeysymToKeycode(s->dpy, kCcModifiers[i].keysym);
      if (code != 0) {
        X.TestFakeKeyEvent(s->dpy, code, down, 0);
      }
    }
  }
}

static int32_t cc_aim(CcSession *s, double x, double y, int *root_x,
                      int *root_y) {
  if (!(x >= 0 && y >= 0 && x < s->width && y < s->height)) {
    return cc_fail(s->out_error, CC_WINDOW_ERR_OUT_OF_BOUNDS,
                   "(%.0f, %.0f) is outside the %dx%d window.", x, y, s->width,
                   s->height);
  }
  *root_x = s->x + (int)x;
  *root_y = s->y + (int)y;
  X.RaiseWindow(s->dpy, s->window);
  X.Sync(s->dpy, 0);
  if (!cc_point_is_owned(s, *root_x, *root_y)) {
    return cc_fail(s->out_error, CC_WINDOW_ERR_NOT_OWNED,
                   "Another app's window covers (%.0f, %.0f), so input would "
                   "land on it.",
                   x, y);
  }
  return CC_WINDOW_OK;
}

typedef struct {
  int32_t phase, button;
  double x, y;
  int32_t dx, dy;
  uint32_t modifiers;
  bool scroll;
} CcPointer;

static void cc_click_wheel(CcSession *s, unsigned button, int times) {
  for (int i = 0; i < times; i++) {
    X.TestFakeButtonEvent(s->dpy, button, 1, 0);
    X.TestFakeButtonEvent(s->dpy, button, 0, 0);
  }
}

static int32_t cc_pointer(CcSession *s, void *argument) {
  CcPointer *pointer = argument;
  int x = 0, y = 0;
  int32_t status = cc_aim(s, pointer->x, pointer->y, &x, &y);
  if (status != CC_WINDOW_OK) {
    return status;
  }
  X.TestFakeMotionEvent(s->dpy, -1, x, y, 0);
  if (pointer->scroll) {
    cc_press_modifiers(s, pointer->modifiers, 1);
    cc_click_wheel(s, pointer->dy > 0 ? 4 : 5, abs(pointer->dy));
    cc_click_wheel(s, pointer->dx > 0 ? 6 : 7, abs(pointer->dx));
    cc_press_modifiers(s, pointer->modifiers, 0);
    return CC_WINDOW_OK;
  }
  unsigned button = pointer->button == CC_WINDOW_BUTTON_RIGHT    ? 3
                    : pointer->button == CC_WINDOW_BUTTON_MIDDLE ? 2
                                                                 : 1;
  if (pointer->phase == CC_WINDOW_POINTER_DOWN) {
    cc_press_modifiers(s, pointer->modifiers, 1);
    X.TestFakeButtonEvent(s->dpy, button, 1, 0);
  } else if (pointer->phase == CC_WINDOW_POINTER_UP) {
    X.TestFakeButtonEvent(s->dpy, button, 0, 0);
    cc_press_modifiers(s, pointer->modifiers, 0);
  }
  return CC_WINDOW_OK;
}

static bool cc_mode_ok(int32_t mode) {
  return mode == CC_WINDOW_MODE_BACKGROUND || mode == CC_WINDOW_MODE_FOREGROUND;
}

int32_t cc_window_mouse(const int32_t *pids, int32_t pid_count,
                        const char *display, uint64_t window_id, int32_t mode,
                        int32_t phase, int32_t button, double x, double y,
                        int32_t click_count, uint32_t modifiers,
                        char **out_error) {
  (void)click_count; /* X clients derive it from the timing of the presses. */
  if (!cc_mode_ok(mode) || phase < CC_WINDOW_POINTER_MOVE ||
      phase > CC_WINDOW_POINTER_DRAG || window_id == 0) {
    return cc_fail(out_error, CC_WINDOW_ERR_INVALID,
                   "Invalid pointer event.");
  }
  CcPointer pointer = {.phase = phase,
                       .button = button,
                       .x = x,
                       .y = y,
                       .modifiers = modifiers};
  return cc_run(pids, pid_count, display, window_id, cc_pointer, &pointer,
                out_error);
}

int32_t cc_window_scroll(const int32_t *pids, int32_t pid_count,
                         const char *display, uint64_t window_id, int32_t mode,
                         double x, double y, int32_t dx, int32_t dy,
                         uint32_t modifiers, char **out_error) {
  if (!cc_mode_ok(mode) || window_id == 0) {
    return cc_fail(out_error, CC_WINDOW_ERR_INVALID, "Invalid scroll event.");
  }
  CcPointer pointer = {.x = x,
                       .y = y,
                       .dx = dx,
                       .dy = dy,
                       .modifiers = modifiers,
                       .scroll = true};
  return cc_run(pids, pid_count, display, window_id, cc_pointer, &pointer,
                out_error);
}

static const struct {
  const char *name;
  XKeySym keysym;
} kCcKeys[] = {
    {"ret", 0xff0d},          {"tab", 0xff09},        {"esc", 0xff1b},
    {"spc", 0x20},            {"backspace", 0xff08},  {"delete", 0xffff},
    {"insert", 0xff63},       {"home", 0xff50},       {"end", 0xff57},
    {"pgup", 0xff55},         {"pgdn", 0xff56},       {"left", 0xff51},
    {"up", 0xff52},           {"right", 0xff53},      {"down", 0xff54},
    {"menu", 0xff67},         {"print", 0xff61},      {"pause", 0xff13},
    {"scroll_lock", 0xff14},  {"caps_lock", 0xffe5},  {"num_lock", 0xff7f},
    {"kp_enter", 0xff8d},     {"minus", 0x2d},        {"equal", 0x3d},
    {"bracket_left", 0x5b},   {"bracket_right", 0x5d}, {"backslash", 0x5c},
    {"semicolon", 0x3b},      {"apostrophe", 0x27},   {"grave_accent", 0x60},
    {"comma", 0x2c},          {"dot", 0x2e},          {"slash", 0x2f},
    {"shift", 0xffe1},        {"shift_r", 0xffe2},    {"ctrl", 0xffe3},
    {"ctrl_r", 0xffe4},       {"alt", 0xffe9},        {"alt_r", 0xffea},
    {"meta_l", 0xffeb},       {"meta_r", 0xffec},
};

static XKeySym cc_keysym(const char *name) {
  if (name[0] != 0 && name[1] == 0 && isalnum((unsigned char)name[0])) {
    return (XKeySym)(unsigned char)name[0];
  }
  if (name[0] == 'f' && isdigit((unsigned char)name[1])) {
    int n = atoi(name + 1);
    return n >= 1 && n <= 12 ? 0xffbd + (XKeySym)n : 0;
  }
  for (size_t i = 0; i < sizeof(kCcKeys) / sizeof(kCcKeys[0]); i++) {
    if (strcmp(kCcKeys[i].name, name) == 0) {
      return kCcKeys[i].keysym;
    }
  }
  return 0;
}

typedef struct {
  const char *key;
  int32_t action;
  uint32_t modifiers;
} CcKeyEvent;

static void cc_focus(CcSession *s) {
  X.RaiseWindow(s->dpy, s->window);
  X.SetInputFocus(s->dpy, s->window, kRevertToParent, 0);
  X.Sync(s->dpy, 0);
}

/* XTEST keys go wherever X focus is, and on a real display that can move. A
 * subwindow carries no pid of its own, so walk up to the one that does. */
static bool cc_focus_is_owned(CcSession *s) {
  XWindow window = 0;
  int revert = 0;
  X.GetInputFocus(s->dpy, &window, &revert);
  while (window > kPointerRoot && window != s->root) {
    if (window == s->window) {
      return true;
    }
    int pid = cc_window_pid(s, window);
    if (pid != 0) {
      return cc_tree_has(&s->tree, pid);
    }
    XWindow root = 0, parent = 0, *children = NULL;
    unsigned count = 0;
    if (X.QueryTree(s->dpy, window, &root, &parent, &children, &count) == 0) {
      return false;
    }
    if (children != NULL) {
      X.Free(children);
    }
    window = parent;
  }
  return false;
}

static int32_t cc_key(CcSession *s, void *argument) {
  CcKeyEvent *event = argument;
  XKeySym keysym = cc_keysym(event->key);
  XKeyCode code = keysym == 0 ? 0 : X.KeysymToKeycode(s->dpy, keysym);
  if (code == 0) {
    return cc_fail(s->out_error, CC_WINDOW_ERR_INVALID, "Unknown key \"%s\".",
                   event->key);
  }
  cc_focus(s);
  if (!cc_focus_is_owned(s)) {
    return cc_fail(s->out_error, CC_WINDOW_ERR_NOT_OWNED,
                   "This app did not take keyboard focus, so the key would "
                   "reach another app.");
  }
  if (event->action != CC_WINDOW_KEY_UP) {
    cc_press_modifiers(s, event->modifiers, 1);
    X.TestFakeKeyEvent(s->dpy, code, 1, 0);
  }
  if (event->action != CC_WINDOW_KEY_DOWN) {
    X.TestFakeKeyEvent(s->dpy, code, 0, 0);
    cc_press_modifiers(s, event->modifiers, 0);
  }
  return CC_WINDOW_OK;
}

int32_t cc_window_key(const int32_t *pids, int32_t pid_count,
                      const char *display, uint64_t window_id, int32_t mode,
                      const char *key, int32_t action, uint32_t modifiers,
                      char **out_error) {
  if (!cc_mode_ok(mode) || key == NULL || window_id == 0) {
    return cc_fail(out_error, CC_WINDOW_ERR_INVALID, "Invalid key event.");
  }
  CcKeyEvent event = {.key = key, .action = action, .modifiers = modifiers};
  return cc_run(pids, pid_count, display, window_id, cc_key, &event, out_error);
}

/* Next code point of valid UTF-8, or -1. */
static long cc_next_rune(const unsigned char **cursor) {
  const unsigned char *c = *cursor;
  int extra = c[0] < 0x80            ? 0
              : (c[0] & 0xe0) == 0xc0 ? 1
              : (c[0] & 0xf0) == 0xe0 ? 2
              : (c[0] & 0xf8) == 0xf0 ? 3
                                      : -1;
  if (extra < 0) {
    return -1;
  }
  long rune = extra == 0 ? c[0] : c[0] & (0x3f >> extra);
  for (int i = 1; i <= extra; i++) {
    if ((c[i] & 0xc0) != 0x80) {
      return -1;
    }
    rune = (rune << 6) | (c[i] & 0x3f);
  }
  *cursor = c + extra + 1;
  return rune;
}

/* Literal text. A character on the current layout uses its real keycode, with
 * Shift for the second level. Anything else borrows an unused keycode for the
 * moment it is pressed, so the result does not depend on the layout.
 *
 * Remapping is the slow path on purpose: clients translate a press with the map
 * they hold when they READ it, so changing the map per character raced them and
 * typed neighbouring letters. Both levels are set, because a lone uppercase
 * keysym is read as a lower/upper pair and types lowercase unshifted. */
static int32_t cc_text(CcSession *s, void *argument) {
  const char *utf8 = argument;
  int min = 0, max = 0, per = 0;
  X.DisplayKeycodes(s->dpy, &min, &max);
  XKeySym *map = X.GetKeyboardMapping(s->dpy, (XKeyCode)min, max - min + 1, &per);
  if (map == NULL || per < 1) {
    return cc_fail(s->out_error, CC_WINDOW_ERR_FAILED,
                   "Could not read the keyboard map.");
  }
  int spare = 0;
  for (int code = max; code >= min && spare == 0; code--) {
    bool empty = true;
    for (int level = 0; level < per; level++) {
      empty = empty && map[(code - min) * per + level] == 0;
    }
    spare = empty ? code : 0;
  }
  XKeyCode shift = X.KeysymToKeycode(s->dpy, 0xffe1);
  int32_t status = CC_WINDOW_OK;
  bool remapped = false;
  cc_focus(s);
  for (const unsigned char *c = (const unsigned char *)utf8; *c != 0;) {
    long rune = cc_next_rune(&c);
    if (rune < 0) {
      status = cc_fail(s->out_error, CC_WINDOW_ERR_INVALID,
                       "Text must be valid UTF-8.");
      break;
    }
    if (!cc_focus_is_owned(s)) {
      status = cc_fail(s->out_error, CC_WINDOW_ERR_NOT_OWNED,
                       "Keyboard focus left this app while typing, so the rest "
                       "of the text was not sent.");
      break;
    }
    XKeySym keysym = rune == '\n'   ? 0xff0d
                     : rune == '\t' ? 0xff09
                     : rune < 0x100 ? (XKeySym)rune
                                    : 0x01000000UL | (XKeySym)rune;
    int found = 0, level = 0;
    int levels = per < 2 ? per : 2;
    for (int wanted = 0; wanted < levels && found == 0; wanted++) {
      for (int code = min; code <= max && found == 0; code++) {
        if (map[(code - min) * per + wanted] == keysym) {
          found = code;
          level = wanted;
        }
      }
    }
    if (found != 0 && (level == 0 || shift != 0)) {
      if (level == 1) {
        X.TestFakeKeyEvent(s->dpy, shift, 1, 0);
      }
      X.TestFakeKeyEvent(s->dpy, (unsigned)found, 1, 0);
      X.TestFakeKeyEvent(s->dpy, (unsigned)found, 0, 0);
      if (level == 1) {
        X.TestFakeKeyEvent(s->dpy, shift, 0, 0);
      }
      X.Sync(s->dpy, 0);
      continue;
    }
    if (spare == 0) {
      status = cc_fail(s->out_error, CC_WINDOW_ERR_FAILED,
                       "No spare keycode is free to type U+%04lX with.", rune);
      break;
    }
    XKeySym pair[2] = {keysym, keysym};
    X.ChangeKeyboardMapping(s->dpy, spare, 2, pair, 1);
    X.Sync(s->dpy, 0);
    remapped = true;
    usleep(20000);
    X.TestFakeKeyEvent(s->dpy, (unsigned)spare, 1, 0);
    X.TestFakeKeyEvent(s->dpy, (unsigned)spare, 0, 0);
    X.Sync(s->dpy, 0);
    usleep(20000);
  }
  if (remapped) {
    XKeySym none[2] = {0, 0};
    X.ChangeKeyboardMapping(s->dpy, spare, 2, none, 1);
  }
  X.Free(map);
  return status;
}

int32_t cc_window_text(const int32_t *pids, int32_t pid_count,
                       const char *display, uint64_t window_id, int32_t mode,
                       const char *utf8, char **out_error) {
  if (!cc_mode_ok(mode) || utf8 == NULL || window_id == 0) {
    return cc_fail(out_error, CC_WINDOW_ERR_INVALID, "Invalid text event.");
  }
  return cc_run(pids, pid_count, display, window_id, cc_text, (void *)utf8,
                out_error);
}

/* ── The accessibility tree (AT-SPI, itself optional) ───────────────────── *
 *
 * Walked in a forked child, for two reasons. libatspi aborts the process with
 * g_error when no accessibility bus answers, which in-process would take the
 * server down with one read_ui. And it initializes once per process from
 * $DISPLAY, while each app has its own X server and so its own bus.
 */

typedef struct {
  int x, y, width, height;
} CcRect;

static struct {
  int (*init)(void);
  void (*set_timeout)(int, int);
  void *(*get_desktop)(int);
  int (*child_count)(void *, void **);
  void *(*child_at)(void *, int, void **);
  char *(*name)(void *, void **);
  char *(*description)(void *, void **);
  char *(*role_name)(void *, void **);
  unsigned (*process_id)(void *, void **);
  void *(*component)(void *);
  CcRect *(*extents)(void *, int, void **);
  void *(*state_set)(void *);
  int (*state_contains)(void *, int);
  void (*unref)(void *);
  void (*gfree)(void *);
} A;

enum { kAtspiEnabled = 8, kAtspiFocused = 12, kAtspiCoordScreen = 0 };

static bool cc_load_atspi(void) {
  void *lib = dlopen("libatspi.so.0", RTLD_NOW | RTLD_GLOBAL);
  if (lib == NULL) {
    return false;
  }
#define CC_SYM(field, name)                            \
  *(void **)(&A.field) = dlsym(lib, name);             \
  if (A.field == NULL) {                               \
    return false;                                      \
  }
  CC_SYM(init, "atspi_init")
  CC_SYM(set_timeout, "atspi_set_timeout")
  CC_SYM(get_desktop, "atspi_get_desktop")
  CC_SYM(child_count, "atspi_accessible_get_child_count")
  CC_SYM(child_at, "atspi_accessible_get_child_at_index")
  CC_SYM(name, "atspi_accessible_get_name")
  CC_SYM(description, "atspi_accessible_get_description")
  CC_SYM(role_name, "atspi_accessible_get_role_name")
  CC_SYM(process_id, "atspi_accessible_get_process_id")
  CC_SYM(component, "atspi_accessible_get_component_iface")
  CC_SYM(extents, "atspi_component_get_extents")
  CC_SYM(state_set, "atspi_accessible_get_state_set")
  CC_SYM(state_contains, "atspi_state_set_contains")
  CC_SYM(unref, "g_object_unref")
  CC_SYM(gfree, "g_free")
#undef CC_SYM
  A.init();
  A.set_timeout(1000, 3000);
  return true;
}

typedef struct {
  int max_nodes, remaining;
  bool truncated;
  const char *display;
  CcText json;
} CcUi;

static void cc_put_field(CcText *json, const char *key, char *value) {
  if (value != NULL) {
    if (value[0] != 0) {
      cc_putf(json, ",\"%s\":", key);
      cc_put_json_string(json, value);
    }
    A.gfree(value);
  }
}

static void cc_ui_node(CcSession *s, CcUi *ui, void *node, int depth) {
  ui->remaining--;
  char *role = A.role_name(node, NULL);
  cc_put(&ui->json, "{\"role\":", 8);
  cc_put_json_string(&ui->json, role != NULL ? role : "");
  if (role != NULL) {
    A.gfree(role);
  }
  cc_put_field(&ui->json, "title", A.name(node, NULL));
  cc_put_field(&ui->json, "description", A.description(node, NULL));
  void *states = A.state_set(node);
  if (states != NULL) {
    cc_putf(&ui->json, ",\"enabled\":%s,\"focused\":%s",
            A.state_contains(states, kAtspiEnabled) ? "true" : "false",
            A.state_contains(states, kAtspiFocused) ? "true" : "false");
    A.unref(states);
  }
  void *component = A.component(node);
  if (component != NULL) {
    CcRect *rect = A.extents(component, kAtspiCoordScreen, NULL);
    if (rect != NULL) {
      cc_putf(&ui->json, ",\"x\":%d,\"y\":%d,\"width\":%d,\"height\":%d",
              rect->x - s->x, rect->y - s->y, rect->width, rect->height);
      A.gfree(rect);
    }
    A.unref(component);
  }
  int count = A.child_count(node, NULL);
  if (count > 0) {
    cc_put(&ui->json, ",\"children\":[", 13);
    bool first = true;
    for (int i = 0; i < count; i++) {
      if (ui->remaining <= 0 || depth >= 48) {
        ui->truncated = true;
        break;
      }
      void *child = A.child_at(node, i, NULL);
      if (child == NULL) {
        continue;
      }
      if (!first) {
        cc_put(&ui->json, ",", 1);
      }
      first = false;
      cc_ui_node(s, ui, child, depth + 1);
      A.unref(child);
    }
    cc_put(&ui->json, "]", 1);
  }
  cc_put(&ui->json, "}", 1);
}

/* The app's frame whose extents match the window, else its first frame. */
static void *cc_ui_frame(CcSession *s, void *app) {
  void *chosen = NULL;
  int count = A.child_count(app, NULL);
  for (int i = 0; i < count; i++) {
    void *frame = A.child_at(app, i, NULL);
    if (frame == NULL) {
      continue;
    }
    void *component = A.component(frame);
    CcRect *rect =
        component == NULL ? NULL : A.extents(component, kAtspiCoordScreen, NULL);
    bool match = rect != NULL && rect->x == s->x && rect->y == s->y &&
                 rect->width == s->width && rect->height == s->height;
    if (rect != NULL) {
      A.gfree(rect);
    }
    if (component != NULL) {
      A.unref(component);
    }
    if (match || chosen == NULL) {
      if (chosen != NULL) {
        A.unref(chosen);
      }
      chosen = frame;
      if (match) {
        break;
      }
    } else {
      A.unref(frame);
    }
  }
  return chosen;
}

/* Runs in the child. Fills ui->json, or leaves it empty for "no tree". */
static void cc_ui_walk(CcSession *s, CcUi *ui, int owner) {
  if (!cc_load_atspi()) {
    return;
  }
  void *desktop = A.get_desktop(0);
  int apps = desktop == NULL ? 0 : A.child_count(desktop, NULL);
  void *frame = NULL;
  for (int i = 0; i < apps && frame == NULL; i++) {
    void *app = A.child_at(desktop, i, NULL);
    if (app == NULL) {
      continue;
    }
    if ((int)A.process_id(app, NULL) == owner) {
      frame = cc_ui_frame(s, app);
    }
    A.unref(app);
  }
  if (frame == NULL) {
    return;
  }
  ui->remaining = ui->max_nodes;
  cc_put(&ui->json, "{\"root\":", 8);
  cc_ui_node(s, ui, frame, 0);
  cc_putf(&ui->json, ",\"truncated\":%s}", ui->truncated ? "true" : "false");
}

static void cc_ui_child(CcSession *s, CcUi *ui, int owner, int out) {
  struct rlimit no_core = {0, 0};
  setrlimit(RLIMIT_CORE, &no_core);
  int null = open("/dev/null", O_WRONLY);
  if (null >= 0) {
    dup2(null, STDERR_FILENO);
    dup2(null, STDOUT_FILENO);
  }
  if (ui->display != NULL) {
    setenv("DISPLAY", ui->display, 1);
  }
  cc_ui_walk(s, ui, owner);
  if (ui->json.length > 0) {
    /* The marker, not the exit status, says it finished: the Dart VM's own
     * waitpid(-1) thread may reap this child first. */
    size_t written = 0;
    while (written < ui->json.length) {
      ssize_t n =
          write(out, ui->json.data + written, ui->json.length - written);
      if (n <= 0) {
        _exit(1);
      }
      written += (size_t)n;
    }
    if (write(out, "\n", 1) != 1) {
      _exit(1);
    }
  }
  _exit(0);
}

static int32_t cc_read_ui(CcSession *s, void *argument) {
  CcUi *ui = argument;
  int owner = cc_window_pid(s, s->window);
  int pipe_fds[2];
  if (pipe(pipe_fds) != 0) {
    return cc_fail(s->out_error, CC_WINDOW_ERR_FAILED, "pipe failed.");
  }
  pid_t child = fork();
  if (child < 0) {
    close(pipe_fds[0]);
    close(pipe_fds[1]);
    return cc_fail(s->out_error, CC_WINDOW_ERR_FAILED, "fork failed.");
  }
  if (child == 0) {
    close(pipe_fds[0]);
    cc_ui_child(s, ui, owner, pipe_fds[1]);
  }
  close(pipe_fds[1]);
  bool timed_out = false;
  struct pollfd reader = {.fd = pipe_fds[0], .events = POLLIN};
  for (int waited = 0;;) {
    int ready = poll(&reader, 1, 250);
    if (ready > 0) {
      char buffer[4096];
      ssize_t got = read(pipe_fds[0], buffer, sizeof(buffer));
      if (got <= 0) {
        break;
      }
      cc_put(&ui->json, buffer, (size_t)got);
    } else if (ready == 0 && (waited += 250) >= 8000) {
      timed_out = true;
      break;
    } else if (ready < 0 && errno != EINTR) {
      break;
    }
  }
  close(pipe_fds[0]);
  kill(child, SIGKILL);
  waitpid(child, NULL, 0);
  if (timed_out) {
    return cc_fail(s->out_error, CC_WINDOW_ERR_TIMEOUT,
                   "The accessibility tree did not answer in time.");
  }
  if (ui->json.length == 0 || ui->json.data[ui->json.length - 1] != '\n') {
    return cc_fail(s->out_error, CC_WINDOW_ERR_UNSUPPORTED,
                   "This window exposes no accessibility tree. Use "
                   "screenshots instead.");
  }
  ui->json.data[--ui->json.length] = '\0';
  return CC_WINDOW_OK;
}

int32_t cc_window_read_ui(const int32_t *pids, int32_t pid_count,
                          const char *display, uint64_t window_id,
                          int32_t max_nodes, char **out_json,
                          char **out_error) {
  if (out_json == NULL || window_id == 0) {
    return cc_fail(out_error, CC_WINDOW_ERR_INVALID,
                   "read_ui needs a window and an output string.");
  }
  CcUi ui = {.max_nodes = max_nodes > 0 ? max_nodes : 500, .display = display};
  int32_t status =
      cc_run(pids, pid_count, display, window_id, cc_read_ui, &ui, out_error);
  if (status == CC_WINDOW_OK) {
    *out_json = ui.json.data;
  } else {
    free(ui.json.data);
  }
  return status;
}

/* ── Permissions ────────────────────────────────────────────────────────── */

int32_t cc_window_permissions(char **out_json, char **out_error) {
  if (out_json == NULL) {
    return cc_fail(out_error, CC_WINDOW_ERR_INVALID,
                   "permissions needs an output string.");
  }
  *out_json = strdup("{\"screen_capture\":\"not_required\","
                     "\"input\":\"not_required\","
                     "\"accessibility\":\"not_required\"}");
  return *out_json == NULL
             ? cc_fail(out_error, CC_WINDOW_ERR_FAILED, "Out of memory.")
             : CC_WINDOW_OK;
}

int32_t cc_window_open_settings(int32_t pane, char **out_error) {
  (void)pane;
  return cc_fail(out_error, CC_WINDOW_ERR_UNSUPPORTED,
                 "Linux needs no permission for app windows.");
}
