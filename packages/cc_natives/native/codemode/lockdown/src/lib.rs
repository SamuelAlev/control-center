//! Self-confinement for `cc_codemode`.
//!
//! The runner calls [`close_inherited_descriptors`], then
//! [`apply_thread_scoped`] before it starts any other thread, then
//! [`apply_process_wide`]. Each step records what it actually achieved in a
//! [`LockdownReport`]; the level is derived from those records, never from
//! what was intended. A control that the platform does not have at all
//! (Landlock on an older Linux kernel) is recorded as `unavailable` and does
//! not lower the level while the controls that are required are applied.
//!
//! [`selftest::run`] proves each control by attempting the denied operation
//! from native code, and runs the caller's session check to prove that real
//! sessions still work under the same lockdown.

#![deny(unsafe_op_in_unsafe_fn)]

mod json;
pub mod selftest;

#[cfg(target_os = "linux")]
mod linux;
#[cfg(target_os = "macos")]
pub(crate) mod macos;
#[cfg(windows)]
pub mod windows;

#[cfg(not(any(target_os = "linux", target_os = "macos", windows)))]
compile_error!("cc_codemode supports Linux, macOS and Windows only");

/// Address-space ceiling (Linux) and job memory limit (Windows). The heap
/// limit the host sends in `init` is at most [`HEAP_CEILING_BYTES`]; this
/// backstop leaves room for the interpreter's own reserve, the frame buffers
/// and the allocator's arenas on top of that.
pub const ADDRESS_SPACE_LIMIT_BYTES: u64 = 3 * 1024 * 1024 * 1024;

/// Largest heap limit a host may request in `init.limits.heap_bytes`.
pub const HEAP_CEILING_BYTES: u64 = 1024 * 1024 * 1024;

/// Kernel CPU backstop in seconds: the 120 s interpreter ceiling plus slack.
/// The interpreter enforces the per-script budget itself; this only ends a
/// process whose interpreter stopped checking.
pub const CPU_LIMIT_SECONDS: u64 = 135;

/// Outcome of one control.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Status {
    /// The control is in force; the call that applied it reported success.
    Applied,
    /// The platform does not have this control. Allowed only for controls
    /// marked optional, and only while the required ones are applied.
    Unavailable(String),
    /// The call that should have applied the control failed.
    Failed(String),
}

/// One control and what happened when the runner applied it.
#[derive(Clone, Debug)]
pub struct Control {
    /// Stable identifier, for example `seccomp` or `appcontainer`.
    pub name: &'static str,
    /// Whether a level of `full` needs this control applied.
    pub required: bool,
    /// What happened.
    pub status: Status,
}

/// Overall result, as the host reads it from `ready.lockdown.level`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Level {
    /// Every required control is applied.
    Full,
    /// Some required control failed, but at least one control is applied.
    Partial,
    /// Nothing is applied.
    None,
}

impl Level {
    /// Wire name.
    pub fn as_str(self) -> &'static str {
        match self {
            Level::Full => "full",
            Level::Partial => "partial",
            Level::None => "none",
        }
    }
}

/// Everything the runner applied to itself, in order.
#[derive(Clone, Debug)]
pub struct LockdownReport {
    /// `linux`, `macos` or `windows`.
    pub os: &'static str,
    /// Controls in the order they were applied.
    pub controls: Vec<Control>,
}

impl Default for LockdownReport {
    fn default() -> Self {
        Self::new()
    }
}

impl LockdownReport {
    /// An empty report for this OS. Its level is `none` until something is
    /// applied.
    pub fn new() -> Self {
        LockdownReport {
            os: current_os(),
            controls: Vec::new(),
        }
    }

    /// Records one control.
    pub fn record(&mut self, name: &'static str, required: bool, status: Status) {
        self.controls.push(Control {
            name,
            required,
            status,
        });
    }

    /// Records a required control from a `Result`.
    pub fn require(&mut self, name: &'static str, result: Result<(), String>) {
        let status = match result {
            Ok(()) => Status::Applied,
            Err(e) => Status::Failed(e),
        };
        self.record(name, true, status);
    }

    /// `full` only when at least one control was recorded, every required
    /// control is applied, and no optional control failed outright.
    pub fn level(&self) -> Level {
        let applied = self
            .controls
            .iter()
            .any(|c| c.status == Status::Applied);
        let failed = self.controls.iter().any(|c| match &c.status {
            Status::Failed(_) => true,
            Status::Unavailable(_) => c.required,
            Status::Applied => false,
        });
        match (applied, failed) {
            (true, false) => Level::Full,
            (true, true) => Level::Partial,
            (false, _) => Level::None,
        }
    }

