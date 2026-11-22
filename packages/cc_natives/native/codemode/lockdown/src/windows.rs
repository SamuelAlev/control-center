//! Windows: the process the host starts is only a launcher. It runs this
//! same executable again inside an AppContainer of its own, in a job object,
//! with process mitigation policies set at creation, passes its three stdio
//! handles down (and nothing else), waits, and exits with the child's code.
//!
//! Every launch takes a new AppContainer name with 128 bits of OS
//! randomness and derives its SID without registering a profile, so no two
//! runners share a package SID and nothing persists (no profile folder, no
//! registry entry, no named-object directory shared across sessions). The
//! one thing every child shares is a capability, `RUNNER_CAPABILITY`, whose
//! only use is the ACE that lets a child read and execute the runner's own
//! executable; the launcher adds that ACE to its executable when it is
//! missing. The child is a less-privileged AppContainer: it opts out of ALL
//! APPLICATION PACKAGES (`PROC_THREAD_ATTRIBUTE_ALL_APPLICATION_PACKAGES_POLICY`),
//! so the many objects that grant that group access (an all-users install
//! under Program Files, parts of the Windows directory and ProgramData, the
//! brokers that admit it) are closed to it. It still reaches what grants ALL
//! RESTRICTED APPLICATION PACKAGES, which is where Windows grants System32
//! and the known DLLs; nothing here grants either group anything.
//!
//! The child does not trust how it was started: it reads its own token, job
//! and mitigation policies back and reports only what it finds.
//!
//! `userenv.dll` (AppContainer profiles) and `ws2_32.dll` (the self-test's
//! network probe) are loaded at run time from System32 rather than imported,
//! so the confined child never maps them; with win32k system calls disabled,
//! a DLL that pulls in user32 at load time would stop the child from
//! starting.

use std::ffi::c_void;
use std::mem::{size_of, zeroed};
use std::ptr::{null, null_mut};

use windows_sys::core::{BOOL, HRESULT, PCSTR, PCWSTR, PWSTR};
use windows_sys::Win32::Foundation::{
    CloseHandle, GetLastError, LocalFree, SetHandleInformation, ERROR_ACCESS_DENIED, HANDLE,
    HANDLE_FLAG_INHERIT, HMODULE, INVALID_HANDLE_VALUE, WAIT_OBJECT_0,
};
use windows_sys::Win32::Networking::WinSock::{
    AF_INET, INVALID_SOCKET, IPPROTO_TCP, SOCKADDR, SOCKADDR_IN, SOCKET, SOCK_STREAM, WSADATA,
};
use windows_sys::Win32::Security::Authorization::{
    ConvertSidToStringSidW, ConvertStringSecurityDescriptorToSecurityDescriptorW, GetNamedSecurityInfoW, SetEntriesInAclW, SetNamedSecurityInfoW, EXPLICIT_ACCESS_W,
    GRANT_ACCESS, NO_MULTIPLE_TRUSTEE, SE_FILE_OBJECT, TRUSTEE_IS_SID, TRUSTEE_IS_UNKNOWN,
    TRUSTEE_W,
};
use windows_sys::Win32::Security::{
    EqualSid, FreeSid, GetAce, GetTokenInformation, TokenCapabilities, TokenIsAppContainer,
    TokenIsLessPrivilegedAppContainer, TokenSecurityAttributes, SECURITY_ATTRIBUTES,
    ACCESS_ALLOWED_ACE, ACE_HEADER, ACL, DACL_SECURITY_INFORMATION, NO_INHERITANCE, PSECURITY_DESCRIPTOR,
    PSID, SECURITY_CAPABILITIES, SID_AND_ATTRIBUTES, TOKEN_GROUPS, TOKEN_QUERY,
};
use windows_sys::Win32::Storage::FileSystem::{
    CreateFileW, DeleteFileW, ReadFile, WriteFile, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, FILE_GENERIC_EXECUTE,
    FILE_GENERIC_WRITE,
    FILE_GENERIC_READ, FILE_SHARE_READ, OPEN_EXISTING,
};
use windows_sys::Win32::System::Console::{
    GetStdHandle, STD_ERROR_HANDLE, STD_INPUT_HANDLE, STD_OUTPUT_HANDLE,
};
use windows_sys::Win32::System::JobObjects::{
    AssignProcessToJobObject, CreateJobObjectW, IsProcessInJob, JobObjectBasicUIRestrictions,
    JobObjectExtendedLimitInformation, QueryInformationJobObject, SetInformationJobObject,
    JOBOBJECT_BASIC_UI_RESTRICTIONS, JOBOBJECT_EXTENDED_LIMIT_INFORMATION,
    JOB_OBJECT_LIMIT_ACTIVE_PROCESS, JOB_OBJECT_LIMIT_DIE_ON_UNHANDLED_EXCEPTION,
    JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE, JOB_OBJECT_LIMIT_PROCESS_MEMORY,
    JOB_OBJECT_LIMIT_PROCESS_TIME,
};
use windows_sys::Win32::System::LibraryLoader::{
    GetModuleFileNameW, GetProcAddress, LoadLibraryExW, LOAD_LIBRARY_SEARCH_SYSTEM32,
};
use windows_sys::Win32::System::Memory::{HeapEnableTerminationOnCorruption, HeapSetInformation};
use windows_sys::Win32::System::SystemInformation::{GetSystemDirectoryW, GetSystemWindowsDirectoryW};
use windows_sys::Win32::System::SystemServices::{JOB_OBJECT_UILIMIT_ALL, SE_GROUP_ENABLED};
use windows_sys::Win32::System::Threading::{
    CreateProcessW, DeleteProcThreadAttributeList, GetCurrentProcess, GetExitCodeProcess,
    GetProcessMitigationPolicy, InitializeProcThreadAttributeList, OpenProcess, OpenProcessToken,
    ProcessASLRPolicy, ProcessChildProcessPolicy, ProcessControlFlowGuardPolicy, ProcessDynamicCodePolicy,
    ProcessSignaturePolicy, ProcessUserShadowStackPolicy, SetProcessMitigationPolicy,
    PROC_THREAD_ATTRIBUTE_ALL_APPLICATION_PACKAGES_POLICY,
    ProcessExtensionPointDisablePolicy, ProcessFontDisablePolicy, ProcessImageLoadPolicy,
    ProcessStrictHandleCheckPolicy, ProcessSystemCallDisablePolicy, ResumeThread, TerminateProcess,
    UpdateProcThreadAttribute, WaitForSingleObject, CREATE_SUSPENDED,
    CREATE_UNICODE_ENVIRONMENT, DETACHED_PROCESS, EXTENDED_STARTUPINFO_PRESENT, INFINITE,
    LPPROC_THREAD_ATTRIBUTE_LIST, PROCESS_INFORMATION, PROC_THREAD_ATTRIBUTE_CHILD_PROCESS_POLICY,
    PROC_THREAD_ATTRIBUTE_HANDLE_LIST, PROC_THREAD_ATTRIBUTE_MITIGATION_POLICY,
    PROCESS_DUP_HANDLE, PROCESS_VM_READ, PROC_THREAD_ATTRIBUTE_SECURITY_CAPABILITIES,
    STARTF_USESTDHANDLES, STARTUPINFOEXW,
};

use crate::selftest::{all_checks, overall_ok, render, CheckResult, SessionCheck};
use crate::{Level, LockdownReport, ADDRESS_SPACE_LIMIT_BYTES, CPU_LIMIT_SECONDS};

/// Second argument that marks the confined child. The child verifies its
/// confinement itself, so passing the flag by hand gains nothing.
pub const CONTAINED_FLAG: &str = "--contained-child";

/// Second argument (after [`CONTAINED_FLAG`]) of the self-test's idle
/// sibling: a second confined child the probing child must not be able to
/// open.
pub const SIBLING_FLAG: &str = "--sibling";

/// Only argument of the installer's step: add the capability ACE to this
/// executable (as the launcher does before every launch), print one line
/// and exit. An all-users install runs it elevated, because there the
/// launcher, running as the user, may not change the file's DACL.
pub const GRANT_ACCESS_FLAG: &str = "--grant-runner-access";

/// Prefix of every launch's AppContainer name; 32 hex digits of OS
/// randomness follow (55 characters in all, within the 64 allowed).
const CONTAINER_PREFIX: &str = "ControlCenter.CodeMode.";

/// The capability every confined child carries. Its SID appears in exactly
/// one ACE: read and execute on the runner's executable.
const RUNNER_CAPABILITY: &str = "controlCenterCodeModeRunner";

/// What a child needs on its own executable.
const RUNNER_ACCESS: u32 = FILE_GENERIC_READ | FILE_GENERIC_EXECUTE;

