# Provenance

The two workspace crates, `cc_codemode` and `cc_codemode_lockdown`, are first
party and licensed MIT. Every dependency is pinned with `=` in its
`Cargo.toml`, locked in `Cargo.lock` and built with `--locked`. All of them
come from crates.io. The licences below were read from each crate's
`Cargo.toml` at the locked version.

## Compiled into the binary

| Crate | Version | Licence | Source | Used for |
| --- | --- | --- | --- | --- |
| rquickjs | 0.14.0 | MIT | https://github.com/DelSkayn/rquickjs | engine bindings (features `std`, `allocator`) |
| rquickjs-core | 0.14.0 | MIT | https://github.com/DelSkayn/rquickjs | engine bindings |
| rquickjs-sys | 0.14.0 | MIT | https://github.com/DelSkayn/rquickjs | vendored QuickJS-NG C sources, built with `cc` |
| QuickJS-NG (C, inside rquickjs-sys) | 0.16.2 | MIT (Fabrice Bellard, Charlie Gordon, Ben Noordhuis and contributors; `rquickjs-sys-0.14.0/quickjs/LICENSE`) | https://github.com/quickjs-ng/quickjs | the interpreter: `quickjs.c`, `libregexp.c`, `libunicode.c`, `dtoa.c` |
| hashbrown | 0.17.1 | MIT OR Apache-2.0 | https://github.com/rust-lang/hashbrown | rquickjs-core dependency |
| allocator-api2 | 0.2.21 | MIT OR Apache-2.0 | https://github.com/zakarumych/allocator-api2 | hashbrown dependency |
| equivalent | 1.0.3 | Apache-2.0 OR MIT | https://github.com/indexmap-rs/equivalent | hashbrown dependency |
| foldhash | 0.2.0 | Zlib | https://github.com/orlp/foldhash | hashbrown dependency |
| serde_json | 1.0.149 | MIT OR Apache-2.0 | https://github.com/serde-rs/json | wire protocol (no default features; `std`, `float_roundtrip`: exact number parsing, no extra crate) |
| serde_core | 1.0.229 | MIT OR Apache-2.0 | https://github.com/serde-rs/serde | serde_json dependency |
| itoa | 1.0.19 | MIT OR Apache-2.0 | https://github.com/dtolnay/itoa | serde_json dependency |
| zmij | 1.0.23 | MIT | https://github.com/dtolnay/zmij | serde_json float formatting |
| memchr | 2.8.3 | Unlicense OR MIT | https://github.com/BurntSushi/memchr | serde_json dependency |
| libc | 0.2.191 | MIT OR Apache-2.0 | https://github.com/rust-lang/libc | system calls and `_exit` |
| seccompiler | 0.5.0 | Apache-2.0 OR BSD-3-Clause | https://github.com/rust-vmm/seccompiler | Linux only: seccomp BPF filter (no default features) |
| windows-sys | 0.61.2 | MIT OR Apache-2.0 | https://github.com/microsoft/windows-rs | Windows only: Win32 bindings |
| windows-link | 0.2.1 | MIT OR Apache-2.0 | https://github.com/microsoft/windows-rs | Windows only: windows-sys linking |

## Build only (not in the binary)

| Crate | Version | Licence | Source |
| --- | --- | --- | --- |
| cc | 1.11.2 | MIT OR Apache-2.0 | https://github.com/rust-lang/cc-rs |
| find-msvc-tools | 0.1.15 | MIT OR Apache-2.0 | https://github.com/rust-lang/cc-rs |
| shlex | 2.0.1 | MIT OR Apache-2.0 | https://github.com/comex/rust-shlex |

## Listed in Cargo.lock but never compiled

serde_json declares these behind `cfg(any())`, a condition that is always
false, so Cargo records them but never builds them (`cargo tree` does not show
them):

- serde
- serde_derive
- proc-macro2
- quote
- syn
- unicode-ident

rquickjs-core declares `relative-path` 2.0.3 as an optional dependency of its
`loader` feature, which is not enabled (there is no module loader), so it is
locked but never compiled either.

## Engine behaviour the runner relies on

Call sites (`at` on `call` frames, README.md "Call sites") depend on
QuickJS-NG 0.16.2 internals; recheck them, with the `call_sites_*` tests,
on any engine update:

- `Error.prepareStackTrace` and `Error.stackTraceLimit` are accessors whose
  setters write engine state, so the setter the prelude captures keeps
  working after the property is deleted and the constructor frozen.
- With a prepare function installed, the engine hands it CallSite objects
  whose `getFileName`, `getLineNumber` and `getColumnNumber` come from the
  bytecode, not from the function's `name`.
- Columns count UTF-8 bytes from the line start; `\n`, `\r\n` and a lone
  `\r` end a line everywhere, U+2028/U+2029 only outside comments.
- `eval` and `Function` compile under the file name `<input>`, so the
  runner compiles the script itself (`JS_Eval`, file name `<script>`).

## Not used

- quickjs-libc (`std`/`os` modules) is not compiled: rquickjs is built
  without its `std`-module features.
- No Performance, DOMException or base64 intrinsics are registered.

## How QuickJS-NG is compiled

rquickjs-sys compiles the C sources with the `cc` crate, which takes extra
flags from `CFLAGS_<target>`. The build scripts set them; nothing in the
sources or the lock file changes.

