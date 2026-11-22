//! macOS: the Mach ports the process inherited are cut off, then a
//! deny-default Seatbelt profile is applied to the running process, plus the
//! rlimits macOS enforces (CPU, file size, core dumps). macOS gives an
//! unprivileged process no way to bound its own memory (`RLIMIT_AS` and
//! `RLIMIT_DATA` cannot be lowered, and the jetsam and footprint limits need
//! privilege), so the interpreter's allocator limit is the heap bound and the
//! host's deadline kill is the backstop.

use std::ffi::{c_char, c_int, CStr, CString};
use std::io;

use crate::{LockdownReport, CPU_LIMIT_SECONDS};

/// The Seatbelt profile. `(deny default)` alone leaves several operation
/// classes open, so they are denied by name; README.md ("macOS profile")
/// lists what each line closes and what stays possible.
///
/// - `process-info*`: `proc_listallpids`, `proc_pidinfo`, `proc_pidpath`,
///   `proc_pid_rusage` and `sysctl(KERN_PROCARGS2)` on other processes; the
///   last returns another process's whole environment, credentials included.
/// - `file-test-existence`: `access()` as an existence oracle for any path.
/// - `process-codesigning*`, `dynamic-code-generation` (`MAP_JIT`),
///   `system-info`, `iokit-get-properties`: code-signing queries, JIT
///   mappings, system information and I/O Registry properties (serial
///   number, platform UUID).
/// - `syscall-mig`: the kernel MIG routines on the host and processor-set
///   ports (CPU load per core, memory statistics, kernel version, task and
///   thread counts, clocks) and the I/O Kit main port and registry lookups.
/// - `syscall-unix`: system calls with no operation of their own that read or
///   touch other processes or the machine (`getppid`, `getpriority`/
///   `setpriority` on another pid, `gethostuuid`, `getfsstat`, `proc_info`,
///   `memorystatus_control`, System V IPC) and the ones that start processes
///   or create sockets, which the operations above already refuse. Also the
///   process group and session of any pid (`getpgid`, `getsid`: they
///   enumerate processes), leaving the server's process group or session
///   (`setpgid`, `setsid`), kernel event queues (`kqueue`, `kevent*`: they
///   watch other processes fork, exec and exit), the memory pressure level,
///   the login name, the audit identity and session, and kernel trace
///   points. (`csops` is listed too, but Seatbelt does not filter it, nor
///   `kill`; README.md says what they still answer.)
/// - `syscall-mig` on the task: reading the task's exception ports, special
///   ports and registered ports. [`apply_thread_scoped`] nulls the ones it
///   can before the profile applies; `TASK_ACCESS_PORT` cannot be changed
///   without privilege, and this rule is what keeps it out of reach.
///
/// Applied after the dynamic loader has finished, so the process needs no
/// allowances for it. Reading and writing the descriptors that are already
/// open (stdio) is not re-checked. The runner needs nothing this profile
/// denies; its own process is not exempted from any line.
pub const PROFILE: &str = r#"(version 1)
(deny default)
(deny process-info*)
(deny file-test-existence)
(deny process-codesigning*)
(deny dynamic-code-generation)
(deny system-info)
(deny iokit-get-properties)
(deny syscall-mig (kernel-mig-routine
  host_info host_kernel_version host_processor_info host_get_io_master
  host_get_clock_service host_statistics_from_user host_statistics64_from_user
  host_processor_sets host_get_special_port host_virtual_physical_table_info
  host_request_notification host_page_size host_lockgroup_info mach_zone_info
  mach_memory_info processor_set_default processor_set_statistics
  processor_set_info processor_set_tasks processor_info io_registry_get_root_entry
  io_registry_entry_from_path io_service_get_matching_service
  io_service_get_matching_service_bin io_service_get_matching_services_bin))
(deny syscall-unix (syscall-number
  SYS_getppid SYS_getpriority SYS_setpriority SYS_gethostuuid SYS_getfsstat SYS_getfsstat64
  SYS_csops SYS_csops_audittoken SYS_proc_info SYS_memorystatus_control
  SYS_shmget SYS_shmsys SYS_shmat SYS_msgget SYS_msgsys SYS_msgsnd SYS_msgrcv
  SYS_semget SYS_semsys SYS_semop
  SYS_socket SYS_socketpair SYS_fork SYS_vfork SYS_posix_spawn SYS_execve
  SYS_getpgid SYS_getsid SYS_setpgid SYS_setsid
  SYS_kqueue SYS_kevent SYS_kevent64 SYS_kevent_qos SYS_kevent_id SYS_kqueue_workloop_ctl
  SYS_memorystatus_get_level SYS_getlogin SYS_setlogin
  SYS_getauid SYS_setauid SYS_getaudit_addr SYS_setaudit_addr SYS_audit SYS_auditon SYS_auditctl
  SYS_audit_session_self SYS_audit_session_join SYS_audit_session_port
  SYS_kdebug_trace SYS_kdebug_trace64 SYS_kdebug_trace_string SYS_kdebug_typefilter))
