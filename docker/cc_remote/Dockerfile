# syntax=docker/dockerfile:1.7

# =============================================================================
# Dockerfile for self-hosting the Control Center phone PWA (cc_remote).
#
#   # the release `containers` job builds `flutter build web --release` in
#   # apps/cc_remote and stages the output to docker/cc_remote/site/, then:
#   docker build -t control-center-remote docker/cc_remote/
#   docker run --rm -p 8081:8080 control-center-remote
#
# Runtime-only: the Flutter web build runs in CI (with the cached fvm SDK), the
# same way deploy-remote.yml builds for Cloudflare. This image just serves the
# pre-built static PWA. cc_remote pairs with a desktop/server over a WebRTC
# signaling broker (wss); see docker/cc_remote/nginx.conf for the SPA fallback +
# the (already static) CSP it ships.
#
# nginx-unprivileged runs as a non-root user (uid 101) and listens on 8080.
# =============================================================================

FROM nginxinc/nginx-unprivileged:alpine

LABEL org.opencontainers.image.title="Control Center remote" \
      org.opencontainers.image.description="Static PWA that pairs with and remote-controls a Control Center desktop/server over WebRTC" \
      org.opencontainers.image.source="https://github.com/SamuelAlev/control-center" \
      org.opencontainers.image.licenses="MIT"

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY site       /usr/share/nginx/html

EXPOSE 8080

# BusyBox wget (alpine) — `sh` here is ash, which has no /dev/tcp.
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["sh", "-c", "wget -q -O /dev/null http://127.0.0.1:8080/ || exit 1"]