// PROCESS_CREATION_MITIGATION_POLICY_* (winbase.h); windows-sys does not
// define them. Each policy is a two-bit field; 01 means "always on".
const MITIGATION_FORCE_RELOCATE_IMAGES_ALWAYS_ON: u64 = 1 << 8;
const MITIGATION_HEAP_TERMINATE_ALWAYS_ON: u64 = 1 << 12;
const MITIGATION_BOTTOM_UP_ASLR_ALWAYS_ON: u64 = 1 << 16;
const MITIGATION_HIGH_ENTROPY_ASLR_ALWAYS_ON: u64 = 1 << 20;
const MITIGATION_STRICT_HANDLE_CHECKS_ALWAYS_ON: u64 = 1 << 24;
const MITIGATION_WIN32K_SYSTEM_CALL_DISABLE_ALWAYS_ON: u64 = 1 << 28;
const MITIGATION_EXTENSION_POINT_DISABLE_ALWAYS_ON: u64 = 1 << 32;
const MITIGATION_PROHIBIT_DYNAMIC_CODE_ALWAYS_ON: u64 = 1 << 36;
const MITIGATION_FONT_DISABLE_ALWAYS_ON: u64 = 1 << 48;
const MITIGATION_IMAGE_LOAD_NO_REMOTE_ALWAYS_ON: u64 = 1 << 52;
const MITIGATION_IMAGE_LOAD_NO_LOW_LABEL_ALWAYS_ON: u64 = 1 << 56;
const MITIGATION_IMAGE_LOAD_PREFER_SYSTEM32_ALWAYS_ON: u64 = 1 << 60;
const MITIGATIONS: u64 = MITIGATION_FORCE_RELOCATE_IMAGES_ALWAYS_ON
    | MITIGATION_BOTTOM_UP_ASLR_ALWAYS_ON
    | MITIGATION_HIGH_ENTROPY_ASLR_ALWAYS_ON
    | MITIGATION_HEAP_TERMINATE_ALWAYS_ON
    | MITIGATION_STRICT_HANDLE_CHECKS_ALWAYS_ON
    | MITIGATION_WIN32K_SYSTEM_CALL_DISABLE_ALWAYS_ON
    | MITIGATION_EXTENSION_POINT_DISABLE_ALWAYS_ON
    | MITIGATION_PROHIBIT_DYNAMIC_CODE_ALWAYS_ON
    | MITIGATION_FONT_DISABLE_ALWAYS_ON
    | MITIGATION_IMAGE_LOAD_NO_REMOTE_ALWAYS_ON
    | MITIGATION_IMAGE_LOAD_NO_LOW_LABEL_ALWAYS_ON
    | MITIGATION_IMAGE_LOAD_PREFER_SYSTEM32_ALWAYS_ON;
// PROCESS_CREATION_MITIGATION_POLICY2_CET_USER_SHADOW_STACKS_ALWAYS_ON
// (winbase.h): user-mode shadow stacks in compatibility mode, the mode a
// binary without the CETCOMPAT marking runs under. Set only where the
// processor and Windows support them; see `shadow_stack_available`.
const MITIGATION2_CET_USER_SHADOW_STACKS_ALWAYS_ON: u64 = 1 << 28;
// PROCESS_CREATION_CHILD_PROCESS_RESTRICTED (winbase.h).
const CHILD_PROCESS_RESTRICTED: u32 = 0x01;
// PROCESS_CREATION_ALL_APPLICATION_PACKAGES_OPT_OUT (winbase.h).
const ALL_APPLICATION_PACKAGES_OPT_OUT: u32 = 0x01;

// BCRYPT_USE_SYSTEM_PREFERRED_RNG (bcrypt.h).
const BCRYPT_USE_SYSTEM_PREFERRED_RNG: u32 = 0x02;
// ACCESS_ALLOWED_ACE_TYPE (winnt.h).
const ACCESS_ALLOWED_ACE_TYPE: u8 = 0;

const JOB_LIMIT_FLAGS: u32 = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
    | JOB_OBJECT_LIMIT_ACTIVE_PROCESS
    | JOB_OBJECT_LIMIT_PROCESS_MEMORY
    | JOB_OBJECT_LIMIT_PROCESS_TIME
    | JOB_OBJECT_LIMIT_DIE_ON_UNHANDLED_EXCEPTION;

/// The job's per-process user-mode CPU limit, in 100 ns units: the same
/// backstop as RLIMIT_CPU on Linux and macOS (kernel-mode time is not
/// counted by this limit).
const JOB_CPU_LIMIT_100NS: i64 = CPU_LIMIT_SECONDS as i64 * 10_000_000;

/// Whether this process was started as the confined child.
pub fn is_contained_child(args: &[String]) -> bool {
    args.get(1).map(String::as_str) == Some(CONTAINED_FLAG)
}

fn wide(s: &str) -> Vec<u16> {
    s.encode_utf16().chain(std::iter::once(0)).collect()
}

fn last_error(what: &str) -> String {
    // SAFETY: GetLastError has no preconditions.
    let code = unsafe { GetLastError() };
    format!("{what}: error {code} ({})", std::io::Error::from_raw_os_error(code as i32))
}

/// Closes a handle when dropped.
struct Owned(HANDLE);

impl Drop for Owned {
    fn drop(&mut self) {
        if !self.0.is_null() && self.0 != INVALID_HANDLE_VALUE {
            // SAFETY: we own this handle.
            unsafe { CloseHandle(self.0) };
        }
    }
}

/// A SID allocated by userenv, freed with FreeSid.
struct Sid(PSID);

impl Drop for Sid {
    fn drop(&mut self) {
        if !self.0.is_null() {
            // SAFETY: the SID came from CreateAppContainerProfile or
            // DeriveAppContainerSidFromAppContainerName, which document FreeSid.
            unsafe { FreeSid(self.0) };
        }
    }
}

fn load_system_library(name: &str) -> Result<HMODULE, String> {
    let w = wide(name);
    // SAFETY: w is NUL-terminated; the flag restricts the search to System32.
    let m = unsafe { LoadLibraryExW(w.as_ptr(), null_mut(), LOAD_LIBRARY_SEARCH_SYSTEM32) };
    if m.is_null() {
        return Err(last_error(&format!("load {name}")));
    }
    Ok(m)
}

/// # Safety
/// `T` must be the exact function pointer type of the export.
unsafe fn proc_address<T: Copy>(module: HMODULE, name: &[u8]) -> Result<T, String> {
    debug_assert_eq!(name.last(), Some(&0));
    // SAFETY: name is NUL-terminated; module is a loaded module.
    let p = unsafe { GetProcAddress(module, name.as_ptr() as PCSTR) };
    match p {
        // SAFETY: the caller names the matching function pointer type, which
        // has the same size as FARPROC's payload.
        Some(f) => Ok(unsafe { std::mem::transmute_copy::<unsafe extern "system" fn() -> isize, T>(&f) }),
        None => Err(last_error(&format!(
            "GetProcAddress {}",
            String::from_utf8_lossy(&name[..name.len() - 1])
        ))),
    }
}

/// Memory from LocalAlloc (a SID or an ACL from the security APIs), freed
/// with LocalFree.
struct Local(*mut c_void);

impl Drop for Local {
    fn drop(&mut self) {
        if !self.0.is_null() {
            // SAFETY: the API that returned this pointer documents LocalFree.
            unsafe { LocalFree(self.0) };
        }
    }
}

type BCryptGenRandomFn = unsafe extern "system" fn(*mut c_void, *mut u8, u32, u32) -> i32;
type DeriveAppContainerSidFn = unsafe extern "system" fn(PCWSTR, *mut PSID) -> HRESULT;
type DeriveCapabilitySidsFn =
    unsafe extern "system" fn(PCWSTR, *mut *mut PSID, *mut u32, *mut *mut PSID, *mut u32) -> BOOL;

/// A fresh AppContainer name: the prefix and 128 bits from the system RNG.
fn container_name() -> Result<String, String> {
    let bcrypt = load_system_library("bcrypt.dll")?;
    // SAFETY: the type matches BCryptGenRandom(BCRYPT_ALG_HANDLE, PUCHAR,
    // ULONG, ULONG) -> NTSTATUS.
    let generate: BCryptGenRandomFn = unsafe { proc_address(bcrypt, b"BCryptGenRandom\0")? };
    let mut bytes = [0u8; 16];
    // SAFETY: no algorithm handle with the system-preferred flag; the buffer
    // is valid for its length.
    let status = unsafe {
        generate(null_mut(), bytes.as_mut_ptr(), bytes.len() as u32, BCRYPT_USE_SYSTEM_PREFERRED_RNG)
    };
    if status != 0 {
        return Err(format!("BCryptGenRandom: NTSTATUS {status:#x}"));
    }
    let mut name = String::from(CONTAINER_PREFIX);
    for b in bytes {
        name.push_str(&format!("{b:02x}"));
    }
    Ok(name)
}

/// The package SID for `name`, derived without registering a profile.
fn container_sid(name: &str) -> Result<Sid, String> {
    let userenv = load_system_library("userenv.dll")?;
    // SAFETY: the type matches the documented userenv export.
    let derive: DeriveAppContainerSidFn =
        unsafe { proc_address(userenv, b"DeriveAppContainerSidFromAppContainerName\0")? };
    let name = wide(name);
    let mut sid: PSID = null_mut();
    // SAFETY: name is NUL-terminated; sid is an out-pointer freed by Sid.
    let hr = unsafe { derive(name.as_ptr(), &mut sid) };
    if hr != 0 || sid.is_null() {
        return Err(format!("DeriveAppContainerSidFromAppContainerName: HRESULT {hr:#x}"));
    }
    Ok(Sid(sid))
}

/// The SID of [`RUNNER_CAPABILITY`].
fn runner_capability_sid() -> Result<Local, String> {
    let kernelbase = load_system_library("kernelbase.dll")?;
    // SAFETY: the type matches DeriveCapabilitySidsFromName.
    let derive: DeriveCapabilitySidsFn =
        unsafe { proc_address(kernelbase, b"DeriveCapabilitySidsFromName\0")? };
    let name = wide(RUNNER_CAPABILITY);
    let (mut groups, mut group_count, mut caps, mut cap_count) = (null_mut(), 0u32, null_mut(), 0u32);
    // SAFETY: name is NUL-terminated; the four out-pointers are valid. Every
    // SID and both arrays are LocalAlloc'd and freed below.
    let ok = unsafe { derive(name.as_ptr(), &mut groups, &mut group_count, &mut caps, &mut cap_count) };
    if ok == 0 {
        return Err(last_error("DeriveCapabilitySidsFromName"));
    }
    // SAFETY: the arrays hold the stated number of SIDs.
    unsafe {
        let _groups = Local(groups as *mut c_void);
        let _caps = Local(caps as *mut c_void);
        for i in 0..group_count as usize {
            drop(Local(*groups.add(i)));
        }
        if cap_count != 1 {
            for i in 0..cap_count as usize {
                drop(Local(*caps.add(i)));
            }
            return Err(format!("DeriveCapabilitySidsFromName returned {cap_count} capability SIDs"));
        }
        Ok(Local(*caps))
    }
}