(deny syscall-mig (kernel-mig-routine
  task_get_special_port_from_user task_get_exception_ports_from_user
  thread_get_exception_ports_from_user mach_ports_lookup))
"#;

extern "C" {
    fn sandbox_init(profile: *const c_char, flags: u64, errorbuf: *mut *mut c_char) -> c_int;
    fn sandbox_free_error(errorbuf: *mut c_char);
    fn sandbox_check(pid: libc::pid_t, operation: *const c_char, filter_type: c_int, ...) -> c_int;
}

const SANDBOX_FILTER_NONE: c_int = 0;

pub fn close_inherited_fds() -> Result<(), String> {
    // /dev/fd lists this process's descriptors. Collect first so the
    // listing's own descriptor is closed before the loop runs.
    let fds: Vec<i32> = std::fs::read_dir("/dev/fd")
        .map_err(|e| format!("list /dev/fd: {e}"))?
        .filter_map(|entry| entry.ok()?.file_name().to_str()?.parse().ok())
        .collect();
    for fd in fds.into_iter().filter(|fd| *fd > 2) {
        // SAFETY: closing a descriptor number touches no memory.
        unsafe { libc::close(fd) };
    }
    // Confirm nothing above 2 survived (fcntl on a closed fd gives EBADF).
    for fd in 3..256 {
        // SAFETY: F_GETFD only queries flags.
        if unsafe { libc::fcntl(fd, libc::F_GETFD) } != -1 {
            return Err(format!("descriptor {fd} is still open"));
        }
    }
    Ok(())
}

// Mach, from <mach/*.h>.
pub(crate) type MachPort = u32;
type KernReturn = c_int;
const KERN_SUCCESS: KernReturn = 0;
const MACH_PORT_NULL: MachPort = 0;
const MACH_PORT_DEAD: MachPort = !0;
const MACH_PORT_RIGHT_SEND: u32 = 0;
const EXCEPTION_DEFAULT: c_int = 1;
#[cfg(target_arch = "aarch64")]
const THREAD_STATE_NONE: c_int = 5;
#[cfg(target_arch = "x86_64")]
const THREAD_STATE_NONE: c_int = 13;
/// `EXC_MASK_ALL | EXC_MASK_CRASH | EXC_MASK_CORPSE_NOTIFY`: every
/// exception type a task or thread can name a handler for.
pub(crate) const EXC_MASK_EVERY: u32 = 0x3ffe;
pub(crate) const TASK_BOOTSTRAP_PORT: c_int = 4;
pub(crate) const TASK_ACCESS_PORT: c_int = 9;
pub(crate) const TASK_DEBUG_CONTROL_PORT: c_int = 10;
const EXC_TYPES_COUNT: usize = 32;

pub(crate) fn port_valid(p: MachPort) -> bool {
    p != MACH_PORT_NULL && p != MACH_PORT_DEAD
}

extern "C" {
    pub(crate) static mut bootstrap_port: MachPort;
    static mach_task_self_: MachPort;
    pub(crate) fn mach_thread_self() -> MachPort;
    fn task_set_exception_ports(task: MachPort, mask: u32, port: MachPort, behavior: c_int, flavor: c_int) -> KernReturn;
    fn thread_set_exception_ports(thread: MachPort, mask: u32, port: MachPort, behavior: c_int, flavor: c_int) -> KernReturn;
    fn task_get_exception_ports(
        task: MachPort,
        mask: u32,
        masks: *mut u32,
        count: *mut u32,
        ports: *mut MachPort,
        behaviors: *mut c_int,
        flavors: *mut c_int,
    ) -> KernReturn;
    fn thread_get_exception_ports(
        thread: MachPort,
        mask: u32,
        masks: *mut u32,
        count: *mut u32,
        ports: *mut MachPort,
        behaviors: *mut c_int,
        flavors: *mut c_int,
    ) -> KernReturn;
    fn mach_ports_register(task: MachPort, ports: *mut MachPort, count: u32) -> KernReturn;
    fn mach_ports_lookup(task: MachPort, ports: *mut *mut MachPort, count: *mut u32) -> KernReturn;
    fn task_set_special_port(task: MachPort, which: c_int, port: MachPort) -> KernReturn;
    pub(crate) fn task_get_special_port(task: MachPort, which: c_int, port: *mut MachPort) -> KernReturn;
    fn mach_port_get_refs(task: MachPort, name: MachPort, right: u32, refs: *mut u32) -> KernReturn;
    fn mach_port_mod_refs(task: MachPort, name: MachPort, right: u32, delta: i32) -> KernReturn;
    pub(crate) fn mach_port_deallocate(task: MachPort, name: MachPort) -> KernReturn;
    fn vm_deallocate(task: MachPort, address: usize, size: usize) -> KernReturn;
}

