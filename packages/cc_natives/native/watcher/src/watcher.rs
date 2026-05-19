//! notify wiring: event → canonical-root rewrite → ignore filter → queue.

use std::path::{Path, PathBuf};
use std::sync::mpsc::Sender;
use std::sync::Arc;

use notify::event::{CreateKind, EventKind, ModifyKind, RemoveKind};
use notify::Event;

use crate::ignore::IgnoreSet;
use crate::queue::{Queue, FLAG_RESCAN};

/// Immutable per-handle context shared by the event handler and (on Linux)
/// the walker thread.
pub struct WatchContext {
    /// The root exactly as the caller supplied it — every emitted path is
    /// rewritten back under this prefix.
    pub given_root: PathBuf,
    /// `canonicalize(given_root)`: FSEvents realpaths everything, so a
    /// checkout under `/var/...` reports `/private/var/...`. Without the
    /// rewrite the Dart consumer sees paths outside the root it asked for.
    pub canonical_root: PathBuf,
    pub ignore: IgnoreSet,
    pub queue: Arc<Queue>,
    /// Linux only: new directories are sent here so the walker thread
    /// installs their (non-recursive) watches off the event thread.
    pub dir_jobs: Option<Sender<PathBuf>>,
}

impl WatchContext {
    /// Rewrites an event path back under [given_root]; `None` when the path
    /// is under neither root spelling (not ours).
    pub fn rewrite(&self, path: &Path) -> Option<PathBuf> {
        if let Ok(rel) = path.strip_prefix(&self.canonical_root) {
            return Some(self.given_root.join(rel));
        }
        if path.strip_prefix(&self.given_root).is_ok() {
            return Some(path.to_path_buf());
        }
        None
    }

    /// Handles one notify event (runs on notify's own thread).
    pub fn on_event(&self, result: Result<Event, notify::Error>) {
        let event = match result {
            Ok(event) => event,
            Err(_) => {
                // A watch stream error means unknown lost events: degrade to
                // a rescan signal rather than silently missing changes.
                self.queue.set_flags(FLAG_RESCAN);
                return;
            }
        };
        if event.need_rescan() {
            // FSEvents MustScanSubDirs / inotify IN_Q_OVERFLOW, normalized
            // by notify.
            self.queue.set_flags(FLAG_RESCAN);
        }

        // Directory-level structural changes: after a dir create/remove/
        // rename, descendant coverage is uncertain (a moved-in tree's files
        // predate any watch; rename bookkeeping is exactly the bug class this
        // library refuses to hand-roll). Directory renames are rare inside a
        // checkout, so a conservative extra (debounced) reindex is cheap.
        let structural = matches!(
            event.kind,
            EventKind::Create(CreateKind::Folder)
                | EventKind::Remove(RemoveKind::Folder)
                | EventKind::Modify(ModifyKind::Name(_))
        );

        for path in &event.paths {
            let Some(rewritten) = self.rewrite(path) else {
                continue;
            };
            if self.ignore.is_ignored(&rewritten, &self.given_root) {
                continue;
            }
            if structural {
                let is_dir_like = !matches!(
                    event.kind,
                    EventKind::Modify(ModifyKind::Name(_))
                ) || path.is_dir();
                if is_dir_like {
                    self.queue.set_flags(FLAG_RESCAN);
                }
                // A brand-new directory needs watches installed under it
                // (Linux; no-op elsewhere — kernel-recursive backends).
                if matches!(event.kind, EventKind::Create(CreateKind::Folder)) {
                    if let Some(jobs) = &self.dir_jobs {
                        let _ = jobs.send(path.clone());
                    }
                }
            }
            self.queue.push(rewritten);
        }
    }
}
