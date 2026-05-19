# syntax=docker/dockerfile:1.7

# =============================================================================
# Dockerfile for self-hosting the Control Center WEB CLIENT.
#
#   # the release `containers` job builds `flutter build web --release` and
#   # stages the output to docker/web/site/ next to this Dockerfile, then:
#   docker build -t control-center-web docker/web/
#   docker run --rm -p 8080:8080 control-center-web
#
# Runtime-only: the Flutter web build runs in CI (with the cached fvm SDK), the
# same way deploy-webapp.yml builds for Cloudflare. This image just serves the
# pre-built static SPA. The web client is a THIN CLIENT — no backend here; it
# dials a cc-server (the cc-server image) over a WebSocket the user enters at
# connect time. See docker/web/nginx.conf for the SPA fallback + static CSP.
#
# nginx-unprivileged runs as a non-root user (uid 101) and listens on 8080.
# =============================================================================

FROM nginxinc/nginx-unprivileged:alpine

LABEL org.opencontainers.image.title="Control Center web client" \
      org.opencontainers.image.description="Static thin-client web UI for Control Center; dials a self-hosted cc-server over WebSocket" \
      org.opencontainers.image.source="https://github.com/SamuelAlev/control-center" \
      org.opencontainers.image.licenses="MIT"

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY site       /usr/share/nginx/html

EXPOSE 8080

# BusyBox wget (alpine) — `sh` here is ash, which has no /dev/tcp.
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["sh", "-c", "wget -q -O /dev/null http://127.0.0.1:8080/ || exit 1"]