/// Whether `dacl` has an access-allowed ACE that gives `sid` all of `mask`.
///
/// # Safety
/// `dacl` must be a valid ACL.
unsafe fn dacl_grants(dacl: *const ACL, sid: PSID, mask: u32) -> bool {
    // SAFETY: the caller passes a valid ACL.
    let count = unsafe { (*dacl).AceCount } as u32;
    for i in 0..count {
        let mut ace: *mut c_void = null_mut();
        // SAFETY: i is below the ACL's ACE count.
        if unsafe { GetAce(dacl, i, &mut ace) } == 0 {
            return false;
        }
        // SAFETY: every ACE starts with an ACE_HEADER.
        let header = unsafe { &*(ace as *const ACE_HEADER) };
        if header.AceType != ACCESS_ALLOWED_ACE_TYPE {
            continue;
        }
        let allowed = ace as *const ACCESS_ALLOWED_ACE;
        // SAFETY: an access-allowed ACE holds its SID at SidStart.
        let (ace_mask, ace_sid) = unsafe { ((*allowed).Mask, &(*allowed).SidStart as *const u32 as PSID) };
        // SAFETY: both are valid SIDs.
        if ace_mask & mask == mask && unsafe { EqualSid(ace_sid, sid) } != 0 {
            return true;
        }
    }
    false
}

/// Gives `capability` read and execute access to the runner's executable
/// (`exe`, NUL-terminated) unless it has it already; true when it added the
/// ACE. Fails when the ACE is missing and this user may not change the
/// file's DACL; the installer must then add it (`--grant-runner-access`).
fn ensure_runner_access(exe: &[u16], capability: PSID) -> Result<bool, String> {
    let mut dacl: *mut ACL = null_mut();
    let mut sd: PSECURITY_DESCRIPTOR = null_mut();
    // SAFETY: exe is NUL-terminated; dacl points into sd, which is freed by
    // Local below.
    let rc = unsafe {
        GetNamedSecurityInfoW(
            exe.as_ptr(),
            SE_FILE_OBJECT,
            DACL_SECURITY_INFORMATION,
            null_mut(),
            null_mut(),
            &mut dacl,
            null_mut(),
            &mut sd,
        )
    };
    if rc != 0 {
        return Err(format!("GetNamedSecurityInfoW on the runner: error {rc}"));
    }
    let _sd = Local(sd);
    // A null DACL grants everyone everything.
    // SAFETY: dacl is valid while sd lives.
    if dacl.is_null() || unsafe { dacl_grants(dacl, capability, RUNNER_ACCESS) } {
        return Ok(false);
    }
    let entry = EXPLICIT_ACCESS_W {
        grfAccessPermissions: RUNNER_ACCESS,
        grfAccessMode: GRANT_ACCESS,
        grfInheritance: NO_INHERITANCE,
        Trustee: TRUSTEE_W {
            pMultipleTrustee: null_mut(),
            MultipleTrusteeOperation: NO_MULTIPLE_TRUSTEE,
            TrusteeForm: TRUSTEE_IS_SID,
            TrusteeType: TRUSTEE_IS_UNKNOWN,
            ptstrName: capability as PWSTR,
        },
    };
    let mut updated: *mut ACL = null_mut();
    // SAFETY: one valid entry; dacl is the current DACL; updated is freed by
    // Local.
    let rc = unsafe { SetEntriesInAclW(1, &entry, dacl, &mut updated) };
    if rc != 0 {
        return Err(format!("SetEntriesInAclW: error {rc}"));
    }
    let updated = Local(updated as *mut c_void);
    // SAFETY: exe is NUL-terminated; the new DACL is valid.
    let rc = unsafe {
        SetNamedSecurityInfoW(
            exe.as_ptr(),
            SE_FILE_OBJECT,
            DACL_SECURITY_INFORMATION,
            null_mut(),
            null_mut(),
            updated.0 as *const ACL,
            null(),
        )
    };
    if rc != 0 {
        let path = String::from_utf16_lossy(exe.strip_suffix(&[0]).unwrap_or(exe));
        return Err(format!(
            "the runner's executable does not grant the {RUNNER_CAPABILITY} capability read and execute access, and adding it failed: error {rc} ({}). Run \"{path}\" {GRANT_ACCESS_FLAG} as an administrator, or reinstall, which runs it.",
            std::io::Error::from_raw_os_error(rc as i32)
        ));
    }
    Ok(true)
}

/// The installer's step ([`GRANT_ACCESS_FLAG`]): makes this executable grant
/// [`RUNNER_CAPABILITY`] read and execute access, with the code the launcher
/// runs before every launch. Prints one line (stdout on success, stderr on
/// failure) and returns the exit code: 0 when the executable grants it, 1
/// when it does not and adding it failed.
pub fn grant_runner_access() -> i32 {
    let result = runner_capability_sid().and_then(|capability| {
        let mut exe = own_path()?;
        let path = String::from_utf16_lossy(&exe);
        exe.push(0);
        ensure_runner_access(&exe, capability.0).map(|added| (path, added))
    });
    match result {
        Ok((path, added)) => {
            let verb = if added { "now grants" } else { "already grants" };
            println!("cc_codemode: {path} {verb} the {RUNNER_CAPABILITY} capability read and execute access");
            0
        }
        Err(e) => {
            eprintln!("cc_codemode: {e}");
            1
        }
    }
}

fn create_job() -> Result<Owned, String> {
    // SAFETY: no name, default security.
    let job = Owned(unsafe { CreateJobObjectW(null(), null()) });
    if job.0.is_null() {
        return Err(last_error("CreateJobObjectW"));
    }
    // SAFETY: a zeroed limit structure is valid; fields are set below.
    let mut limits: JOBOBJECT_EXTENDED_LIMIT_INFORMATION = unsafe { zeroed() };
    limits.BasicLimitInformation.LimitFlags = JOB_LIMIT_FLAGS;
    limits.BasicLimitInformation.ActiveProcessLimit = 1;
    limits.BasicLimitInformation.PerProcessUserTimeLimit = JOB_CPU_LIMIT_100NS;
    limits.ProcessMemoryLimit = ADDRESS_SPACE_LIMIT_BYTES as usize;
    // SAFETY: the buffer and its size match the information class.
    let ok = unsafe {
        SetInformationJobObject(
            job.0,
            JobObjectExtendedLimitInformation,
            &limits as *const _ as *const c_void,
            size_of::<JOBOBJECT_EXTENDED_LIMIT_INFORMATION>() as u32,
        )
    };
    if ok == 0 {
        return Err(last_error("SetInformationJobObject(limits)"));
    }
    let ui = JOBOBJECT_BASIC_UI_RESTRICTIONS {
        UIRestrictionsClass: JOB_OBJECT_UILIMIT_ALL,
    };
    // SAFETY: as above.
    let ok = unsafe {
        SetInformationJobObject(
            job.0,
            JobObjectBasicUIRestrictions,
            &ui as *const _ as *const c_void,
            size_of::<JOBOBJECT_BASIC_UI_RESTRICTIONS>() as u32,
        )
    };
    if ok == 0 {
        return Err(last_error("SetInformationJobObject(ui)"));
    }
    Ok(job)
}

fn own_path() -> Result<Vec<u16>, String> {
    let mut buf = vec![0u16; 1024];
    loop {
        // SAFETY: buf is valid for its length.
        let n = unsafe { GetModuleFileNameW(null_mut(), buf.as_mut_ptr(), buf.len() as u32) } as usize;
        if n == 0 {
            return Err(last_error("GetModuleFileNameW"));
        }
        if n < buf.len() {
            buf.truncate(n);
            return Ok(buf);
        }
        if buf.len() >= 32768 {
            return Err("executable path is too long".into());
        }
        buf.resize(buf.len() * 2, 0);
    }
}

fn system_directory() -> Result<Vec<u16>, String> {
    let mut buf = vec![0u16; 512];
    // SAFETY: buf is valid for its length.
    let n = unsafe { GetSystemDirectoryW(buf.as_mut_ptr(), buf.len() as u32) } as usize;
    if n == 0 || n >= buf.len() {
        return Err(last_error("GetSystemDirectoryW"));
    }
    buf.truncate(n);
    Ok(buf)
}

/// Appends one argument using the quoting rules CommandLineToArgvW and the
/// MSVC runtime parse.
fn push_arg(cmd: &mut Vec<u16>, arg: &[u16]) {
    if !cmd.is_empty() {
        cmd.push(b' ' as u16);
    }
    cmd.push(b'"' as u16);
    let mut backslashes = 0usize;
    for &c in arg {
        if c == b'\\' as u16 {
            backslashes += 1;
        } else if c == b'"' as u16 {
            cmd.extend(std::iter::repeat_n(b'\\' as u16, backslashes * 2 + 1));
            cmd.push(c);
            backslashes = 0;
        } else {
            cmd.extend(std::iter::repeat_n(b'\\' as u16, backslashes));
            cmd.push(c);
            backslashes = 0;
        }
    }
    cmd.extend(std::iter::repeat_n(b'\\' as u16, backslashes * 2));
    cmd.push(b'"' as u16);
}

fn std_handles() -> Result<[HANDLE; 3], String> {
    let mut hs = [null_mut(); 3];
    for (i, which) in [STD_INPUT_HANDLE, STD_OUTPUT_HANDLE, STD_ERROR_HANDLE].iter().enumerate() {
        // SAFETY: GetStdHandle has no preconditions.
        let h = unsafe { GetStdHandle(*which) };
        if h.is_null() || h == INVALID_HANDLE_VALUE {
            return Err(format!("standard handle {i} is missing; the runner needs piped stdio"));
        }
        // SAFETY: h is one of our standard handles.
        if unsafe { SetHandleInformation(h, HANDLE_FLAG_INHERIT, HANDLE_FLAG_INHERIT) } == 0 {
            return Err(last_error("SetHandleInformation"));
        }
        hs[i] = h;
    }
    Ok(hs)
}

/// An initialized PROC_THREAD_ATTRIBUTE_LIST, deleted on drop.
struct AttributeList {
    buf: Vec<u64>,
}

