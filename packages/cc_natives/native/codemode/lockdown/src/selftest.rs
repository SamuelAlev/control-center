//! `cc_codemode --self-test`: applies the lockdown and proves each control by
//! attempting the denied operation from native code, then proves the other
//! half: that real sessions still work under that lockdown. Prints one JSON
//! line:
//!
//! ```json
//! {"selftest":{"ok":true,"os":"linux","build":"release","lockdown":{...},"checks":[
//!   {"name":"file_read","denied":true,"detail":"killed by SIGSYS"}, ...],
//!   "session":{"passed":true,"runs":8,"detail":"…"}}}
//! ```
//!
//! `ok` is true only when the lockdown level is `full`, every check was
//! denied and the session check passed. The caller exits 0 exactly when `ok`
//! is true. The session check is supplied by the runner (it speaks the wire
//! protocol); it starts this same executable in session mode and must run
//! while the calling process is still unconfined. Its object says `passed`,
//! not `ok`, so a consumer that looks for `"ok":true` in the line only ever
//! finds the overall verdict.
//!
//! On Linux a denied syscall kills the process, so each check runs in its own
//! child, forked before anything is confined, and the parent reads how the
//! child ended. On macOS the sandbox returns an error, so the checks run in
//! the confined process itself. On Windows the unconfined launcher prepares a
//! probe file, a probe directory and a loopback listener, and the confined
//! child attempts to use them.

use crate::json;
#[cfg(unix)]
use crate::{Level, LockdownReport};

/// The four operations every platform must deny.
pub const CHECKS: [&str; 4] = ["file_read", "file_create", "network", "process"];

/// Operations this platform must also deny, each one a way out that a
/// review found or that the platform's confinement is known to leave open
/// by default. README.md ("Self-test") says what each one attempts.
#[cfg(target_os = "linux")]
pub const PLATFORM_CHECKS: &[&str] = &["cpu_clock", "futex_pi", "madvise_advice", "landlock"];
/// See the Linux list.
#[cfg(target_os = "macos")]
pub const PLATFORM_CHECKS: &[&str] = &[
    "process_args",
    "process_info",
    "file_exists",
    "mach_lookup",
    "host_statistics",
    "signal",
    "process_group",
    "process_watch",
    "leave_group",
    "new_session",
    "memory_pressure",
    "login_name",
    "audit_session",
    "kdebug",
    "mach_ports",
];
/// See the Linux list. On Windows `file_read` and `file_create` already
/// probe a directory under the user's profile.
#[cfg(windows)]
pub const PLATFORM_CHECKS: &[&str] = &[
    "windows_write",
    "sibling_vm_read",
    "sibling_dup_handle",
    "install_dir_read",
    "all_packages_object",
];

/// Every check this platform runs, common ones first.
pub fn all_checks() -> impl Iterator<Item = &'static str> {
    CHECKS.iter().copied().chain(PLATFORM_CHECKS.iter().copied())
}

/// Result of one check.
#[derive(Clone, Debug)]
pub struct CheckResult {
    /// One of [`CHECKS`].
    pub name: &'static str,
    /// Whether the operation was refused.
    pub denied: bool,
    /// How it was refused, or what happened instead.
    pub detail: String,
}

/// Result of running real sessions of this executable under its lockdown.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct SessionCheck {
    /// Whether every session ended with the expected value and exit code 0.
    pub passed: bool,
    /// Sessions started, including the one that failed.
    pub runs: u32,
    /// What the sessions showed, or what went wrong and in which run.
    pub detail: String,
}

impl SessionCheck {
    /// A session check that could not take place, for example because the
    /// self-test failed earlier.
    pub fn not_run(detail: &str) -> SessionCheck {
        SessionCheck {
            passed: false,
            runs: 0,
            detail: detail.to_string(),
        }
    }
}

/// The overall verdict: the lockdown is full, every operation it must deny
/// was denied, and real sessions work under it.
pub fn overall_ok(full: bool, checks: &[CheckResult], session: &SessionCheck) -> bool {
    full && !checks.is_empty() && checks.iter().all(|c| c.denied) && session.passed
}

/// The build profile this executable was compiled with, reported as the
/// self-test's `build` field: `release`, or `debug` when debug assertions are
/// on. Packaging refuses anything but `release` (`scripts/lib/codemode.sh`);
/// `--version` and the `ready` frame do not carry it.
pub const BUILD_PROFILE: &str = if cfg!(debug_assertions) { "debug" } else { "release" };

