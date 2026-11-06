/*
 * macOS backend: CGWindowList, ScreenCaptureKit, CGEvent, AXUIElement.
 *
 * Deliberately no AppKit: the server's boot preflight dlopens this library,
 * and activation goes through the Accessibility API foreground input already
 * needs. Every call runs on a Dart worker isolate's thread, which has no run
 * loop, so async APIs are bridged with a bounded semaphore wait.
 */
#import <ApplicationServices/ApplicationServices.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreServices/CoreServices.h>
#import <Foundation/Foundation.h>
#import <ImageIO/ImageIO.h>
#import <ScreenCaptureKit/ScreenCaptureKit.h>

#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <sys/sysctl.h>
#include <unistd.h>

#include "cc_window.h"

/* The window fields of a mouse CGEvent. Not named in the public headers, but
 * without them an event posted to a PID does not reach a background window. */
static const CGEventField kCcWindowUnderPointer = (CGEventField)91;
static const CGEventField kCcWindowCanHandle = (CGEventField)92;

static const int64_t kCcCaptureTimeoutSeconds = 5;
static const float kCcAxTimeoutSeconds = 1.0f;
static const int kCcAxDepthLimit = 48;

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

static char *cc_copy_json(id object) {
  NSData *data = [NSJSONSerialization dataWithJSONObject:object
                                                 options:0
                                                   error:nil];
  if (data == nil) {
    return NULL;
  }
  char *out = malloc(data.length + 1);
  if (out != NULL) {
    memcpy(out, data.bytes, data.length);
    out[data.length] = '\0';
  }
  return out;
}

/* ── The process tree ───────────────────────────────────────────────────── */

/* `pids` plus every descendant, or nil when a root is unusable.
 *
 * Windows belong to the tree the caller launched: a launcher such as
 * `fvm flutter run` is the root, the app is its child. A root at this process
 * or above it is refused outright, because that tree holds every other app the
 * server launched and, at launchd, every process on the machine: the ownership
 * check would pass for all of them. */
static NSSet<NSNumber *> *cc_process_tree(const int32_t *pids, int32_t count) {
  NSMutableSet<NSNumber *> *allowed = [NSMutableSet setWithCapacity:count];
  for (int32_t i = 0; i < count; i++) {
    if (pids[i] <= 1) {
      return nil;
    }
    [allowed addObject:@(pids[i])];
  }
  int mib[3] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL};
  size_t size = 0;
  struct kinfo_proc *procs = NULL;
  BOOL read = NO;
  for (int attempt = 0; attempt < 4 && !read; attempt++) {
    if (sysctl(mib, 3, NULL, &size, NULL, 0) != 0) {
      break;
    }
    size += size / 4;
    struct kinfo_proc *grown = realloc(procs, size);
    if (grown == NULL) {
      break;
    }
    procs = grown;
    read = sysctl(mib, 3, procs, &size, NULL, 0) == 0;
  }
  if (!read) {
    /* Without the table the ancestor check cannot run, so fail closed. */
    free(procs);
    return nil;
  }
  size_t total = size / sizeof(struct kinfo_proc);
  for (pid_t walk = getpid(); walk > 1;) {
    if ([allowed containsObject:@(walk)]) {
      free(procs);
      return nil;
    }
    pid_t parent = 0;
    for (size_t i = 0; i < total; i++) {
      if (procs[i].kp_proc.p_pid == walk) {
        parent = procs[i].kp_eproc.e_ppid;
        break;
      }
    }
    walk = parent;
  }
  /* A fixed point over the table: a child can sort before its parent. */
  BOOL grew = total > 0;
  while (grew) {
    grew = NO;
    for (size_t i = 0; i < total; i++) {
      NSNumber *pid = @(procs[i].kp_proc.p_pid);
      if (![allowed containsObject:pid] &&
          [allowed containsObject:@(procs[i].kp_eproc.e_ppid)]) {
        [allowed addObject:pid];
        grew = YES;
      }
    }
  }
  free(procs);
  return allowed;
}

typedef struct {
  pid_t pid;
  CGRect bounds;
  BOOL on_screen;
} CcOwnedWindow;

static BOOL cc_read_bounds(NSDictionary *info, CGRect *out) {
  NSDictionary *bounds = info[(__bridge NSString *)kCGWindowBounds];
  return bounds != nil &&
         CGRectMakeWithDictionaryRepresentation(
             (__bridge CFDictionaryRef)bounds, out);
}

/* The one chokepoint: every capture and input call resolves its window here. */
static int32_t cc_resolve(const int32_t *pids, int32_t count, uint64_t window_id,
                          NSSet<NSNumber *> **out_tree, CcOwnedWindow *out,
                          char **out_error) {
  if (pids == NULL || count <= 0) {
    return cc_fail(out_error, CC_WINDOW_ERR_INVALID,
                   "An empty process set owns no windows.");
  }
  if (window_id == 0 || window_id > UINT32_MAX) {
    return cc_fail(out_error, CC_WINDOW_ERR_NOT_FOUND,
                   "Window %llu does not exist.", window_id);
  }
  CFArrayRef raw = CGWindowListCopyWindowInfo(kCGWindowListOptionIncludingWindow,
                                              (CGWindowID)window_id);
  NSArray *list = CFBridgingRelease(raw);
  if (list.count == 0) {
    return cc_fail(out_error, CC_WINDOW_ERR_NOT_FOUND,
                   "Window %llu no longer exists.", window_id);
  }
  NSDictionary *info = list[0];
  NSNumber *owner = info[(__bridge NSString *)kCGWindowOwnerPID];
  NSSet<NSNumber *> *tree = cc_process_tree(pids, count);
  if (tree == nil) {
    return cc_fail(out_error, CC_WINDOW_ERR_INVALID,
                   "The process set must name launched apps, not this server "
                   "or anything above it.");
  }
  if (owner == nil || ![tree containsObject:owner]) {
    return cc_fail(out_error, CC_WINDOW_ERR_NOT_OWNED,
                   "Window %llu does not belong to this app's processes.",
                   window_id);
  }
  CGRect bounds;
  if (!cc_read_bounds(info, &bounds)) {
    return cc_fail(out_error, CC_WINDOW_ERR_FAILED,
                   "Window %llu reports no bounds.", window_id);
  }
  out->pid = owner.intValue;
  out->bounds = bounds;
  out->on_screen =
      [info[(__bridge NSString *)kCGWindowIsOnscreen] boolValue];
  if (out_tree != NULL) {
    *out_tree = tree;
  }
  return CC_WINDOW_OK;
}