impl AttributeList {
    fn new(count: u32) -> Result<AttributeList, String> {
        let mut size = 0usize;
        // SAFETY: a size query with a null list is the documented first call.
        unsafe { InitializeProcThreadAttributeList(null_mut(), count, 0, &mut size) };
        if size == 0 {
            return Err(last_error("InitializeProcThreadAttributeList(size)"));
        }
        let mut buf = vec![0u64; size.div_ceil(8)];
        // SAFETY: buf has at least `size` bytes, 8-aligned.
        let ok = unsafe {
            InitializeProcThreadAttributeList(buf.as_mut_ptr() as LPPROC_THREAD_ATTRIBUTE_LIST, count, 0, &mut size)
        };
        if ok == 0 {
            return Err(last_error("InitializeProcThreadAttributeList"));
        }
        Ok(AttributeList { buf })
    }

    fn ptr(&mut self) -> LPPROC_THREAD_ATTRIBUTE_LIST {
        self.buf.as_mut_ptr() as LPPROC_THREAD_ATTRIBUTE_LIST
    }

    /// # Safety
    /// `value` must stay valid until CreateProcessW returns.
    unsafe fn set(&mut self, attribute: u32, value: *const c_void, size: usize, what: &str) -> Result<(), String> {
        // SAFETY: the list is initialized; the caller keeps value alive.
        let ok = unsafe {
            UpdateProcThreadAttribute(self.ptr(), 0, attribute as usize, value, size, null_mut(), null())
        };
        if ok == 0 {
            return Err(last_error(what));
        }
        Ok(())
    }
}

impl Drop for AttributeList {
    fn drop(&mut self) {
        // SAFETY: the list was initialized in new().
        unsafe { DeleteProcThreadAttributeList(self.ptr()) };
    }
}

/// Starts the confined child with `extra` arguments after the flag, waits
/// for it and returns its exit code. When the child cannot be started,
/// `on_failure` receives a report saying which step failed (its level is
/// never `full`) and 3 is returned.
pub fn launch_contained(extra: &[String], on_failure: &dyn Fn(&LockdownReport)) -> i32 {
    let mut report = LockdownReport::new();
    match launch(extra, &mut report) {
        Ok(code) => code,
        Err(()) => {
            on_failure(&report);
            3
        }
    }
}

/// A confined child that is running. Dropping it closes the job, which
/// kills the child if it is still running.
struct Contained {
    process: Owned,
    job: Owned,
    pid: u32,
}

fn launch(extra: &[String], report: &mut LockdownReport) -> Result<i32, ()> {
    let child = start(extra, report)?;
    // SAFETY: process is valid until dropped.
    let waited = unsafe { WaitForSingleObject(child.process.0, INFINITE) };
    let mut code: u32 = 3;
    // SAFETY: as above.
    if waited != WAIT_OBJECT_0 || unsafe { GetExitCodeProcess(child.process.0, &mut code) } == 0 {
        return Ok(3);
    }
    // The job (and so the kill-on-close guarantee) lives until here.
    drop(child.job);
    Ok(code as i32)
}

/// Starts a confined child with `extra` arguments after the flag and
/// returns once it runs.
fn start(extra: &[String], report: &mut LockdownReport) -> Result<Contained, ()> {
    let step = |report: &mut LockdownReport, name: &'static str, r: Result<(), String>| -> Result<(), ()> {
        let failed = r.is_err();
        report.require(name, r);
        if failed {
            Err(())
        } else {
            Ok(())
        }
    };

    let fail = |report: &mut LockdownReport, name: &'static str, e: String| -> Result<Contained, ()> {
        report.require(name, Err(e));
        Err(())
    };
    let sid = match container_name().and_then(|name| container_sid(&name)) {
        Ok(s) => s,
        Err(e) => return fail(report, "appcontainer", e),
    };
    let capability = match runner_capability_sid() {
        Ok(c) => c,
        Err(e) => return fail(report, "appcontainer", e),
    };
    let job = match create_job() {
        Ok(j) => j,
        Err(e) => return fail(report, "job_object", e),
    };
    let handles = match std_handles() {
        Ok(h) => h,
        Err(e) => return fail(report, "stdio", e),
    };
    let mut inherit: Vec<HANDLE> = Vec::with_capacity(3);
    for h in handles {
        if !inherit.contains(&h) {
            inherit.push(h);
        }
    }
    let exe = match own_path() {
        Ok(p) => p,
        Err(e) => return fail(report, "launch", e),
    };
    let cwd = match system_directory() {
        Ok(mut d) => {
            d.push(0);
            d
        }
        Err(e) => return fail(report, "launch", e),
    };
    let mut cmd: Vec<u16> = Vec::new();
    push_arg(&mut cmd, &exe);
    push_arg(&mut cmd, &CONTAINED_FLAG.encode_utf16().collect::<Vec<_>>());
    for a in extra {
        push_arg(&mut cmd, &a.encode_utf16().collect::<Vec<_>>());
    }
    cmd.push(0);
    let mut exe_z = exe.clone();
    exe_z.push(0);
    if let Err(e) = ensure_runner_access(&exe_z, capability.0) {
        return fail(report, "runner_access", e);
    }
    let env = child_environment();

    let mut capability_attr = SID_AND_ATTRIBUTES {
        Sid: capability.0,
        Attributes: SE_GROUP_ENABLED as u32,
    };
    let caps = SECURITY_CAPABILITIES {
        AppContainerSid: sid.0,
        Capabilities: &mut capability_attr,
        CapabilityCount: 1,
        Reserved: 0,
    };
    let mitigations: [u64; 2] = [
        MITIGATIONS,
        if shadow_stack_available() { MITIGATION2_CET_USER_SHADOW_STACKS_ALWAYS_ON } else { 0 },
    ];
    let child_policy: u32 = CHILD_PROCESS_RESTRICTED;
    let all_packages: u32 = ALL_APPLICATION_PACKAGES_OPT_OUT;

    let mut attrs = match AttributeList::new(5) {
        Ok(a) => a,
        Err(e) => return fail(report, "launch", e),
    };
    // SAFETY: every value outlives CreateProcessW below.
    let set = unsafe {
        attrs
            .set(
                PROC_THREAD_ATTRIBUTE_SECURITY_CAPABILITIES,
                &caps as *const _ as *const c_void,
                size_of::<SECURITY_CAPABILITIES>(),
                "attribute SECURITY_CAPABILITIES",
            )
            .and_then(|_| {
                attrs.set(
                    PROC_THREAD_ATTRIBUTE_MITIGATION_POLICY,
                    mitigations.as_ptr() as *const c_void,
                    size_of::<[u64; 2]>(),
                    "attribute MITIGATION_POLICY",
                )
            })
            .and_then(|_| {
                attrs.set(
                    PROC_THREAD_ATTRIBUTE_ALL_APPLICATION_PACKAGES_POLICY,
                    &all_packages as *const _ as *const c_void,
                    size_of::<u32>(),
                    "attribute ALL_APPLICATION_PACKAGES_POLICY",
                )
            })
            .and_then(|_| {
                attrs.set(
                    PROC_THREAD_ATTRIBUTE_CHILD_PROCESS_POLICY,
                    &child_policy as *const _ as *const c_void,
                    size_of::<u32>(),
                    "attribute CHILD_PROCESS_POLICY",
                )
            })
            .and_then(|_| {
                attrs.set(
                    PROC_THREAD_ATTRIBUTE_HANDLE_LIST,
                    inherit.as_ptr() as *const c_void,
                    inherit.len() * size_of::<HANDLE>(),
                    "attribute HANDLE_LIST",
                )
            })
    };
    step(report, "process_attributes", set)?;

    // SAFETY: zeroed STARTUPINFOEXW is valid; fields are set below.
    let mut si: STARTUPINFOEXW = unsafe { zeroed() };
    si.StartupInfo.cb = size_of::<STARTUPINFOEXW>() as u32;
    si.StartupInfo.dwFlags = STARTF_USESTDHANDLES;
    si.StartupInfo.hStdInput = handles[0];
    si.StartupInfo.hStdOutput = handles[1];
    si.StartupInfo.hStdError = handles[2];
    si.lpAttributeList = attrs.ptr();
    // SAFETY: zeroed PROCESS_INFORMATION is a valid out-parameter.
    let mut pi: PROCESS_INFORMATION = unsafe { zeroed() };
    // SAFETY: all pointers are valid, NUL-terminated where required, and
    // live until the call returns; cmd is mutable as CreateProcessW needs.
    let ok = unsafe {
        CreateProcessW(
            exe_z.as_ptr(),
            cmd.as_mut_ptr(),
            null(),
            null(),
            1 as BOOL,
            EXTENDED_STARTUPINFO_PRESENT | CREATE_SUSPENDED | DETACHED_PROCESS | CREATE_UNICODE_ENVIRONMENT,
            env.as_ptr() as *const c_void,
            cwd.as_ptr(),
            &si.StartupInfo,
            &mut pi,
        )
    };
    if ok == 0 {
        return fail(report, "launch", last_error("CreateProcessW"));
    }
    let process = Owned(pi.hProcess);
    let thread = Owned(pi.hThread);
    // SAFETY: both handles are valid.
    if unsafe { AssignProcessToJobObject(job.0, process.0) } == 0 {
        let e = last_error("AssignProcessToJobObject");
        // SAFETY: the suspended child never ran.
        unsafe { TerminateProcess(process.0, 3) };
        return fail(report, "job_object", e);
    }
    // SAFETY: thread is the child's suspended main thread.
    if unsafe { ResumeThread(thread.0) } == u32::MAX {
        let e = last_error("ResumeThread");
        // SAFETY: as above.
        unsafe { TerminateProcess(process.0, 3) };
        return fail(report, "launch", e);
    }
    drop(thread);
    drop(attrs);
    // The package SID and the capability SID were only needed to create the
    // process; its token holds its own copies.
    drop(sid);
    drop(capability);
    Ok(Contained {
        process,
        job,
        pid: pi.dwProcessId,
    })
}