/// Formats the self-test result line.
pub fn render(
    ok: bool,
    os: &str,
    lockdown_json: &str,
    checks: &[CheckResult],
    session: &SessionCheck,
) -> String {
    let mut out = String::from("{\"selftest\":{\"ok\":");
    out.push_str(if ok { "true" } else { "false" });
    out.push_str(",\"os\":");
    json::push_str(&mut out, os);
    out.push_str(",\"build\":");
    json::push_str(&mut out, BUILD_PROFILE);
    out.push_str(",\"lockdown\":");
    out.push_str(lockdown_json);
    out.push_str(",\"checks\":[");
    for (i, c) in checks.iter().enumerate() {
        if i > 0 {
            out.push(',');
        }
        out.push_str("{\"name\":");
        json::push_str(&mut out, c.name);
        out.push_str(",\"denied\":");
        out.push_str(if c.denied { "true" } else { "false" });
        out.push_str(",\"detail\":");
        json::push_str(&mut out, &c.detail);
        out.push('}');
    }
    out.push_str("],\"session\":{\"passed\":");
    out.push_str(if session.passed { "true" } else { "false" });
    out.push_str(",\"runs\":");
    out.push_str(&session.runs.to_string());
    out.push_str(",\"detail\":");
    json::push_str(&mut out, &session.detail);
    out.push_str("}}}");
    out
}

/// Runs the self-test and returns the process exit code. `session` runs real
/// sessions of this executable; it is called once, while this process is
/// still unconfined.
pub fn run(args: &[String], session: &dyn Fn() -> SessionCheck) -> i32 {
    #[cfg(target_os = "linux")]
    {
        let _ = args;
        linux_run(session)
    }
    #[cfg(target_os = "macos")]
    {
        let _ = args;
        macos_run(session)
    }
    #[cfg(windows)]
    {
        crate::windows::selftest(args, session)
    }
}

#[cfg(unix)]
fn print_line(line: &str) {
    use std::io::Write;
    let mut out = std::io::stdout().lock();
    let _ = out.write_all(line.as_bytes());
    let _ = out.write_all(b"\n");
    let _ = out.flush();
}

#[cfg(unix)]
fn last_errno() -> std::io::Error {
    std::io::Error::last_os_error()
}

/// Things a check needs that must be prepared before confinement.
#[cfg(unix)]
struct Probe {
    create_path: std::ffi::CString,
    port: u16,
    /// A process of the same user that is not part of this lockdown (macOS
    /// only; Linux checks run against pid 1). It is `/bin/cat` reading a
    /// pipe this process holds, so it exits when this process does.
    #[cfg(target_os = "macos")]
    sibling: std::process::Child,
    /// This process's parent (the host), read before confinement because
    /// the profile denies `getppid`.
    #[cfg(target_os = "macos")]
    parent: libc::pid_t,
}

#[cfg(unix)]
impl Probe {
    fn new() -> Result<(Probe, i32), String> {
        let dir = std::env::var("TMPDIR")
            .ok()
            .filter(|d| !d.is_empty())
            .unwrap_or_else(|| "/tmp".to_string());
        let path = format!(
            "{}/cc_codemode_selftest_{}",
            dir.trim_end_matches('/'),
            std::process::id()
        );
        let create_path = std::ffi::CString::new(path).map_err(|e| e.to_string())?;
        let (listener, port) = loopback_listener()?;
        #[cfg(target_os = "macos")]
        let sibling = std::process::Command::new("/bin/cat")
            .env_clear()
            .stdin(std::process::Stdio::piped())
            .stdout(std::process::Stdio::null())
            .stderr(std::process::Stdio::null())
            .spawn()
            .map_err(|e| format!("start a sibling process: {e}"))?;
        Ok((
            Probe {
                create_path,
                port,
                #[cfg(target_os = "macos")]
                sibling,
                #[cfg(target_os = "macos")]
                parent: std::os::unix::process::parent_id() as libc::pid_t,
            },
            listener,
        ))
    }
}

/// A TCP listener on 127.0.0.1 with an ephemeral port, so a connect attempt
/// that is not denied succeeds instead of failing for an unrelated reason.
#[cfg(unix)]
fn loopback_listener() -> Result<(i32, u16), String> {
    // SAFETY: plain socket calls with stack-allocated, correctly sized
    // address structures.
    unsafe {
        let fd = libc::socket(libc::AF_INET, libc::SOCK_STREAM, 0);
        if fd < 0 {
            return Err(format!("listener socket: {}", last_errno()));
        }
        let mut addr: libc::sockaddr_in = std::mem::zeroed();
        addr.sin_family = libc::AF_INET as _;
        addr.sin_addr.s_addr = u32::from_ne_bytes([127, 0, 0, 1]);
        addr.sin_port = 0;
        let len = std::mem::size_of::<libc::sockaddr_in>() as libc::socklen_t;
        if libc::bind(fd, &addr as *const _ as *const libc::sockaddr, len) != 0 {
            return Err(format!("listener bind: {}", last_errno()));
        }
        if libc::listen(fd, 4) != 0 {
            return Err(format!("listener listen: {}", last_errno()));
        }
        let mut bound: libc::sockaddr_in = std::mem::zeroed();
        let mut blen = len;
        if libc::getsockname(fd, &mut bound as *mut _ as *mut libc::sockaddr, &mut blen) != 0 {
            return Err(format!("listener getsockname: {}", last_errno()));
        }
        Ok((fd, u16::from_be(bound.sin_port)))
    }
}

