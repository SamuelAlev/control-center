# Vendored `apply-seccomp` binaries

Drop a pre-built `apply-seccomp-x64` and/or `apply-seccomp-arm64` binary in
this directory to enable the seccomp-based defense-in-depth layer in the
Linux sandbox. When the matching arch binary is present and executable, the
sandbox runtime wraps user commands with it so `socket(AF_UNIX, …)` is
blocked at the syscall level (mirrors the `@anthropic-ai/sandbox-runtime`
default).

If the binary is missing for the current arch, the sandbox still runs — it
just falls back to the "allow all Unix sockets" mode (kernel + filesystem
isolation are unaffected). A warning is surfaced in Settings → Sandboxing.

## Building

Cross-compile from the C source in `vendor/seccomp-src/apply-seccomp.c` in
the `@anthropic-ai/sandbox-runtime` repo:

```bash
gcc -static -O2 apply-seccomp.c -o apply-seccomp-x64 \
    -I/usr/include -lseccomp

# arm64 cross:
aarch64-linux-gnu-gcc -static -O2 apply-seccomp.c -o apply-seccomp-arm64 \
    -I/path/to/aarch64-libseccomp/include -L/path/to/aarch64-libseccomp/lib -lseccomp
```

Or grab the already-built binaries from
`@anthropic-ai/sandbox-runtime`'s release artifacts on npm.

After dropping the binary in:

```bash
chmod +x apply-seccomp-*
```

## Asset wiring

`pubspec.yaml` declares `assets/sandbox/seccomp/` so anything dropped in
this directory ships with the Flutter bundle.
