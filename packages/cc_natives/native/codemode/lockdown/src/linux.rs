//! Linux: no_new_privs, no capabilities, Landlock, not dumpable, rlimits and
//! a seccomp-bpf allowlist whose default action kills the process. Needs no
//! namespaces or capabilities, so it works for an unprivileged user inside a
//! container; started as root, it drops every capability it was given.

use std::collections::BTreeMap;
use std::io;

use seccompiler::{
    BpfProgram, SeccompAction, SeccompCmpArgLen, SeccompCmpOp, SeccompCondition, SeccompFilter,
    SeccompRule, TargetArch,
};

use crate::{LockdownReport, Status, ADDRESS_SPACE_LIMIT_BYTES, CPU_LIMIT_SECONDS};

fn errno_text(what: &str) -> String {
    let e = io::Error::last_os_error();
    format!("{what}: {e}")
}

pub fn close_inherited_fds() -> Result<(), String> {
    // SAFETY: close_range only closes descriptors; it touches no memory.
    let rc = unsafe { libc::syscall(libc::SYS_close_range, 3u32, u32::MAX, 0u32) };
    if rc == 0 {
        return Ok(());
    }
    let err = io::Error::last_os_error();
    if err.raw_os_error() != Some(libc::ENOSYS) {
        return Err(format!("close_range: {err}"));
    }
    // Kernels before 5.9: list /proc/self/fd, then close everything above 2.
    // The listing's own descriptor is closed when the iterator drops, before
    // the loop runs, so closing it again just reports EBADF.
    let fds: Vec<i32> = std::fs::read_dir("/proc/self/fd")
        .map_err(|e| format!("list /proc/self/fd: {e}"))?
        .filter_map(|entry| entry.ok()?.file_name().to_str()?.parse().ok())
        .collect();
    for fd in fds.into_iter().filter(|fd| *fd > 2) {
        // SAFETY: closing a descriptor number touches no memory.
        unsafe { libc::close(fd) };
    }
    Ok(())
}

pub fn single_malloc_arena() {
    // SAFETY: mallopt only changes allocator tuning; called before threads.
    unsafe { libc::mallopt(libc::M_ARENA_MAX, 1) };
}

pub fn apply_thread_scoped(report: &mut LockdownReport) {
    fix_time_zone();
    report.require("personality", personality_check());
    report.require("no_new_privs", no_new_privs());
    report.require("capabilities", drop_capabilities());
    landlock(report);
}

// From <linux/capability.h> and <linux/prctl.h>.
const LINUX_CAPABILITY_VERSION_3: u32 = 0x2008_0522;
const PR_CAPBSET_READ: libc::c_int = 23;
const PR_CAP_AMBIENT_IS_SET: libc::c_ulong = 1;
const CAP_SETPCAP: libc::c_ulong = 8;

#[repr(C)]
struct CapHeader {
    version: u32,
    pid: libc::c_int,
}

#[repr(C)]
#[derive(Clone, Copy, Default)]
struct CapData {
    effective: u32,
    permitted: u32,
    inheritable: u32,
}

fn capget() -> Result<[CapData; 2], String> {
    let mut header = CapHeader {
        version: LINUX_CAPABILITY_VERSION_3,
        pid: 0,
    };
    let mut data = [CapData::default(); 2];
    // SAFETY: version 3 takes two data entries, both valid out-pointers.
    if unsafe { libc::syscall(libc::SYS_capget, &mut header as *mut CapHeader, data.as_mut_ptr()) } != 0 {
        return Err(errno_text("capget"));
    }
    Ok(data)
}

/// Capability numbers the kernel knows: `PR_CAPBSET_READ` answers 0 or 1
/// for each and `EINVAL` past the last.
fn known_capabilities() -> impl Iterator<Item = libc::c_ulong> {
    // SAFETY: prctl with integer arguments.
    (0..64).take_while(|cap| unsafe { libc::prctl(PR_CAPBSET_READ, *cap, 0, 0, 0) } >= 0)
}