| Target | Flags | Set and checked by |
| --- | --- | --- |
| macOS arm64 | `-fstack-protector-strong -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2` | `scripts/natives/build_codemode.sh` |
| Linux x86_64 | the above and `-fcf-protection=full` (IBT, shadow stack) | `scripts/natives/build_codemode.sh` |
| Linux aarch64 | the above and `-mbranch-protection=standard` (BTI, PAC) | `scripts/natives/build_codemode.sh` |
| Windows (MSVC) | `/guard:cf /GS /d1trimfile:<target dir>\`, with `-Ccontrol-flow-guard` for the Rust code | `scripts/release/windows_natives.sh`; `runner/build.rs` refuses a build without the first two |

The Unix targets also get `-ffile-prefix-map` for each remapped prefix (see
[Build paths](#build-paths)).

The Unix script fails unless the compiled `quickjs.o` references
`__stack_chk_fail`, on Linux also a fortified `__*_chk` call, and on Linux
carries the IBT/SHSTK or BTI/PAC property. Measured on the objects (before:
built without the flags; after: through the script):

- Linux aarch64 (Docker, GCC 12): before, no `__stack_chk_fail`, no `_chk`
  calls, no property note; after, `__stack_chk_fail`, `__snprintf_chk`,
  `__vsnprintf_chk`, `__printf_chk`, `__fprintf_chk`, `__vfprintf_chk` and
  `AArch64 feature: BTI, PAC`.
- Linux x86_64 (Ubuntu 22.04, GCC 11): `__stack_chk_fail`, `__snprintf_chk`,
  `__vsnprintf_chk` and `x86 feature: IBT, SHSTK`.
- macOS arm64 (Apple clang): `__stack_chk_fail`. Clang folds QuickJS's
  fortified calls back to the plain ones because their destination sizes are
  unknown, so there is no `_chk` call to see.

**What is in force.** The executable carries no IBT or BTI property: Rust's
own objects are not marked (stable Rust has no flag that marks them), and the
linker keeps the property only when every object has it. So no loader
enables branch-target enforcement or user shadow stacks for the runner, and
the IBT and BTI instructions in QuickJS-NG are inert. The property is checked
on the C object only to prove the flags arrived. What runs today:

- Linux aarch64: stack protector and fortified calls in QuickJS-NG, and
  return-address signing (PAC) in QuickJS-NG's functions on processors with
  pointer authentication; that needs no property. No BTI. Rust code signs no
  return addresses.
- Linux x86_64: stack protector and fortified calls in QuickJS-NG. Nothing
  from `-fcf-protection`.
- macOS arm64: stack protector in QuickJS-NG, nothing else (no fortified
  calls survive, see above; the `arm64` ABI signs no return addresses).
- Windows: `/GS` in QuickJS-NG and Control Flow Guard for the whole image,
  which the loader enforces and the confined child reads back.

**Assertions stay on** (`NDEBUG` is not defined, as rquickjs-sys builds it by
default). A failed QuickJS assertion calls `abort()`, which ends the runner
with `SIGABRT` instead of letting the interpreter continue from a state its
authors ruled impossible. Measured cost: a mixed benchmark (JSON, sort,
strings, regex, recursion, classes), 20 interleaved release runs each on
macOS arm64, median 744 ms CPU with assertions against 714 ms without
(4.3%).

## Build paths

Without remapping, the release executable named the builder's machine:
panic locations in Rust code and QuickJS-NG's assertion messages (`__FILE__`)
carry source paths, which included the home directory, the cargo registry
under it, and the checkout (the macOS release binary contained the home
directory twice). The builds now rewrite each prefix:

| Prefix | Rust (`--remap-path-prefix`) | C (`-ffile-prefix-map`; MSVC `/d1trimfile`) |
| --- | --- | --- |
| home directory | `/build/home` | `/build/home` |
| cargo home | `/build/cargo` | `/build/cargo` |
| checkout | `/build/src` | `/build/src` |
| cargo target directory | `/build/target` | `/build/target`; on MSVC the prefix is removed |

rquickjs-sys copies the C sources into its build directory under the target
directory, so QuickJS-NG's file names start there
(`/build/target/release/build/rquickjs-sys/<hash>/out/quickjs.c`, measured on
Linux aarch64).

On Windows the targets are `C:\build\home` and so on.

Rust's standard library paths are already `/rustc/<commit>/…`. The flags
travel in `CARGO_ENCODED_RUSTFLAGS`, so a path with spaces stays one
argument. The check is `cc_codemode_check_paths` in `scripts/lib/codemode.sh`.
`scripts/natives/build_codemode.sh` runs it on the built executable with
the home directory, the checkout, the cargo home and the target directory;
`scripts/release/windows_natives.sh` runs it with the same prefixes (the
target directory under `RUNNER_TEMP` is the one `/d1trimfile` removes) in
both path styles, as bytes and as UTF-16 (MSVC's `assert` stores `__FILE__`
as a wide string), and fails first if `cl` reported `/d1trimfile` as
ignored (warning D9002, read from the rquickjs-sys build script's output).
`cc_codemode_verify`, which every staging and packaging step runs, repeats
the check on whatever runner it is given, with the prefixes it can know on
its own machine and generic markers: `/Users/`, `/home/` outside
`/build/home/`, `C:\Users\`, and a cargo registry path (`registry/src/`)
outside `/build/cargo/`. Cargo names workspace sources by relative path, so
the registry paths are what an unremapped build always carries. Verify also
requires the self-test's `build` field to be `release`.

Measured on macOS arm64: before, the home directory occurred twice; after, no
occurrence of the home directory, the checkout or the scratch directory, and
the registry paths read `/build/cargo/registry/src/…`. A debug build is
refused by verify (`build` is `debug`); a release build without remapping
(cargo home outside the home directory) is refused for its 14 registry
paths, also when verify runs from a copy of the scripts outside the checkout
with no home or cargo home it could match.

## Third-party notices

A distributed binary includes QuickJS-NG and rquickjs, both MIT, so the
licence-notice generation must include their texts. The MIT/Apache-2.0
dependencies need their usual notices.
