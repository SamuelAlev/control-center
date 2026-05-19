# syntax=docker/dockerfile:1.7

# =============================================================================
# Dockerfile for the Control Center signaling server.
#
#   docker build -t cc-signaling-server apps/cc_signaling_server/
#   docker run --rm -p 8788:8788 cc-signaling-server
#
# The signaling server is a pure-Dart, zero-dependency WebSocket relay. Although
# it is a workspace member of a larger Flutter monorepo, it has no Dart/Flutter
# dependencies of its own, so we build it STANDALONE here: no Flutter SDK, no
# monorepo build context, and no network during the build. The output is a
# self-contained AOT executable shipped in a minimal glibc image.
# =============================================================================

# ---- Build stage: compile a native AOT executable ---------------------------
# Pin the Dart SDK to satisfy `sdk: ">=3.11.0 <4.0.0"`.
# Keep this in sync with apps/cc_signaling_server/pubspec.yaml's `environment`.
ARG DART_SDK_VERSION=3.11
FROM dart:${DART_SDK_VERSION}-sdk AS builder

WORKDIR /build

# Copy only what the compiler needs. The real pubspec carries
# `resolution: workspace`, which would force resolution against the Flutter
# monorepo root (and pull in the Flutter SDK). Instead we emit a minimal
# standalone manifest, so `dart pub get` resolves offline and `dart compile exe`
# produces a hermetic binary.
COPY lib ./lib
COPY bin ./bin

RUN printf '%s\n' \
      'name: cc_signaling_server' \
      'publish_to: none' \
      'environment:' \
      '  sdk: ">=3.11.0 <4.0.0"' > pubspec.yaml \
 && dart pub get \
 && dart compile exe bin/server.dart -o /signaling-server

# ---- Runtime stage: minimal glibc base with the single binary ---------------
# `dart compile exe` embeds the Dart VM, but the binary still links glibc, so we
# keep a debian-slim base that matches the SDK image's glibc major (bookworm).
FROM debian:bookworm-slim AS runtime

LABEL org.opencontainers.image.title="Control Center signaling server" \
      org.opencontainers.image.description="Pure-Dart stateless WebSocket signaling broker for WebRTC pairing" \
      org.opencontainers.image.source="https://github.com/SamuelAlev/control-center" \
      org.opencontainers.image.licenses="MIT"

# Run as a fixed unprivileged, login-disabled user — never root.
RUN groupadd --gid 10001 signaling \
 && useradd  --uid 10001 --gid signaling \
             --home-dir /nonexistent --no-create-home \
             --shell /usr/sbin/nologin signaling

# Single source of truth for bind address/port — consumed by both CMD and
# HEALTHCHECK, and overridable with `docker run -e SIGNALING_PORT=…`.
ENV SIGNALING_HOST=0.0.0.0 \
    SIGNALING_PORT=8788 \
    LANG=C.UTF-8

COPY --from=builder --chown=root:root --chmod=0555 /signaling-server /usr/local/bin/signaling-server

EXPOSE 8788

USER signaling:signaling

# The broker only performs WebSocket upgrades, so a successful TCP handshake on
# the listen port is sufficient proof of liveness (no extra tooling installed).
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["bash", "-c", "</dev/tcp/127.0.0.1/${SIGNALING_PORT:-8788}"]

# `exec` replaces the shell so the Dart binary becomes PID 1 and receives
# SIGINT / SIGTERM directly for graceful shutdown (handled in bin/server.dart).
CMD ["sh", "-c", "exec /usr/local/bin/signaling-server --host ${SIGNALING_HOST:-0.0.0.0} --port ${SIGNALING_PORT:-8788}"]