/// This task's own port name, which libSystem sets up at start.
pub(crate) fn task() -> MachPort {
    // SAFETY: a plain read of a global that is written once, before main.
    unsafe { mach_task_self_ }
}

/// Exception handler ports set for the task (`thread` false) or the
/// calling thread, as the kernel reports them. Each valid port in the
/// answer is a new send right, so the caller deallocates it.
pub(crate) fn exception_ports(thread: bool) -> Result<Vec<MachPort>, KernReturn> {
    let mut masks = [0u32; EXC_TYPES_COUNT];
    let mut ports = [0 as MachPort; EXC_TYPES_COUNT];
    let mut behaviors = [0 as c_int; EXC_TYPES_COUNT];
    let mut flavors = [0 as c_int; EXC_TYPES_COUNT];
    let mut count = EXC_TYPES_COUNT as u32;
    // SAFETY: every array holds EXC_TYPES_COUNT entries and count says so.
    let kr = unsafe {
        if thread {
            let me = mach_thread_self();
            let kr = thread_get_exception_ports(
                me,
                EXC_MASK_EVERY,
                masks.as_mut_ptr(),
                &mut count,
                ports.as_mut_ptr(),
                behaviors.as_mut_ptr(),
                flavors.as_mut_ptr(),
            );
            mach_port_deallocate(task(), me);
            kr
        } else {
            task_get_exception_ports(
                task(),
                EXC_MASK_EVERY,
                masks.as_mut_ptr(),
                &mut count,
                ports.as_mut_ptr(),
                behaviors.as_mut_ptr(),
                flavors.as_mut_ptr(),
            )
        }
    };
    if kr != KERN_SUCCESS {
        return Err(kr);
    }
    Ok(ports[..(count as usize).min(EXC_TYPES_COUNT)]
        .iter()
        .copied()
        .filter(|p| port_valid(*p))
        .collect())
}

/// The task's registered ports (`mach_ports_register`), valid ones only;
/// each is a new send right.
pub(crate) fn registered_ports() -> Result<Vec<MachPort>, KernReturn> {
    let mut array: *mut MachPort = std::ptr::null_mut();
    let mut count = 0u32;
    // SAFETY: the kernel returns an array it allocated in this task.
    let kr = unsafe { mach_ports_lookup(task(), &mut array, &mut count) };
    if kr != KERN_SUCCESS {
        return Err(kr);
    }
    if array.is_null() {
        return Ok(Vec::new());
    }
    // SAFETY: array holds count entries; it is released right after.
    let ports: Vec<MachPort> = unsafe { std::slice::from_raw_parts(array, count as usize) }
        .iter()
        .copied()
        .filter(|p| port_valid(*p))
        .collect();
    // SAFETY: deallocates the array the kernel allocated for this call.
    unsafe { vm_deallocate(task(), array as usize, count as usize * std::mem::size_of::<MachPort>()) };
    Ok(ports)
}

fn special_port(which: c_int) -> Result<MachPort, KernReturn> {
    let mut port = MACH_PORT_NULL;
    // SAFETY: port is a valid out-pointer.
    let kr = unsafe { task_get_special_port(task(), which, &mut port) };
    if kr != KERN_SUCCESS {
        return Err(kr);
    }
    Ok(port)
}

fn release(ports: &[MachPort]) {
    for p in ports {
        // SAFETY: each is a send right the kernel just gave this task.
        unsafe { mach_port_deallocate(task(), *p) };
    }
}

pub fn apply_thread_scoped(report: &mut LockdownReport) {
    report.require("mach_ports", mach_ports());
}