/// Attempts one denied operation. `Ok(text)` means it succeeded (the
/// control failed); `Err(text)` means it was refused.
#[cfg(unix)]
fn attempt(check: &str, probe: &Probe) -> Result<String, String> {
    // SAFETY: each branch makes plain libc calls with valid C strings and
    // stack-allocated structures, and closes what it opens.
    unsafe {
        match check {
            "file_read" => {
                let path = c"/etc/hosts";
                let fd = libc::open(path.as_ptr(), libc::O_RDONLY);
                if fd < 0 {
                    return Err(format!("open /etc/hosts: {}", last_errno()));
                }
                let mut buf = [0u8; 1];
                let n = libc::read(fd, buf.as_mut_ptr().cast(), 1);
                libc::close(fd);
                if n < 0 {
                    Err(format!("read /etc/hosts: {}", last_errno()))
                } else {
                    Ok("read /etc/hosts".into())
                }
            }
            "file_create" => {
                let fd = libc::open(
                    probe.create_path.as_ptr(),
                    libc::O_CREAT | libc::O_EXCL | libc::O_WRONLY,
                    0o600,
                );
                if fd < 0 {
                    return Err(format!("create file: {}", last_errno()));
                }
                libc::close(fd);
                libc::unlink(probe.create_path.as_ptr());
                Ok("created a file in the temporary directory".into())
            }
            "network" => {
                let fd = libc::socket(libc::AF_INET, libc::SOCK_STREAM, 0);
                if fd < 0 {
                    return Err(format!("socket: {}", last_errno()));
                }
                let mut addr: libc::sockaddr_in = std::mem::zeroed();
                addr.sin_family = libc::AF_INET as _;
                addr.sin_addr.s_addr = u32::from_ne_bytes([127, 0, 0, 1]);
                addr.sin_port = probe.port.to_be();
                let rc = libc::connect(
                    fd,
                    &addr as *const _ as *const libc::sockaddr,
                    std::mem::size_of::<libc::sockaddr_in>() as libc::socklen_t,
                );
                let err = last_errno();
                libc::close(fd);
                if rc == 0 {
                    Ok("connected to a loopback listener".into())
                } else {
                    Err(format!("connect: {err}"))
                }
            }
            "process" => {
                #[cfg(target_os = "linux")]
                {
                    let pid = libc::fork();
                    if pid == 0 {
                        libc::_exit(0);
                    }
                    if pid < 0 {
                        return Err(format!("fork: {}", last_errno()));
                    }
                    let mut status = 0;
                    libc::waitpid(pid, &mut status, 0);
                    Ok("forked a child process".into())
                }
                #[cfg(target_os = "macos")]
                {
                    let prog = c"/usr/bin/true";
                    let argv = [prog.as_ptr() as *mut libc::c_char, std::ptr::null_mut()];
                    let envp = [std::ptr::null_mut::<libc::c_char>()];
                    let mut pid: libc::pid_t = 0;
                    let rc = libc::posix_spawn(
                        &mut pid,
                        prog.as_ptr(),
                        std::ptr::null(),
                        std::ptr::null(),
                        argv.as_ptr(),
                        envp.as_ptr(),
                    );
                    if rc != 0 {
                        return Err(format!(
                            "posix_spawn: {}",
                            std::io::Error::from_raw_os_error(rc)
                        ));
                    }
                    let mut status = 0;
                    libc::waitpid(pid, &mut status, 0);
                    Ok("spawned /usr/bin/true".into())
                }
            }
            #[cfg(target_os = "linux")]
            "cpu_clock" => {
                // MAKE_PROCESS_CPUCLOCK(1, CPUCLOCK_SCHED): pid 1's CPU time.
                let clock: libc::clockid_t = ((!1i32) << 3) | 2;
                let mut ts: libc::timespec = std::mem::zeroed();
                if libc::syscall(libc::SYS_clock_gettime, clock, &mut ts) != 0 {
                    return Err(format!("clock_gettime(CPU clock of pid 1): {}", last_errno()));
                }
                Ok("read the CPU clock of pid 1".into())
            }
            #[cfg(target_os = "linux")]
            "futex_pi" => {
                let word: u32 = 0;
                let rc = libc::syscall(libc::SYS_futex, &word as *const u32, libc::FUTEX_LOCK_PI, 0, 0usize, 0usize, 0);
                if rc != 0 {
                    return Err(format!("FUTEX_LOCK_PI: {}", last_errno()));
                }
                libc::syscall(libc::SYS_futex, &word as *const u32, libc::FUTEX_UNLOCK_PI, 0, 0usize, 0usize, 0);
                Ok("took a priority-inheritance futex".into())
            }
            #[cfg(target_os = "linux")]
            "madvise_advice" => {
                // An advice value off the list, on a page of this process.
                let page = libc::mmap(
                    std::ptr::null_mut(),
                    4096,
                    libc::PROT_READ | libc::PROT_WRITE,
                    libc::MAP_PRIVATE | libc::MAP_ANONYMOUS,
                    -1,
                    0,
                );
                if page == libc::MAP_FAILED {
                    return Err(format!("mmap: {}", last_errno()));
                }
                let rc = libc::madvise(page, 4096, libc::MADV_RANDOM);
                let err = last_errno();
                libc::munmap(page, 4096);
                if rc != 0 {
                    return Err(format!("madvise(MADV_RANDOM): {err}"));
                }
                Ok("madvise(MADV_RANDOM) is allowed".into())
            }
            // Landlock's own refusal: the child applies only the
            // thread-scoped controls (Landlock among them), not the filter,
            // which would kill it first.
            #[cfg(target_os = "linux")]
            "landlock" => {
                let fd = libc::open(c"/etc/hosts".as_ptr(), libc::O_RDONLY);
                if fd < 0 {
                    return Err(format!("open /etc/hosts under Landlock, no seccomp filter: {}", last_errno()));
                }
                libc::close(fd);
                Ok("opened /etc/hosts under Landlock, no seccomp filter".into())
            }
            #[cfg(target_os = "macos")]
            "process_args" => {
                // Arguments and the whole environment of another process.
                let mut mib = [libc::CTL_KERN, libc::KERN_PROCARGS2, probe.sibling.id() as libc::c_int];
                let mut buf = vec![0u8; 64 * 1024];
                let mut len = buf.len();
                let rc = libc::sysctl(mib.as_mut_ptr(), 3, buf.as_mut_ptr().cast(), &mut len, std::ptr::null_mut(), 0);
                if rc != 0 {
                    return Err(format!("sysctl(KERN_PROCARGS2) of a sibling: {}", last_errno()));
                }
                Ok(format!("read {len} bytes of a sibling's arguments and environment"))
            }
            #[cfg(target_os = "macos")]
            "process_info" => {
                let mut info: libc::proc_bsdinfo = std::mem::zeroed();
                let size = std::mem::size_of::<libc::proc_bsdinfo>() as libc::c_int;
                let rc = libc::proc_pidinfo(
                    probe.sibling.id() as libc::c_int,
                    libc::PROC_PIDTBSDINFO,
                    0,
                    (&mut info as *mut libc::proc_bsdinfo).cast(),
                    size,
                );
                if rc <= 0 {
                    return Err(format!("proc_pidinfo of a sibling: {}", last_errno()));
                }
                Ok("read a sibling's process information".into())
            }
            #[cfg(target_os = "macos")]
            "file_exists" => {
                if libc::access(c"/etc/hosts".as_ptr(), libc::F_OK) != 0 {
                    return Err(format!("access /etc/hosts: {}", last_errno()));
                }
                Ok("learned that /etc/hosts exists".into())
            }
            #[cfg(target_os = "macos")]
            "mach_lookup" => {
                let mut port: libc::mach_port_t = 0;
                let kr = bootstrap_look_up(bootstrap_port, c"com.apple.system.notification_center".as_ptr(), &mut port);
                if kr != 0 {
                    return Err(format!("bootstrap_look_up(notification center): kern_return {kr}"));
                }
                Ok("looked up the notification center's Mach service".into())
            }
            #[cfg(target_os = "macos")]
            "host_statistics" => {
                let mut load = [0 as libc::integer_t; 4];
                let mut count: libc::mach_msg_type_number_t = 4;
                let kr = host_statistics(
                    mach_host_self(),
                    libc::HOST_CPU_LOAD_INFO,
                    load.as_mut_ptr(),
                    &mut count,
                );
                if kr != 0 {
                    return Err(format!("host_statistics(CPU load): kern_return {kr}"));
                }
                Ok("read the machine's CPU load".into())
            }
            #[cfg(target_os = "macos")]
            "signal" => {
                if libc::kill(probe.sibling.id() as libc::pid_t, 0) != 0 {
                    return Err(format!("kill(sibling, 0): {}", last_errno()));
                }
                Ok("signalled a sibling".into())
            }
            #[cfg(target_os = "macos")]
            "process_group" => {
                // Answered for any live pid, so it enumerates processes and
                // finds the ones in the server's group.
                let pg = libc::getpgid(probe.parent);
                if pg >= 0 {
                    return Ok("read the parent's process group".into());
                }
                let pg_err = last_errno();
                if libc::getsid(probe.sibling.id() as libc::pid_t) >= 0 {
                    return Ok("read a sibling's session".into());
                }
                Err(format!("getpgid(parent): {pg_err}; getsid(sibling): {}", last_errno()))
            }
            #[cfg(target_os = "macos")]
            "process_watch" => {
                let kq = libc::kqueue();
                if kq < 0 {
                    return Err(format!("kqueue: {}", last_errno()));
                }
                let mut ev: libc::kevent = std::mem::zeroed();
                ev.ident = probe.parent as usize;
                ev.filter = libc::EVFILT_PROC;
                ev.flags = libc::EV_ADD;
                ev.fflags = libc::NOTE_EXIT | libc::NOTE_FORK | libc::NOTE_EXEC;
                let rc = libc::kevent(kq, &ev, 1, std::ptr::null_mut(), 0, std::ptr::null());
                let err = last_errno();
                libc::close(kq);
                if rc < 0 {
                    return Err(format!("kevent(EVFILT_PROC, parent): {err}"));
                }
                Ok("watching the parent's forks, execs and exit".into())
            }
            #[cfg(target_os = "macos")]
            "leave_group" => {
                // Moves into the group it is already in: changes nothing
                // when allowed, so the unconfined test can run it.
                if libc::setpgid(0, libc::getpgrp()) != 0 {
                    return Err(format!("setpgid: {}", last_errno()));
                }
                Ok("setpgid is allowed".into())
            }
            #[cfg(target_os = "macos")]
            "new_session" => {
                if libc::setsid() < 0 {
                    return Err(format!("setsid: {}", last_errno()));
                }
                Ok("left the host's session and process group".into())
            }
            #[cfg(target_os = "macos")]
            "memory_pressure" => {
                let mut level: libc::c_int = 0;
                if libc::syscall(SYS_MEMORYSTATUS_GET_LEVEL, &mut level as *mut libc::c_int) != 0 {
                    return Err(format!("memorystatus_get_level: {}", last_errno()));
                }
                Ok(format!("read the memory pressure level ({level})"))
            }
            #[cfg(target_os = "macos")]
            "login_name" => {
                let mut name = [0 as libc::c_char; 256];
                if libc::syscall(SYS_GETLOGIN, name.as_mut_ptr(), name.len() as libc::c_uint) != 0 {
                    return Err(format!("getlogin: {}", last_errno()));
                }
                Ok("read the login name".into())
            }
            #[cfg(target_os = "macos")]
            "audit_session" => {
                // auditinfo_addr_t is 48 bytes.
                let mut info = [0u64; 6];
                if getaudit_addr(info.as_mut_ptr().cast(), 48) == 0 {
                    return Ok("read the audit user and session".into());
                }
                let err = last_errno();
                let port = audit_session_self();
                if crate::macos::port_valid(port) {
                    crate::macos::mach_port_deallocate(crate::macos::task(), port);
                    return Ok("got the audit session port".into());
                }
                Err(format!("getaudit_addr: {err}; audit_session_self: no port"))
            }
            #[cfg(target_os = "macos")]
            "kdebug" => {
                if libc::syscall(SYS_KDEBUG_TRACE, 0x1f00_0000u64, 0u64, 0u64, 0u64, 0u64) != 0 {
                    return Err(format!("kdebug_trace: {}", last_errno()));
                }
                Ok("emitted a kernel trace point".into())
            }
            #[cfg(target_os = "macos")]
            "mach_ports" => mach_ports_probe(),
            other => Ok(format!("unknown check {other}")),
        }
    }
}