/// The child's environment: only the variables system DLLs need to find the
/// Windows directory (Winsock, for one, fails to start without SystemRoot).
/// Nothing from the host's environment reaches the script.
fn child_environment() -> Vec<u16> {
    let mut block: Vec<u16> = Vec::new();
    for name in ["SystemRoot", "SystemDrive", "windir"] {
        if let Some(value) = std::env::var_os(name) {
            if let Some(value) = value.to_str() {
                block.extend(format!("{name}={value}").encode_utf16());
                block.push(0);
            }
        }
    }
    if block.is_empty() {
        block.push(0);
    }
    block.push(0);
    block
}

fn token_check() -> Result<(), String> {
    let mut token: HANDLE = null_mut();
    // SAFETY: token is an out-pointer.
    if unsafe { OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &mut token) } == 0 {
        return Err(last_error("OpenProcessToken"));
    }
    let token = Owned(token);
    let mut is_container: u32 = 0;
    let mut len = 0u32;
    // SAFETY: the buffer matches TokenIsAppContainer (a DWORD).
    if unsafe {
        GetTokenInformation(token.0, TokenIsAppContainer, &mut is_container as *mut _ as *mut c_void, 4, &mut len)
    } == 0
    {
        return Err(last_error("GetTokenInformation(TokenIsAppContainer)"));
    }
    if is_container == 0 {
        return Err("the process token is not an AppContainer token".into());
    }
    // Size query, then the capability list itself.
    // SAFETY: a null buffer with length 0 asks for the size.
    unsafe { GetTokenInformation(token.0, TokenCapabilities, null_mut(), 0, &mut len) };
    if (len as usize) < size_of::<u32>() {
        return Err(last_error("GetTokenInformation(TokenCapabilities size)"));
    }
    let mut buf = vec![0u64; (len as usize).div_ceil(8)];
    // SAFETY: buf holds len bytes, 8-aligned.
    if unsafe { GetTokenInformation(token.0, TokenCapabilities, buf.as_mut_ptr() as *mut c_void, len, &mut len) } == 0 {
        return Err(last_error("GetTokenInformation(TokenCapabilities)"));
    }
    // SAFETY: the kernel filled a TOKEN_GROUPS header at the start.
    let groups = unsafe { &*(buf.as_ptr() as *const TOKEN_GROUPS) };
    if groups.GroupCount != 1 {
        return Err(format!(
            "the AppContainer token has {} capabilities; expected only {RUNNER_CAPABILITY}",
            groups.GroupCount
        ));
    }
    let expected = runner_capability_sid()?;
    // SAFETY: GroupCount is 1, so Groups[0] is the one entry; both SIDs are
    // valid.
    if unsafe { EqualSid(groups.Groups[0].Sid, expected.0) } == 0 {
        return Err(format!("the AppContainer token's one capability is not {RUNNER_CAPABILITY}"));
    }
    Ok(())
}

// TOKEN_SECURITY_ATTRIBUTES_INFORMATION and TOKEN_SECURITY_ATTRIBUTE_V1
// (ntseapi.h), the layout GetTokenInformation(TokenSecurityAttributes)
// returns: names are counted strings.
#[repr(C)]
struct CountedString {
    length: u16,
    maximum_length: u16,
    buffer: *const u16,
}

#[repr(C)]
struct TokenAttribute {
    name: CountedString,
    value_type: u16,
    reserved: u16,
    flags: u32,
    value_count: u32,
    values: *const c_void,
}

#[repr(C)]
struct TokenAttributes {
    version: u16,
    reserved: u16,
    attribute_count: u32,
    attributes: *const TokenAttribute,
}

/// The token attribute Windows sets on a less-privileged AppContainer.
const LPAC_ATTRIBUTE: &str = "WIN://NOALLAPPPKG";

/// `TokenIsLessPrivilegedAppContainer` (a DWORD). The class is listed as
/// reserved in the public documentation, so a failing query is not an
/// answer: the caller then reads the token attribute instead.
fn lpac_flag(token: HANDLE) -> Result<bool, String> {
    let mut lpac: u32 = 0;
    let mut len = 0u32;
    // SAFETY: the buffer is the class's single DWORD.
    if unsafe { GetTokenInformation(token, TokenIsLessPrivilegedAppContainer, &mut lpac as *mut _ as *mut c_void, 4, &mut len) }
        == 0
    {
        return Err(last_error("GetTokenInformation(TokenIsLessPrivilegedAppContainer)"));
    }
    Ok(lpac != 0)
}

/// Whether the token carries [`LPAC_ATTRIBUTE`].
fn lpac_attribute(token: HANDLE) -> Result<bool, String> {
    let mut len = 0u32;
    // SAFETY: a null buffer with length 0 asks for the size.
    unsafe { GetTokenInformation(token, TokenSecurityAttributes, null_mut(), 0, &mut len) };
    if (len as usize) < size_of::<TokenAttributes>() {
        return Err(last_error("GetTokenInformation(TokenSecurityAttributes size)"));
    }
    let mut buf = vec![0u64; (len as usize).div_ceil(8)];
    // SAFETY: buf holds len bytes, 8-aligned.
    if unsafe { GetTokenInformation(token, TokenSecurityAttributes, buf.as_mut_ptr() as *mut c_void, len, &mut len) } == 0 {
        return Err(last_error("GetTokenInformation(TokenSecurityAttributes)"));
    }
    // SAFETY: the kernel filled the header at the start of buf, and the
    // attribute array and the names it points to lie inside buf.
    let found = unsafe {
        let info = &*(buf.as_ptr() as *const TokenAttributes);
        (0..info.attribute_count as usize).any(|i| {
            let a = &*info.attributes.add(i);
            if a.name.buffer.is_null() {
                return false;
            }
            let name = std::slice::from_raw_parts(a.name.buffer, a.name.length as usize / 2);
            String::from_utf16_lossy(name).eq_ignore_ascii_case(LPAC_ATTRIBUTE)
        })
    };
    Ok(found)
}

/// The token must be a less-privileged AppContainer token, which Windows
/// gives a process created with ALL APPLICATION PACKAGES opted out. Two
/// readings, either of which may say yes: `TokenIsLessPrivilegedAppContainer`
/// (documented as reserved), then the token's [`LPAC_ATTRIBUTE`] attribute,
/// consulted whenever the first did not say yes. A refusal names what each
/// reading said.
fn lpac_check() -> Result<(), String> {
    let mut token: HANDLE = null_mut();
    // SAFETY: token is an out-pointer.
    if unsafe { OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &mut token) } == 0 {
        return Err(last_error("OpenProcessToken"));
    }
    let token = Owned(token);
    let flag = lpac_flag(token.0);
    if flag == Ok(true) {
        return Ok(());
    }
    let attribute = lpac_attribute(token.0);
    if attribute == Ok(true) {
        return Ok(());
    }
    let said = |r: &Result<bool, String>| match r {
        Ok(_) => "no".to_string(),
        Err(e) => e.clone(),
    };
    Err(format!(
        "not a less-privileged AppContainer: token class said {}; {LPAC_ATTRIBUTE} attribute said {}",
        said(&flag),
        said(&attribute)
    ))
}

/// Thread-scoped step on Windows: the token must be an AppContainer token
/// whose only capability is [`RUNNER_CAPABILITY`], and a less-privileged
/// one.
pub fn verify_container(report: &mut LockdownReport) {
    report.require("appcontainer", token_check());
    report.require("lpac", lpac_check());
}

fn job_check() -> Result<(), String> {
    let mut in_job: BOOL = 0;
    // SAFETY: a null job handle asks about any job.
    if unsafe { IsProcessInJob(GetCurrentProcess(), null_mut(), &mut in_job) } == 0 {
        return Err(last_error("IsProcessInJob"));
    }
    if in_job == 0 {
        return Err("the process is not in a job".into());
    }
    // SAFETY: zeroed is a valid out-buffer; a null handle means our own job.
    let mut limits: JOBOBJECT_EXTENDED_LIMIT_INFORMATION = unsafe { zeroed() };
    let ok = unsafe {
        QueryInformationJobObject(
            null_mut(),
            JobObjectExtendedLimitInformation,
            &mut limits as *mut _ as *mut c_void,
            size_of::<JOBOBJECT_EXTENDED_LIMIT_INFORMATION>() as u32,
            null_mut(),
        )
    };
    if ok == 0 {
        return Err(last_error("QueryInformationJobObject(limits)"));
    }
    let basic = &limits.BasicLimitInformation;
    if basic.LimitFlags & JOB_LIMIT_FLAGS != JOB_LIMIT_FLAGS {
        return Err(format!("job limit flags are {:#x}", basic.LimitFlags));
    }
    if basic.ActiveProcessLimit != 1 {
        return Err(format!("job allows {} processes", basic.ActiveProcessLimit));
    }
    if basic.PerProcessUserTimeLimit <= 0 || basic.PerProcessUserTimeLimit > JOB_CPU_LIMIT_100NS {
        return Err(format!("job CPU limit is {} (100 ns units)", basic.PerProcessUserTimeLimit));
    }
    if limits.ProcessMemoryLimit == 0 || limits.ProcessMemoryLimit as u64 > ADDRESS_SPACE_LIMIT_BYTES {
        return Err(format!("job memory limit is {}", limits.ProcessMemoryLimit));
    }
    let mut ui = JOBOBJECT_BASIC_UI_RESTRICTIONS {
        UIRestrictionsClass: 0,
    };
    // SAFETY: as above.
    let ok = unsafe {
        QueryInformationJobObject(
            null_mut(),
            JobObjectBasicUIRestrictions,
            &mut ui as *mut _ as *mut c_void,
            size_of::<JOBOBJECT_BASIC_UI_RESTRICTIONS>() as u32,
            null_mut(),
        )
    };
    if ok == 0 {
        return Err(last_error("QueryInformationJobObject(ui)"));
    }
    if ui.UIRestrictionsClass & JOB_OBJECT_UILIMIT_ALL != JOB_OBJECT_UILIMIT_ALL {
        return Err(format!("job UI restrictions are {:#x}", ui.UIRestrictionsClass));
    }
    Ok(())
}