/// Empties the effective, permitted, inheritable and ambient sets and, when
/// the process may (it holds `CAP_SETPCAP`, as root does), the bounding
/// set; then reads each back. A process started as root keeps uid 0 but no
/// capability, so the kernel grants it nothing a user would not get. The
/// bounding set only limits what an exec could gain, which `no_new_privs`
/// and the filter (no `execve`) already rule out, so an unprivileged process,
/// which cannot change it, leaves it as it is.
fn drop_capabilities() -> Result<(), String> {
    let before = capget()?;
    let may_drop_bounding = before[0].effective & (1 << CAP_SETPCAP) != 0;
    if may_drop_bounding {
        for cap in known_capabilities() {
            // SAFETY: prctl with integer arguments.
            if unsafe { libc::prctl(PR_CAPBSET_READ, cap, 0, 0, 0) } == 1
                && unsafe { libc::prctl(libc::PR_CAPBSET_DROP, cap, 0, 0, 0) } != 0
            {
                return Err(errno_text(&format!("PR_CAPBSET_DROP {cap}")));
            }
        }
    }
    // SAFETY: prctl with integer arguments. Kernels before 4.3 have no
    // ambient set and answer EINVAL; there is nothing to clear then.
    let rc = unsafe { libc::prctl(libc::PR_CAP_AMBIENT, libc::PR_CAP_AMBIENT_CLEAR_ALL as libc::c_ulong, 0, 0, 0) };
    if rc != 0 && io::Error::last_os_error().raw_os_error() != Some(libc::EINVAL) {
        return Err(errno_text("PR_CAP_AMBIENT_CLEAR_ALL"));
    }
    let mut header = CapHeader {
        version: LINUX_CAPABILITY_VERSION_3,
        pid: 0,
    };
    let empty = [CapData::default(); 2];
    // SAFETY: version 3 takes two data entries.
    if unsafe { libc::syscall(libc::SYS_capset, &mut header as *mut CapHeader, empty.as_ptr()) } != 0 {
        return Err(errno_text("capset"));
    }
    let after = capget()?;
    if after.iter().any(|d| d.effective | d.permitted | d.inheritable != 0) {
        return Err("capabilities remain after capset".into());
    }
    for cap in known_capabilities() {
        // SAFETY: prctl with integer arguments.
        if unsafe { libc::prctl(libc::PR_CAP_AMBIENT, PR_CAP_AMBIENT_IS_SET, cap, 0, 0) } == 1 {
            return Err(format!("ambient capability {cap} remains"));
        }
        // SAFETY: as above.
        if may_drop_bounding && unsafe { libc::prctl(PR_CAPBSET_READ, cap, 0, 0, 0) } != 0 {
            return Err(format!("bounding capability {cap} remains"));
        }
    }
    Ok(())
}

/// `READ_IMPLIES_EXEC` from `<sys/personality.h>`: with it set, every
/// readable mapping is also executable, whatever `mmap` and `mprotect` were
/// asked for, which would void the filter's no-exec rules. The kernel clears
/// it when it executes a 64-bit program (x86_64 `set_personality_64bit`,
/// arm64 `SET_PERSONALITY`), so `setarch -X` does not reach the runner; the
/// step below clears it anyway if it is set, refuses to continue if it stays
/// set, and the filter refuses `personality` afterwards.
const READ_IMPLIES_EXEC: libc::c_int = 0x0040_0000;

fn current_personality() -> libc::c_int {
    // SAFETY: 0xffffffff only queries the persona.
    unsafe { libc::personality(0xffff_ffff) }
}

/// Clears `READ_IMPLIES_EXEC` if it is set and fails unless it is clear
/// afterwards. Runs before any mapping the script can reach is made.
fn personality_check() -> Result<(), String> {
    let persona = current_personality();
    if persona == -1 {
        return Err(errno_text("personality query"));
    }
    if persona & READ_IMPLIES_EXEC != 0 {
        // SAFETY: sets the persona of this thread, before any other exists.
        unsafe { libc::personality((persona & !READ_IMPLIES_EXEC) as libc::c_ulong) };
        let now = current_personality();
        if now == -1 || now & READ_IMPLIES_EXEC != 0 {
            return Err("READ_IMPLIES_EXEC is set and could not be cleared, so readable memory is executable".into());
        }
    }
    Ok(())
}

pub fn apply_process_wide(report: &mut LockdownReport) {
    report.require("not_dumpable", not_dumpable());
    report.require("rlimits", rlimits());
    report.require("seccomp", seccomp());
}

extern "C" {
    fn tzset();
}

/// glibc loads the time zone the first time anything asks for local time
/// (a script's `getTimezoneOffset` or `toString`), and with `TZ` unset that
/// opens `/etc/localtime`, which seccomp answers by killing the process. So
/// the zone is fixed to UTC and loaded here, before any confinement: glibc
/// keeps it and does not look again while `TZ` is unchanged. UTC also keeps
/// the host's zone out of the script and matches macOS, where the sandbox
/// denies the zone file and libc falls back to UTC.
fn fix_time_zone() {
    // Runs before any other thread exists, so nothing reads the environment
    // concurrently.
    std::env::set_var("TZ", "UTC0");
    // SAFETY: tzset takes no arguments and only fills libc's zone state.
    unsafe { tzset() };
}

