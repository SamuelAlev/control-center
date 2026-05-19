# cc-server-demo image

The public demo server as a container. Built and pushed by the release workflow
to `ghcr.io/<owner>/cc-server-demo:<version>` and `:latest`, with a signed
Sigstore provenance attestation (verify with `gh attestation verify`).

It uses the **same Dockerfile as `cc-server`** (`../cc_server/Dockerfile`),
selected by the `CC_SERVER_BINARY` build arg. Only the binary and the bundle
differ — the natives layout, the unprivileged user, the healthcheck and the
PaaS port shim must not drift between the two images, so there is one file.

`bundle/` is CI-staged from the `cc_demo_server-*-linux-x64.tar.gz` archive and
is gitignored; this directory holds only this README in the repo.

## Deploying on Railway

Railway can deploy a public GHCR image directly — no repo build, no build
timeout, and the natives are already compiled by the release job.

1. **New Project → Deploy from Docker Image**
   ```
   ghcr.io/<owner>/cc-server-demo:latest
   ```
   (A private package needs a Railway registry credential; making the GHCR
   package public is simpler for a demo.)

2. **Networking → Generate Domain.** Railway then sets `PORT` and
   `RAILWAY_PUBLIC_DOMAIN` for you, and the image's entry shim turns those into
   `--port $PORT` and `CC_SERVER_PUBLIC_URL=wss://$RAILWAY_PUBLIC_DOMAIN/rpc`.

   That second one is not cosmetic: the public URL is what goes into the redeem
   envelope and the connection descriptor. Without it a hosted server hands
   every client a **loopback** path and the visitor's browser has nothing to
   reconnect to.

3. **Variables** — the one you must set, plus the ones worth setting:

   ```
   CC_SERVER_ALLOWED_ORIGINS = https://demo.usectrl.dev
   CC_SERVER_CODE_INDEX      = off
   CC_SERVER_SANDBOX         = off
   ```

   `CC_SERVER_ALLOWED_ORIGINS` gates the WebSocket upgrade — without your web
   client's origin the browser connects and is refused. The other two are
   honest no-ops made explicit: a demo registers no repo to index and executes
   nothing to sandbox.

   Optional demo tuning (defaults in parentheses):

   ```
   CC_SERVER_DEMO_TTL_MINUTES    (45)
   CC_SERVER_DEMO_MAX_VISITORS   (60)
   CC_SERVER_DEMO_POOL_SIZE      (4)
   CC_SERVER_DEMO_DISK_BUDGET_MB (8192)
   CC_SERVER_DEMO_MAX_PER_IP     (3)
   CC_SERVER_DEMO_INVITE_CODE    (demo)
   ```

   On a small Railway instance, drop `POOL_SIZE` to `1–2` and
   `DISK_BUDGET_MB` to something under your plan's disk — the pool seeds
   workspaces eagerly, and the budget is what stops it.

4. **TLS is already handled.** Railway terminates TLS at its edge and forwards
   plaintext, which is exactly the topology `CC_SERVER_INSECURE=1` (baked into
   the image) is documented for. Do not add a certificate.

5. **Skip the volume.** A demo's whole storage story is that visitors are
   reaped on a TTL and a fresh container is the cleanest reaper of all. Without
   an attached volume `/data` lives in the container layer and every redeploy
   starts clean, which is the behaviour you want.

Then hand people the entry URL — the web client's existing auto-redeem path
does the rest:

```
https://demo.usectrl.dev/#<base64url({"server":"wss://<your-domain>/rpc","invite":"demo"})>
```

Build that fragment with:

```bash
python3 -c 'import base64,json,sys
u={"server":"wss://"+sys.argv[1]+"/rpc","invite":"demo"}
print("https://demo.usectrl.dev/#"+base64.urlsafe_b64encode(json.dumps(u).encode()).decode().rstrip("="))' \
  cc-demo-production.up.railway.app
```

## Running it anywhere else

The shim also understands Render (`RENDER_EXTERNAL_HOSTNAME`) and Fly
(`FLY_APP_NAME`). Plain Docker, with the runtime locked down too:

```bash
docker run --rm -p 9030:9030 \
  --read-only --tmpfs /tmp --tmpfs /data \
  --cap-drop=ALL --security-opt=no-new-privileges \
  --pids-limit=256 --memory=4g --cpus=2 \
  -e CC_SERVER_PUBLIC_URL=wss://demo.example.com/rpc \
  -e CC_SERVER_ALLOWED_ORIGINS=https://app.example.com \
  ghcr.io/<owner>/cc-server-demo:latest
```

`--pids-limit` is meaningful defence in depth even though the demo spawns
nothing: it is the backstop for the claim, not the mechanism behind it.

## Building it locally

The image is runtime-only — it expects a prebuilt bundle, because the natives
(rift, fff, tree-sitter + grammars, ccpty, cc_watcher, lame, cc_inference,
cc_saml) are far too costly to compile per image build.

```bash
scripts/natives/build_natives.sh
scripts/release/cc_demo_server_package.sh 0.0.0-local
mkdir -p docker/cc_demo_server/bundle
tar xzf cc_demo_server-0.0.0-local-linux-x64.tar.gz \
  -C docker/cc_demo_server/bundle --strip-components=1
docker build -t cc-server-demo:local \
  --build-arg CC_SERVER_BINARY=cc_demo_server \
  -f docker/cc_server/Dockerfile docker/cc_demo_server
```

Note the archive must be built **for Linux** — packaging on macOS produces
macOS dylibs the image cannot load. In practice: let CI build it, or run the
packaging inside a Linux container.