/* ── Listing ────────────────────────────────────────────────────────────── */

int32_t cc_window_abi_version(void) { return CC_WINDOW_ABI; }

void cc_window_free(void *ptr) { free(ptr); }

int32_t cc_window_list(const int32_t *pids, int32_t pid_count,
                       const char *display, char **out_json, char **out_error) {
  (void)display;
  if (pids == NULL || pid_count <= 0 || out_json == NULL) {
    return cc_fail(out_error, CC_WINDOW_ERR_INVALID,
                   "An empty process set owns no windows.");
  }
  @autoreleasepool {
    NSSet<NSNumber *> *tree = cc_process_tree(pids, pid_count);
    if (tree == nil) {
      return cc_fail(out_error, CC_WINDOW_ERR_INVALID,
                     "The process set must name launched apps, not this "
                     "server or anything above it.");
    }
    NSArray *all = CFBridgingRelease(CGWindowListCopyWindowInfo(
        kCGWindowListOptionAll | kCGWindowListExcludeDesktopElements,
        kCGNullWindowID));
    NSMutableArray *windows = [NSMutableArray array];
    for (NSDictionary *info in all) {
      NSNumber *owner = info[(__bridge NSString *)kCGWindowOwnerPID];
      /* Layer 0 is application content. Menus, tooltips and status items sit
       * above it and are not windows an agent selects. */
      if (owner == nil || ![tree containsObject:owner] ||
          [info[(__bridge NSString *)kCGWindowLayer] intValue] != 0) {
        continue;
      }
      CGRect bounds;
      if (!cc_read_bounds(info, &bounds) || bounds.size.width < 8 ||
          bounds.size.height < 8) {
        continue;
      }
      NSString *title = info[(__bridge NSString *)kCGWindowName] ?: @"";
      [windows addObject:@{
        @"id" : info[(__bridge NSString *)kCGWindowNumber],
        @"pid" : owner,
        @"title" : title,
        @"x" : @(bounds.origin.x),
        @"y" : @(bounds.origin.y),
        @"width" : @(bounds.size.width),
        @"height" : @(bounds.size.height),
        @"on_screen" :
            @([info[(__bridge NSString *)kCGWindowIsOnscreen] boolValue]),
      }];
    }
    *out_json = cc_copy_json(windows);
    if (*out_json == NULL) {
      return cc_fail(out_error, CC_WINDOW_ERR_FAILED,
                     "Could not encode the window list.");
    }
    return CC_WINDOW_OK;
  }
}

/* ── Capture ────────────────────────────────────────────────────────────── */

static int32_t cc_encode_png(CGImageRef image, uint8_t **out_png,
                             int64_t *out_len, char **out_error) {
  NSMutableData *data = [NSMutableData data];
  CGImageDestinationRef destination = CGImageDestinationCreateWithData(
      (__bridge CFMutableDataRef)data, CFSTR("public.png"), 1, NULL);
  if (destination == NULL) {
    return cc_fail(out_error, CC_WINDOW_ERR_FAILED,
                   "Could not create a PNG encoder.");
  }
  CGImageDestinationAddImage(destination, image, NULL);
  bool encoded = CGImageDestinationFinalize(destination);
  CFRelease(destination);
  if (!encoded) {
    return cc_fail(out_error, CC_WINDOW_ERR_FAILED,
                   "Could not encode the window as PNG.");
  }
  uint8_t *bytes = malloc(data.length);
  if (bytes == NULL) {
    return cc_fail(out_error, CC_WINDOW_ERR_FAILED, "Out of memory.");
  }
  memcpy(bytes, data.bytes, data.length);
  *out_png = bytes;
  *out_len = (int64_t)data.length;
  return CC_WINDOW_OK;
}

static int32_t cc_capture_error(NSError *error, uint64_t window_id,
                                char **out_error) {
  /* SCStreamErrorUserDeclined, and the failure ScreenCaptureKit reports for a
   * window parked off every display (measured). */
  if (error.code == -3801) {
    return cc_fail(out_error, CC_WINDOW_ERR_PERMISSION,
                   "Screen Recording was declined for this process.");
  }
  if (error.code == -3811) {
    return cc_fail(out_error, CC_WINDOW_ERR_OFF_DISPLAY,
                   "Window %llu is off every display, so it cannot be "
                   "captured.",
                   window_id);
  }
  return cc_fail(out_error, CC_WINDOW_ERR_FAILED, "Capture failed: %s",
                 error.localizedDescription.UTF8String ?: "unknown error");
}

