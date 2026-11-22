# syntax=docker/dockerfile:1.29

# =============================================================================
# Dockerfile for Control Center Connect.
#
#   docker buildx build \
#     --build-context core=packages/cc_connect_core \
#     -t cc-connect apps/cc_connect
#   docker run --rm -p 8790:8790 \
#     -e CONNECT_PUBLIC_URL=https://connect.example.com \
#     -e CONNECT_ALLOWED_INSTALLS=<install id> \
#     -e CONNECT_SEAL_KEYS_FILE=/run/secrets/seal_keys \
#     -v cc-connect-data:/data cc-connect
#
# Connect is pure Dart with one in-repo dependency, `cc_connect_core` (the wire
# contract it shares with cc_server), passed in as the named build context
# `core`. We build STANDALONE: no Flutter SDK and no monorepo context. The
# builder lays the two packages out at their real relative paths, synthesizes
# minimal manifests (the real ones carry `resolution: workspace`, which would
# resolve against the Flutter monorepo root), fetches the pure-Dart packages
# from pub.dev against a committed lockfile and AOT-compiles the service and
# its config tool.
# =============================================================================

# ---- Build stage: compile native AOT executables ----------------------------
# Pinned by digest. Keep the tag in sync with the `environment:` of
# apps/cc_connect/pubspec.yaml.
FROM dart:3.14-sdk@sha256:36176bf7b6400bdc4aa77ba07b733b2eabf22640f71afd1b83eba679a26d5698 AS builder

WORKDIR /build
COPY --from=core lib ./packages/cc_connect_core/lib
COPY lib ./apps/cc_connect/lib
COPY bin ./apps/cc_connect/bin
COPY docker/pubspec.lock ./apps/cc_connect/pubspec.lock

# KEEP IN SYNC with the `dependencies:` of packages/cc_connect_core/pubspec.yaml
# and apps/cc_connect/pubspec.yaml. docker/pubspec.lock pins every package,
# transitive ones included, to the version and content hash in the monorepo's
# pubspec.lock (test/docker_test.dart checks both), and `--enforce-lockfile`
# refuses any other. The tests ran on that resolution, but in the workspace,
# not on this standalone layout.
RUN printf '%s\n' \
      'name: cc_connect_core' \
      'publish_to: none' \
      'environment:' \
      '  sdk: ">=3.12.0 <4.0.0"' \
      'dependencies:' \
      '  crypto: 3.0.7' \
      '  cryptography: 2.9.0' \
      '  meta: 1.19.0' > packages/cc_connect_core/pubspec.yaml \
 && printf '%s\n' \
      'name: cc_connect' \
      'publish_to: none' \
      'environment:' \
      '  sdk: ">=3.12.0 <4.0.0"' \
      'dependencies:' \
      '  cc_connect_core:' \
      '    path: ../../packages/cc_connect_core' \
      '  crypto: 3.0.7' \
      '  cryptography: 2.9.0' \
      '  dart_jsonwebtoken: 3.4.1' > apps/cc_connect/pubspec.yaml \
 && mkdir -p /out \
 && cd apps/cc_connect \
 && dart pub get --enforce-lockfile \
 && dart compile exe bin/server.dart -o /out/cc-connect \
 && dart compile exe bin/config_tool.dart -o /out/cc-connect-config

# ---- Runtime stage: minimal glibc base with the binaries --------------------
# `dart compile exe` embeds the Dart VM but links glibc, so the runtime matches
# the SDK image's Debian (13, trixie). Connect makes outbound TLS calls (GitHub,
# Google, Slack, Klipy, Cloud KMS, Firestore, Redis), so it needs the system
# trust store: `ca-certificates` is the only package added.
FROM debian:trixie-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2 AS runtime

LABEL org.opencontainers.image.title="Control Center Connect" \
      org.opencontainers.image.description="OAuth broker for Control Center servers: provider sign-in, install-bound credential seals, one-repository GitHub tokens, Slack event references and a Klipy proxy" \
      org.opencontainers.image.source="https://github.com/SamuelAlev/control-center" \
      org.opencontainers.image.licenses="MIT"

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Run as a fixed unprivileged, login-disabled user — never root.
RUN groupadd --gid 10001 connect \
 && useradd  --uid 10001 --gid connect \
             --home-dir /nonexistent --no-create-home \
             --shell /usr/sbin/nologin connect \
 && install -d -o 10001 -g 10001 -m 0700 /data

# Bind address/port and the binding store's directory (self-hosted
# CONNECT_BINDINGS=file). Every other setting is a CONNECT_* variable; secrets
# should come from <NAME>_FILE mounts.
ENV CONNECT_HOST=0.0.0.0 \
    CONNECT_PORT=8790 \
    CONNECT_DATA_DIR=/data \
    LANG=C.UTF-8

COPY --from=builder --chown=root:root --chmod=0555 /out/cc-connect /usr/local/bin/cc-connect
COPY --from=builder --chown=root:root --chmod=0555 /out/cc-connect-config /usr/local/bin/cc-connect-config

VOLUME ["/data"]
EXPOSE 8790

USER connect:connect

# Probes GET /healthz on 127.0.0.1:$CONNECT_PORT with the binary itself.
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["/usr/local/bin/cc-connect", "--healthcheck"]

# Exec form: the binary is PID 1 and receives SIGINT / SIGTERM directly for a
# graceful shutdown (handled in bin/server.dart). Configuration is env-only.
CMD ["/usr/local/bin/cc-connect"]