#[cfg(target_os = "macos")]
const SYS_GETLOGIN: libc::c_int = 49;
#[cfg(target_os = "macos")]
const SYS_KDEBUG_TRACE: libc::c_int = 180;
#[cfg(target_os = "macos")]
const SYS_MEMORYSTATUS_GET_LEVEL: libc::c_int = 453;

/// Sends a message to every port the process inherited that it can still
/// name: the libSystem bootstrap port, then whatever the task's and the
/// thread's exception ports, the registered ports and the bootstrap, debug
/// control and access special ports give back. Refused when nothing comes
/// back or no send gets through. Unconfined, the bootstrap port (launchd)
/// takes the message and the probe stops there.
#[cfg(target_os = "macos")]
fn mach_ports_probe() -> Result<String, String> {
    use crate::macos as m;
    let mut reached: Vec<(String, m::MachPort, bool)> = Vec::new();
    let mut misses = Vec::new();
    // SAFETY: reads libSystem's global; the name is not released here.
    let boot = unsafe { m::bootstrap_port };
    if m::port_valid(boot) {
        reached.push(("bootstrap_port".into(), boot, false));
    } else {
        misses.push("bootstrap_port null".to_string());
    }
    match m::exception_ports(false) {
        Ok(ports) => reached.extend(ports.into_iter().map(|p| ("task exception port".to_string(), p, true))),
        Err(kr) => misses.push(format!("task exception ports kr {kr}")),
    }
    match m::exception_ports(true) {
        Ok(ports) => reached.extend(ports.into_iter().map(|p| ("thread exception port".to_string(), p, true))),
        Err(kr) => misses.push(format!("thread exception ports kr {kr}")),
    }
    match m::registered_ports() {
        Ok(ports) => reached.extend(ports.into_iter().map(|p| ("registered port".to_string(), p, true))),
        Err(kr) => misses.push(format!("registered ports kr {kr}")),
    }
    for (which, what) in [
        (m::TASK_BOOTSTRAP_PORT, "bootstrap"),
        (m::TASK_DEBUG_CONTROL_PORT, "debug control"),
        (m::TASK_ACCESS_PORT, "access"),
    ] {
        let mut port: m::MachPort = 0;
        // SAFETY: port is a valid out-pointer.
        let kr = unsafe { m::task_get_special_port(m::task(), which, &mut port) };
        if kr != 0 {
            misses.push(format!("{what} port kr {kr}"));
        } else if m::port_valid(port) {
            reached.push((format!("{what} port"), port, true));
        }
    }
    let mut result = Err(format!("no inherited port reachable ({})", misses.join(", ")));
    for (what, port, _) in &reached {
        if result.is_ok() {
            break;
        }
        let kr = send_empty(*port);
        result = if kr == 0 {
            Ok(format!("sent a message to the inherited {what}"))
        } else {
            Err(format!("send to the {what}: {kr:#x}"))
        };
    }
    for (_, port, owned) in reached {
        if owned {
            // SAFETY: a send right the kernel gave this task for the probe.
            unsafe { m::mach_port_deallocate(m::task(), port) };
        }
    }
    result
}