pub(crate) fn no_new_privs() -> Result<(), String> {
    // SAFETY: prctl with integer arguments.
    if unsafe { libc::prctl(libc::PR_SET_NO_NEW_PRIVS, 1, 0, 0, 0) } != 0 {
        return Err(errno_text("PR_SET_NO_NEW_PRIVS"));
    }
    // SAFETY: as above.
    match unsafe { libc::prctl(libc::PR_GET_NO_NEW_PRIVS, 0, 0, 0, 0) } {
        1 => Ok(()),
        other => Err(format!("PR_GET_NO_NEW_PRIVS returned {other}")),
    }
}

fn not_dumpable() -> Result<(), String> {
    // SAFETY: prctl with integer arguments.
    if unsafe { libc::prctl(libc::PR_SET_DUMPABLE, 0, 0, 0, 0) } != 0 {
        return Err(errno_text("PR_SET_DUMPABLE"));
    }
    // SAFETY: as above.
    match unsafe { libc::prctl(libc::PR_GET_DUMPABLE, 0, 0, 0, 0) } {
        0 => Ok(()),
        other => Err(format!("PR_GET_DUMPABLE returned {other}")),
    }
}

fn set_limit(resource: libc::__rlimit_resource_t, soft: u64, hard: u64, name: &str) -> Result<(), String> {
    let lim = libc::rlimit {
        rlim_cur: soft as libc::rlim_t,
        rlim_max: hard as libc::rlim_t,
    };
    // SAFETY: lim is a valid rlimit for the duration of the call.
    if unsafe { libc::setrlimit(resource, &lim) } != 0 {
        return Err(errno_text(name));
    }
    let mut got = libc::rlimit {
        rlim_cur: 0,
        rlim_max: 0,
    };
    // SAFETY: got is a valid out-pointer.
    if unsafe { libc::getrlimit(resource, &mut got) } != 0 {
        return Err(errno_text(name));
    }
    if got.rlim_cur > soft || got.rlim_max > hard {
        return Err(format!("{name}: limit did not take effect"));
    }
    Ok(())
}

fn rlimits() -> Result<(), String> {
    set_limit(libc::RLIMIT_CORE, 0, 0, "RLIMIT_CORE")?;
    set_limit(libc::RLIMIT_FSIZE, 0, 0, "RLIMIT_FSIZE")?;
    set_limit(libc::RLIMIT_NPROC, 0, 0, "RLIMIT_NPROC")?;
    set_limit(libc::RLIMIT_NOFILE, 3, 3, "RLIMIT_NOFILE")?;
    set_limit(
        libc::RLIMIT_AS,
        ADDRESS_SPACE_LIMIT_BYTES,
        ADDRESS_SPACE_LIMIT_BYTES,
        "RLIMIT_AS",
    )?;
    set_limit(
        libc::RLIMIT_CPU,
        CPU_LIMIT_SECONDS,
        CPU_LIMIT_SECONDS + 5,
        "RLIMIT_CPU",
    )?;
    Ok(())
}

// Landlock, through the raw syscalls (uapi/linux/landlock.h).
const LANDLOCK_CREATE_RULESET_VERSION: u32 = 1 << 0;

#[repr(C)]
struct RulesetAttr {
    handled_access_fs: u64,
    handled_access_net: u64,
    scoped: u64,
}

/// Every filesystem right the kernel's ABI version knows, so the ruleset
/// (which has no rules) denies all of them.
fn fs_rights(abi: i64) -> u64 {
    let highest_bit = match abi {
        1 => 12, // EXECUTE .. MAKE_SYM
        2 => 13, // + REFER
        3 | 4 => 14, // + TRUNCATE
        _ => 15, // + IOCTL_DEV (ABI 5 and later)
    };
    (1u64 << (highest_bit + 1)) - 1
}

