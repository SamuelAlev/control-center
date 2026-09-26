# cc-server-demo image

The release workflow pushes `ghcr.io/<owner>/cc-server-demo:<version>` and `:latest` with signed Sigstore provenance (`gh attestation verify`). This image uses the **same** `../cc_server/Dockerfile` as `cc-server`; `CC_SERVER_BINARY` selects the binary. Do not fork the unprivileged user, native layout, healthcheck or PaaS port shim. CI stages the gitignored `bundle/` from `cc_demo_server-*-linux-x64.tar.gz`.

## Railway

1. Deploy Docker image `ghcr.io/<owner>/cc-server-demo:latest`. A private GHCR package needs a Railway registry credential.
2. Generate a domain. Railway sets `PORT` and `RAILWAY_PUBLIC_DOMAIN`; the image translates these to `--port $PORT` and `CC_SERVER_PUBLIC_URL=wss://$RAILWAY_PUBLIC_DOMAIN/rpc`. **The public URL is required** in redeem/connection descriptors: without it clients receive a loopback address and cannot reconnect.
3. Set `CC_SERVER_ALLOWED_ORIGINS=https://demo.usectrl.dev` or the actual web client origin. It gates WebSocket upgrades. Set `CC_SERVER_CODE_INDEX=off` and `CC_SERVER_SANDBOX=off`: this demo indexes no repo and executes nothing. Optional limits (defaults): `CC_SERVER_DEMO_TTL_MINUTES=45`, `CC_SERVER_DEMO_MAX_VISITORS=60`, `CC_SERVER_DEMO_POOL_SIZE=4`, `CC_SERVER_DEMO_DISK_BUDGET_MB=8192`, `CC_SERVER_DEMO_MAX_PER_IP=3`, `CC_SERVER_DEMO_INVITE_CODE=demo`. On a small instance, reduce pool size to 1–2 and disk budget below the plan limit; workspaces seed eagerly.
4. Railway terminates TLS. The image's `CC_SERVER_INSECURE=1` is for that edge-termination topology; do not add a server certificate. Do not attach a volume if redeploy should wipe visitor data. TTL reaps visitors, while `/data` in the container layer resets on redeploy.

The web client's auto-redeem entry is `https://demo.usectrl.dev/#<base64url({"server":"wss://<your-domain>/rpc","invite":"demo"})>`. Generate it without hand-encoding JSON:

```sh
python3 -c 'import base64,json,sys
u={"server":"wss://"+sys.argv[1]+"/rpc","invite":"demo"}
print("https://demo.usectrl.dev/#"+base64.urlsafe_b64encode(json.dumps(u).encode()).decode().rstrip("="))' \
  cc-demo-production.up.railway.app
```

## Docker and local build

The shim also recognizes Render's `RENDER_EXTERNAL_HOSTNAME` and Fly's `FLY_APP_NAME`. Plain Docker requires an explicit externally reachable URL:

```sh
docker run --rm -p 9030:9030 \
  --read-only --tmpfs /tmp --tmpfs /data \
  --cap-drop=ALL --security-opt=no-new-privileges \
  --pids-limit=256 --memory=4g --cpus=2 \
  -e CC_SERVER_PUBLIC_URL=wss://demo.example.com/rpc \
  -e CC_SERVER_ALLOWED_ORIGINS=https://app.example.com \
  ghcr.io/<owner>/cc-server-demo:latest
```

The image expects a prebuilt bundle, not native compilation during `docker build`. On **Linux** (a macOS package contains incompatible dylibs):

```sh
scripts/natives/build_natives.sh
scripts/release/cc_demo_server_package.sh 0.0.0-local
mkdir -p docker/cc_demo_server/bundle
tar xzf cc_demo_server-0.0.0-local-linux-x64.tar.gz \
  -C docker/cc_demo_server/bundle --strip-components=1
docker build -t cc-server-demo:local \
  --build-arg CC_SERVER_BINARY=cc_demo_server \
  -f docker/cc_server/Dockerfile docker/cc_demo_server
```