/// Sends a header-only message with no reply port, waiting at most 100 ms.
#[cfg(target_os = "macos")]
fn send_empty(port: crate::macos::MachPort) -> libc::c_int {
    #[repr(C)]
    struct Header {
        bits: u32,
        size: u32,
        remote: u32,
        local: u32,
        voucher: u32,
        id: i32,
    }
    const MACH_MSG_TYPE_COPY_SEND: u32 = 19;
    const MACH_SEND_MSG: libc::c_int = 1;
    const MACH_SEND_TIMEOUT: libc::c_int = 0x10;
    let mut h = Header {
        bits: MACH_MSG_TYPE_COPY_SEND,
        size: std::mem::size_of::<Header>() as u32,
        remote: port,
        local: 0,
        voucher: 0,
        id: 0x5eed,
    };
    // SAFETY: h is a complete message header of the size given.
    unsafe {
        mach_msg(
            &mut h as *mut Header as *mut libc::c_void,
            MACH_SEND_MSG | MACH_SEND_TIMEOUT,
            h.size,
            0,
            0,
            100,
            0,
        )
    }
}

#[cfg(target_os = "macos")]
extern "C" {
    static bootstrap_port: libc::mach_port_t;
    fn mach_msg(
        msg: *mut libc::c_void,
        option: libc::c_int,
        send_size: u32,
        rcv_size: u32,
        rcv_name: u32,
        timeout: u32,
        notify: u32,
    ) -> libc::c_int;
    fn getaudit_addr(info: *mut libc::c_void, length: libc::c_int) -> libc::c_int;
    fn audit_session_self() -> crate::macos::MachPort;
    fn mach_host_self() -> libc::mach_port_t;
    fn host_statistics(
        host: libc::mach_port_t,
        flavor: libc::c_int,
        info: *mut libc::integer_t,
        count: *mut libc::mach_msg_type_number_t,
    ) -> libc::kern_return_t;
    fn bootstrap_look_up(
        bp: libc::mach_port_t,
        name: *const libc::c_char,
        sp: *mut libc::mach_port_t,
    ) -> libc::kern_return_t;
}