/// Cuts the process off from the Mach ports it inherited: the task's and
/// this thread's exception handlers (a parent's crash reporter, which would
/// otherwise receive whatever the runner sends it), the registered ports,
/// the bootstrap port (launchd; the profile denies its lookups, but launchd
/// answers other requests) and the debug control port. Then reads each one
/// back. Runs before any other thread exists; threads created later start
/// with no exception ports of their own. `TASK_ACCESS_PORT` cannot be
/// changed without privilege; the profile denies reading it.
fn mach_ports() -> Result<(), String> {
    let me = task();
    // SAFETY: Mach calls on this task and thread with null ports; the
    // thread port from mach_thread_self is released after use.
    let set = unsafe {
        let thread = mach_thread_self();
        let krs = [
            task_set_exception_ports(me, EXC_MASK_EVERY, MACH_PORT_NULL, EXCEPTION_DEFAULT, THREAD_STATE_NONE),
            thread_set_exception_ports(thread, EXC_MASK_EVERY, MACH_PORT_NULL, EXCEPTION_DEFAULT, THREAD_STATE_NONE),
            mach_ports_register(me, std::ptr::null_mut(), 0),
            task_set_special_port(me, TASK_BOOTSTRAP_PORT, MACH_PORT_NULL),
            task_set_special_port(me, TASK_DEBUG_CONTROL_PORT, MACH_PORT_NULL),
        ];
        mach_port_deallocate(me, thread);
        krs
    };
    let names = ["task exception ports", "thread exception ports", "registered ports", "bootstrap port", "debug control port"];
    for (kr, what) in set.iter().zip(names) {
        if *kr != KERN_SUCCESS {
            return Err(format!("clearing the {what}: kern_return {kr}"));
        }
    }
    // libSystem keeps its own send right to the bootstrap port; drop every
    // reference so the name is gone from this task.
    // SAFETY: bootstrap_port is libSystem's global, read and written here
    // before any other thread exists.
    unsafe {
        let name = bootstrap_port;
        if port_valid(name) {
            let mut refs = 0u32;
            let kr = mach_port_get_refs(me, name, MACH_PORT_RIGHT_SEND, &mut refs);
            if kr != KERN_SUCCESS {
                return Err(format!("bootstrap port references: kern_return {kr}"));
            }
            if refs > 0 {
                let kr = mach_port_mod_refs(me, name, MACH_PORT_RIGHT_SEND, -(refs as i32));
                if kr != KERN_SUCCESS {
                    return Err(format!("releasing the bootstrap port: kern_return {kr}"));
                }
            }
            bootstrap_port = MACH_PORT_NULL;
        }
    }
    // Read back. Nothing valid comes back, so nothing needs releasing on
    // success; on failure the rights are released before reporting.
    for (thread, what) in [(false, "task"), (true, "thread")] {
        let ports = exception_ports(thread).map_err(|kr| format!("reading the {what} exception ports: kern_return {kr}"))?;
        if !ports.is_empty() {
            release(&ports);
            return Err(format!("{} {what} exception port(s) still set", ports.len()));
        }
    }
    let registered = registered_ports().map_err(|kr| format!("reading the registered ports: kern_return {kr}"))?;
    if !registered.is_empty() {
        release(&registered);
        return Err(format!("{} registered port(s) still set", registered.len()));
    }
    for (which, what) in [(TASK_BOOTSTRAP_PORT, "bootstrap"), (TASK_DEBUG_CONTROL_PORT, "debug control")] {
        let port = special_port(which).map_err(|kr| format!("reading the {what} port: kern_return {kr}"))?;
        if port_valid(port) {
            release(&[port]);
            return Err(format!("the {what} port is still set"));
        }
    }
    Ok(())
}

pub fn apply_process_wide(report: &mut LockdownReport) {
    report.require("rlimits", rlimits());
    report.require("seatbelt", seatbelt());
}

fn set_limit(resource: c_int, soft: u64, hard: u64, name: &str) -> Result<(), String> {
    let lim = libc::rlimit {
        rlim_cur: soft as libc::rlim_t,
        rlim_max: hard as libc::rlim_t,
    };
    // SAFETY: lim is valid for the call.
    if unsafe { libc::setrlimit(resource, &lim) } != 0 {
        return Err(format!("{name}: {}", io::Error::last_os_error()));
    }
    Ok(())
}

fn rlimits() -> Result<(), String> {
    set_limit(libc::RLIMIT_CORE, 0, 0, "RLIMIT_CORE")?;
    set_limit(libc::RLIMIT_FSIZE, 0, 0, "RLIMIT_FSIZE")?;
    set_limit(
        libc::RLIMIT_CPU,
        CPU_LIMIT_SECONDS,
        CPU_LIMIT_SECONDS + 5,
        "RLIMIT_CPU",
    )
}

