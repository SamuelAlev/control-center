# syntax=docker/dockerfile:1.7

# =============================================================================
# Dockerfile for the self-hostable Control Center backend (cc_server).
#
#   # in the release `containers` job, the CI-built Linux standalone archive is
#   # extracted to ./bundle next to this Dockerfile, then:
#   docker build -t cc-server docker/cc_server/
#   docker run --rm -p 9030:9030 -v cc_data:/data cc-server
#
# The PUBLIC DEMO ships from this same file with a different bundle and one
# build arg, because the demo binary has the same native requirements and the
# same runtime shape — two Dockerfiles would be two things to keep in sync:
#
#   docker build -t cc-demo --build-arg CC_SERVER_BINARY=cc_demo_server \
#     docker/cc_server/
#
# The demo is a SEPARATE BINARY, never a flag on this one. Its fixtures compile
# in (so a flag would ship them to every desktop install), and a public endpoint
# whose lockdown depends on an environment variable becomes a fully armed
# server the first time a deployment drops that variable. See
# apps/cc_demo_server/bin/cc_demo_server.dart.
#
# Unlike the signaling server, cc_server has heavy native dependencies (sherpa
# speech recognizer, onnxruntime, tree-sitter, rift, …) that are too costly to
# build inside the image. So we DON'T compile here — we ship the exact, already
# signed-elsewhere `dart build cli` bundle the release pipeline produced
# (apps/cc_server, built on a real Linux runner with the native toolchains) plus
# every FFI dylib staged where the resolver looks. This image is runtime-only.
#
# Security: cc_server normally refuses a non-loopback bind without TLS. A
# container must bind 0.0.0.0 to receive published-port traffic, so we run it
# with CC_SERVER_INSECURE=1 — which is ONLY safe behind a TLS-terminating
# reverse proxy (Caddy / Traefik / nginx / Cloudflare Tunnel) on a trusted
# network. To terminate TLS in-process instead, mount a cert + key and set
# CC_SERVER_TLS_CERT / CC_SERVER_TLS_KEY (then unset CC_SERVER_INSECURE).
# =============================================================================

# THE BASE IMAGE IS AN ABI CONTRACT, not a taste in distros. The natives are
# compiled on the release runner (ubuntu-24.04: glibc 2.39, libstdc++ 14) and
# merely COPIED in here, so this image must provide at least what they link
# against. Debian 12 did not — it ships glibc 2.36 and libstdc++ 12, while rift
# needs GLIBC_2.39 (`pidfd_spawnp`, from Rust std's spawn path), fff/lame/aec
# need GLIBC_2.38 (`__isoc23_strtol`: glibc >=2.38 headers redirect `strtol`
# under `_GNU_SOURCE`) and aec needs GLIBCXX_3.4.32. Those three failed
# `dlopen`, and because the boot preflight probes BY LOADING it reported them
# MISSING with every file present in /app — an error that reads as a packaging
# bug and is not one.
#
# Debian 13 (glibc 2.41, libstdc++ 14) clears all of it with headroom, at the
# same size as the slim Debian 12 it replaces. Keep it in step with
# CC_NATIVES_BASE_IMAGE in scripts/lib/natives.sh: verify_natives.sh fails the
# packaging step when a library needs more than that floor, and
# test/tooling/native_matrix_test.dart pins this FROM line to it.
FROM debian:trixie-slim

LABEL org.opencontainers.image.title="Control Center server" \
      org.opencontainers.image.description="Self-hostable pure-Dart backend (RPC, meetings, tickets, messaging) the Control Center web/desktop/remote clients dial" \
      org.opencontainers.image.source="https://github.com/SamuelAlev/control-center" \
      org.opencontainers.image.licenses="MIT"