#[cfg(target_os = "macos")]
fn macos_run(session: &dyn Fn() -> SessionCheck) -> i32 {
    // The checks below run in this process after it confines itself, and the
    // sandbox denies starting processes, so the sessions run first.
    let session = session();
    let mut report = LockdownReport::new();
    crate::close_inherited_descriptors(&mut report);
    let (probe, listener) = match Probe::new() {
        Ok(p) => p,
        Err(e) => {
            print_line(&render(false, report.os, &report.to_json(), &[CheckResult {
                name: "setup",
                denied: false,
                detail: e,
            }], &session));
            return 1;
        }
    };
    crate::apply_thread_scoped(&mut report);
    crate::apply_process_wide(&mut report);
    let checks: Vec<CheckResult> = all_checks()
        .map(|name| match attempt(name, &probe) {
            Ok(text) => CheckResult {
                name,
                denied: false,
                detail: format!("allowed: {text}"),
            },
            Err(text) => CheckResult {
                name,
                denied: true,
                detail: text,
            },
        })
        .collect();
    // SAFETY: closing our own listener.
    unsafe { libc::close(listener) };
    let ok = overall_ok(report.level() == Level::Full, &checks, &session);
    print_line(&render(ok, report.os, &report.to_json(), &checks, &session));
    if ok {
        0
    } else {
        1
    }
}

#[cfg(target_os = "linux")]
fn linux_run(session: &dyn Fn() -> SessionCheck) -> i32 {
    let (probe, listener) = match Probe::new() {
        Ok(p) => p,
        Err(e) => {
            let report = LockdownReport::new();
            print_line(&render(false, report.os, &report.to_json(), &[CheckResult {
                name: "setup",
                denied: false,
                detail: e,
            }], &SessionCheck::not_run("the self-test could not be set up")));
            return 1;
        }
    };
    let mut lockdown_json = LockdownReport::new().to_json();
    let mut full = true;
    let mut checks = Vec::new();
    for name in all_checks() {
        if name == "landlock" {
            // Only where the kernel has Landlock: elsewhere the lockdown
            // already reports it `unavailable`, and there is nothing to
            // refuse.
            if !lockdown_json.contains("{\"name\":\"landlock\",\"required\":false,\"status\":\"applied\"}") {
                continue;
            }
            let (_, result) = linux_check(name, &probe);
            checks.push(result);
            continue;
        }
        let (report_line, result) = linux_check(name, &probe);
        if let Some(line) = report_line {
            if !line.contains("\"level\":\"full\"") {
                full = false;
            }
            lockdown_json = line;
        } else {
            full = false;
        }
        checks.push(result);
    }
    // SAFETY: closing our own listener.
    unsafe { libc::close(listener) };
    // This process was never confined (each check confined its own child),
    // so it can start the sessions now.
    let session = session();
    let ok = overall_ok(full, &checks, &session);
    print_line(&render(ok, "linux", &lockdown_json, &checks, &session));
    if ok {
        0
    } else {
        1
    }
}

