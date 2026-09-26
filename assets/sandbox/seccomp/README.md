# Vendored `apply-seccomp` binaries

`apply-seccomp-x64` / `apply-seccomp-arm64` come from `@anthropic-ai/sandbox-runtime` (release binaries on npm or `vendor/seccomp-src/apply-seccomp.c` in that project's source). When the current Linux architecture has an executable binary here, the sandbox wraps commands to block `socket(AF_UNIX, …)` at the syscall level, matching that runtime's default. Without it, the sandbox still runs with kernel/filesystem isolation but **allows all Unix sockets**; Settings → Sandboxing shows a warning. Do not describe that fallback as equivalent security.

Build statically for the matching Linux architecture (from the upstream C source, with libseccomp):

```sh
gcc -static -O2 apply-seccomp.c -o apply-seccomp-x64 \
  -I/usr/include -lseccomp
aarch64-linux-gnu-gcc -static -O2 apply-seccomp.c -o apply-seccomp-arm64 \
  -I/path/to/aarch64-libseccomp/include -L/path/to/aarch64-libseccomp/lib -lseccomp
chmod +x apply-seccomp-*
```

`pubspec.yaml` declares `assets/sandbox/seccomp/`; dropped binaries are bundled with Flutter. See [SECURITY.md](../../../SECURITY.md) for sandbox trust boundaries.