    /// Names of the controls that keep the level below `full`.
    pub fn failed(&self) -> Vec<&'static str> {
        self.controls
            .iter()
            .filter(|c| match &c.status {
                Status::Failed(_) => true,
                Status::Unavailable(_) => c.required,
                Status::Applied => false,
            })
            .map(|c| c.name)
            .collect()
    }

    /// The `ready.lockdown` object:
    /// `{"level","os","controls":[{"name","status","required","detail"?}],"failed":[...]}`.
    pub fn to_json(&self) -> String {
        let mut out = String::from("{\"level\":");
        json::push_str(&mut out, self.level().as_str());
        out.push_str(",\"os\":");
        json::push_str(&mut out, self.os);
        out.push_str(",\"controls\":[");
        for (i, c) in self.controls.iter().enumerate() {
            if i > 0 {
                out.push(',');
            }
            out.push_str("{\"name\":");
            json::push_str(&mut out, c.name);
            out.push_str(",\"required\":");
            out.push_str(if c.required { "true" } else { "false" });
            out.push_str(",\"status\":");
            let (status, detail) = match &c.status {
                Status::Applied => ("applied", None),
                Status::Unavailable(d) => ("unavailable", Some(d)),
                Status::Failed(d) => ("failed", Some(d)),
            };
            json::push_str(&mut out, status);
            if let Some(d) = detail {
                out.push_str(",\"detail\":");
                json::push_str(&mut out, d);
            }
            out.push('}');
        }
        out.push_str("],\"failed\":[");
        for (i, name) in self.failed().iter().enumerate() {
            if i > 0 {
                out.push(',');
            }
            json::push_str(&mut out, name);
        }
        out.push_str("]}");
        out
    }
}

fn current_os() -> &'static str {
    if cfg!(target_os = "linux") {
        "linux"
    } else if cfg!(target_os = "macos") {
        "macos"
    } else {
        "windows"
    }
}

/// Step 1: closes every descriptor above 2 the process inherited. On Windows
/// the launcher passes exactly three handles, so there is nothing to close
/// and the step records nothing.
pub fn close_inherited_descriptors(report: &mut LockdownReport) {
    #[cfg(target_os = "linux")]
    report.require("close_inherited_fds", linux::close_inherited_fds());
    #[cfg(target_os = "macos")]
    report.require("close_inherited_fds", macos::close_inherited_fds());
    #[cfg(windows)]
    let _ = report;
}

/// Step 2: controls that bind only the calling thread and the threads it
/// creates afterwards. Call before any other thread exists.
pub fn apply_thread_scoped(report: &mut LockdownReport) {
    #[cfg(target_os = "linux")]
    linux::apply_thread_scoped(report);
    #[cfg(target_os = "macos")]
    macos::apply_thread_scoped(report);
    #[cfg(windows)]
    windows::verify_container(report);
}

/// Step 3: controls that bind the whole process, including threads started
/// after step 2.
pub fn apply_process_wide(report: &mut LockdownReport) {
    #[cfg(target_os = "linux")]
    linux::apply_process_wide(report);
    #[cfg(target_os = "macos")]
    macos::apply_process_wide(report);
    #[cfg(windows)]
    windows::verify_job_and_mitigations(report);
}

/// All three steps, for a process that starts no threads in between.
pub fn apply() -> LockdownReport {
    let mut report = LockdownReport::new();
    close_inherited_descriptors(&mut report);
    apply_thread_scoped(&mut report);
    apply_process_wide(&mut report);
    report
}

/// Linux only: glibc creates a malloc arena the first time a new thread
/// allocates, and sizing the arena list reads CPU information through
/// syscalls the filter does not allow. Limiting glibc to one arena before
/// any thread starts keeps every thread on the main arena. No-op elsewhere.
pub fn prepare_allocator_for_threads() {
    #[cfg(all(target_os = "linux", target_env = "gnu"))]
    linux::single_malloc_arena();
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty_report_is_none() {
        assert_eq!(LockdownReport::new().level(), Level::None);
    }

    #[test]
    fn optional_unavailable_keeps_full() {
        let mut r = LockdownReport::new();
        r.record("a", true, Status::Applied);
        r.record("b", false, Status::Unavailable("old kernel".into()));
        assert_eq!(r.level(), Level::Full);
        assert!(r.failed().is_empty());
    }

    #[test]
    fn required_failure_is_partial() {
        let mut r = LockdownReport::new();
        r.record("a", true, Status::Applied);
        r.require("b", Err("EPERM".into()));
        assert_eq!(r.level(), Level::Partial);
        assert_eq!(r.failed(), vec!["b"]);
        assert!(r.to_json().contains("\"level\":\"partial\""));
    }

    #[test]
    fn optional_failure_is_partial() {
        let mut r = LockdownReport::new();
        r.record("a", true, Status::Applied);
        r.record("b", false, Status::Failed("E2BIG".into()));
        assert_eq!(r.level(), Level::Partial);
    }

    #[test]
    fn nothing_applied_is_none() {
        let mut r = LockdownReport::new();
        r.require("a", Err("x".into()));
        assert_eq!(r.level(), Level::None);
    }

    #[test]
    fn json_escapes_details() {
        let mut r = LockdownReport::new();
        r.require("a", Err("quote \" and \n newline".into()));
        let j = r.to_json();
        assert!(j.contains("quote \\\" and \\n newline"));
    }
}