API_AVAILABLE(macos(14.0))
static int32_t cc_capture(uint64_t window_id, CGSize points, int32_t max_width,
                          int32_t max_height, uint8_t **out_png,
                          int64_t *out_len, int32_t *out_width,
                          int32_t *out_height, char **out_error) {
  dispatch_time_t deadline =
      dispatch_time(DISPATCH_TIME_NOW, kCcCaptureTimeoutSeconds * NSEC_PER_SEC);

  dispatch_semaphore_t listed = dispatch_semaphore_create(0);
  __block SCShareableContent *content = nil;
  __block NSError *failure = nil;
  [SCShareableContent
      getShareableContentExcludingDesktopWindows:NO
                             onScreenWindowsOnly:NO
                               completionHandler:^(SCShareableContent *result,
                                                   NSError *error) {
                                 content = result;
                                 failure = error;
                                 dispatch_semaphore_signal(listed);
                               }];
  if (dispatch_semaphore_wait(listed, deadline) != 0) {
    return cc_fail(out_error, CC_WINDOW_ERR_TIMEOUT,
                   "ScreenCaptureKit did not list the windows in time.");
  }
  if (failure != nil) {
    return cc_capture_error(failure, window_id, out_error);
  }
  SCWindow *target = nil;
  for (SCWindow *candidate in content.windows) {
    if (candidate.windowID == (CGWindowID)window_id) {
      target = candidate;
      break;
    }
  }
  if (target == nil) {
    return cc_fail(out_error, CC_WINDOW_ERR_NOT_FOUND,
                   "Window %llu is not capturable.", window_id);
  }

  SCContentFilter *filter =
      [[SCContentFilter alloc] initWithDesktopIndependentWindow:target];
  double scale = filter.pointPixelScale > 0 ? filter.pointPixelScale : 1;
  double pixel_width = points.width * scale;
  double pixel_height = points.height * scale;
  double fit = 1;
  if (max_width > 0 && pixel_width * fit > max_width) {
    fit = max_width / pixel_width;
  }
  if (max_height > 0 && pixel_height * fit > max_height) {
    fit = max_height / pixel_height;
  }
  SCStreamConfiguration *config = [[SCStreamConfiguration alloc] init];
  config.width = (size_t)MAX(1, floor(pixel_width * fit));
  config.height = (size_t)MAX(1, floor(pixel_height * fit));
  config.showsCursor = NO;
  config.ignoreShadowsSingleWindow = YES;

  dispatch_semaphore_t captured = dispatch_semaphore_create(0);
  __block CGImageRef image = NULL;
  [SCScreenshotManager
      captureImageWithFilter:filter
               configuration:config
           completionHandler:^(CGImageRef result, NSError *error) {
             if (result != NULL) {
               image = CGImageRetain(result);
             }
             failure = error;
             dispatch_semaphore_signal(captured);
           }];
  if (dispatch_semaphore_wait(captured, deadline) != 0) {
    /* The handler still owns `image` if it fires late; leaking one frame on a
     * wedged capture beats freeing under it. */
    return cc_fail(out_error, CC_WINDOW_ERR_TIMEOUT,
                   "ScreenCaptureKit did not capture the window in time.");
  }
  if (image == NULL) {
    if (failure != nil) {
      return cc_capture_error(failure, window_id, out_error);
    }
    return cc_fail(out_error, CC_WINDOW_ERR_FAILED,
                   "Capture returned no image.");
  }
  int32_t status = cc_encode_png(image, out_png, out_len, out_error);
  if (status == CC_WINDOW_OK) {
    if (out_width != NULL) {
      *out_width = (int32_t)CGImageGetWidth(image);
    }
    if (out_height != NULL) {
      *out_height = (int32_t)CGImageGetHeight(image);
    }
  }
  CGImageRelease(image);
  return status;
}

int32_t cc_window_capture(const int32_t *pids, int32_t pid_count,
                          const char *display, uint64_t window_id,
                          int32_t max_width, int32_t max_height,
                          uint8_t **out_png, int64_t *out_len,
                          int32_t *out_width, int32_t *out_height,
                          char **out_error) {
  (void)display;
  if (out_png == NULL || out_len == NULL) {
    return cc_fail(out_error, CC_WINDOW_ERR_INVALID,
                   "Capture needs an output buffer.");
  }
  @autoreleasepool {
    CcOwnedWindow window;
    int32_t status =
        cc_resolve(pids, pid_count, window_id, NULL, &window, out_error);
    if (status != CC_WINDOW_OK) {
      return status;
    }
    if (!CGPreflightScreenCaptureAccess()) {
      return cc_fail(out_error, CC_WINDOW_ERR_PERMISSION,
                     "Screen Recording is not granted to this process.");
    }
    if (@available(macOS 14.0, *)) {
      return cc_capture(window_id, window.bounds.size, max_width, max_height,
                        out_png, out_len, out_width, out_height, out_error);
    }
    return cc_fail(out_error, CC_WINDOW_ERR_UNSUPPORTED,
                   "Window capture needs macOS 14 or later.");
  }
}

/* ── Foreground activation and the hit test ─────────────────────────────── */

static CFTypeRef cc_ax_copy(AXUIElementRef element, CFStringRef attribute) {
  CFTypeRef value = NULL;
  return AXUIElementCopyAttributeValue(element, attribute, &value) ==
                 kAXErrorSuccess
             ? value
             : NULL;
}