pub(crate) fn landlock(report: &mut LockdownReport) {
    // SAFETY: a version query passes no pointers the kernel writes to.
    let abi = unsafe {
        libc::syscall(
            libc::SYS_landlock_create_ruleset,
            std::ptr::null::<RulesetAttr>(),
            0usize,
            LANDLOCK_CREATE_RULESET_VERSION,
        )
    };
    if abi < 0 {
        let err = io::Error::last_os_error();
        let status = match err.raw_os_error() {
            Some(libc::ENOSYS) => Status::Unavailable("kernel has no Landlock (ENOSYS); seccomp still denies file access".into()),
            Some(libc::EOPNOTSUPP) => Status::Unavailable("Landlock is disabled at boot (EOPNOTSUPP); seccomp still denies file access".into()),
            // A container runtime's own seccomp profile that does not know
            // Landlock answers the version query with EPERM. That says
            // nothing about this process's filter, which is the required
            // control, so it counts as absent, like ENOSYS.
            Some(libc::EPERM) => Status::Unavailable("the container refuses Landlock (EPERM on the version query); seccomp still denies file access".into()),
            _ => Status::Failed(format!("landlock_create_ruleset version query: {err}")),
        };
        report.record("landlock", false, status);
        return;
    }
    let attr = RulesetAttr {
        handled_access_fs: fs_rights(abi),
        // ABI 4: TCP bind and connect.
        handled_access_net: if abi >= 4 { 0b11 } else { 0 },
        // ABI 6: abstract UNIX sockets and signals outside the domain.
        scoped: if abi >= 6 { 0b11 } else { 0 },
    };
    let size = if abi >= 6 {
        24
    } else if abi >= 4 {
        16
    } else {
        8
    };
    // SAFETY: attr outlives the call and `size` does not exceed it.
    let fd = unsafe {
        libc::syscall(
            libc::SYS_landlock_create_ruleset,
            &attr as *const RulesetAttr,
            size as usize,
            0u32,
        )
    };
    if fd < 0 {
        report.record(
            "landlock",
            false,
            Status::Failed(errno_text("landlock_create_ruleset")),
        );
        return;
    }
    // SAFETY: fd is the ruleset descriptor just returned.
    let rc = unsafe { libc::syscall(libc::SYS_landlock_restrict_self, fd as i32, 0u32) };
    let status = if rc == 0 {
        Status::Applied
    } else {
        Status::Failed(errno_text("landlock_restrict_self"))
    };
    // SAFETY: closing our own ruleset descriptor.
    unsafe { libc::close(fd as i32) };
    report.record("landlock", false, status);
}

fn target_arch() -> TargetArch {
    #[cfg(target_arch = "x86_64")]
    {
        TargetArch::x86_64
    }
    #[cfg(target_arch = "aarch64")]
    {
        TargetArch::aarch64
    }
}

fn cond(arg: u8, op: SeccompCmpOp, value: u64) -> Result<SeccompCondition, String> {
    SeccompCondition::new(arg, SeccompCmpArgLen::Dword, op, value).map_err(|e| e.to_string())
}

fn rule(conditions: Vec<SeccompCondition>) -> Result<SeccompRule, String> {
    SeccompRule::new(conditions).map_err(|e| e.to_string())
}

/// Highest static clock id (`CLOCK_TAI`). Negative ids name the CPU clock
/// of another process or thread, which the kernel hands out without a
/// permission check; compared as unsigned 32-bit numbers they are all above
/// this.
const MAX_STATIC_CLOCK: u64 = 11;

/// The futex operations Rust std and glibc use: WAIT, WAKE, WAIT_BITSET and
/// WAKE_BITSET, with or without `FUTEX_PRIVATE_FLAG` and
/// `FUTEX_CLOCK_REALTIME` (both outside the command mask). The priority
/// inheritance and requeue operations stay out.
const FUTEX_CMD_MASK: u64 = 0x7f;
const FUTEX_OPS: [u64; 4] = [0, 1, 9, 10];

/// The `madvise` advice values the allocators use: glibc's `free` and
/// thread-stack release (`DONTNEED`), the transparent huge page hints its
/// tunables may ask for (`HUGEPAGE`, `NOHUGEPAGE`), and `WILLNEED`, `FREE`
/// and `DONTDUMP`. Everything else kills the process, among them
/// `MADV_HWPOISON` and `MADV_SOFT_OFFLINE` (which retire a physical page
/// when the caller has `CAP_SYS_ADMIN`), `MADV_PAGEOUT` and `MADV_COLD`.
///
/// Also `MADV_GUARD_INSTALL` (102), which recent glibc may use for a new
/// thread's stack guard. That is safe only because the runner creates no
/// thread after the filter (clone and clone3 are denied too; see
/// `lock_down` in the runner and its `threads_stay_at_three` test). A change
/// that starts a thread later must start it before the filter, or this list
/// must grow.
pub(crate) const MADVISE_ADVICE: [libc::c_int; 6] = [
    libc::MADV_WILLNEED,
    libc::MADV_DONTNEED,
    libc::MADV_FREE,
    libc::MADV_HUGEPAGE,
    libc::MADV_NOHUGEPAGE,
    libc::MADV_DONTDUMP,
];