# Runtime libs the bundle links beyond glibc: ca-certificates (the server makes
# outbound HTTPS to GitHub/Linear/Google + model downloads); libstdc++6/libgcc
# + libgomp1 for onnxruntime/sherpa. `dart build cli` embeds the Dart VM itself.
#
# bubblewrap + socat are the Linux agent sandbox (NativeSandboxAdapter probes
# for `bwrap` and `socat`; LinuxSandbox uses the first for namespace isolation
# and the second for the proxy bridges). ~1 MB together, and without them a
# self-hosted server runs agents bounded by env sanitization and the action
# guardrails alone — it says so at boot. bwrap still needs the host to permit
# unprivileged user namespaces; where it does not, the probe reports the
# backend unavailable, which is the honest answer rather than a silent one.
#
# Do NOT reach for CC_SERVER_SANDBOX=off to quiet the boot warning: `off` logs
# its own warning (`agent sandbox DISABLED by --sandbox off`) because a server
# running agents unsandboxed is exactly the thing an operator must not learn
# about from silence. With these two packages present the probe succeeds and
# the line becomes an INFO one, which the default `warning` log level hides.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates libstdc++6 libgcc-s1 libgomp1 \
      bubblewrap socat \
 && rm -rf /var/lib/apt/lists/*

# Fixed unprivileged, login-disabled user — never root.
RUN groupadd --gid 10001 ccserver \
 && useradd  --uid 10001 --gid ccserver \
             --home-dir /data --no-create-home \
             --shell /usr/sbin/nologin ccserver

# The standalone Linux bundle (CI-extracted to ./bundle): binary at bin/cc_server,
# the code assets `dart build cli` resolves BY ASSET ID (sqlite3, the vector
# extension, the AOT snapshot) in lib/, and ALL FFI natives — rift, fff,
# tree-sitter + grammars, pty, watcher, saml, inference (which statically links
# sherpa-onnx and its ONNX Runtime) — in bin/lib/, exactly where
# native_library.dart's `bundledLibraryCandidates` probes (`<exeDir>/lib`) and
# where CC_NATIVE_LIB_DIR points below.
#
# ONE copy of each: the packaging scripts drop the build hook's duplicate out of
# lib/ once it is byte-identical to the staged one, because both directories are
# searched and carrying each native twice cost 49 MB of image for nothing.
COPY bundle /app

# Which binary in the bundle to run: `cc_server` (default) or `cc_demo_server`.
# The CI job extracts the matching standalone archive into ./bundle.
ARG CC_SERVER_BINARY=cc_server

ENV CC_SERVER_BINARY=${CC_SERVER_BINARY} \
    CC_SERVER_DATA_DIR=/data \
    CC_SERVER_PORT=9030 \
    CC_SERVER_BIND=any \
    CC_SERVER_INSECURE=1 \
    CC_NATIVE_LIB_DIR=/app/bin/lib \
    LD_LIBRARY_PATH=/app/lib:/app/bin/lib \
    LANG=C.UTF-8

# Persist the SQLite DB, downloaded models, paired-device secrets and meeting
# audio across container restarts.
RUN mkdir -p /data && chown ccserver:ccserver /data
VOLUME ["/data"]

EXPOSE 9030

USER ccserver:ccserver

# A successful TCP handshake on the RPC port is sufficient proof of liveness
# (the same approach as the signaling server; no extra tooling installed).
HEALTHCHECK --interval=30s --timeout=3s --start-period=20s --retries=3 \
  CMD ["bash", "-c", "</dev/tcp/127.0.0.1/${PORT:-${CC_SERVER_PORT:-9030}}"]

# Entry shim, because a PaaS does not let you choose your port.
#
# Railway / Render / Fly / Cloud Run all INJECT `PORT` and route to it; this
# server reads `CC_SERVER_PORT`. The shim maps one to the other (a `--port`
# flag beats the env var in CcServerConfig.resolve, so passing it is
# unambiguous) and derives `CC_SERVER_PUBLIC_URL` from the platform's own
# domain variable when the operator has not set one.
#
# That last part matters more than it looks: the public URL is what goes into
# the redeem envelope and the connection descriptor. Without it a hosted
# server hands every client a LOOPBACK path, and a demo visitor's browser has
# nothing it can reconnect to.
#
# `exec` so the binary REPLACES the shell and is PID 1 — it receives
# SIGINT/SIGTERM directly, which is what the clean shutdown depends on (the
# demo'"'"'s teardown reaps every live visitor there). All config comes from the
# CC_SERVER_* env above, overridable with `docker run -e …`.
#
# Demo deployments additionally set, all optional (defaults in parentheses):
#   CC_SERVER_DEMO_TTL_MINUTES    (45)    workspace lifetime per visitor
#   CC_SERVER_DEMO_MAX_VISITORS   (60)    live visitors before redemption 503s
#   CC_SERVER_DEMO_POOL_SIZE      (4)     workspaces seeded and kept warm
#   CC_SERVER_DEMO_DISK_BUDGET_MB (8192)  data-directory ceiling
#   CC_SERVER_DEMO_MAX_PER_IP     (3)     concurrent sessions from one address
#   CC_SERVER_DEMO_INVITE_CODE    (demo)  the code the public entry URL carries
# plus CC_SERVER_ALLOWED_ORIGINS / CC_SERVER_PUBLIC_URL for the web client and
# CC_SERVER_CODE_INDEX=off (a demo has no repos to index). CC_SERVER_SANDBOX is
# deliberately NOT in that list: the demo's agent loop is scripted and executes
# nothing, so the sandbox is moot either way, and `off` trades a warning for a
# warning.
#
# Run a demo container locked down at the runtime too:
#   docker run --read-only --tmpfs /tmp --cap-drop=ALL \
#     --security-opt=no-new-privileges --pids-limit=256 \
#     --memory=4g --cpus=2 -p 9030:9030 --tmpfs /data cc-demo
# `--pids-limit` is meaningful defence in depth even though nothing spawns, and
# a tmpfs /data makes a container restart the cleanest reaper there is.
CMD ["/bin/sh", "-c", "\
if [ -n \"$PORT\" ]; then set -- --port \"$PORT\"; fi; \
if [ -z \"$CC_SERVER_PUBLIC_URL\" ] && [ -n \"$RAILWAY_PUBLIC_DOMAIN\" ]; then \
  export CC_SERVER_PUBLIC_URL=\"wss://$RAILWAY_PUBLIC_DOMAIN/rpc\"; fi; \
if [ -z \"$CC_SERVER_PUBLIC_URL\" ] && [ -n \"$RENDER_EXTERNAL_HOSTNAME\" ]; then \
  export CC_SERVER_PUBLIC_URL=\"wss://$RENDER_EXTERNAL_HOSTNAME/rpc\"; fi; \
if [ -z \"$CC_SERVER_PUBLIC_URL\" ] && [ -n \"$FLY_APP_NAME\" ]; then \
  export CC_SERVER_PUBLIC_URL=\"wss://$FLY_APP_NAME.fly.dev/rpc\"; fi; \
exec /app/bin/$CC_SERVER_BINARY \"$@\""]
