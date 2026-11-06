/*
 * cc_window: OS-level window access for desktop apps Control Center launched.
 *
 * It never talks to the app. Everything is keyed on a process tree: each call
 * takes the PIDs the caller launched, the library adds their descendants, and
 * a window whose owner is outside that set is refused HERE, in the native
 * layer, whichever caller asked. That is the "own windows only" rule. A root
 * at PID 1, at the calling process or at any of its ancestors is refused too:
 * those trees contain every other app.
 *
 * `display` names the X server on Linux and is ignored elsewhere. NULL means
 * the process's own $DISPLAY.
 *
 * Coordinates are relative to the window's top-left corner, in the units the
 * platform's window bounds use: points on macOS, pixels on Linux and Windows.
 * An input coordinate outside the window is refused, never clamped.
 *
 * Every out-string and out-buffer is owned by the caller and released with
 * cc_window_free. On failure *out_error, when non-NULL, holds the reason.
 * Status codes are ABI: extend, never renumber.
 */
#ifndef CC_WINDOW_H
#define CC_WINDOW_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32)
#define CC_WINDOW_API __declspec(dllexport)
#else
#define CC_WINDOW_API __attribute__((visibility("default")))
#endif

#define CC_WINDOW_ABI 1

enum {
  CC_WINDOW_OK = 0,
  CC_WINDOW_ERR_INVALID = 1,        /* malformed arguments, empty PID set */
  CC_WINDOW_ERR_NOT_OWNED = 2,      /* window or point outside the PID set */
  CC_WINDOW_ERR_NOT_FOUND = 3,      /* the window no longer exists */
  CC_WINDOW_ERR_PERMISSION = 4,     /* an OS permission is missing */
  CC_WINDOW_ERR_OFF_DISPLAY = 5,    /* hidden, minimized or off every display */
  CC_WINDOW_ERR_OUT_OF_BOUNDS = 6,  /* coordinate outside the window */
  CC_WINDOW_ERR_UNSUPPORTED = 7,    /* this host cannot do it */
  CC_WINDOW_ERR_FAILED = 8,         /* the OS call failed */
  CC_WINDOW_ERR_TIMEOUT = 9         /* the OS call did not answer in time */
};

/* Input modes. BACKGROUND leaves the cursor and focus alone. */
enum { CC_WINDOW_MODE_BACKGROUND = 0, CC_WINDOW_MODE_FOREGROUND = 1 };

enum {
  CC_WINDOW_POINTER_MOVE = 0,
  CC_WINDOW_POINTER_DOWN = 1,
  CC_WINDOW_POINTER_UP = 2,
  CC_WINDOW_POINTER_DRAG = 3 /* a move with `button` held */
};

enum {
  CC_WINDOW_BUTTON_LEFT = 0,
  CC_WINDOW_BUTTON_RIGHT = 1,
  CC_WINDOW_BUTTON_MIDDLE = 2
};

enum { CC_WINDOW_KEY_TAP = 0, CC_WINDOW_KEY_DOWN = 1, CC_WINDOW_KEY_UP = 2 };

/* Modifier bitmask. */
enum {
  CC_WINDOW_MOD_SHIFT = 1,
  CC_WINDOW_MOD_CTRL = 2,
  CC_WINDOW_MOD_ALT = 4,
  CC_WINDOW_MOD_META = 8 /* Command on macOS, Super elsewhere */
};

enum { CC_WINDOW_PANE_SCREEN_CAPTURE = 0, CC_WINDOW_PANE_ACCESSIBILITY = 1 };

CC_WINDOW_API int32_t cc_window_abi_version(void);
CC_WINDOW_API void cc_window_free(void *ptr);

/*
 * JSON array, frontmost first:
 * [{"id":1,"pid":2,"title":"…","x":0,"y":0,"width":1,"height":1,
 *   "on_screen":true}]
 */
CC_WINDOW_API int32_t cc_window_list(const int32_t *pids, int32_t pid_count,
                                     const char *display, char **out_json,
                                     char **out_error);

/*
 * PNG of one window, scaled down to fit max_width x max_height and never up.
 * A max of 0 leaves that axis unbounded. out_width/out_height report the
 * encoded image.
 */
CC_WINDOW_API int32_t cc_window_capture(const int32_t *pids, int32_t pid_count,
                                        const char *display, uint64_t window_id,
                                        int32_t max_width, int32_t max_height,
                                        uint8_t **out_png, int64_t *out_len,
                                        int32_t *out_width, int32_t *out_height,
                                        char **out_error);

CC_WINDOW_API int32_t cc_window_mouse(const int32_t *pids, int32_t pid_count,
                                      const char *display, uint64_t window_id,
                                      int32_t mode, int32_t phase,
                                      int32_t button, double x, double y,
                                      int32_t click_count, uint32_t modifiers,
                                      char **out_error);

/* dx/dy are wheel lines: positive dy scrolls up, positive dx scrolls left. */
CC_WINDOW_API int32_t cc_window_scroll(const int32_t *pids, int32_t pid_count,
                                       const char *display, uint64_t window_id,
                                       int32_t mode, double x, double y,
                                       int32_t dx, int32_t dy,
                                       uint32_t modifiers, char **out_error);

/* `key` is a QEMU qcode name (`ret`, `a`, `f5`, `bracket_left`). */
CC_WINDOW_API int32_t cc_window_key(const int32_t *pids, int32_t pid_count,
                                    const char *display, uint64_t window_id,
                                    int32_t mode, const char *key,
                                    int32_t action, uint32_t modifiers,
                                    char **out_error);

/* Types UTF-8 text as literal characters, independent of the keyboard map. */
CC_WINDOW_API int32_t cc_window_text(const int32_t *pids, int32_t pid_count,
                                     const char *display, uint64_t window_id,
                                     int32_t mode, const char *utf8,
                                     char **out_error);

/*
 * JSON accessibility tree with window-relative geometry:
 * {"truncated":false,"root":{"role":"…","title":"…","value":"…",
 *   "description":"…","enabled":true,"focused":false,
 *   "x":0,"y":0,"width":1,"height":1,"children":[…]}}
 * Secure text fields never report a value.
 */
CC_WINDOW_API int32_t cc_window_read_ui(const int32_t *pids, int32_t pid_count,
                                        const char *display, uint64_t window_id,
                                        int32_t max_nodes, char **out_json,
                                        char **out_error);

/*
 * {"screen_capture":S,"input":S,"accessibility":S}, where S is "granted",
 * "denied" or "not_required". Never prompts.
 */
CC_WINDOW_API int32_t cc_window_permissions(char **out_json, char **out_error);

/* Opens the settings pane that grants `pane`. */
CC_WINDOW_API int32_t cc_window_open_settings(int32_t pane, char **out_error);

#ifdef __cplusplus
}
#endif

#endif /* CC_WINDOW_H */
