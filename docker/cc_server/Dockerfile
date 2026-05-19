# syntax=docker/dockerfile:1.7

# =============================================================================
# Dockerfile for the self-hostable Control Center backend (cc_server).
#
#   # in the release `containers` job, the CI-built Linux standalone archive is
#   # extracted to ./bundle next to this Dockerfile, then:
#   docker build -t cc-server docker/cc_server/
#   docker run --rm -p 9030:9030 -v cc_data:/data cc-server
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

FROM debian:bookworm-slim

LABEL org.opencontainers.image.title="Control Center server" \
      org.opencontainers.image.description="Self-hostable pure-Dart backend (RPC, meetings, tickets, messaging) the Control Center web/desktop/remote clients dial" \
      org.opencontainers.image.source="https://github.com/SamuelAlev/control-center" \
      org.opencontainers.image.licenses="MIT"

# Runtime libs the bundle links beyond glibc: ca-certificates (the server makes
# outbound HTTPS to GitHub/Linear/Google + model downloads); libstdc++6/libgcc
# + libgomp1 for onnxruntime/sherpa. `dart build cli` embeds the Dart VM itself.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates libstdc++6 libgcc-s1 libgomp1 \
 && rm -rf /var/lib/apt/lists/*

# Fixed unprivileged, login-disabled user — never root.
RUN groupadd --gid 10001 ccserver \
 && useradd  --uid 10001 --gid ccserver \
             --home-dir /data --no-create-home \
             --shell /usr/sbin/nologin ccserver

# The standalone Linux bundle (CI-extracted to ./bundle): binary at bin/cc_server,
# sqlite3 in lib/, and ALL FFI natives (rift/fff/tree-sitter/pty/aec + sherpa-onnx
# + onnxruntime) in bin/lib/ — exactly where native_library.dart +
# resolveSherpaLibraryDir probe (`<exeDir>/lib`).
COPY bundle /app

ENV CC_SERVER_DATA_DIR=/data \
    CC_SERVER_PORT=9030 \
    CC_SERVER_BIND=any \
    CC_SERVER_INSECURE=1 \
    CC_NATIVE_LIB_DIR=/app/bin/lib \
    LD_LIBRARY_PATH=/app/lib:/app/bin/lib \
    LANG=C.UTF-8

# Persist the SQLite DB, downloaded models, paired-device secrets, and meeting
# audio across container restarts.
RUN mkdir -p /data && chown ccserver:ccserver /data
VOLUME ["/data"]

EXPOSE 9030

USER ccserver:ccserver

# A successful TCP handshake on the RPC port is sufficient proof of liveness
# (the same approach as the signaling server; no extra tooling installed).
HEALTHCHECK --interval=30s --timeout=3s --start-period=20s --retries=3 \
  CMD ["bash", "-c", "</dev/tcp/127.0.0.1/${CC_SERVER_PORT:-9030}"]

# The binary becomes PID 1 and receives SIGINT/SIGTERM directly for the clean
# shutdown cc_server.dart implements. All config comes from the CC_SERVER_* env
# above, overridable with `docker run -e …`.
CMD ["/app/bin/cc_server"]