/* AX has no public CGWindowID lookup, so a window is matched on its frame. */
static AXUIElementRef cc_ax_window_for(AXUIElementRef app, CGRect bounds) {
  NSArray *windows =
      CFBridgingRelease(cc_ax_copy(app, kAXWindowsAttribute));
  for (id window in windows) {
    AXUIElementRef element = (__bridge AXUIElementRef)window;
    CFTypeRef position_value = cc_ax_copy(element, kAXPositionAttribute);
    CFTypeRef size_value = cc_ax_copy(element, kAXSizeAttribute);
    CGPoint position = CGPointZero;
    CGSize size = CGSizeZero;
    BOOL read = position_value != NULL && size_value != NULL &&
                AXValueGetValue(position_value, kAXValueTypeCGPoint,
                                &position) &&
                AXValueGetValue(size_value, kAXValueTypeCGSize, &size);
    if (position_value != NULL) {
      CFRelease(position_value);
    }
    if (size_value != NULL) {
      CFRelease(size_value);
    }
    if (read && fabs(position.x - bounds.origin.x) < 2 &&
        fabs(position.y - bounds.origin.y) < 2 &&
        fabs(size.width - bounds.size.width) < 2 &&
        fabs(size.height - bounds.size.height) < 2) {
      return (AXUIElementRef)CFRetain(element);
    }
  }
  return NULL;
}

static void cc_activate(const CcOwnedWindow *window) {
  AXUIElementRef app = AXUIElementCreateApplication(window->pid);
  AXUIElementSetMessagingTimeout(app, kCcAxTimeoutSeconds);
  AXUIElementSetAttributeValue(app, kAXFrontmostAttribute, kCFBooleanTrue);
  AXUIElementRef element = cc_ax_window_for(app, window->bounds);
  if (element != NULL) {
    AXUIElementPerformAction(element, kAXRaiseAction);
    CFRelease(element);
  }
  CFRelease(app);
}

/* Whether a system-level event at `point` would land on an owned window.
 *
 * Foreground input goes to whatever is on top, so the own-windows rule has to
 * be checked against the screen rather than against the target window: a click
 * into a covered window is a click into someone else's. */
static BOOL cc_point_is_owned(CGPoint point, NSSet<NSNumber *> *tree) {
  NSArray *visible = CFBridgingRelease(CGWindowListCopyWindowInfo(
      kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements,
      kCGNullWindowID));
  for (NSDictionary *info in visible) {
    CGRect bounds;
    if (!cc_read_bounds(info, &bounds) || !CGRectContainsPoint(bounds, point)) {
      continue;
    }
    if ([info[(__bridge NSString *)kCGWindowAlpha] doubleValue] <= 0) {
      continue;
    }
    /* The window server's own always-on-screen overlays are not targets. */
    NSString *owner = info[(__bridge NSString *)kCGWindowOwnerName];
    if ([owner isEqualToString:@"Window Server"]) {
      continue;
    }
    return [tree containsObject:info[(__bridge NSString *)kCGWindowOwnerPID]];
  }
  return NO;
}

static BOOL cc_frontmost_is_owned(NSSet<NSNumber *> *tree) {
  AXUIElementRef system = AXUIElementCreateSystemWide();
  AXUIElementSetMessagingTimeout(system, kCcAxTimeoutSeconds);
  CFTypeRef focused = cc_ax_copy(system, kAXFocusedApplicationAttribute);
  CFRelease(system);
  if (focused == NULL) {
    return NO;
  }
  pid_t pid = 0;
  BOOL read = AXUIElementGetPid((AXUIElementRef)focused, &pid) == kAXErrorSuccess;
  CFRelease(focused);
  return read && [tree containsObject:@(pid)];
}

/* Raises the window until `ready` holds, or gives up after ~500 ms. */
static BOOL cc_raise_until(const CcOwnedWindow *window, BOOL (^ready)(void)) {
  if (ready()) {
    return YES;
  }
  cc_activate(window);
  for (int attempt = 0; attempt < 10; attempt++) {
    [NSThread sleepForTimeInterval:0.05];
    if (ready()) {
      return YES;
    }
  }
  return NO;
}

/* ── Input ──────────────────────────────────────────────────────────────── */

static CGEventFlags cc_flags(uint32_t modifiers) {
  CGEventFlags flags = 0;
  if (modifiers & CC_WINDOW_MOD_SHIFT) flags |= kCGEventFlagMaskShift;
  if (modifiers & CC_WINDOW_MOD_CTRL) flags |= kCGEventFlagMaskControl;
  if (modifiers & CC_WINDOW_MOD_ALT) flags |= kCGEventFlagMaskAlternate;
  if (modifiers & CC_WINDOW_MOD_META) flags |= kCGEventFlagMaskCommand;
  return flags;
}

static CGEventSourceRef cc_source(int32_t mode) {
  /* A private source keeps a background post out of the HID state the
   * operator's own keyboard and mouse are feeding. */
  return CGEventSourceCreate(mode == CC_WINDOW_MODE_FOREGROUND
                                 ? kCGEventSourceStateHIDSystemState
                                 : kCGEventSourceStatePrivate);
}

static void cc_post(CGEventRef event, int32_t mode, pid_t pid) {
  if (mode == CC_WINDOW_MODE_FOREGROUND) {
    CGEventPost(kCGHIDEventTap, event);
  } else {
    CGEventPostToPid(pid, event);
  }
}

/* Shared front half of every input call. Without the access preflight the OS
 * drops events without a word, so "sent" would be a claim nothing backs. */