/// Forks a child that confines itself, prints its lockdown report, then
/// attempts one check. Returns the child's report and how the check ended.
///
/// The child confines itself the way the runner does: descriptors, then
/// the thread-scoped controls, then a second thread (as the runner starts
/// its reader and watchdog), then the process-wide controls, so the filter
/// is applied with another thread alive and has to reach it (TSYNC). The
/// check then runs on that thread. The `landlock` check stops after the
/// thread-scoped controls instead, so that Landlock, not the filter,
/// answers.
#[cfg(target_os = "linux")]
fn linux_check(name: &'static str, probe: &Probe) -> (Option<String>, CheckResult) {
    let mut fds = [0i32; 2];
    // SAFETY: fds is a valid two-element array.
    if unsafe { libc::pipe(fds.as_mut_ptr()) } != 0 {
        return (None, CheckResult {
            name,
            denied: false,
            detail: format!("pipe: {}", last_errno()),
        });
    }
    let (read_end, write_end) = (fds[0], fds[1]);
    // SAFETY: the self-test is single-threaded when it forks.
    let pid = unsafe { libc::fork() };
    if pid < 0 {
        return (None, CheckResult {
            name,
            denied: false,
            detail: format!("fork: {}", last_errno()),
        });
    }
    if pid == 0 {
        // Child: stdout becomes the pipe, then everything above 2 closes
        // as part of the lockdown.
        // SAFETY: dup2/close on our own descriptors; _exit never returns.
        unsafe {
            libc::dup2(write_end, 1);
            libc::close(read_end);
            libc::close(write_end);
        }
        let mut report = LockdownReport::new();
        crate::close_inherited_descriptors(&mut report);
        crate::prepare_allocator_for_threads();
        crate::apply_thread_scoped(&mut report);
        if name == "landlock" {
            let mut text = report.to_json();
            text.push('\n');
            child_write(&text);
            if report.level() != Level::Full {
                child_write("lockdown-incomplete\n");
                // SAFETY: terminates the child.
                unsafe { libc::_exit(10) };
            }
            child_attempt(name, probe);
        }
        std::thread::scope(|scope| {
            let (go, wait) = std::sync::mpsc::channel::<()>();
            let (started_tx, started) = std::sync::mpsc::channel::<()>();
            let checker = scope.spawn(move || {
                // As the runner's threads do: allocate, then say so, so the
                // thread has finished starting before the filter applies.
                let first: Vec<u8> = Vec::with_capacity(4096);
                let _ = started_tx.send(());
                drop(first);
                if wait.recv().is_ok() {
                    child_attempt(name, probe);
                }
            });
            let _ = started.recv();
            crate::apply_process_wide(&mut report);
            let mut text = report.to_json();
            text.push('\n');
            child_write(&text);
            if report.level() != Level::Full {
                child_write("lockdown-incomplete\n");
                // SAFETY: terminates the child.
                unsafe { libc::_exit(10) };
            }
            let _ = go.send(());
            let _ = checker.join();
        });
        child_write("the check thread returned\n");
        // SAFETY: terminates the child.
        unsafe { libc::_exit(12) };
    }
    // SAFETY: closing the parent's copy of the write end.
    unsafe { libc::close(write_end) };
    let mut output = Vec::new();
    let mut buf = [0u8; 4096];
    loop {
        // SAFETY: buf is valid for its length.
        let n = unsafe { libc::read(read_end, buf.as_mut_ptr().cast(), buf.len()) };
        if n <= 0 {
            break;
        }
        output.extend_from_slice(&buf[..n as usize]);
    }
    // SAFETY: closing our read end.
    unsafe { libc::close(read_end) };
    let mut status = 0;
    // SAFETY: waits for the child we forked.
    unsafe { libc::waitpid(pid, &mut status, 0) };
    let text = String::from_utf8_lossy(&output).into_owned();
    let mut lines = text.lines();
    let report_line = lines.next().map(str::to_string);
    let outcome = lines.next().unwrap_or("").to_string();
    let result = if libc::WIFSIGNALED(status) && libc::WTERMSIG(status) == libc::SIGSYS {
        CheckResult {
            name,
            denied: true,
            detail: "killed by SIGSYS (seccomp)".into(),
        }
    } else if libc::WIFEXITED(status) && libc::WEXITSTATUS(status) == 0 && outcome.starts_with("denied: ") {
        CheckResult {
            name,
            denied: true,
            detail: outcome["denied: ".len()..].to_string(),
        }
    } else {
        let how = if libc::WIFSIGNALED(status) {
            format!("signal {}", libc::WTERMSIG(status))
        } else {
            format!("exit {}", libc::WEXITSTATUS(status))
        };
        CheckResult {
            name,
            denied: false,
            detail: format!("{how}: {outcome}"),
        }
    };
    (report_line, result)
}