/// The allowlist, by system call number, for the process `pid`. Everything
/// else kills the process.
fn rules(pid: u32) -> Result<BTreeMap<i64, Vec<SeccompRule>>, String> {
    let mut rules: BTreeMap<i64, Vec<SeccompRule>> = BTreeMap::new();
    // Unconditional: memory housekeeping, signal return, randomness for hash
    // seeds, and exit.
    //
    // gettimeofday: QuickJS reads the wall clock with it (Date.now and the
    // context's random seed, created after the lockdown). The vDSO normally
    // answers without entering the kernel, but on a clocksource the vDSO
    // cannot read (hpet or acpi_pm, as on a VM without a stable TSC) it falls
    // back to the real system call. It only writes the time into the caller's
    // own memory, and unlike clock_gettime it takes no clock id.
    //
    // gettid: the first time a thread blocks on a std channel, std builds
    // the thread's handle and asks the kernel for its id. The main thread
    // usually does that before the lockdown (waiting for the reader thread to
    // start), but when the reader starts first, the first wait comes after
    // it. It takes no arguments and returns the caller's own thread id.
    //
    // getpid: abort() asks for it to address SIGABRT to its own process (see
    // tgkill below). No arguments; the caller's own id.
    for nr in [
        libc::SYS_munmap,
        libc::SYS_mremap,
        libc::SYS_brk,
        libc::SYS_gettimeofday,
        libc::SYS_gettid,
        libc::SYS_getpid,
        libc::SYS_sched_yield,
        libc::SYS_rt_sigreturn,
        libc::SYS_rt_sigprocmask,
        libc::SYS_sigaltstack,
        libc::SYS_restart_syscall,
        libc::SYS_getrandom,
        libc::SYS_exit,
        libc::SYS_exit_group,
    ] {
        rules.insert(nr, vec![]);
    }
    // Static clocks only (the interpreter's CPU budget reads
    // CLOCK_THREAD_CPUTIME_ID, 3). Another process's CPU clock would show
    // when other runs and the server are busy.
    rules.insert(
        libc::SYS_clock_gettime,
        vec![rule(vec![cond(0, SeccompCmpOp::Le, MAX_STATIC_CLOCK)?])?],
    );
    let mut futex = Vec::new();
    for op in FUTEX_OPS {
        futex.push(rule(vec![cond(1, SeccompCmpOp::MaskedEq(FUTEX_CMD_MASK), op)?])?);
    }
    rules.insert(libc::SYS_futex, futex);
    // abort(), whether from a Rust allocation failure or a QuickJS
    // assertion, raises SIGABRT with tgkill(getpid(), gettid(), SIGABRT).
    // Without it the kernel would kill the runner with SIGSYS, which reads as
    // an allowlist violation. Only SIGABRT, and only to this process (a tid
    // outside the thread group `pid` is refused by the kernel), so the
    // runner can signal nothing else.
    rules.insert(
        libc::SYS_tgkill,
        vec![rule(vec![
            cond(0, SeccompCmpOp::Eq, pid as u64)?,
            cond(2, SeccompCmpOp::Eq, libc::SIGABRT as u64)?,
        ])?],
    );
    // A fault (SIGSEGV, SIGBUS) that is not a stack overflow: std's handler
    // puts the default action back with sigaction and returns, so the fault
    // repeats and the kernel ends the process with that signal. Without this
    // rule the handler's sigaction would be SIGSYS, which reads as a system
    // call outside the allowlist. Only those two signals; the new action is
    // a pointer the filter cannot inspect, so the runner can set any action
    // for them, which changes nothing outside the process.
    rules.insert(
        libc::SYS_rt_sigaction,
        vec![
            rule(vec![cond(0, SeccompCmpOp::Eq, libc::SIGSEGV as u64)?])?,
            rule(vec![cond(0, SeccompCmpOp::Eq, libc::SIGBUS as u64)?])?,
        ],
    );
    // read only from stdin; write only to stdout and stderr.
    rules.insert(libc::SYS_read, vec![rule(vec![cond(0, SeccompCmpOp::Eq, 0)?])?]);
    rules.insert(
        libc::SYS_write,
        vec![
            rule(vec![cond(0, SeccompCmpOp::Eq, 1)?])?,
            rule(vec![cond(0, SeccompCmpOp::Eq, 2)?])?,
        ],
    );
    // Anonymous mappings only, never executable.
    let no_exec = cond(2, SeccompCmpOp::MaskedEq(libc::PROT_EXEC as u64), 0)?;
    let anonymous = cond(
        3,
        SeccompCmpOp::MaskedEq(libc::MAP_ANONYMOUS as u64),
        libc::MAP_ANONYMOUS as u64,
    )?;
    rules.insert(libc::SYS_mmap, vec![rule(vec![no_exec.clone(), anonymous])?]);
    rules.insert(libc::SYS_mprotect, vec![rule(vec![no_exec])?]);
    let mut madvise = Vec::new();
    for advice in MADVISE_ADVICE {
        madvise.push(rule(vec![cond(2, SeccompCmpOp::Eq, advice as u64)?])?);
    }
    rules.insert(libc::SYS_madvise, madvise);
    Ok(rules)
}

/// The allowlist compiled to BPF for this architecture.
pub fn filter() -> Result<BpfProgram, String> {
    let filter = SeccompFilter::new(
        rules(std::process::id())?,
        SeccompAction::KillProcess,
        SeccompAction::Allow,
        target_arch(),
    )
    .map_err(|e| e.to_string())?;
    BpfProgram::try_from(filter).map_err(|e| e.to_string())
}