static int32_t cc_input_begin(const int32_t *pids, int32_t pid_count,
                              uint64_t window_id, int32_t mode,
                              NSSet<NSNumber *> **out_tree, CcOwnedWindow *out,
                              char **out_error) {
  if (mode != CC_WINDOW_MODE_BACKGROUND && mode != CC_WINDOW_MODE_FOREGROUND) {
    return cc_fail(out_error, CC_WINDOW_ERR_INVALID, "Unknown input mode %d.",
                   mode);
  }
  int32_t status =
      cc_resolve(pids, pid_count, window_id, out_tree, out, out_error);
  if (status != CC_WINDOW_OK) {
    return status;
  }
  if (!CGPreflightPostEventAccess()) {
    return cc_fail(out_error, CC_WINDOW_ERR_PERMISSION,
                   "Accessibility is not granted to this process, so input "
                   "cannot be posted.");
  }
  return CC_WINDOW_OK;
}

/* Global point for a window-relative one, or an error when it is outside. */
static int32_t cc_point(const CcOwnedWindow *window, double x, double y,
                        int32_t mode, NSSet<NSNumber *> *tree, CGPoint *out,
                        char **out_error) {
  if (!(x >= 0 && y >= 0 && x < window->bounds.size.width &&
        y < window->bounds.size.height)) {
    return cc_fail(out_error, CC_WINDOW_ERR_OUT_OF_BOUNDS,
                   "(%.0f, %.0f) is outside the %.0fx%.0f window.", x, y,
                   window->bounds.size.width, window->bounds.size.height);
  }
  CGPoint point = CGPointMake(window->bounds.origin.x + x,
                              window->bounds.origin.y + y);
  if (mode == CC_WINDOW_MODE_FOREGROUND &&
      !cc_raise_until(window, ^BOOL {
        return cc_point_is_owned(point, tree);
      })) {
    return cc_fail(out_error, CC_WINDOW_ERR_NOT_OWNED,
                   "Another app's window covers (%.0f, %.0f), so foreground "
                   "input would land on it.",
                   x, y);
  }
  *out = point;
  return CC_WINDOW_OK;
}

int32_t cc_window_mouse(const int32_t *pids, int32_t pid_count,
                        const char *display, uint64_t window_id, int32_t mode,
                        int32_t phase, int32_t button, double x, double y,
                        int32_t click_count, uint32_t modifiers,
                        char **out_error) {
  (void)display;
  @autoreleasepool {
    CcOwnedWindow window;
    NSSet<NSNumber *> *tree = nil;
    int32_t status = cc_input_begin(pids, pid_count, window_id, mode, &tree,
                                    &window, out_error);
    if (status != CC_WINDOW_OK) {
      return status;
    }
    CGPoint point;
    status = cc_point(&window, x, y, mode, tree, &point, out_error);
    if (status != CC_WINDOW_OK) {
      return status;
    }
    CGMouseButton mouse_button = button == CC_WINDOW_BUTTON_RIGHT
                                     ? kCGMouseButtonRight
                                 : button == CC_WINDOW_BUTTON_MIDDLE
                                     ? kCGMouseButtonCenter
                                     : kCGMouseButtonLeft;
    CGEventType type;
    switch (phase) {
      case CC_WINDOW_POINTER_MOVE:
        type = kCGEventMouseMoved;
        break;
      case CC_WINDOW_POINTER_DOWN:
        type = button == CC_WINDOW_BUTTON_RIGHT    ? kCGEventRightMouseDown
               : button == CC_WINDOW_BUTTON_MIDDLE ? kCGEventOtherMouseDown
                                                   : kCGEventLeftMouseDown;
        break;
      case CC_WINDOW_POINTER_UP:
        type = button == CC_WINDOW_BUTTON_RIGHT    ? kCGEventRightMouseUp
               : button == CC_WINDOW_BUTTON_MIDDLE ? kCGEventOtherMouseUp
                                                   : kCGEventLeftMouseUp;
        break;
      case CC_WINDOW_POINTER_DRAG:
        type = button == CC_WINDOW_BUTTON_RIGHT ? kCGEventRightMouseDragged
               : button == CC_WINDOW_BUTTON_MIDDLE
                   ? kCGEventOtherMouseDragged
                   : kCGEventLeftMouseDragged;
        break;
      default:
        return cc_fail(out_error, CC_WINDOW_ERR_INVALID,
                       "Unknown pointer phase %d.", phase);
    }
    CGEventSourceRef source = cc_source(mode);
    CGEventRef event =
        CGEventCreateMouseEvent(source, type, point, mouse_button);
    if (source != NULL) {
      CFRelease(source);
    }
    if (event == NULL) {
      return cc_fail(out_error, CC_WINDOW_ERR_FAILED,
                     "Could not create a mouse event.");
    }
    CGEventSetFlags(event, cc_flags(modifiers));
    CGEventSetIntegerValueField(event, kCGMouseEventClickState,
                                MAX(1, click_count));
    CGEventSetIntegerValueField(event, kCcWindowUnderPointer,
                                (int64_t)window_id);
    CGEventSetIntegerValueField(event, kCcWindowCanHandle, (int64_t)window_id);
    cc_post(event, mode, window.pid);
    CFRelease(event);
    return CC_WINDOW_OK;
  }
}