/// Attempts the check and ends the child with its verdict: 0 denied, 3
/// allowed. A refusal by the filter ends it with SIGSYS instead.
#[cfg(target_os = "linux")]
fn child_attempt(name: &str, probe: &Probe) -> ! {
    match attempt(name, probe) {
        Ok(t) => {
            child_write(&format!("allowed: {t}\n"));
            // SAFETY: terminates the child.
            unsafe { libc::_exit(3) }
        }
        Err(t) => {
            child_write(&format!("denied: {t}\n"));
            // SAFETY: terminates the child.
            unsafe { libc::_exit(0) }
        }
    }
}

#[cfg(target_os = "linux")]
fn child_write(text: &str) {
    let bytes = text.as_bytes();
    let mut off = 0;
    while off < bytes.len() {
        // SAFETY: the slice is valid for its length.
        let n = unsafe { libc::write(1, bytes[off..].as_ptr().cast(), bytes.len() - off) };
        if n <= 0 {
            return;
        }
        off += n as usize;
    }
}

#[cfg(all(test, unix))]
mod tests {
    use super::*;

    /// Unconfined, every probe must succeed; otherwise the self-test could
    /// pass for a reason other than the lockdown.
    #[test]
    fn probes_succeed_without_lockdown() {
        let (probe, listener) = Probe::new().unwrap();
        // `new_session` would move the test process into a session of its
        // own; `new_session_probe_succeeds_without_lockdown` runs it in a
        // child instead.
        for name in all_checks().filter(|n| *n != "new_session") {
            let r = attempt(name, &probe);
            assert!(r.is_ok(), "{name}: {r:?}");
        }
        // SAFETY: closing our listener.
        unsafe { libc::close(listener) };
    }

    #[cfg(target_os = "macos")]
    #[test]
    fn new_session_probe_succeeds_without_lockdown() {
        if std::env::var_os("CC_NEW_SESSION_CHILD").is_some() {
            let (probe, listener) = Probe::new().unwrap();
            let r = attempt("new_session", &probe);
            // SAFETY: closing our listener.
            unsafe { libc::close(listener) };
            assert!(r.is_ok(), "{r:?}");
            println!("new_session allowed unconfined");
            return;
        }
        let out = std::process::Command::new(std::env::current_exe().unwrap())
            .args(["--exact", "selftest::tests::new_session_probe_succeeds_without_lockdown", "--nocapture", "--test-threads=1"])
            .env("CC_NEW_SESSION_CHILD", "1")
            .output()
            .unwrap();
        let text = String::from_utf8_lossy(&out.stdout);
        assert!(out.status.success() && text.contains("new_session allowed unconfined"), "{text}\n{}", String::from_utf8_lossy(&out.stderr));
    }

    fn denied(name: &'static str) -> CheckResult {
        CheckResult {
            name,
            denied: true,
            detail: "EPERM \"quoted\"".into(),
        }
    }

    fn passed() -> SessionCheck {
        SessionCheck {
            passed: true,
            runs: 8,
            detail: "8 sessions".into(),
        }
    }

    #[test]
    fn render_is_json_shaped() {
        let line = render(true, "linux", "{}", &[denied("file_read")], &passed());
        assert!(line.starts_with("{\"selftest\":{\"ok\":true"));
        let build = if cfg!(debug_assertions) { "debug" } else { "release" };
        assert!(line.contains(&format!(",\"os\":\"linux\",\"build\":\"{build}\",\"lockdown\":")), "{line}");
        assert!(line.contains("\\\"quoted\\\""));
        assert!(line.ends_with(",\"session\":{\"passed\":true,\"runs\":8,\"detail\":\"8 sessions\"}}}"));
    }

    /// A lockdown that denies everything but kills real sessions is not a
    /// working runner: the overall verdict must be false, and nothing in the
    /// line may read as `"ok":true` to a consumer that matches text.
    #[test]
    fn a_failing_session_fails_the_self_test() {
        let checks: Vec<CheckResult> = all_checks().map(denied).collect();
        assert!(overall_ok(true, &checks, &passed()));
        let failed = SessionCheck {
            passed: false,
            runs: 1,
            detail: "run 1 of 8: killed by signal 31 (SIGSYS)".into(),
        };
        assert!(!overall_ok(true, &checks, &failed));
        let line = render(false, "linux", "{\"level\":\"full\"}", &checks, &failed);
        assert!(!line.contains("\"ok\":true"), "{line}");
        assert!(line.contains("\"passed\":false"));
        // The other inputs still decide on their own.
        assert!(!overall_ok(false, &checks, &passed()));
        assert!(!overall_ok(true, &[], &passed()));
        let mut allowed = checks.clone();
        allowed[0].denied = false;
        assert!(!overall_ok(true, &allowed, &passed()));
    }
}