fn mitigation_bits(policy: i32, what: &str) -> Result<u32, String> {
    let mut v: u32 = 0;
    // SAFETY: every policy queried here is a single DWORD bitfield.
    let ok = unsafe {
        GetProcessMitigationPolicy(GetCurrentProcess(), policy, &mut v as *mut _ as *mut c_void, size_of::<u32>())
    };
    if ok == 0 {
        return Err(last_error(&format!("GetProcessMitigationPolicy({what})")));
    }
    Ok(v)
}

fn mitigation_check() -> Result<(), String> {
    let need = |policy: i32, what: &str, mask: u32| -> Result<(), String> {
        let v = mitigation_bits(policy, what)?;
        if v & mask != mask {
            return Err(format!("{what} policy is {v:#x}"));
        }
        Ok(())
    };
    // Each mask names the policy's first bits (winnt.h PROCESS_MITIGATION_*
    // structures): ProhibitDynamicCode; DisallowWin32kSystemCalls;
    // DisableExtensionPoints; NoChildProcessCreation; NoRemoteImages,
    // NoLowMandatoryLabelImages and PreferSystem32Images;
    // RaiseExceptionOnInvalidHandleReference; DisableNonSystemFonts;
    // EnableControlFlowGuard (on only when the image is CFG-instrumented).
    need(ProcessDynamicCodePolicy, "dynamic code", 0x1)?;
    need(ProcessSystemCallDisablePolicy, "win32k system calls", 0x1)?;
    need(ProcessExtensionPointDisablePolicy, "extension points", 0x1)?;
    need(ProcessChildProcessPolicy, "child processes", 0x1)?;
    need(ProcessImageLoadPolicy, "image load", 0x7)?;
    need(ProcessStrictHandleCheckPolicy, "strict handle checks", 0x1)?;
    need(ProcessFontDisablePolicy, "font loading", 0x1)?;
    need(ProcessControlFlowGuardPolicy, "control flow guard", 0x1)?;
    // EnableBottomUpRandomization, EnableForceRelocateImages and
    // EnableHighEntropy. The image is linked /DYNAMICBASE and
    // /HIGHENTROPYVA (Rust's defaults), so forcing them changes nothing
    // for it. Force-relocate is the plain "always on" mode: it relocates a
    // DLL that was linked without /DYNAMICBASE but still carries
    // relocations; one with no relocation section still loads at its fixed
    // base (only the "require relocations" mode would refuse it). Every DLL
    // the runner loads is part of Windows.
    need(ProcessASLRPolicy, "address randomisation", 0x7)?;
    // Heap termination on corruption has no query. Enabling it is
    // idempotent and cannot be undone, so the child turns it on itself: if
    // that succeeds, it is in force whatever the launcher managed.
    // SAFETY: a null heap handle with this class and no buffer is the
    // documented process-wide call.
    if unsafe { HeapSetInformation(null_mut(), HeapEnableTerminationOnCorruption, null(), 0) } == 0 {
        return Err(last_error("HeapSetInformation(HeapEnableTerminationOnCorruption)"));
    }
    Ok(())
}

type IsUserCetAvailableFn = unsafe extern "system" fn(u32) -> BOOL;
// USER_CET_ENVIRONMENT_WIN32_PROCESS (winnt.h).
const USER_CET_ENVIRONMENT_WIN32_PROCESS: u32 = 0;

/// Whether this processor and Windows give user-mode processes shadow
/// stacks. Looked up at run time: the export exists from Windows 10 2004
/// on, and an import would stop the runner from loading on older systems.
fn shadow_stack_available() -> bool {
    let Ok(kernel32) = load_system_library("kernel32.dll") else {
        return false;
    };
    // SAFETY: the type matches IsUserCetAvailableInEnvironment.
    match unsafe { proc_address::<IsUserCetAvailableFn>(kernel32, b"IsUserCetAvailableInEnvironment\0") } {
        // SAFETY: the export takes one enum value and has no preconditions.
        Ok(available) => (unsafe { available(USER_CET_ENVIRONMENT_WIN32_PROCESS) }) != 0,
        Err(_) => false,
    }
}

/// Optional: user-mode shadow stacks (in compatibility mode), set by the
/// launcher at creation and read back. Hardening the lockdown does not
/// depend on, so it never blocks `full`: `unavailable` where the processor
/// or Windows has none (Windows on Arm, x86 before CET, Windows 10 before
/// 2004), and also, with the policy read back, where they are available but
/// not in force for this image.
fn shadow_stack(report: &mut LockdownReport) {
    if !shadow_stack_available() {
        report.record(
            "shadow_stack",
            false,
            crate::Status::Unavailable("this processor or Windows has no user-mode shadow stacks".into()),
        );
        return;
    }
    let status = match mitigation_bits(ProcessUserShadowStackPolicy, "shadow stack") {
        Ok(v) if v & 0x1 != 0 => crate::Status::Applied,
        Ok(v) => crate::Status::Unavailable(format!("available but not in force: policy {v:#x}")),
        Err(e) => crate::Status::Unavailable(e),
    };
    report.record("shadow_stack", false, status);
}

/// Optional: only Microsoft-signed images may load from here on. The child
/// sets it itself, once it has started (at creation it would apply to the
/// runner's own executable, which Microsoft did not sign), then reads it
/// back. Every DLL the runner loads later is part of Windows. Hardening the
/// lockdown does not depend on: when it cannot be set or does not read back,
/// it is `unavailable` and does not block `full`.
fn signature_policy(report: &mut LockdownReport) {
    // PROCESS_MITIGATION_BINARY_SIGNATURE_POLICY: MicrosoftSignedOnly.
    let policy: u32 = 0x1;
    // SAFETY: the buffer is the policy's single DWORD.
    let set = unsafe {
        SetProcessMitigationPolicy(ProcessSignaturePolicy, &policy as *const u32 as *const c_void, size_of::<u32>())
    };
    let status = if set == 0 {
        crate::Status::Unavailable(last_error("SetProcessMitigationPolicy(signature)"))
    } else {
        match mitigation_bits(ProcessSignaturePolicy, "signature") {
            Ok(v) if v & 0x1 != 0 => crate::Status::Applied,
            Ok(v) => crate::Status::Unavailable(format!("set but not in force: policy {v:#x}")),
            Err(e) => crate::Status::Unavailable(e),
        }
    };
    report.record("signature_policy", false, status);
}

/// Process-wide step on Windows: the job limits and the mitigation policies
/// must be in force; the signature policy and shadow stacks are optional
/// controls, read back like the rest and reported, never blocking.
pub fn verify_job_and_mitigations(report: &mut LockdownReport) {
    report.require("job_object", job_check());
    report.require("mitigations", mitigation_check());
    signature_policy(report);
    shadow_stack(report);
}

// ---- Self-test ----------------------------------------------------------------

type WsaStartupFn = unsafe extern "system" fn(u16, *mut WSADATA) -> i32;
type SocketFn = unsafe extern "system" fn(i32, i32, i32) -> SOCKET;
type BindFn = unsafe extern "system" fn(SOCKET, *const SOCKADDR, i32) -> i32;
type ListenFn = unsafe extern "system" fn(SOCKET, i32) -> i32;
type GetSockNameFn = unsafe extern "system" fn(SOCKET, *mut SOCKADDR, *mut i32) -> i32;
type ConnectFn = unsafe extern "system" fn(SOCKET, *const SOCKADDR, i32) -> i32;
type CloseSocketFn = unsafe extern "system" fn(SOCKET) -> i32;
type WsaGetLastErrorFn = unsafe extern "system" fn() -> i32;

struct Winsock {
    socket: SocketFn,
    bind: BindFn,
    listen: ListenFn,
    getsockname: GetSockNameFn,
    connect: ConnectFn,
    closesocket: CloseSocketFn,
    last_error: WsaGetLastErrorFn,
}

fn winsock() -> Result<Winsock, String> {
    let m = load_system_library("ws2_32.dll")?;
    // SAFETY: each type matches the documented ws2_32 export.
    unsafe {
        let startup: WsaStartupFn = proc_address(m, b"WSAStartup\0")?;
        let mut data: WSADATA = zeroed();
        let rc = startup(0x0202, &mut data);
        if rc != 0 {
            return Err(format!("WSAStartup: {rc}"));
        }
        Ok(Winsock {
            socket: proc_address(m, b"socket\0")?,
            bind: proc_address(m, b"bind\0")?,
            listen: proc_address(m, b"listen\0")?,
            getsockname: proc_address(m, b"getsockname\0")?,
            connect: proc_address(m, b"connect\0")?,
            closesocket: proc_address(m, b"closesocket\0")?,
            last_error: proc_address(m, b"WSAGetLastError\0")?,
        })
    }
}

fn loopback(port: u16) -> SOCKADDR_IN {
    // SAFETY: zeroed SOCKADDR_IN is valid.
    let mut a: SOCKADDR_IN = unsafe { zeroed() };
    a.sin_family = AF_INET;
    a.sin_port = port.to_be();
    a.sin_addr.S_un.S_addr = u32::from_ne_bytes([127, 0, 0, 1]);
    a
}