int32_t cc_window_scroll(const int32_t *pids, int32_t pid_count,
                         const char *display, uint64_t window_id, int32_t mode,
                         double x, double y, int32_t dx, int32_t dy,
                         uint32_t modifiers, char **out_error) {
  (void)display;
  @autoreleasepool {
    CcOwnedWindow window;
    NSSet<NSNumber *> *tree = nil;
    int32_t status = cc_input_begin(pids, pid_count, window_id, mode, &tree,
                                    &window, out_error);
    if (status != CC_WINDOW_OK) {
      return status;
    }
    CGPoint point;
    status = cc_point(&window, x, y, mode, tree, &point, out_error);
    if (status != CC_WINDOW_OK) {
      return status;
    }
    CGEventSourceRef source = cc_source(mode);
    CGEventRef event = CGEventCreateScrollWheelEvent(
        source, kCGScrollEventUnitLine, 2, dy, dx);
    if (source != NULL) {
      CFRelease(source);
    }
    if (event == NULL) {
      return cc_fail(out_error, CC_WINDOW_ERR_FAILED,
                     "Could not create a scroll event.");
    }
    CGEventSetLocation(event, point);
    CGEventSetFlags(event, cc_flags(modifiers));
    CGEventSetIntegerValueField(event, kCcWindowUnderPointer,
                                (int64_t)window_id);
    CGEventSetIntegerValueField(event, kCcWindowCanHandle, (int64_t)window_id);
    cc_post(event, mode, window.pid);
    CFRelease(event);
    return CC_WINDOW_OK;
  }
}

/* qcode → macOS virtual key (HIToolbox kVK_*). ANSI positions, matching the
 * physical-key meaning a qcode has. */
typedef struct {
  const char *name;
  CGKeyCode code;
} CcKey;

static const CcKey kCcKeys[] = {
    {"a", 0x00},           {"s", 0x01},          {"d", 0x02},
    {"f", 0x03},           {"h", 0x04},          {"g", 0x05},
    {"z", 0x06},           {"x", 0x07},          {"c", 0x08},
    {"v", 0x09},           {"b", 0x0B},          {"q", 0x0C},
    {"w", 0x0D},           {"e", 0x0E},          {"r", 0x0F},
    {"y", 0x10},           {"t", 0x11},          {"1", 0x12},
    {"2", 0x13},           {"3", 0x14},          {"4", 0x15},
    {"6", 0x16},           {"5", 0x17},          {"equal", 0x18},
    {"9", 0x19},           {"7", 0x1A},          {"minus", 0x1B},
    {"8", 0x1C},           {"0", 0x1D},          {"bracket_right", 0x1E},
    {"o", 0x1F},           {"u", 0x20},          {"bracket_left", 0x21},
    {"i", 0x22},           {"p", 0x23},          {"ret", 0x24},
    {"l", 0x25},           {"j", 0x26},          {"apostrophe", 0x27},
    {"k", 0x28},           {"semicolon", 0x29},  {"backslash", 0x2A},
    {"comma", 0x2B},       {"slash", 0x2C},      {"n", 0x2D},
    {"m", 0x2E},           {"dot", 0x2F},        {"tab", 0x30},
    {"spc", 0x31},         {"grave_accent", 0x32}, {"backspace", 0x33},
    {"esc", 0x35},         {"meta_r", 0x36},     {"meta_l", 0x37},
    {"shift", 0x38},       {"caps_lock", 0x39},  {"alt", 0x3A},
    {"ctrl", 0x3B},        {"shift_r", 0x3C},    {"alt_r", 0x3D},
    {"ctrl_r", 0x3E},      {"kp_enter", 0x4C},   {"f5", 0x60},
    {"f6", 0x61},          {"f7", 0x62},         {"f3", 0x63},
    {"f8", 0x64},          {"f9", 0x65},         {"f11", 0x67},
    {"f10", 0x6D},         {"f12", 0x6F},        {"insert", 0x72},
    {"home", 0x73},        {"pgup", 0x74},       {"delete", 0x75},
    {"f4", 0x76},          {"end", 0x77},        {"f2", 0x78},
    {"pgdn", 0x79},        {"f1", 0x7A},         {"left", 0x7B},
    {"right", 0x7C},       {"down", 0x7D},       {"up", 0x7E},
};

static BOOL cc_key_code(const char *name, CGKeyCode *out) {
  for (size_t i = 0; i < sizeof(kCcKeys) / sizeof(kCcKeys[0]); i++) {
    if (strcmp(kCcKeys[i].name, name) == 0) {
      *out = kCcKeys[i].code;
      return YES;
    }
  }
  return NO;
}

/* Foreground keys go to the focused app, so it has to be ours. */
static int32_t cc_require_focus(const CcOwnedWindow *window, int32_t mode,
                                NSSet<NSNumber *> *tree, char **out_error) {
  if (mode == CC_WINDOW_MODE_FOREGROUND &&
      !cc_raise_until(window, ^BOOL {
        return cc_frontmost_is_owned(tree);
      })) {
    return cc_fail(out_error, CC_WINDOW_ERR_NOT_OWNED,
                   "This app did not take keyboard focus, so foreground input "
                   "would reach another app.");
  }
  return CC_WINDOW_OK;
}

int32_t cc_window_key(const int32_t *pids, int32_t pid_count,
                      const char *display, uint64_t window_id, int32_t mode,
                      const char *key, int32_t action, uint32_t modifiers,
                      char **out_error) {
  (void)display;
  @autoreleasepool {
    if (key == NULL) {
      return cc_fail(out_error, CC_WINDOW_ERR_INVALID, "No key was named.");
    }
    CGKeyCode code;
    if (!cc_key_code(key, &code)) {
      return cc_fail(out_error, CC_WINDOW_ERR_INVALID, "Unknown key \"%s\".",
                     key);
    }
    CcOwnedWindow window;
    NSSet<NSNumber *> *tree = nil;
    int32_t status = cc_input_begin(pids, pid_count, window_id, mode, &tree,
                                    &window, out_error);
    if (status != CC_WINDOW_OK) {
      return status;
    }
    status = cc_require_focus(&window, mode, tree, out_error);
    if (status != CC_WINDOW_OK) {
      return status;
    }
    CGEventSourceRef source = cc_source(mode);
    for (int phase = 0; phase < 2; phase++) {
      bool down = phase == 0;
      if ((down && action == CC_WINDOW_KEY_UP) ||
          (!down && action == CC_WINDOW_KEY_DOWN)) {
        continue;
      }
      CGEventRef event = CGEventCreateKeyboardEvent(source, code, down);
      if (event == NULL) {
        if (source != NULL) {
          CFRelease(source);
        }
        return cc_fail(out_error, CC_WINDOW_ERR_FAILED,
                       "Could not create a key event.");
      }
      CGEventSetFlags(event, cc_flags(modifiers));
      cc_post(event, mode, window.pid);
      CFRelease(event);
    }
    if (source != NULL) {
      CFRelease(source);
    }
    return CC_WINDOW_OK;
  }
}

