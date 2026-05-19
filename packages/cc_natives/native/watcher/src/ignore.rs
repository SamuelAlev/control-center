//! The ignore filter: directory NAMES whose subtrees are never watched or
//! reported. Fed from Dart (`SourceFileWalker.watchIgnoredDirs`) so the
//! native filter and the Dart-side `affectsIndex` gate agree by
//! construction — nothing is hardcoded here.

use std::collections::HashSet;
use std::path::Path;

#[derive(Debug, Default)]
pub struct IgnoreSet {
    names: HashSet<String>,
}

impl IgnoreSet {
    /// Parses the '\n'-separated name list handed across the FFI boundary.
    pub fn parse(raw: &str) -> Self {
        Self {
            names: raw
                .split('\n')
                .map(str::trim)
                .filter(|s| !s.is_empty())
                .map(str::to_owned)
                .collect(),
        }
    }

    /// Whether the directory NAME itself is ignored.
    #[allow(dead_code)] // used by the Linux walker (cfg-gated module)
    pub fn is_ignored_name(&self, name: &str) -> bool {
        self.names.contains(name)
    }

    /// Whether `path` has any ignored component BELOW `root` (the root's own
    /// components never count, so a checkout parked under a directory that
    /// happens to carry an ignored name still works).
    pub fn is_ignored(&self, path: &Path, root: &Path) -> bool {
        if self.names.is_empty() {
            return false;
        }
        let rel = match path.strip_prefix(root) {
            Ok(rel) => rel,
            // Outside the root (shouldn't happen post-rewrite): not ours to
            // judge; the Dart-side gate still filters.
            Err(_) => return false,
        };
        rel.components().any(|c| {
            c.as_os_str()
                .to_str()
                .map(|s| self.names.contains(s))
                .unwrap_or(false)
        })
    }
}
