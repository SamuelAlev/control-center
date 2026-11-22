//! Windows-only link settings. The interpreter runs on the main thread, whose
//! stack MSVC sizes at 1 MiB by default; QuickJS's own stack limit has to sit
//! well inside it, so the image asks for 8 MiB like Linux and macOS give.
//! Its imported DLLs load from System32 only (`/DEPENDENTLOADFLAG:0x800`).
//! The confined child also must not depend on a CRT DLL beside it, so a
//! dynamic-CRT build is refused instead of producing a binary that may not
//! start inside the AppContainer. The child also requires Control Flow
//! Guard to be in force (its self-check reads the policy back), so a build
//! without it is refused here rather than failing at run time: Rust code
//! needs `-Ccontrol-flow-guard`, QuickJS-NG's C code `/guard:cf` in
//! `CFLAGS_<target>` (scripts/release/windows_natives.sh sets both).

fn main() {
    println!("cargo:rerun-if-changed=build.rs");
    let os = std::env::var("CARGO_CFG_TARGET_OS").unwrap_or_default();
    let env = std::env::var("CARGO_CFG_TARGET_ENV").unwrap_or_default();
    if os == "windows" && env == "msvc" {
        println!("cargo:rustc-link-arg-bins=/STACK:8388608");
        // The DLLs the executable imports (Rust std's, such as
        // bcryptprimitives.dll) are looked up in System32 only, never
        // beside the executable, where a planted DLL would run in the
        // unconfined launcher before any mitigation applies.
        println!("cargo:rustc-link-arg-bins=/DEPENDENTLOADFLAG:0x800");
        let features = std::env::var("CARGO_CFG_TARGET_FEATURE").unwrap_or_default();
        if !features.split(',').any(|f| f == "crt-static") {
            panic!(
                "cc_codemode must be built with RUSTFLAGS=\"-Ctarget-feature=+crt-static\" on Windows"
            );
        }
        let rustflags = std::env::var("CARGO_ENCODED_RUSTFLAGS").unwrap_or_default();
        let flags: Vec<&str> = rustflags.split('\x1f').collect();
        let cfg = flags.windows(2).any(|w| w[0] == "-C" && w[1].starts_with("control-flow-guard"))
            || flags.iter().any(|f| f.starts_with("-Ccontrol-flow-guard"));
        if !cfg || flags.iter().any(|f| f.ends_with("control-flow-guard=no") || f.ends_with("control-flow-guard=false")) {
            panic!("cc_codemode must be built with RUSTFLAGS=\"-Ccontrol-flow-guard\" on Windows");
        }
        let target = std::env::var("TARGET").unwrap_or_default().replace('-', "_");
        let cflags_var = format!("CFLAGS_{target}");
        println!("cargo:rerun-if-env-changed={cflags_var}");
        let cflags = std::env::var(&cflags_var).unwrap_or_default();
        if !cflags.split_whitespace().any(|f| f.eq_ignore_ascii_case("/guard:cf")) {
            panic!("cc_codemode must be built with {cflags_var}=\"/guard:cf\" on Windows, so QuickJS-NG is CFG-instrumented too");
        }
    }
}