int32_t cc_window_text(const int32_t *pids, int32_t pid_count,
                       const char *display, uint64_t window_id, int32_t mode,
                       const char *utf8, char **out_error) {
  (void)display;
  @autoreleasepool {
    NSString *text = utf8 == NULL ? nil : [NSString stringWithUTF8String:utf8];
    if (text == nil) {
      return cc_fail(out_error, CC_WINDOW_ERR_INVALID,
                     "Text must be valid UTF-8.");
    }
    CcOwnedWindow window;
    NSSet<NSNumber *> *tree = nil;
    int32_t status = cc_input_begin(pids, pid_count, window_id, mode, &tree,
                                    &window, out_error);
    if (status != CC_WINDOW_OK) {
      return status;
    }
    status = cc_require_focus(&window, mode, tree, out_error);
    if (status != CC_WINDOW_OK) {
      return status;
    }
    CGEventSourceRef source = cc_source(mode);
    /* One composed character per event, because CGEvent caps a unicode string
     * at 20 units and a split surrogate pair is two broken characters. */
    __block int32_t result = CC_WINDOW_OK;
    [text enumerateSubstringsInRange:NSMakeRange(0, text.length)
                             options:NSStringEnumerationByComposedCharacterSequences
                          usingBlock:^(NSString *piece, NSRange range,
                                       NSRange enclosing, BOOL *stop) {
                            (void)range;
                            (void)enclosing;
                            /* Focus can move mid-string, and the rest of the
                             * text would land in the operator's frontmost app. */
                            if (mode == CC_WINDOW_MODE_FOREGROUND &&
                                !cc_frontmost_is_owned(tree)) {
                              result = CC_WINDOW_ERR_NOT_OWNED;
                              *stop = YES;
                              return;
                            }
                            UniChar units[20];
                            NSUInteger length = MIN(piece.length, 20);
                            [piece getCharacters:units
                                           range:NSMakeRange(0, length)];
                            for (int phase = 0; phase < 2; phase++) {
                              CGEventRef event = CGEventCreateKeyboardEvent(
                                  source, 0, phase == 0);
                              if (event == NULL) {
                                result = CC_WINDOW_ERR_FAILED;
                                *stop = YES;
                                return;
                              }
                              CGEventKeyboardSetUnicodeString(event, length,
                                                              units);
                              cc_post(event, mode, window.pid);
                              CFRelease(event);
                            }
                          }];
    if (source != NULL) {
      CFRelease(source);
    }
    if (result == CC_WINDOW_ERR_NOT_OWNED) {
      return cc_fail(out_error, result,
                     "Keyboard focus left this app while typing, so the rest "
                     "of the text was not sent.");
    }
    return result == CC_WINDOW_OK
               ? CC_WINDOW_OK
               : cc_fail(out_error, result, "Could not create a key event.");
  }
}

/* ── The accessibility tree ─────────────────────────────────────────────── */

typedef struct {
  int remaining;
  BOOL truncated;
  CGPoint origin;
  CFAbsoluteTime deadline;
} CcUiWalk;

static NSString *cc_ax_string(AXUIElementRef element, CFStringRef attribute) {
  id value = CFBridgingRelease(cc_ax_copy(element, attribute));
  if ([value isKindOfClass:[NSString class]]) {
    return value;
  }
  if ([value isKindOfClass:[NSNumber class]]) {
    return [value stringValue];
  }
  return nil;
}

static BOOL cc_ax_bool(AXUIElementRef element, CFStringRef attribute,
                       BOOL fallback) {
  id value = CFBridgingRelease(cc_ax_copy(element, attribute));
  return [value isKindOfClass:[NSNumber class]] ? [value boolValue] : fallback;
}