fn seatbelt() -> Result<(), String> {
    let profile = CString::new(PROFILE).expect("profile has no NUL");
    let mut err: *mut c_char = std::ptr::null_mut();
    // SAFETY: profile is a valid C string; err is a valid out-pointer.
    let rc = unsafe { sandbox_init(profile.as_ptr(), 0, &mut err) };
    if rc != 0 {
        let msg = if err.is_null() {
            format!("sandbox_init returned {rc}")
        } else {
            // SAFETY: sandbox_init set err to a C string we must free.
            let text = unsafe { CStr::from_ptr(err) }.to_string_lossy().into_owned();
            // SAFETY: err came from sandbox_init.
            unsafe { sandbox_free_error(err) };
            format!("sandbox_init: {text}")
        };
        return Err(msg);
    }
    // Ask the kernel whether this process is now sandboxed.
    // SAFETY: a NULL operation queries sandbox membership only.
    let sandboxed =
        unsafe { sandbox_check(libc::getpid(), std::ptr::null(), SANDBOX_FILTER_NONE) };
    if sandboxed != 1 {
        return Err(format!("sandbox_check reports {sandboxed} after sandbox_init"));
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    extern "C" {
        fn mach_port_allocate(task: MachPort, right: u32, name: *mut MachPort) -> KernReturn;
        fn mach_port_insert_right(task: MachPort, name: MachPort, right: MachPort, kind: u32) -> KernReturn;
    }
    const MACH_PORT_RIGHT_RECEIVE: u32 = 1;
    const MACH_MSG_TYPE_MAKE_SEND: u32 = 20;

    /// Runs this test binary again with `var` set, running only `test`, and
    /// returns how it ended and what it printed.
    fn child(test: &str, var: &str) -> (std::process::ExitStatus, String) {
        let out = std::process::Command::new(std::env::current_exe().unwrap())
            .args(["--exact", test, "--nocapture", "--test-threads=1"])
            .env(var, "1")
            .output()
            .unwrap();
        (out.status, String::from_utf8_lossy(&out.stdout).into_owned())
    }

    /// An exception handler set before the lockdown (as a parent's crash
    /// reporter would be) is gone after the `mach_ports` step, and the
    /// readback is what says so.
    #[test]
    fn mach_ports_clears_an_exception_handler() {
        if std::env::var_os("CC_MACH_PORTS_CHILD").is_some() {
            let me = task();
            let mut port = MACH_PORT_NULL;
            // SAFETY: allocates a receive right in this task and gives it a
            // send right, which the handler setting takes.
            unsafe {
                assert_eq!(mach_port_allocate(me, MACH_PORT_RIGHT_RECEIVE, &mut port), KERN_SUCCESS);
                assert_eq!(mach_port_insert_right(me, port, port, MACH_MSG_TYPE_MAKE_SEND), KERN_SUCCESS);
                assert_eq!(
                    task_set_exception_ports(me, EXC_MASK_EVERY, port, EXCEPTION_DEFAULT, THREAD_STATE_NONE),
                    KERN_SUCCESS
                );
            }
            let before = exception_ports(false).unwrap();
            assert!(!before.is_empty());
            release(&before);
            assert_eq!(mach_ports(), Ok(()));
            assert!(exception_ports(false).unwrap().is_empty());
            assert!(registered_ports().unwrap().is_empty());
            // SAFETY: reads libSystem's global.
            assert_eq!(unsafe { bootstrap_port }, MACH_PORT_NULL);
            println!("mach_ports cleared a handler that was set");
            return;
        }
        let (status, text) = child("macos::tests::mach_ports_clears_an_exception_handler", "CC_MACH_PORTS_CHILD");
        assert!(status.success() && text.contains("mach_ports cleared a handler that was set"), "{status}: {text}");
    }

    /// `abort()` still ends the process with SIGABRT under the full
    /// lockdown (the profile denies neither `__pthread_kill` nor the signal
    /// to itself), so a Rust or QuickJS abort reads as an abort, not a hang.
    #[test]
    fn abort_works_under_the_lockdown() {
        if std::env::var_os("CC_ABORT_CHILD").is_some() {
            let report = crate::apply();
            println!("lockdown {}", report.level().as_str());
            use std::io::Write;
            let _ = std::io::stdout().flush();
            // SAFETY: ends this child process.
            unsafe { libc::abort() };
        }
        let (status, text) = child("macos::tests::abort_works_under_the_lockdown", "CC_ABORT_CHILD");
        use std::os::unix::process::ExitStatusExt;
        assert!(text.contains("lockdown full"), "{text}");
        assert_eq!(status.signal(), Some(libc::SIGABRT), "{status}: {text}");
    }
}