fn seccomp() -> Result<(), String> {
    let program = filter()?;
    seccompiler::apply_filter_all_threads(&program).map_err(|e| format!("seccomp: {e}"))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn filter_compiles() {
        let program = filter().unwrap();
        assert!(!program.is_empty());
    }

    /// Pins the allowlist by raw number per architecture, so a change to
    /// it (or a libc constant resolving differently) is a visible decision.
    #[test]
    fn allowlist_is_pinned_per_architecture() {
        let allowed: Vec<i64> = rules(1).unwrap().into_keys().collect();
        // read write mmap mprotect munmap brk rt_sigaction rt_sigprocmask
        // rt_sigreturn sched_yield mremap madvise getpid exit gettimeofday
        // sigaltstack gettid futex restart_syscall clock_gettime exit_group
        // tgkill getrandom
        #[cfg(target_arch = "x86_64")]
        let expected = [0, 1, 9, 10, 11, 12, 13, 14, 15, 24, 25, 28, 39, 60, 96, 131, 186, 202, 219, 228, 231, 234, 318];
        // futex clock_gettime sched_yield restart_syscall sigaltstack
        // tgkill rt_sigaction rt_sigprocmask rt_sigreturn gettimeofday getpid
        // gettid read write exit exit_group brk munmap mremap mmap mprotect
        // madvise getrandom
        #[cfg(target_arch = "aarch64")]
        let expected = [63, 64, 93, 94, 98, 113, 124, 128, 131, 134, 132, 135, 139, 169, 172, 178, 214, 215, 216, 222, 226, 233, 278];
        let mut expected = expected.to_vec();
        expected.sort_unstable();
        assert_eq!(allowed, expected);
    }

    /// Nothing that opens files or sockets, creates processes or threads,
    /// or changes memory to executable may ever be on the list.
    #[test]
    fn allowlist_has_no_opening_or_spawning_calls() {
        let allowed = rules(1).unwrap();
        // Legacy calls only x86_64 has; aarch64 has just the *at forms below.
        #[cfg(target_arch = "x86_64")]
        let legacy = [
            libc::SYS_open,
            libc::SYS_creat,
            libc::SYS_fork,
            libc::SYS_vfork,
        ];
        #[cfg(target_arch = "aarch64")]
        let legacy: [i64; 0] = [];
        let common = [
            libc::SYS_openat,
            libc::SYS_open_by_handle_at,
            libc::SYS_socket,
            libc::SYS_socketpair,
            libc::SYS_connect,
            libc::SYS_bind,
            libc::SYS_clone,
            libc::SYS_clone3,
            libc::SYS_execve,
            libc::SYS_execveat,
            libc::SYS_ptrace,
            libc::SYS_memfd_create,
            libc::SYS_io_uring_setup,
            libc::SYS_pkey_mprotect,
        ];
        for nr in common.into_iter().chain(legacy) {
            assert!(!allowed.contains_key(&nr), "system call {nr} must stay denied");
        }
    }

    /// The personality step clears `READ_IMPLIES_EXEC`. The flag is set in
    /// a fresh copy of the test binary (the kernel clears it on exec, so it
    /// cannot be passed in), which then runs the step.
    #[test]
    fn read_implies_exec_is_cleared_by_the_personality_control() {
        if std::env::var_os("CC_PERSONALITY_CHILD").is_some() {
            assert_eq!(personality_check(), Ok(()));
            // SAFETY: sets the persona of this test process only.
            let persona = unsafe { libc::personality((current_personality() | READ_IMPLIES_EXEC) as libc::c_ulong) };
            if persona == -1 && std::io::Error::last_os_error().raw_os_error() == Some(libc::EPERM) {
                // Docker's default seccomp profile admits only a few personas.
                println!("\npersonality skipped: this container refuses personality(READ_IMPLIES_EXEC) with EPERM");
                return;
            }
            assert_ne!(persona, -1, "{}", errno_text("personality"));
            let set = current_personality();
            assert_ne!(set & READ_IMPLIES_EXEC, 0);
            assert_eq!(personality_check(), Ok(()));
            let after = current_personality();
            assert_eq!(after & READ_IMPLIES_EXEC, 0);
            println!("\npersonality cleared: READ_IMPLIES_EXEC was set (persona {set:#x}) and the step cleared it (persona {after:#x})");
            return;
        }
        let out = std::process::Command::new(std::env::current_exe().unwrap())
            .args(["--exact", "linux::tests::read_implies_exec_is_cleared_by_the_personality_control", "--nocapture", "--test-threads=1"])
            .env("CC_PERSONALITY_CHILD", "1")
            .output()
            .unwrap();
        let text = String::from_utf8_lossy(&out.stdout);
        assert!(out.status.success(), "child failed:\n{text}\n{}", String::from_utf8_lossy(&out.stderr));
        for line in text.lines().filter(|l| l.starts_with("personality ")) {
            println!("{line}");
        }
        assert!(
            text.contains("personality skipped:")
                || text.contains("personality cleared: READ_IMPLIES_EXEC was set"),
            "{text}"
        );
    }

    /// `sigaction` passes the filter for SIGSEGV and SIGBUS only (std's
    /// fault handler resets those); for any other signal it is SIGSYS.
    #[test]
    fn sigaction_only_for_the_fault_signals() {
        if let Ok(sig) = std::env::var("CC_SIGACTION_CHILD") {
            let sig: libc::c_int = sig.parse().unwrap();
            let report = crate::apply();
            println!("lockdown {}", report.level().as_str());
            use std::io::Write;
            let _ = std::io::stdout().flush();
            // SAFETY: puts the default action back for `sig`.
            let r = unsafe { libc::signal(sig, libc::SIG_DFL) };
            println!("sigaction {sig} {}", if r == libc::SIG_ERR { "failed" } else { "allowed" });
            let _ = std::io::stdout().flush();
            // SAFETY: ends this child without the harness's own clean-up,
            // which runs nothing the test is about.
            unsafe { libc::_exit(0) };
        }
        use std::os::unix::process::ExitStatusExt;
        for (sig, allowed) in [(libc::SIGSEGV, true), (libc::SIGBUS, true), (libc::SIGTERM, false), (libc::SIGINT, false)] {
            let out = std::process::Command::new(std::env::current_exe().unwrap())
                .args(["--exact", "linux::tests::sigaction_only_for_the_fault_signals", "--nocapture", "--test-threads=1"])
                .env("CC_SIGACTION_CHILD", sig.to_string())
                .output()
                .unwrap();
            let text = String::from_utf8_lossy(&out.stdout);
            assert!(text.contains("lockdown full"), "{text}");
            if allowed {
                assert!(out.status.success() && text.contains(&format!("sigaction {sig} allowed")), "{sig}: {}: {text}", out.status);
            } else {
                assert_eq!(out.status.signal(), Some(libc::SIGSYS), "{sig}: {text}");
            }
        }
    }

    /// Landlock on its own, without seccomp, in a fresh process (this test
    /// binary started again), because a Landlock domain cannot be left. The
    /// seccomp filter kills the process before Landlock is ever consulted,
    /// so this is the only place Landlock's own refusals are seen.
    #[test]
    fn landlock_alone_denies_files_network_and_signals() {
        if std::env::var_os("CC_LANDLOCK_CHILD").is_some() {
            return landlock_child();
        }
        let dir = std::env::temp_dir().join(format!("cc_codemode_landlock_{}", std::process::id()));
        std::fs::create_dir_all(&dir).unwrap();
        let readable = dir.join("readable");
        std::fs::write(&readable, b"x").unwrap();
        // Unconfined, every attempt works, so a refusal below is Landlock's.
        let listener = std::net::TcpListener::bind("127.0.0.1:0").unwrap();
        let port = listener.local_addr().unwrap().port();
        std::fs::read(&readable).unwrap();
        std::fs::write(dir.join("unconfined"), b"x").unwrap();
        std::net::TcpStream::connect(("127.0.0.1", port)).unwrap();
        std::net::TcpListener::bind("127.0.0.1:0").unwrap();
        let out = std::process::Command::new(std::env::current_exe().unwrap())
            .args(["--exact", "linux::tests::landlock_alone_denies_files_network_and_signals", "--nocapture", "--test-threads=1"])
            .env("CC_LANDLOCK_CHILD", "1")
            .env("CC_LANDLOCK_DIR", &dir)
            .env("CC_LANDLOCK_PORT", port.to_string())
            .output()
            .unwrap();
        let _ = std::fs::remove_dir_all(&dir);
        let text = String::from_utf8_lossy(&out.stdout);
        let lines: Vec<&str> = text.lines().filter(|l| l.starts_with("landlock ")).collect();
        for l in &lines {
            println!("{l}");
        }
        assert!(out.status.success(), "child failed:\n{text}\n{}", String::from_utf8_lossy(&out.stderr));
        if lines.iter().any(|l| l.starts_with("landlock skipped:")) {
            return;
        }
        for check in ["file_read", "file_create", "tcp_connect", "tcp_bind", "signal_parent"] {
            assert!(
                lines.iter().any(|l| l.starts_with(&format!("landlock {check} "))),
                "no result for {check}: {lines:?}"
            );
        }
    }

    /// The confined half: applies `no_new_privs` and Landlock exactly as the
    /// runner does, then attempts each operation and prints how it ended.
    fn landlock_child() {
        let dir = std::path::PathBuf::from(std::env::var_os("CC_LANDLOCK_DIR").unwrap());
        let port: u16 = std::env::var("CC_LANDLOCK_PORT").unwrap().parse().unwrap();
        no_new_privs().unwrap();
        let mut report = LockdownReport::new();
        landlock(&mut report);
        let abi = match &report.controls[0].status {
            Status::Applied => {
                // SAFETY: a version query passes no pointers the kernel writes to.
                unsafe {
                    libc::syscall(
                        libc::SYS_landlock_create_ruleset,
                        std::ptr::null::<RulesetAttr>(),
                        0usize,
                        LANDLOCK_CREATE_RULESET_VERSION,
                    )
                }
            }
            Status::Unavailable(why) => {
                println!("landlock skipped: this kernel has no Landlock ({why})");
                return;
            }
            Status::Failed(why) => panic!("Landlock failed to apply: {why}"),
        };
        println!("landlock abi {abi}");
        let expect_denied = |what: &str, r: std::io::Result<()>| {
            let err = r.expect_err(what);
            assert!(
                matches!(err.raw_os_error(), Some(libc::EACCES) | Some(libc::EPERM)),
                "{what}: {err}"
            );
            println!("landlock {what} denied: {err}");
        };
        expect_denied("file_read", std::fs::read(dir.join("readable")).map(|_| ()));
        expect_denied("file_create", std::fs::write(dir.join("created"), b"x"));
        if abi >= 4 {
            expect_denied("tcp_connect", std::net::TcpStream::connect(("127.0.0.1", port)).map(|_| ()));
            expect_denied("tcp_bind", std::net::TcpListener::bind("127.0.0.1:0").map(|_| ()));
        } else {
            println!("landlock tcp_connect skipped: Landlock ABI {abi} has no network rules (needs 4)");
            println!("landlock tcp_bind skipped: Landlock ABI {abi} has no network rules (needs 4)");
        }
        if abi >= 6 {
            // SAFETY: signal 0 only checks permission; the parent is the
            // test process, outside this Landlock domain.
            let rc = unsafe { libc::kill(libc::getppid(), 0) };
            expect_denied("signal_parent", if rc == 0 { Ok(()) } else { Err(std::io::Error::last_os_error()) });
        } else {
            println!("landlock signal_parent skipped: Landlock ABI {abi} has no signal scoping (needs 6)");
        }
    }

    /// The advice values on the list, pinned.
    #[test]
    fn madvise_advice_is_pinned() {
        assert_eq!(MADVISE_ADVICE, [3, 4, 8, 14, 15, 16]);
    }

    /// The capabilities step leaves no capability in any set, as root
    /// (where it also empties the bounding set) and as a user. Runs in a
    /// fresh copy of the test binary, because the step cannot be undone.
    #[test]
    fn capabilities_are_dropped() {
        if std::env::var_os("CC_CAPS_CHILD").is_some() {
            let before = capget().unwrap();
            let bounding_before = known_capabilities()
                .filter(|c| unsafe { libc::prctl(PR_CAPBSET_READ, *c, 0, 0, 0) } == 1)
                .count();
            assert_eq!(drop_capabilities(), Ok(()));
            let after = capget().unwrap();
            assert!(after.iter().all(|d| d.effective | d.permitted | d.inheritable == 0));
            let bounding_after = known_capabilities()
                .filter(|c| unsafe { libc::prctl(PR_CAPBSET_READ, *c, 0, 0, 0) } == 1)
                .count();
            if before[0].effective & (1 << CAP_SETPCAP) != 0 {
                assert_eq!(bounding_after, 0);
            }
            println!(
                "\ncapabilities dropped: uid {} effective {:#x}/{:#x} -> 0, bounding {} -> {}",
                unsafe { libc::getuid() },
                before[0].effective,
                before[1].effective,
                bounding_before,
                bounding_after
            );
            return;
        }
        let out = std::process::Command::new(std::env::current_exe().unwrap())
            .args(["--exact", "linux::tests::capabilities_are_dropped", "--nocapture", "--test-threads=1"])
            .env("CC_CAPS_CHILD", "1")
            .output()
            .unwrap();
        let text = String::from_utf8_lossy(&out.stdout);
        assert!(out.status.success(), "child failed:\n{text}\n{}", String::from_utf8_lossy(&out.stderr));
        for line in text.lines().filter(|l| l.starts_with("capabilities ")) {
            println!("{line}");
        }
        assert!(text.contains("capabilities dropped:"), "{text}");
    }

    #[test]
    fn fs_rights_cover_known_bits() {
        assert_eq!(fs_rights(1), 0x1fff);
        assert_eq!(fs_rights(2), 0x3fff);
        assert_eq!(fs_rights(3), 0x7fff);
        assert_eq!(fs_rights(5), 0xffff);
        assert_eq!(fs_rights(8), 0xffff);
    }
}
