# cc_inference — provenance

First-party Rust source (`src/`, `build.rs`, `cc_inference.h`) plus two
third-party components that are **statically linked** into the shipped dylib.

## What is linked in

| Component                  | Version | License    | Where it comes from                                               |
| -------------------------- | ------- | ---------- | ----------------------------------------------------------------- |
| sherpa-onnx (C API + core) | 1.13.5  | Apache-2.0 | k2-fsa/sherpa-onnx prebuilt `*-static-lib` release archive        |
| ONNX Runtime               | 1.27.1  | MIT        | bundled inside that same sherpa-onnx archive (`libonnxruntime.a`) |

Both arrive in ONE archive, so there is exactly one ONNX Runtime in the process.
That matters on Windows in particular, where the loader satisfies a DLL
dependency from already-loaded modules BY BASE NAME — two `onnxruntime.dll`s
cannot coexist.

License texts are in `LICENSE-THIRD-PARTY/`.

## How the archive is pinned

`scripts/natives/build_inference.sh` downloads the archive and verifies it
against a sha256 in `scripts/lib/native_pins.env`, then points cargo at the
extracted `lib/` via `SHERPA_ONNX_LIB_DIR`. Left to itself, the `sherpa-onnx-sys`
build script downloads its own copy, unverified, at build time — unacceptable for
something linked into a signed release artifact.

Bumping the version means updating, together:

1. `SHERPA_ONNX_VERSION` + every `SHERPA_ONNX_LIB_SHA256_*` in `native_pins.env`
   (checksums differ per platform; get them with
   `shasum -a 256 <archive>` for each of macOS arm64/x64, Linux x64/arm64, Windows x64);
2. `sherpa-onnx-sys` in `Cargo.toml` (pinned `=` and `Cargo.lock` regenerated);
3. `src/ort_sys.rs`, **if** the bundled ONNX Runtime version moved — see below.

## Regenerating `src/ort_sys.rs`

The ONNX Runtime C API bindings are generated ONCE and committed; no build
machine needs bindgen. Header version must match the ONNX Runtime inside the
sherpa archive (check with `strings libonnxruntime.a | grep -E '^1\.[0-9]+\.[0-9]+$'`).

```sh
V=1.27.1   # the ONNX Runtime version bundled by the pinned sherpa archive
base="https://raw.githubusercontent.com/microsoft/onnxruntime/v$V/include/onnxruntime/core/session"
curl -sLO "$base/onnxruntime_c_api.h"
curl -sLO "$base/onnxruntime_ep_c_api.h"     # included by the above
curl -sLO "$base/onnxruntime_float16.h"      # ditto
cargo install bindgen-cli --locked           # build-time-only, never a dependency
bindgen onnxruntime_c_api.h -o src/ort_sys.rs --no-layout-tests \
  --allowlist-type "Ort.*" --allowlist-function "OrtGetApiBase" \
  --allowlist-var "ORT_API_VERSION" --default-enum-style rust
```

Then re-add the header comment at the top of the generated file (it records this
recipe and the Windows `ORTCHAR_T` caveat) and run `cargo test` — the
`ort_api_table_resolves` test fails if the header and the linked runtime disagree
about the API version.

`OrtApi` is append-only across ONNX Runtime versions, so old offsets stay valid
after a bump; regenerate anyway so newly added entry points are reachable.

### Windows caveat baked into the generated file

`CreateSession` takes `const ORTCHAR_T*`, which is `char*` on Unix but `wchar_t*`
on Windows. Bindings generated on macOS type it `*const c_char`, so `embed.rs`
encodes the path as UTF-16 on Windows and casts the pointer (ABI-identical). If
you ever regenerate on Windows, that cast still holds — do not "fix" it by
passing a `CString` through.

## Why the C API and not the safe wrapper

The crate binds `sherpa-onnx-sys` (raw C declarations) rather than the safe
`sherpa-onnx` wrapper, so no wrapper defaults sit between this code and the
engine — every config field it sets is visible in `asr.rs`. That is also why
`asr.rs` sets every unused `char*` explicitly: sherpa dereferences them into
`std::string`, so a NULL is a crash, not a default.