static NSDictionary *cc_ui_node(AXUIElementRef element, CcUiWalk *walk,
                                int depth) {
  if (walk->remaining <= 0 || depth > kCcAxDepthLimit ||
      CFAbsoluteTimeGetCurrent() > walk->deadline) {
    walk->truncated = YES;
    return nil;
  }
  walk->remaining--;
  NSMutableDictionary *node = [NSMutableDictionary dictionary];
  node[@"role"] = cc_ax_string(element, kAXRoleAttribute) ?: @"";
  NSString *subrole = cc_ax_string(element, kAXSubroleAttribute);
  NSString *title = cc_ax_string(element, kAXTitleAttribute);
  NSString *description = cc_ax_string(element, kAXDescriptionAttribute);
  if (title.length > 0) {
    node[@"title"] = title;
  }
  if (description.length > 0) {
    node[@"description"] = description;
  }
  if (![subrole isEqualToString:(__bridge NSString *)kAXSecureTextFieldSubrole]) {
    NSString *value = cc_ax_string(element, kAXValueAttribute);
    if (value.length > 0) {
      node[@"value"] = value;
    }
  }
  node[@"enabled"] = @(cc_ax_bool(element, kAXEnabledAttribute, YES));
  node[@"focused"] = @(cc_ax_bool(element, kAXFocusedAttribute, NO));
  CFTypeRef position_value = cc_ax_copy(element, kAXPositionAttribute);
  CFTypeRef size_value = cc_ax_copy(element, kAXSizeAttribute);
  CGPoint position;
  CGSize size;
  if (position_value != NULL && size_value != NULL &&
      AXValueGetValue(position_value, kAXValueTypeCGPoint, &position) &&
      AXValueGetValue(size_value, kAXValueTypeCGSize, &size)) {
    node[@"x"] = @(position.x - walk->origin.x);
    node[@"y"] = @(position.y - walk->origin.y);
    node[@"width"] = @(size.width);
    node[@"height"] = @(size.height);
  }
  if (position_value != NULL) {
    CFRelease(position_value);
  }
  if (size_value != NULL) {
    CFRelease(size_value);
  }
  NSArray *children =
      CFBridgingRelease(cc_ax_copy(element, kAXChildrenAttribute));
  if (children.count > 0) {
    NSMutableArray *out = [NSMutableArray arrayWithCapacity:children.count];
    for (id child in children) {
      NSDictionary *mapped =
          cc_ui_node((__bridge AXUIElementRef)child, walk, depth + 1);
      if (mapped != nil) {
        [out addObject:mapped];
      }
    }
    node[@"children"] = out;
  }
  return node;
}

int32_t cc_window_read_ui(const int32_t *pids, int32_t pid_count,
                          const char *display, uint64_t window_id,
                          int32_t max_nodes, char **out_json,
                          char **out_error) {
  (void)display;
  if (out_json == NULL) {
    return cc_fail(out_error, CC_WINDOW_ERR_INVALID,
                   "read_ui needs an output string.");
  }
  @autoreleasepool {
    CcOwnedWindow window;
    int32_t status =
        cc_resolve(pids, pid_count, window_id, NULL, &window, out_error);
    if (status != CC_WINDOW_OK) {
      return status;
    }
    if (!AXIsProcessTrusted()) {
      return cc_fail(out_error, CC_WINDOW_ERR_PERMISSION,
                     "Accessibility is not granted to this process.");
    }
    AXUIElementRef app = AXUIElementCreateApplication(window.pid);
    AXUIElementSetMessagingTimeout(app, kCcAxTimeoutSeconds);
    /* Chromium builds its tree only for a client that asks. This is a plain
     * accessibility attribute, not a channel into the app. */
    AXUIElementSetAttributeValue(app, CFSTR("AXManualAccessibility"),
                                 kCFBooleanTrue);
    AXUIElementRef element = cc_ax_window_for(app, window.bounds);
    CFRelease(app);
    if (element == NULL) {
      return cc_fail(out_error, CC_WINDOW_ERR_UNSUPPORTED,
                     "This window exposes no accessibility tree. Use "
                     "screenshots instead.");
    }
    CcUiWalk walk = {
        .remaining = max_nodes > 0 ? max_nodes : 500,
        .truncated = NO,
        .origin = window.bounds.origin,
        .deadline = CFAbsoluteTimeGetCurrent() + 5,
    };
    NSDictionary *root = cc_ui_node(element, &walk, 0);
    CFRelease(element);
    *out_json = cc_copy_json(@{
      @"truncated" : @(walk.truncated),
      @"root" : root ?: @{},
    });
    if (*out_json == NULL) {
      return cc_fail(out_error, CC_WINDOW_ERR_FAILED,
                     "Could not encode the accessibility tree.");
    }
    return CC_WINDOW_OK;
  }
}

/* ── Permissions ────────────────────────────────────────────────────────── */

int32_t cc_window_permissions(char **out_json, char **out_error) {
  if (out_json == NULL) {
    return cc_fail(out_error, CC_WINDOW_ERR_INVALID,
                   "permissions needs an output string.");
  }
  @autoreleasepool {
    *out_json = cc_copy_json(@{
      @"screen_capture" : CGPreflightScreenCaptureAccess() ? @"granted"
                                                           : @"denied",
      @"input" : CGPreflightPostEventAccess() ? @"granted" : @"denied",
      @"accessibility" : AXIsProcessTrusted() ? @"granted" : @"denied",
    });
    return *out_json == NULL
               ? cc_fail(out_error, CC_WINDOW_ERR_FAILED,
                         "Could not encode the permissions.")
               : CC_WINDOW_OK;
  }
}

int32_t cc_window_open_settings(int32_t pane, char **out_error) {
  const char *anchor;
  switch (pane) {
    case CC_WINDOW_PANE_SCREEN_CAPTURE:
      anchor = "Privacy_ScreenCapture";
      break;
    case CC_WINDOW_PANE_ACCESSIBILITY:
      anchor = "Privacy_Accessibility";
      break;
    default:
      return cc_fail(out_error, CC_WINDOW_ERR_INVALID,
                     "Unknown settings pane %d.", pane);
  }
  @autoreleasepool {
    NSString *link = [NSString
        stringWithFormat:
            @"x-apple.systempreferences:com.apple.preference.security?%s",
            anchor];
    OSStatus opened =
        LSOpenCFURLRef((__bridge CFURLRef)[NSURL URLWithString:link], NULL);
    return opened == noErr ? CC_WINDOW_OK
                           : cc_fail(out_error, CC_WINDOW_ERR_FAILED,
                                     "Could not open System Settings (%d).",
                                     (int)opened);
  }
}