/// Opens a loopback listener in the unconfined launcher. Returns the socket
/// and its port.
fn listener(ws: &Winsock) -> Result<(SOCKET, u16), String> {
    // SAFETY: plain Winsock calls with correctly sized address structures.
    unsafe {
        let s = (ws.socket)(AF_INET as i32, SOCK_STREAM, IPPROTO_TCP);
        if s == INVALID_SOCKET {
            return Err(format!("socket: {}", (ws.last_error)()));
        }
        let addr = loopback(0);
        let len = size_of::<SOCKADDR_IN>() as i32;
        if (ws.bind)(s, &addr as *const _ as *const SOCKADDR, len) != 0 {
            return Err(format!("bind: {}", (ws.last_error)()));
        }
        if (ws.listen)(s, 4) != 0 {
            return Err(format!("listen: {}", (ws.last_error)()));
        }
        let mut bound: SOCKADDR_IN = zeroed();
        let mut blen = len;
        if (ws.getsockname)(s, &mut bound as *mut _ as *mut SOCKADDR, &mut blen) != 0 {
            return Err(format!("getsockname: {}", (ws.last_error)()));
        }
        Ok((s, u16::from_be(bound.sin_port)))
    }
}

fn print_line(line: &str) {
    use std::io::Write;
    let mut out = std::io::stdout().lock();
    let _ = out.write_all(line.as_bytes());
    let _ = out.write_all(b"\n");
    let _ = out.flush();
}

type GetUserProfileDirectoryFn = unsafe extern "system" fn(HANDLE, PWSTR, *mut u32) -> BOOL;

/// The current user's profile directory, from the token (the host starts
/// the runner without USERPROFILE or TEMP in its environment).
fn user_profile_dir() -> Result<std::path::PathBuf, String> {
    use std::os::windows::ffi::OsStringExt;
    let userenv = load_system_library("userenv.dll")?;
    // SAFETY: the type matches GetUserProfileDirectoryW.
    let get: GetUserProfileDirectoryFn = unsafe { proc_address(userenv, b"GetUserProfileDirectoryW\0")? };
    let mut token: HANDLE = null_mut();
    // SAFETY: token is an out-pointer.
    if unsafe { OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &mut token) } == 0 {
        return Err(last_error("OpenProcessToken"));
    }
    let token = Owned(token);
    let mut buf = vec![0u16; 1024];
    let mut len = buf.len() as u32;
    // SAFETY: buf holds len characters; on success len counts the NUL.
    if unsafe { get(token.0, buf.as_mut_ptr(), &mut len) } == 0 {
        return Err(last_error("GetUserProfileDirectoryW"));
    }
    buf.truncate(len.saturating_sub(1) as usize);
    Ok(std::ffi::OsString::from_wide(&buf).into())
}

fn windows_directory() -> Result<std::path::PathBuf, String> {
    use std::os::windows::ffi::OsStringExt;
    let mut buf = vec![0u16; 512];
    // SAFETY: buf is valid for its length.
    let n = unsafe { GetSystemWindowsDirectoryW(buf.as_mut_ptr(), buf.len() as u32) } as usize;
    if n == 0 || n >= buf.len() {
        return Err(last_error("GetSystemWindowsDirectoryW"));
    }
    buf.truncate(n);
    Ok(std::ffi::OsString::from_wide(&buf).into())
}

/// `--self-test` on Windows, in the unconfined launcher: run real sessions
/// (each through its own launcher, the production path), prepare the probes,
/// start a second confined child as the sibling to probe, and run the
/// confined child, which prints the result. The session result travels to
/// the child on its command line, so the child's line carries it and its
/// verdict includes it.
pub fn selftest(_args: &[String], session: &dyn Fn() -> SessionCheck) -> i32 {
    let session = session();
    let fail = |detail: String| {
        let report = LockdownReport::new();
        print_line(&render(false, report.os, &report.to_json(), &[CheckResult {
            name: "setup",
            denied: false,
            detail,
        }], &session));
        1
    };
    let pid = std::process::id();
    // Under the user's profile: a user-only directory, which no AppContainer
    // ACE reaches.
    let dir = match user_profile_dir() {
        Ok(p) => p.join("AppData").join("Local").join(format!("cc_codemode_selftest_{pid}")),
        Err(e) => return fail(e),
    };
    if let Err(e) = std::fs::create_dir_all(&dir) {
        return fail(format!("create probe directory: {e}"));
    }
    let probe = dir.join("probe.txt");
    if let Err(e) = std::fs::write(&probe, b"probe") {
        return fail(format!("write probe file: {e}"));
    }
    // Windows\Temp lets every user create files; an AppContainer must not.
    let windows_file = match windows_directory() {
        Ok(w) => w.join("Temp").join(format!("cc_codemode_selftest_{pid}.txt")),
        Err(e) => return fail(e),
    };
    let install_file = match install_neighbour() {
        Ok(f) => f,
        Err(e) => return fail(e),
    };
    // all_packages_object: a file only ALL APPLICATION PACKAGES may read,
    // which any ordinary AppContainer could and a less-privileged one cannot.
    // Its positive control, in the same directory: a file only the runner
    // capability may read, which the child holds. The child must read the
    // second and be refused the first, so the refusal is the group's, not
    // the path's.
    let all_packages_file = dir.join("all_packages.txt");
    if let Err(e) = create_probe_file(&all_packages_file, "AC") {
        return fail(e);
    }
    let capability_file = dir.join("capability.txt");
    let capability = match runner_capability_sid().and_then(|sid| sid_string(sid.0)) {
        Ok(s) => s,
        Err(e) => return fail(e),
    };
    if let Err(e) = create_probe_file(&capability_file, &capability) {
        return fail(e);
    }
    let ws = match winsock() {
        Ok(w) => w,
        Err(e) => return fail(e),
    };
    let (sock, port) = match listener(&ws) {
        Ok(v) => v,
        Err(e) => return fail(e),
    };
    let mut sibling_report = LockdownReport::new();
    let sibling = match start(&[SIBLING_FLAG.to_string()], &mut sibling_report) {
        Ok(c) => c,
        Err(()) => return fail(format!("start the sibling child: {}", sibling_report.to_json())),
    };
    // The sibling probes mean something only if an ordinary process of this
    // user can open the sibling: then a refusal is the AppContainer's.
    // SAFETY: plain OpenProcess; the handle is closed by Owned.
    let opened = Owned(unsafe { OpenProcess(PROCESS_VM_READ | PROCESS_DUP_HANDLE, 0, sibling.pid) });
    if opened.0.is_null() {
        return fail(last_error("the launcher cannot open the sibling child itself"));
    }
    drop(opened);
    let extra = vec![
        "--self-test".to_string(),
        probe.to_string_lossy().into_owned(),
        dir.to_string_lossy().into_owned(),
        port.to_string(),
        windows_file.to_string_lossy().into_owned(),
        sibling.pid.to_string(),
        install_file.to_string_lossy().into_owned(),
        all_packages_file.to_string_lossy().into_owned(),
        capability_file.to_string_lossy().into_owned(),
        if session.passed { "passed" } else { "failed" }.to_string(),
        session.runs.to_string(),
        session.detail.clone(),
    ];
    let code = launch_contained(&extra, &|report| {
        print_line(&render(false, report.os, &report.to_json(), &[], &session));
    });
    // SAFETY: the sibling is ours; closing its job would kill it as well.
    unsafe { TerminateProcess(sibling.process.0, 0) };
    drop(sibling);
    // SAFETY: closing the listener we opened.
    unsafe { (ws.closesocket)(sock) };
    let _ = std::fs::remove_dir_all(&dir);
    // Only there if the child could create it, which already failed the
    // check.
    let w = wide(&windows_file.to_string_lossy());
    // SAFETY: w is NUL-terminated.
    unsafe { DeleteFileW(w.as_ptr()) };
    code
}

/// A file of the installation other than the runner that this user can
/// read: one beside the runner, else one in the directory above (the
/// server's `bin`). The confined child must not be able to read it.
fn install_neighbour() -> Result<std::path::PathBuf, String> {
    use std::os::windows::ffi::OsStringExt;
    let exe = std::path::PathBuf::from(std::ffi::OsString::from_wide(&own_path()?));
    let mut dirs = Vec::new();
    if let Some(d) = exe.parent() {
        dirs.push(d.to_path_buf());
        if let Some(up) = d.parent() {
            dirs.push(up.to_path_buf());
        }
    }
    for d in dirs {
        let Ok(entries) = std::fs::read_dir(&d) else { continue };
        let mut files: Vec<std::path::PathBuf> = entries
            .filter_map(|e| e.ok())
            .filter(|e| e.file_type().map(|t| t.is_file()).unwrap_or(false))
            .map(|e| e.path())
            .filter(|p| p != &exe && std::fs::File::open(p).is_ok())
            .collect();
        files.sort();
        if let Some(f) = files.into_iter().next() {
            return Ok(f);
        }
    }
    Err("no other readable file beside the runner or in the directory above it".into())
}

/// `sid` in SDDL form (`S-1-15-3-…`).
fn sid_string(sid: PSID) -> Result<String, String> {
    let mut text: PWSTR = null_mut();
    // SAFETY: sid is a valid SID; text receives a LocalAlloc'd string,
    // freed by Local.
    if unsafe { ConvertSidToStringSidW(sid, &mut text) } == 0 {
        return Err(last_error("ConvertSidToStringSidW"));
    }
    let text = Local(text as *mut c_void);
    let p = text.0 as *const u16;
    // SAFETY: the string is NUL-terminated.
    let len = (0..).take_while(|&i| unsafe { *p.add(i) } != 0).count();
    // SAFETY: len units before the terminator are initialised.
    Ok(String::from_utf16_lossy(unsafe { std::slice::from_raw_parts(p, len) }))
}

