//! Restricts what the cdylib exports to this crate's own `cc_*` C ABI.
//!
//! Without this, every symbol from the statically linked sherpa-onnx AND ONNX
//! Runtime (`OrtGetApiBase`, `SherpaOnnx*`, plus a large amount of C++ internal
//! machinery) would be exported from the dylib. That matters for two reasons:
//!
//! 1. **Interposition.** On Linux the dynamic loader resolves symbols globally
//!    and first-loaded-wins. During the migration the old `libonnxruntime.so`
//!    can still be present in the same process; two ONNX Runtimes exporting the
//!    same symbols is exactly the class of bug this whole change removes.
//! 2. **Honest surface.** The dylib's exported set becomes precisely the
//!    contract in `cc_inference.h`, so `nm` in build_inference.sh can assert it.
//!
//! Windows needs nothing here: a Rust cdylib already exports only `#[no_mangle]`
//! symbols (plus anything marked `dllexport`), never its static dependencies'.

use std::env;
use std::fs;
use std::path::PathBuf;

fn main() {
    println!("cargo:rerun-if-changed=build.rs");
    println!("cargo:rerun-if-changed=cc_inference.h");

    let target_os = env::var("CARGO_CFG_TARGET_OS").unwrap_or_default();
    match target_os.as_str() {
        "macos" | "ios" => {
            // Mach-O symbols carry a leading underscore.
            println!("cargo:rustc-link-arg=-Wl,-exported_symbol,_cc_*");
        }
        "linux" | "android" => {
            let out_dir = PathBuf::from(env::var("OUT_DIR").expect("OUT_DIR"));
            let script = out_dir.join("cc_inference.map");
            fs::write(&script, "{ global: cc_*; local: *; };\n")
                .expect("failed to write the linker version script");
            println!(
                "cargo:rustc-link-arg=-Wl,--version-script={}",
                script.display()
            );
        }
        _ => {}
    }
}
