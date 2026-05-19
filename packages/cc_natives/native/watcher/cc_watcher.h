/* cc_watcher — Control Center's native recursive file watcher.
 *
 * The C ABI contract mirrored 1:1 by
 * packages/cc_natives/lib/src/watch/watcher_ffi_bindings.dart.
 * Bump CC_WATCH_ABI_VERSION on ANY change to these signatures or structs;
 * the Dart side refuses to bind on a mismatch and falls back to
 * package:watcher.
 */
#ifndef CC_WATCHER_H
#define CC_WATCHER_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define CC_WATCH_ABI_VERSION 1u

/* Opaque watch handle. */
typedef struct CcWatch CcWatch;

/* Out-struct for cc_watch_drain. `buf` is a NUL-separated UTF-8 list of
 * absolute paths, OWNED BY THE HANDLE and reused: valid only until the next
 * cc_watch_drain / cc_watch_destroy on the same handle — callers must copy. */
typedef struct {
  const uint8_t* buf;
  uintptr_t      len;
  uint32_t       flags;       /* bitmask below */
  uint32_t       dropped;     /* paths discarded since the last drain */
  uint32_t       watch_count; /* live OS watches (Linux: dirs; else 1) */
} CcWatchDrain;

/* Something under the root changed but the paths are unknown (queue
 * overflow, kernel rescan hint, structural directory change on Linux). */
#define CC_WATCH_FLAG_RESCAN 1u
/* The watched root vanished; the handle delivers nothing more. */
#define CC_WATCH_FLAG_ROOT_GONE 2u
/* Watch budget / ENOSPC hit: coverage is partial. */
#define CC_WATCH_FLAG_DEGRADED 4u

/* The ABI version this library speaks. */
uint32_t cc_watch_abi_version(void);

/* Starts watching `root_utf8` (absolute path) recursively. Directories whose
 * NAME appears in `ignore_dirs_utf8` ('\n'-separated) are never watched or
 * reported. `queue_cap` bounds distinct pending paths before the queue
 * degrades to a RESCAN signal; `max_watches` bounds Linux inotify watches
 * (0 = unlimited). NEVER blocks: any watch-install walk (Linux) runs on the
 * library's own thread. Returns NULL on failure (see cc_watch_last_error). */
CcWatch* cc_watch_create(const char* root_utf8,
                         const char* ignore_dirs_utf8,
                         uint32_t queue_cap,
                         uint32_t max_watches);

/* Drains pending changes: 1 = `out` filled (payload and/or flags),
 * 0 = nothing pending. Takes an internal mutex (not a leaf call). */
int32_t cc_watch_drain(CcWatch* w, CcWatchDrain* out);

/* Stops watching and frees the handle. NULL-safe. */
void cc_watch_destroy(CcWatch* w);

/* Thread-local message describing the most recent failure on this thread;
 * NULL when none. Owned by the library; valid until the next failing call
 * on the same thread. */
const char* cc_watch_last_error(void);

#ifdef __cplusplus
}
#endif

#endif /* CC_WATCHER_H */