/// Creates `path` with a protected DACL that grants its owner full access
/// and `grantee` (an SDDL trustee: `AC` for ALL APPLICATION PACKAGES, or a
/// SID string) read access, and nothing else.
fn create_probe_file(path: &std::path::Path, grantee: &str) -> Result<(), String> {
    let sddl = wide(&format!("D:P(A;;FA;;;OW)(A;;FR;;;{grantee})"));
    let mut sd: PSECURITY_DESCRIPTOR = null_mut();
    // SAFETY: sddl is NUL-terminated; sd is freed by Local.
    if unsafe { ConvertStringSecurityDescriptorToSecurityDescriptorW(sddl.as_ptr(), 1, &mut sd, null_mut()) } == 0 {
        return Err(last_error("ConvertStringSecurityDescriptorToSecurityDescriptorW"));
    }
    let sd = Local(sd);
    let sa = SECURITY_ATTRIBUTES {
        nLength: size_of::<SECURITY_ATTRIBUTES>() as u32,
        lpSecurityDescriptor: sd.0,
        bInheritHandle: 0,
    };
    let w = wide(&path.to_string_lossy());
    // SAFETY: w is NUL-terminated; sa and its descriptor outlive the call.
    let h = unsafe { CreateFileW(w.as_ptr(), FILE_GENERIC_WRITE, 0, &sa, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, null_mut()) };
    if h == INVALID_HANDLE_VALUE {
        return Err(last_error(&format!("create the probe file {}", path.display())));
    }
    let h = Owned(h);
    let mut n = 0u32;
    // SAFETY: the buffer is valid for its length.
    if unsafe { WriteFile(h.0, b"probe".as_ptr(), 5, &mut n, null_mut()) } == 0 {
        return Err(last_error(&format!("write the probe file {}", path.display())));
    }
    Ok(())
}

/// The self-test's sibling: a confined child that only waits until the
/// launcher ends it.
pub fn sibling_child() -> ! {
    loop {
        std::thread::park();
    }
}

/// `--self-test` in the confined child, started as
/// `cc_codemode --contained-child --self-test <probe file> <probe dir> <port>
/// <Windows directory file> <sibling pid> <install file> <all-packages file>
/// <capability file> <passed|failed> <session runs> <session detail>`; `rest` is everything
/// after `--self-test`. Verifies the
/// confinement, attempts each check and prints the result, including the
/// launcher's session check.
pub fn selftest_child(rest: &[String]) -> i32 {
    let mut report = LockdownReport::new();
    verify_container(&mut report);
    verify_job_and_mitigations(&mut report);
    let (probe_file, probe_dir, port, windows_file, sibling, install_file, all_packages_file, capability_file, session) =
        match rest {
        [file, dir, port, windows_file, sibling, install_file, all_packages_file, capability_file, passed, runs, detail] => (
            file.clone(),
            dir.clone(),
            port.parse::<u16>().unwrap_or(0),
            windows_file.clone(),
            sibling.parse::<u32>().unwrap_or(0),
            install_file.clone(),
            all_packages_file.clone(),
            capability_file.clone(),
            SessionCheck {
                passed: passed == "passed",
                runs: runs.parse::<u32>().unwrap_or(0),
                detail: detail.clone(),
            },
        ),
        _ => {
            print_line(&render(
                false,
                report.os,
                &report.to_json(),
                &[],
                &SessionCheck::not_run("the launcher passed no session result"),
            ));
            return 1;
        }
    };
    let checks: Vec<CheckResult> = all_checks()
        .map(|name| {
            let r = match name {
                "file_read" => try_read(&probe_file),
                "file_create" => try_create(&format!("{probe_dir}\\created.txt")),
                "network" => try_connect(port),
                "process" => try_spawn(),
                "windows_write" => try_create(&windows_file).map_err(only_access_denied),
                "sibling_vm_read" => try_open(sibling, PROCESS_VM_READ, "PROCESS_VM_READ"),
                "sibling_dup_handle" => try_open(sibling, PROCESS_DUP_HANDLE, "PROCESS_DUP_HANDLE"),
                "install_dir_read" => own_executable()
                    .and_then(|exe| positive_control(&exe, "the runner's own executable"))
                    .and_then(|()| try_read(&install_file).map_err(only_access_denied)),
                "all_packages_object" => positive_control(&capability_file, "the file granted to the runner capability")
                    .and_then(|()| try_read(&all_packages_file).map_err(only_access_denied)),
                other => Err(Probe::NotAttempted(format!("unknown check {other}"))),
            };
            match r {
                Ok(t) => CheckResult { name, denied: false, detail: format!("allowed: {t}") },
                Err(Probe::Denied(t)) => CheckResult { name, denied: true, detail: t },
                Err(Probe::NotAttempted(t)) => CheckResult {
                    name,
                    denied: false,
                    detail: format!("not attempted: {t}"),
                },
            }
        })
        .collect();
    let ok = overall_ok(report.level() == Level::Full, &checks, &session);
    print_line(&render(ok, report.os, &report.to_json(), &checks, &session));
    if ok {
        0
    } else {
        1
    }
}

/// The runner's own executable, as a path the probes can read.
fn own_executable() -> Result<String, Probe> {
    own_path().map(|w| String::from_utf16_lossy(&w)).map_err(Probe::NotAttempted)
}

/// A read the child must be able to make before a refusal next to it
/// counts: the same path up to the file, an access entry the child's token
/// matches. If it fails, the refusal beside it could be traversal or the
/// path, so the check is not attempted (and fails).
fn positive_control(path: &str, what: &str) -> Result<(), Probe> {
    match try_read(path) {
        Ok(_) => Ok(()),
        Err(Probe::Denied(t) | Probe::NotAttempted(t)) => {
            Err(Probe::NotAttempted(format!("positive control failed, could not read {what}: {t}")))
        }
    }
}

/// Why a check did not succeed. Only a refusal from the operation itself
/// counts as denied; a probe that could not be set up proves nothing.
enum Probe {
    Denied(String),
    NotAttempted(String),
}

impl From<String> for Probe {
    fn from(s: String) -> Probe {
        Probe::Denied(s)
    }
}

/// Keeps a refusal only when it was ERROR_ACCESS_DENIED: for the probes of
/// places an ordinary process of this user may reach, any other error (a
/// missing directory, a sharing violation) proves nothing.
fn only_access_denied(p: Probe) -> Probe {
    match p {
        Probe::Denied(t) if t.contains(&format!("error {ERROR_ACCESS_DENIED} ")) => Probe::Denied(t),
        Probe::Denied(t) => Probe::NotAttempted(format!("failed, but not with access denied: {t}")),
        other => other,
    }
}

fn try_open(pid: u32, access: u32, what: &str) -> Result<String, Probe> {
    if pid == 0 {
        return Err(Probe::NotAttempted("no sibling pid".into()));
    }
    // SAFETY: plain OpenProcess; a handle it returns is closed by Owned.
    let h = Owned(unsafe { OpenProcess(access, 0, pid) });
    if h.0.is_null() {
        return Err(only_access_denied(last_error(&format!("OpenProcess({what}) on the sibling")).into()));
    }
    Ok(format!("opened the sibling child with {what}"))
}

fn try_read(path: &str) -> Result<String, Probe> {
    let w = wide(path);
    // SAFETY: w is NUL-terminated.
    let h = unsafe {
        CreateFileW(w.as_ptr(), 0x8000_0000, FILE_SHARE_READ, null(), OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, null_mut())
    };
    if h == INVALID_HANDLE_VALUE {
        return Err(last_error("CreateFileW(read)").into());
    }
    let h = Owned(h);
    let mut b = [0u8; 1];
    let mut n = 0u32;
    // SAFETY: b is valid for one byte.
    if unsafe { ReadFile(h.0, b.as_mut_ptr(), 1, &mut n, null_mut()) } == 0 {
        return Err(last_error("ReadFile").into());
    }
    Ok("read the probe file".into())
}

fn try_create(path: &str) -> Result<String, Probe> {
    let w = wide(path);
    // SAFETY: w is NUL-terminated.
    let h = unsafe {
        CreateFileW(w.as_ptr(), 0x4000_0000, 0, null(), CREATE_NEW, FILE_ATTRIBUTE_NORMAL, null_mut())
    };
    if h == INVALID_HANDLE_VALUE {
        return Err(last_error("CreateFileW(create)").into());
    }
    drop(Owned(h));
    Ok("created a file in the probe directory".into())
}

fn try_connect(port: u16) -> Result<String, Probe> {
    if port == 0 {
        return Err(Probe::NotAttempted("no listener port".into()));
    }
    let ws = winsock().map_err(Probe::NotAttempted)?;
    // SAFETY: plain Winsock calls with a correctly sized address.
    unsafe {
        let s = (ws.socket)(AF_INET as i32, SOCK_STREAM, IPPROTO_TCP);
        if s == INVALID_SOCKET {
            return Err(format!("socket: WSA error {}", (ws.last_error)()).into());
        }
        let addr = loopback(port);
        let rc = (ws.connect)(s, &addr as *const _ as *const SOCKADDR, size_of::<SOCKADDR_IN>() as i32);
        let err = (ws.last_error)();
        (ws.closesocket)(s);
        if rc == 0 {
            Ok("connected to the launcher's loopback listener".into())
        } else {
            Err(format!("connect: WSA error {err}").into())
        }
    }
}

fn try_spawn() -> Result<String, Probe> {
    let mut app = system_directory().map_err(Probe::NotAttempted)?;
    app.extend("\\cmd.exe".encode_utf16());
    let mut cmd: Vec<u16> = Vec::new();
    push_arg(&mut cmd, &app);
    cmd.extend(" /c exit 0".encode_utf16());
    cmd.push(0);
    app.push(0);
    // SAFETY: zeroed structures are valid in/out parameters.
    let mut si: windows_sys::Win32::System::Threading::STARTUPINFOW = unsafe { zeroed() };
    si.cb = size_of::<windows_sys::Win32::System::Threading::STARTUPINFOW>() as u32;
    let mut pi: PROCESS_INFORMATION = unsafe { zeroed() };
    // SAFETY: pointers are valid and NUL-terminated; cmd is mutable.
    let ok = unsafe {
        CreateProcessW(app.as_ptr(), cmd.as_mut_ptr(), null(), null(), 0, DETACHED_PROCESS, null(), null(), &si, &mut pi)
    };
    if ok == 0 {
        return Err(last_error("CreateProcessW").into());
    }
    let p = Owned(pi.hProcess);
    drop(Owned(pi.hThread));
    // SAFETY: p is the process we started.
    unsafe { TerminateProcess(p.0, 0) };
    Ok("started cmd.exe".into())
}
