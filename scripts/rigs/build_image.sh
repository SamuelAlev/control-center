#!/usr/bin/env bash
#
# Builds the rig desktop base image from the stock Ubuntu cloud image.
#
# The desktop (Computer) surface is the ONLY one that boots a qcow2 we build:
# it needs an X11 session and the small capture agent the host talks to, which
# a stock cloud image has no way to provide. The terminal (exec) and browser
# surfaces are smolvm microVMs booting digest-pinned OCI images the runtime
# pulls itself (`kSmolvmExecImage` / `kSmolvmBrowserImage`), and mobile runs on
# Google's emulator — none of them has an image to build here.
#
# This runs the customisation INSIDE a throwaway VM rather than with
# libguestfs/chroot: the guest is a different architecture and distro release
# from whatever you are running, and "install packages into someone else's
# rootfs from outside" is the part that breaks on every host it meets.
#
#   scripts/rigs/build_image.sh cc-desktop-linux
#
# Then: Settings → Server → Enclosures → Import, and give it the path printed
# at the end.

set -euo pipefail

# One buildable image, named explicitly rather than assumed: the id is what the
# store catalogues, what the output file is called and what the completion
# marker carries, so a caller that means something else should be told so here
# instead of finding out from a filename ten minutes later.
IMAGE_ID="${1:-cc-desktop-linux}"
case "$IMAGE_ID" in
  cc-desktop-linux) ;;
  *)
    echo "usage: $0 [cc-desktop-linux]" >&2
    echo "The desktop image is the only one built from source; terminal and" >&2
    echo "browser rigs boot digest-pinned OCI images the runtime pulls, and" >&2
    echo "mobile uses Google's emulator (see setup_android.sh)." >&2
    exit 2
    ;;
esac

# ── Host tooling ────────────────────────────────────────────────────────────
for tool in qemu-img curl; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "missing required tool: $tool" >&2
    echo "  macOS:  brew install qemu" >&2
    echo "  Debian: sudo apt-get install qemu-utils curl" >&2
    exit 1
  fi
done

case "$(uname -m)" in
  arm64|aarch64) ARCH=arm64; QEMU_BIN=qemu-system-aarch64 ;;
  *)             ARCH=amd64; QEMU_BIN=qemu-system-x86_64 ;;
esac

if ! command -v "$QEMU_BIN" >/dev/null 2>&1; then
  echo "missing required tool: $QEMU_BIN (brew install qemu)" >&2
  exit 1
fi

# The fixed guest-visible egress addresses. Keep in lockstep with
# `QemuGuestAddresses` in packages/cc_infra/lib/src/rigs/qemu_argv.dart —
# they are protocol between host and image, not preference.
QEMU_HTTP_PROXY_ADDR="10.0.2.100:3128"
QEMU_SOCKS_PROXY_ADDR="10.0.2.101:1080"

# Keep the release in step with `kSmolvmExecImage` in
# packages/cc_infra/lib/src/rigs/smolvm_enclosure_backend.dart (currently
# `ubuntu:24.04`). The two images boot different hypervisors, but a desktop rig
# and a terminal rig running different userlands is a confusing way to debug a
# guest. This is the only place the desktop pin lives — nothing in Dart reads
# it, so it cannot drift silently against a constant; it drifts against that
# OCI tag.
UBUNTU_RELEASE="release-20260814"
BASE_URL="https://cloud-images.ubuntu.com/releases/noble/${UBUNTU_RELEASE}"
BASE_IMG="ubuntu-24.04-server-cloudimg-${ARCH}.img"

OUT_DIR="${RIG_IMAGE_OUT:-$PWD/build/rig-images}"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
mkdir -p "$OUT_DIR"

echo "==> building $IMAGE_ID for $ARCH"

# ── Base image, verified ────────────────────────────────────────────────────
BASE_PATH="$OUT_DIR/$BASE_IMG"
if [[ ! -f "$BASE_PATH" ]]; then
  echo "==> downloading $BASE_IMG"
  curl -fSL --progress-bar "$BASE_URL/$BASE_IMG" -o "$BASE_PATH.part"
  mv "$BASE_PATH.part" "$BASE_PATH"
fi

echo "==> verifying against upstream SHA256SUMS"
EXPECTED="$(curl -fsSL "$BASE_URL/SHA256SUMS" | awk -v f="*$BASE_IMG" '$2 == f {print $1}')"
if [[ -z "$EXPECTED" ]]; then
  echo "could not find $BASE_IMG in the upstream SHA256SUMS" >&2
  exit 1
fi
if command -v sha256sum >/dev/null 2>&1; then
  ACTUAL="$(sha256sum "$BASE_PATH" | awk '{print $1}')"
else
  ACTUAL="$(shasum -a 256 "$BASE_PATH" | awk '{print $1}')"
fi
if [[ "$ACTUAL" != "$EXPECTED" ]]; then
  echo "checksum mismatch for $BASE_IMG" >&2
  echo "  expected $EXPECTED" >&2
  echo "  got      $ACTUAL" >&2
  echo "Delete $BASE_PATH and re-run." >&2
  exit 1
fi

# ── The image we are about to customise ─────────────────────────────────────
OUT_IMG="$OUT_DIR/$IMAGE_ID-$ARCH.qcow2"
echo "==> preparing $OUT_IMG"
cp "$BASE_PATH" "$OUT_IMG"
# Cloud images ship small and grow on first boot; a desktop needs room.
qemu-img resize "$OUT_IMG" 12G >/dev/null

# ── What goes in ────────────────────────────────────────────────────────────
# Base: the SSH server worktree sync tars through, the git credential helper's
# dependencies, and the tiny capture agent the host's guest-agent client talks
# to on :7811.
COMMON_PACKAGES="openssh-server ca-certificates curl git jq python3 python3-pil"

# A real desktop someone debugs apps on: XFCE (panel, Thunar, terminal) plus
# Chromium. XFCE and not GNOME because gnome-shell HARD-REQUIRES working GL
# (gnome-session-check-accelerated fails the whole session into the "Oh no!"
# screen) and QEMU-without-virgl has no GL to give it — GNOME becomes possible
# with the roadmap's vendored-virgl GPU tier, not before. openbox + feh stay as
# the fallback session. dbus-user-session + linger give snap apps (chromium) a
# user manager to mint their scopes on. pulseaudio: apps play into a virtual
# sink and the agent streams its monitor — no hypervisor audio device, no host
# audio stack, bytes ride the same relay as frames.
# xclip is load-bearing, not a convenience: it is the only thing in this list
# that can OWN an X selection, which is what putting something on the guest's
# clipboard requires (X has no clipboard daemon — the selection belongs to a
# live client until another one claims it). It is also how the host reads a
# drag in flight, by asking for XdndSelection while the source holds it.
EXTRA_PACKAGES="xserver-xorg xinit x11-xserver-utils x11-utils xdotool xclip scrot ffmpeg feh openbox xfce4 xfce4-terminal chromium-browser dbus-user-session pulseaudio"
SURFACE_UNITS="cc-x11.service"
EXTRA_RUNCMD=$'  - loginctl enable-linger cc'
# Optional wallpaper, baked into the image (base64 in the cloud-init seed).
# Override with CC_RIG_WALLPAPER=/path/to.jpg; keep it display-sized — the
# whole file rides through the seed ISO.
WALLPAPER="${CC_RIG_WALLPAPER:-$(dirname "$0")/assets/wallpaper.jpg}"
[[ -f "$WALLPAPER" ]] || WALLPAPER=""

# ── cloud-init: the whole customisation, run on the guest's first boot ──────
cat > "$WORK_DIR/user-data" <<CLOUDINIT
#cloud-config
package_update: true
packages:
$(for pkg in $COMMON_PACKAGES $EXTRA_PACKAGES; do echo "  - $pkg"; done)

users:
  - name: cc
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: true

write_files:
  # The guest agent: capture, mode-set and the clipboard, and deliberately
  # UNPRIVILEGED. Input injection is the hypervisor's job (QMP), so nothing in
  # here can synthesize a keystroke even if the guest is compromised — and the
  # clipboard does not change that. Owning an X selection is something any
  # ordinary client does; it moves DATA, never events.
  - path: /usr/local/bin/cc-guest-agent
    permissions: '0755'
    content: |
      #!/usr/bin/env python3
      """Capture + display mode-set for a Control Center rig.

      Speaks the small HTTP protocol GuestAgentClient expects on :7811:
        GET  /health                    -> {"display": {"width", "height"}}
        GET  /version                   -> {"protocol": N, "agent": "..."}
        GET  /frame?w=&h=&q=            -> a single JPEG
        GET  /stream?w=&h=&fps=&q=      -> concatenated JPEGs, close-delimited
        GET  /audio?kbps=               -> MP3, close-delimited
        GET  /clipboard?sel=            -> {"text", "image", "files"}
        POST /display  {"width","height"} -> {"display": {...}}
        POST /clipboard {"text"|"image"|"files"} -> {"ok": true}
      Every request must carry the per-VM bearer token from the seed image.
      """
      import base64, hmac, http.server, json, os, socketserver
      import subprocess, sys, time

      # Bumped whenever this agent's protocol changes. The host reads it from
      # /version and can then tell an OLD image from a BROKEN one, which are
      # different problems with different fixes.
      #   1 -> capture, display mode-set, audio
      #   2 -> + /clipboard (text, image/png, text/uri-list; CLIPBOARD,
      #        PRIMARY and XdndSelection)
      PROTOCOL = 2
      AGENT_BUILD = "cc-guest-agent/2"

      # The X selections this agent will touch, by their real X names. A
      # closed map on purpose: 'sel' arrives from a request, and xclip happily
      # accepts any string as a selection name, so an open one would let a
      # caller address selections this protocol says nothing about.
      SELECTIONS = {
          "clipboard": "clipboard",
          "primary": "primary",
          # X's own name, case-sensitive: the drag-and-drop protocol's
          # selection atom is literally 'XdndSelection'.
          "xdnd": "XdndSelection",
      }

      # Fail-closed auth. An empty TOKEN used to mean "let everyone in", and
      # TOKEN is empty exactly when the seed did not land -- so the one state
      # where the guest is misconfigured was also the one where it served any
      # process on the host that could reach the forwarded port. The cause is
      # kept so the refusal can name it instead of being an opaque 403.
      TOKEN = ""
      TOKEN_ERROR = ""
      SEED = "/etc/cc-rig.json"
      try:
          with open(SEED) as fh:
              TOKEN = json.load(fh).get("agent_token", "") or ""
          if not TOKEN:
              TOKEN_ERROR = "seed %s carries no agent_token" % SEED
      except FileNotFoundError:
          TOKEN_ERROR = "seed %s is missing (cc-rig-seed did not run)" % SEED
      except PermissionError:
          TOKEN_ERROR = ("seed %s is unreadable by this user "
                         "(it must be 0640 root:cc)" % SEED)
      except Exception as exc:
          TOKEN_ERROR = "seed %s is unusable: %s" % (SEED, exc)

      # Cached: xdpyinfo is a whole process plus an X round-trip, and paying
      # that per FRAME was half of why the stream crawled. The mode only
      # changes through /display, which busts the cache explicitly.
      _size_cache = {"at": 0.0, "wh": None}

      def display_size(force=False):
          if (not force and _size_cache["wh"] is not None
                  and time.time() - _size_cache["at"] < 10):
              return _size_cache["wh"]
          wh = (1280, 800)
          try:
              out = subprocess.check_output(
                  ["xdpyinfo"], env={**os.environ, "DISPLAY": ":0"}, text=True)
              for line in out.splitlines():
                  if "dimensions:" in line:
                      w, h = line.split()[1].split("x")
                      wh = (int(w), int(h))
                      break
          except Exception:
              pass
          _size_cache["wh"] = wh
          _size_cache["at"] = time.time()
          return wh

      # Aspect-preserving, never upscaling. A forced exact WxH stretched the
      # picture to whatever shape the viewer's canvas happened to be, and a
      # Retina canvas asked for MORE pixels than the guest has — paying 4x
      # the encode for a blurry enlargement.
      def scale_filter(width, height):
          return (f"scale=min(iw\\,{width}):min(ih\\,{height})"
                  ":force_original_aspect_ratio=decrease")

      def grab(width, height, quality):
          w, h = display_size()
          return subprocess.check_output([
              "ffmpeg", "-loglevel", "quiet", "-f", "x11grab",
              "-video_size", f"{w}x{h}", "-i", ":0", "-vframes", "1",
              "-vf", scale_filter(width, height), "-q:v", str(quality),
              "-f", "mjpeg", "-",
          ], env={**os.environ, "DISPLAY": ":0"})

      # ── The clipboard lane ────────────────────────────────────────────
      #
      # Every one of these is BOUNDED and never raises. A selection read asks
      # another X client to answer, and the client that owns it may be busy,
      # mid-drag, or a hostile page in a browser -- so a read that could hang
      # would wedge one of the agent's threads permanently, and enough of them
      # would take the whole agent down with no diagnosis beyond "the rig
      # stopped answering".

      # Longer than a healthy round trip by a wide margin, short enough that a
      # wedged owner does not stall an interactive paste.
      CLIP_TIMEOUT = 4

      # The most one clipboard read carries back. The host caps again on its
      # side; this one stops the GUEST from building a 2 GB string in memory
      # when a page puts something enormous on the clipboard.
      MAX_CLIP_BYTES = 24 * 1024 * 1024

      def xclip_out(selection, target=None):
          """Reads 'target' off 'selection', or None when it is not there."""
          argv = ["xclip", "-selection", selection, "-o"]
          if target:
              argv += ["-t", target]
          try:
              proc = subprocess.run(
                  argv, env={**os.environ, "DISPLAY": ":0"},
                  stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                  timeout=CLIP_TIMEOUT)
          except Exception:
              # Includes TimeoutExpired: an owner that will not answer is
              # indistinguishable from no owner, and both mean "nothing here".
              return None
          if proc.returncode != 0 or not proc.stdout:
              return None
          if len(proc.stdout) > MAX_CLIP_BYTES:
              return None
          return proc.stdout

      def xclip_targets(selection):
          raw = xclip_out(selection, "TARGETS")
          if not raw:
              return []
          return [line.strip() for line in
                  raw.decode("utf-8", "replace").splitlines() if line.strip()]

      def xclip_in(selection, target, data):
          """Takes ownership of 'selection', serving 'data' as 'target'.

          stdout/stderr go to DEVNULL rather than a pipe: xclip forks a child
          that holds the selection for as long as it owns it, and that child
          inherits the parent's pipes -- so capturing output would make this
          call block until the NEXT application claimed the clipboard.
          """
          try:
              proc = subprocess.Popen(
                  ["xclip", "-selection", selection, "-t", target, "-i"],
                  env={**os.environ, "DISPLAY": ":0"},
                  stdin=subprocess.PIPE,
                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
              proc.communicate(input=data, timeout=CLIP_TIMEOUT)
              return True
          except Exception:
              return False

      def uri_list_to_paths(raw):
          """'file:///a/b%20c' lines -> '/a/b c' paths, ignoring anything else.

          Non-file URIs are dropped rather than passed through: the host uses
          these to fetch bytes out of the guest, and an 'http://' entry there
          would turn a clipboard read into an outbound fetch.
          """
          import urllib.parse as _urlparse
          paths = []
          for line in raw.decode("utf-8", "replace").splitlines():
              line = line.strip()
              # A uri-list comment, per RFC 2483.
              if not line or line.startswith("#"):
                  continue
              parsed = _urlparse.urlsplit(line)
              if parsed.scheme != "file":
                  continue
              # Only this host's own files. A 'file://otherhost/...' entry is
              # not something this guest can read.
              if parsed.netloc not in ("", "localhost"):
                  continue
              paths.append(_urlparse.unquote(parsed.path))
          return paths

      def read_clipboard(selection):
          """Everything on 'selection', in the flavours that cross to a host."""
          targets = xclip_targets(selection)
          out = {}
          if "text/uri-list" in targets:
              raw = xclip_out(selection, "text/uri-list")
              if raw:
                  files = []
                  for path in uri_list_to_paths(raw):
                      entry = {"guest_path": path,
                               "name": os.path.basename(path.rstrip("/"))}
                      try:
                          entry["size_bytes"] = os.path.getsize(path)
                      except OSError:
                          # Named but unreadable (a stale entry, a directory
                          # the host cannot fetch). Kept WITH no size rather
                          # than dropped: the name is still the honest answer
                          # to "what is on the clipboard".
                          pass
                      files.append(entry)
                  if files:
                      out["files"] = files
          # PNG first among the image flavours: it is lossless, every toolkit
          # offers it, and it is the one flavour the host promises to accept.
          for image_target in ("image/png", "image/jpeg"):
              if image_target in targets:
                  raw = xclip_out(selection, image_target)
                  if raw:
                      out["image"] = base64.b64encode(raw).decode("ascii")
                      out["image_media_type"] = image_target
                      break
          for text_target in ("UTF8_STRING", "text/plain;charset=utf-8",
                              "text/plain", "STRING"):
              if text_target in targets:
                  raw = xclip_out(selection, text_target)
                  if raw:
                      out["text"] = raw.decode("utf-8", "replace")
                      break
          return out

      class Handler(http.server.BaseHTTPRequestHandler):
          protocol_version = "HTTP/1.1"

          def _authed(self):
              # No token, no service: see TOKEN_ERROR above. compare_digest
              # rather than == so the comparison does not leak the token
              # prefix through its timing.
              if not TOKEN:
                  return False
              # Compared as BYTES: compare_digest rejects a str carrying any
              # character above U+007F with a TypeError, and http.client
              # decodes headers as latin-1 -- so a header with one high byte
              # in it would crash the handler instead of being refused.
              got = (self.headers.get("Authorization") or "").encode()
              return hmac.compare_digest(got, ("Bearer " + TOKEN).encode())

          def _send_json(self, code, payload):
              body = json.dumps(payload).encode()
              self.send_response(code)
              self.send_header("Content-Type", "application/json")
              self.send_header("Content-Length", str(len(body)))
              self.end_headers(); self.wfile.write(body)

          def _refuse(self):
              # 503 (not 403) when the guest has no token at all: the request
              # was fine, the GUEST is not configured, and the host's probe
              # error should say which. A bare 403 sends whoever debugs it
              # looking for a bad token that was never minted.
              if not TOKEN:
                  self._send_json(503, {
                      "error": "guest agent is unconfigured",
                      "cause": TOKEN_ERROR or "no agent token loaded",
                  })
              else:
                  self._send_json(403, {"error": "bad or missing bearer token"})

          def _open_stream(self, content_type):
              # Close-delimited body. HTTP/1.1 with neither Content-Length nor
              # chunked framing is only valid when the connection close marks
              # the end -- and without that, the encoder exiting left the
              # socket open waiting for a NEW request, so the host's response
              # never completed: the viewer froze on its last frame with no
              # onDone, hence no reconnect.
              self.close_connection = True
              self.send_response(200)
              self.send_header("Content-Type", content_type)
              self.send_header("Connection", "close")
              self.end_headers()

          def _relay(self, proc, chunk_size):
              try:
                  while True:
                      buf = proc.stdout.read(chunk_size)
                      if not buf:
                          return
                      self.wfile.write(buf)
                      self.wfile.flush()
              except (BrokenPipeError, ConnectionResetError):
                  return
              except Exception:
                  return
              finally:
                  # The client hanging up must take the encoder with it: an
                  # orphaned ffmpeg keeps grabbing X forever. wait() reaps it
                  # rather than leaving a zombie per viewer.
                  try:
                      proc.kill(); proc.wait(timeout=5)
                  except Exception:
                      pass
                  try:
                      self.wfile.flush()
                  except Exception:
                      pass

          def log_message(self, *args):
              pass

          def do_GET(self):
              if not self._authed():
                  self._refuse(); return
              path, _, query = self.path.partition("?")
              args = dict(p.split("=", 1) for p in query.split("&") if "=" in p)
              if path == "/health":
                  w, h = display_size()
                  self._send_json(200, {"display": {"width": w, "height": h}})
                  return
              if path == "/version":
                  # Forward compatibility: a host talking to an image that
                  # predates this endpoint gets a 404 and treats it as "old",
                  # which is why the client tolerates it instead of throwing.
                  self._send_json(200, {"protocol": PROTOCOL,
                                        "agent": AGENT_BUILD})
                  return
              if path == "/frame":
                  try:
                      jpeg = grab(int(args.get("w", 1280)), int(args.get("h", 800)),
                                  max(2, 31 - int(args.get("q", 80)) * 30 // 100))
                  except Exception as e:
                      # A named failure beats a dropped connection: the host
                      # then reports "the display is not up" instead of a
                      # generic closed-before-header mystery.
                      body = str(e).encode()
                      self.send_response(500)
                      self.send_header("Content-Type", "text/plain")
                      self.send_header("Content-Length", str(len(body)))
                      self.end_headers(); self.wfile.write(body); return
                  self.send_response(200)
                  self.send_header("Content-Type", "image/jpeg")
                  self.send_header("Content-Length", str(len(jpeg)))
                  self.end_headers(); self.wfile.write(jpeg); return
              if path == "/stream":
                  # ONE long-lived ffmpeg per viewer, capturing continuously.
                  # The first version spawned a fresh ffmpeg (X connect, init,
                  # one frame, exit) per frame plus an xdpyinfo — 200-500 ms
                  # of process churn each, so "15 fps" delivered 2-3. The
                  # output is raw concatenated JPEGs; the relay never parses
                  # it and the viewer resynchronises on JPEG markers.
                  fps = max(1, min(60, int(args.get("fps", 15))))
                  width = int(args.get("w", 1280))
                  height = int(args.get("h", 800))
                  qv = max(2, 31 - int(args.get("q", 70)) * 30 // 100)
                  dw, dh = display_size()
                  self._open_stream("video/x-motion-jpeg")
                  proc = subprocess.Popen([
                      "ffmpeg", "-loglevel", "quiet",
                      "-f", "x11grab", "-framerate", str(fps),
                      "-video_size", f"{dw}x{dh}", "-i", ":0",
                      "-vf", scale_filter(width, height),
                      "-q:v", str(qv), "-f", "mjpeg",
                      "-flush_packets", "1", "-",
                  ], env={**os.environ, "DISPLAY": ":0"},
                     stdout=subprocess.PIPE)
                  self._relay(proc, 65536)
                  return
              if path == "/audio":
                  # The audio lane: whatever the guest plays into the null
                  # sink, encoded to MP3 and relayed as bytes — the host
                  # never decodes it, same rule as frames. pulseaudio
                  # autospawns on first client connect.
                  kbps = max(48, min(320, int(args.get("kbps", 128))))
                  self._open_stream("audio/mpeg")
                  proc = subprocess.Popen([
                      "ffmpeg", "-loglevel", "quiet",
                      "-f", "pulse", "-i", "ccout.monitor",
                      "-ac", "2", "-ar", "44100",
                      "-f", "mp3", "-b:a", f"{kbps}k",
                      "-flush_packets", "1", "-",
                  ], stdout=subprocess.PIPE)
                  self._relay(proc, 4096)
                  return
              if path == "/clipboard":
                  name = args.get("sel", "clipboard")
                  selection = SELECTIONS.get(name)
                  if selection is None:
                      # Named, not silently defaulted: a caller that asked for
                      # a selection this agent does not serve and got CLIPBOARD
                      # back would read whatever was last copied and believe it
                      # was looking at a drag.
                      self._send_json(400, {
                          "error": "unknown selection",
                          "selection": name,
                          "expected": sorted(SELECTIONS),
                      })
                      return
                  try:
                      self._send_json(200, read_clipboard(selection))
                  except Exception as e:
                      self._send_json(500, {"error": str(e)})
                  return
              self._send_json(404, {"error": "no such endpoint"})

          # The most a POST body may be. Sized for one full-screen PNG in
          # base64 (which inflates by 4/3) plus its JSON envelope.
          MAX_POST_BYTES = 32 * 1024 * 1024

          def _read_body(self):
              """The request body, or None once a refusal has been sent."""
              try:
                  length = int(self.headers.get("Content-Length", 0))
              except ValueError:
                  length = -1
              if length < 0:
                  self._send_json(411, {"error": "Content-Length is required"})
                  return None
              if length > self.MAX_POST_BYTES:
                  # Refused BEFORE reading: the point of the cap is not to
                  # allocate the body, so draining it first would defeat it.
                  # The connection closes rather than being reused, because
                  # the unread body would otherwise be parsed as the next
                  # request.
                  self.close_connection = True
                  self._send_json(413, {
                      "error": "body too large",
                      "limit_bytes": self.MAX_POST_BYTES,
                  })
                  return None
              return self.rfile.read(length) or b"{}"

          def _post_clipboard(self):
              body = self._read_body()
              if body is None:
                  return
              try:
                  want = json.loads(body)
              except Exception:
                  self._send_json(400, {"error": "malformed JSON body"}); return
              # ONE flavour per write, and this is the order of preference.
              # X selection ownership is exclusive per target holder: a second
              # xclip claiming the same selection evicts the first, so writing
              # text and then an image would leave only the image, with the
              # call reporting that both landed.
              image = want.get("image")
              files = want.get("files")
              text = want.get("text")
              if image:
                  try:
                      raw = base64.b64decode(image, validate=True)
                  except Exception:
                      self._send_json(400, {"error": "image is not base64"})
                      return
                  media = want.get("image_media_type") or "image/png"
                  if media not in ("image/png", "image/jpeg"):
                      self._send_json(400, {
                          "error": "unsupported image type", "got": media})
                      return
                  ok = xclip_in("clipboard", media, raw)
                  wrote = "image"
              elif files:
                  import urllib.parse as _urlparse
                  uris = []
                  for path in files:
                      if isinstance(path, str) and path.startswith("/"):
                          uris.append("file://" + _urlparse.quote(path))
                  if not uris:
                      self._send_json(400, {
                          "error": "files must be absolute guest paths"})
                      return
                  # CRLF and a trailing terminator: RFC 2483 says a uri-list is
                  # CRLF-delimited, and GTK's parser drops a final entry that
                  # is not terminated.
                  payload = ("\r\n".join(uris) + "\r\n").encode("utf-8")
                  ok = xclip_in("clipboard", "text/uri-list", payload)
                  wrote = "files"
              elif text is not None:
                  ok = xclip_in("clipboard", "UTF8_STRING",
                                str(text).encode("utf-8"))
                  wrote = "text"
              else:
                  self._send_json(400, {
                      "error": "nothing to write (expected text, image or files)"})
                  return
              if not ok:
                  self._send_json(500, {
                      "error": "could not take ownership of the clipboard "
                               "(is the X session up?)"})
                  return
              self._send_json(200, {"ok": True, "wrote": wrote})

          def do_POST(self):
              if not self._authed():
                  self._refuse(); return
              if self.path == "/clipboard":
                  self._post_clipboard(); return
              if self.path != "/display":
                  self._send_json(404, {"error": "no such endpoint"}); return
              body = self._read_body()
              if body is None:
                  return
              want = json.loads(body)
              w, h = int(want.get("width", 1280)), int(want.get("height", 800))
              # An arbitrary tab-sized mode almost never pre-exists on the
              # virtual output, and plain --mode fails on an unknown name —
              # which is why resizing "did nothing". Mint the modeline with
              # cvt, register it, then switch. Errors fall through to the
              # nearest existing mode attempt.
              env = {**os.environ, "DISPLAY": ":0"}
              name = f"{w}x{h}_cc"
              try:
                  out = subprocess.check_output(
                      ["cvt", str(w), str(h), "60"], text=True)
                  line = [l for l in out.splitlines()
                          if l.startswith("Modeline")][0]
                  mode = line.split()[1:]
                  mode[0] = name
                  subprocess.call(["xrandr", "--newmode"] + mode, env=env,
                                  stderr=subprocess.DEVNULL)
                  subprocess.call(["xrandr", "--addmode", "Virtual-1", name],
                                  env=env, stderr=subprocess.DEVNULL)
                  subprocess.call(
                      ["xrandr", "--output", "Virtual-1", "--mode", name],
                      env=env)
              except Exception:
                  subprocess.call(
                      ["xrandr", "--output", "Virtual-1",
                       "--mode", f"{w}x{h}"], env=env)
              gw, gh = display_size(force=True)
              self._send_json(200, {"display": {"width": gw, "height": gh}})

      class Server(socketserver.ThreadingMixIn, http.server.HTTPServer):
          daemon_threads = True

      Server(("0.0.0.0", 7811), Handler).serve_forever()

  # Reads the per-VM seed the host built: the SSH key, the agent token and the
  # credential-broker secret. Nothing here is baked into the image — every rig
  # gets its own, and they die with the machine.
  - path: /usr/local/bin/cc-rig-seed
    permissions: '0755'
    content: |
      #!/bin/bash
      set -euo pipefail
      # The build strips the ssh HOST keys so every rig gets its own identity
      # — but only cloud-init ever regenerated them, and a runtime rig boots
      # with no cloud-init datasource (only the CCRIG seed). Without this,
      # socket-activated sshd accepts the TCP connection and dies keyless, so
      # every ssh — including the worktree sync — is reset at the banner.
      ssh-keygen -A
      mkdir -p /mnt/ccseed
      for dev in /dev/vd? /dev/sr0; do
        if blkid "\$dev" 2>/dev/null | grep -qi 'LABEL="CCRIG"'; then
          mount -o ro "\$dev" /mnt/ccseed && break
        fi
      done
      [[ -f /mnt/ccseed/cc-rig.json ]] || exit 0
      # 0640 root:cc, NOT 0600 root. Both consumers run as the unprivileged
      # cc user -- the guest agent (User=cc by design, so a compromised
      # capture process cannot synthesize input) and the git credential
      # helper, which git invokes as whoever runs it. At 0600 root the agent
      # dies with PermissionError on every start, Restart=always turns that
      # into a crash loop, and the host sees nothing on :7811 for its whole
      # 120s timeout. Group-read by cc keeps the broker secret off
      # world-readable while letting the two processes that need it work.
      # (No backticks in this heredoc: it is unquoted, so they would run
      # as a command on the HOST at generation time.)
      install -m 0640 -o root -g cc /mnt/ccseed/cc-rig.json /etc/cc-rig.json
      mkdir -p /home/cc/.ssh
      jq -r '.authorized_key' /etc/cc-rig.json > /home/cc/.ssh/authorized_keys
      chown -R cc:cc /home/cc/.ssh
      chmod 700 /home/cc/.ssh
      chmod 600 /home/cc/.ssh/authorized_keys
      # Egress goes through the host's proxy and nowhere else.
      {
        echo "export http_proxy=\$(jq -r '.http_proxy' /etc/cc-rig.json)"
        echo "export https_proxy=\\\$http_proxy"
        echo "export HTTP_PROXY=\\\$http_proxy"
        echo "export HTTPS_PROXY=\\\$http_proxy"
        echo "export ALL_PROXY=\$(jq -r '.socks_proxy' /etc/cc-rig.json)"
      } > /etc/profile.d/cc-rig-proxy.sh

  # git asks the HOST for a short-lived token per operation. Nothing durable
  # is ever stored in the guest.
  - path: /usr/local/bin/cc-git-credential
    permissions: '0755'
    content: |
      #!/bin/bash
      # git credential helper protocol: read key=value lines on stdin.
      [[ "\${1:-}" == "get" ]] || exit 0
      declare -A req
      while IFS='=' read -r k v; do
        [[ -n "\$k" ]] && req[\$k]="\$v"
      done
      endpoint=\$(jq -r '.credential_endpoint' /etc/cc-rig.json)
      rig=\$(jq -r '.rig_id' /etc/cc-rig.json)
      secret=\$(jq -r '.credential_secret' /etc/cc-rig.json)
      body=\$(jq -n --arg r "\$rig" --arg s "\$secret" --arg h "\${req[host]}" \\
        '{rig_id:\$r, secret:\$s, host:\$h}')
      out=\$(curl -fsS -X POST -H 'Content-Type: application/json' \\
        -d "\$body" "\$endpoint" 2>/dev/null) || exit 0
      echo "username=\$(echo "\$out" | jq -r .username)"
      echo "password=\$(echo "\$out" | jq -r .password)"

  - path: /etc/systemd/system/cc-rig-seed.service
    content: |
      [Unit]
      Description=Control Center rig seed
      Before=ssh.service cc-guest-agent.service
      [Service]
      Type=oneshot
      ExecStart=/usr/local/bin/cc-rig-seed
      RemainAfterExit=yes
      [Install]
      WantedBy=multi-user.target

  - path: /etc/systemd/system/cc-guest-agent.service
    content: |
      [Unit]
      Description=Control Center guest agent
      After=cc-rig-seed.service
      [Service]
      # Unprivileged on purpose: it captures, mode-sets and moves the
      # clipboard, nothing else. It also has to BE the session's user for the
      # clipboard to work at all — an X selection belongs to a client, and a
      # client is a process with a connection to :0.
      User=cc
      Environment=DISPLAY=:0
      # The pulse socket lives in the cc user's runtime dir; without this the
      # audio lane's ffmpeg cannot find the sink monitor it records.
      Environment=XDG_RUNTIME_DIR=/run/user/1000
      ExecStart=/usr/local/bin/cc-guest-agent
      Restart=always
      [Install]
      WantedBy=multi-user.target

  # Xorg on Ubuntu ships behind Xorg.wrap with allowed_users=console: an X
  # started by a systemd unit has no console session, so the wrapper refuses
  # it, cc-x11 crash-loops, and the guest agent serves /health happily while
  # every /frame dies — a desktop image that verifies and cannot capture.
  # anybody + needs_root_rights lets the unit own the VT it names below.
  - path: /etc/X11/Xwrapper.config
    content: |
      allowed_users=anybody
      needs_root_rights=yes

  # The session: GNOME when present, openbox as the fallback. gsettings run
  # inside the session bus BEFORE the shell starts: animations off (software
  # GL — every animation is CPU spent on frames nobody needs), idle/lock off
  # (a rig that locks its own screen is a rig nobody can watch), and the
  # wallpaper through GNOME's own background (it paints over the root window,
  # so feh alone would be invisible under the shell).
  # Prefer the lingering user manager's OWN bus over a throwaway
  # dbus-run-session one: gsettings then land in the real dconf, and snap
  # apps launched inside the session can mint their scopes.
  - path: /usr/local/bin/cc-desktop-session
    permissions: '0755'
    content: |
      #!/bin/bash
      uid="\$(id -u)"
      export XDG_RUNTIME_DIR="/run/user/\${uid}"
      for _ in \$(seq 1 20); do
        [ -S "\${XDG_RUNTIME_DIR}/bus" ] && break
        sleep 1
      done
      if [ -S "\${XDG_RUNTIME_DIR}/bus" ]; then
        export DBUS_SESSION_BUS_ADDRESS="unix:path=\${XDG_RUNTIME_DIR}/bus"
        exec /usr/local/bin/cc-desktop-session-inner
      fi
      exec dbus-run-session -- /usr/local/bin/cc-desktop-session-inner

  - path: /usr/local/bin/cc-desktop-session-inner
    permissions: '0755'
    content: |
      #!/bin/bash
      export XDG_SESSION_TYPE=x11
      # No blanking, no DPMS: a rig that turns its own screen off looks like
      # a broken stream.
      xset s off -dpms 2>/dev/null || true
      # Hand DISPLAY to dbus activation and the user manager — snap apps
      # (chromium) launched inside the session mint their scopes there.
      dbus-update-activation-environment --systemd DISPLAY XAUTHORITY \\
        XDG_CURRENT_DESKTOP XDG_SESSION_TYPE 2>/dev/null || true
      if command -v startxfce4 >/dev/null 2>&1; then
        export XDG_CURRENT_DESKTOP=XFCE
        startxfce4
      fi
      xsetroot -solid "#1c2226"
      [ -f /usr/share/backgrounds/cc-rig.jpg ] && \\
        command -v feh >/dev/null && \\
        feh --bg-fill /usr/share/backgrounds/cc-rig.jpg &
      exec openbox-session

  # The guest's ONLY audio output: a null sink whose monitor the agent
  # records. There is no virtio-sound device on purpose — audio leaves the
  # guest as encoded bytes over the agent channel, exactly like frames do.
  - path: /etc/pulse/default.pa.d/cc-rig.pa
    permissions: '0644'
    content: |
      load-module module-null-sink sink_name=ccout sink_properties=device.description=CC-rig-output
      set-default-sink ccout

  # The wallpaper as XFCE's system default (xfdesktop paints the root, so
  # feh alone would be invisible under it). Both monitor spellings, because
  # the virtual output is "Virtual-1" under modesetting and "monitor0" under
  # older naming.
  - path: /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
    permissions: '0644'
    content: |
      <?xml version="1.0" encoding="UTF-8"?>
      <channel name="xfce4-desktop" version="1.0">
        <property name="backdrop" type="empty">
          <property name="screen0" type="empty">
            <property name="monitorVirtual-1" type="empty">
              <property name="workspace0" type="empty">
                <property name="last-image" type="string" value="/usr/share/backgrounds/cc-rig.jpg"/>
                <property name="image-style" type="int" value="5"/>
              </property>
            </property>
            <property name="monitor0" type="empty">
              <property name="workspace0" type="empty">
                <property name="last-image" type="string" value="/usr/share/backgrounds/cc-rig.jpg"/>
                <property name="image-style" type="int" value="5"/>
              </property>
            </property>
          </property>
        </property>
      </channel>

  - path: /etc/systemd/system/cc-x11.service
    content: |
      [Unit]
      Description=Control Center rig desktop
      After=cc-rig-seed.service
      [Service]
      User=cc
      # vt1 explicitly: without a VT argument X tries to take the current
      # console, which nothing in a headless boot owns.
      ExecStart=/usr/bin/xinit /usr/local/bin/cc-desktop-session -- :0 vt1 -nolisten tcp
      Restart=always
      RestartSec=2
      [Install]
      WantedBy=multi-user.target

  # Session dressing: a solid tone immediately, the wallpaper over it when
  # present. Without this the desktop boots onto X's void-black root window,
  # which reads as "the stream is broken" rather than "an empty desktop".
  - path: /etc/xdg/openbox/autostart
    permissions: '0644'
    content: |
      xsetroot -solid "#1c2226"
      [ -f /usr/share/backgrounds/cc-rig.jpg ] && \\
        command -v feh >/dev/null && \\
        feh --bg-fill /usr/share/backgrounds/cc-rig.jpg &
$([[ -n "${WALLPAPER:-}" ]] && {
  echo "  - path: /usr/share/backgrounds/cc-rig.jpg"
  echo "    encoding: b64"
  echo "    permissions: '0644'"
  echo "    content: |"
  base64 < "$WALLPAPER" | fold -w 76 | sed 's/^/      /'
})

runcmd:
  # Egress proxy for EVERY session at RIG time (PAM reads /etc/environment;
  # profile.d only covers login shells, which is why desktop apps "had no
  # network"). Appended HERE, after the package phase — NOT in write_files:
  # these per-rig proxy addresses do not exist during the BUILD boot (open
  # NAT, no guestfwd), and baking them earlier pointed apt/snapd at a proxy
  # that wasn't there — the snap store retried for 40 minutes and the build
  # died on its watchdog.
  - sh -c 'printf "http_proxy=http://${QEMU_HTTP_PROXY_ADDR}\nhttps_proxy=http://${QEMU_HTTP_PROXY_ADDR}\nHTTP_PROXY=http://${QEMU_HTTP_PROXY_ADDR}\nHTTPS_PROXY=http://${QEMU_HTTP_PROXY_ADDR}\nALL_PROXY=socks5://${QEMU_SOCKS_PROXY_ADDR}\nno_proxy=localhost,127.0.0.1\nNO_PROXY=localhost,127.0.0.1\n" >> /etc/environment'
  - git config --system credential.helper /usr/local/bin/cc-git-credential
  - systemctl enable cc-rig-seed.service cc-guest-agent.service $SURFACE_UNITS
  # The desktop metapackages drag in a display manager (lightdm), which then
  # claims :0 on its own VT with cookie auth — locking the capture agent and
  # the cc session out of the display they expect to own ("Authorization
  # required"). This image runs its own session via cc-x11; no DM, ever.
  # Masking the alias covers whichever DM a future package might install.
  - systemctl mask lightdm.service display-manager.service 2>/dev/null || true
$EXTRA_RUNCMD
  # Leave no identity behind: every rig that boots this image must look new.
  - cloud-init clean --logs --seed
  - rm -f /etc/ssh/ssh_host_* /etc/machine-id
  - touch /etc/machine-id
  # The builder's own hostname is baked into /etc/hostname by this boot, and
  # without this every rig launched from the image calls itself
  # "cc-rig-build" — the build machine's name showing up in the logs of a
  # hundred later rigs is exactly the identity this block exists to strip.
  - sh -c 'echo cc-rig > /etc/hostname'
  - sh -c 'sed -i "s/cc-rig-build/cc-rig/g" /etc/hosts'
  # The host greps the console for this. cloud-init reports success for a boot
  # in which it did nothing at all (a seed it never found is "no config", not
  # an error), so an explicit marker is the only way the build can tell a real
  # customisation from a stock image that merely booted.
  - echo "CC_RIG_BUILD_OK $IMAGE_ID" > /dev/console
  - poweroff
CLOUDINIT

printf '#cloud-config\ninstance-id: cc-rig-build\nlocal-hostname: cc-rig-build\n' \
  > "$WORK_DIR/meta-data"

# ── Build the seed and run the one-shot customisation boot ──────────────────
SEED_ISO="$WORK_DIR/seed.iso"

# Stage the seed in its own directory. cloud-init reads the WHOLE volume, and
# handing the builder $WORK_DIR would ship the 64 MiB firmware and the output
# image inside the seed alongside the two files that belong there.
SEED_DIR="$WORK_DIR/seed"
mkdir -p "$SEED_DIR"
cp "$WORK_DIR/user-data" "$WORK_DIR/meta-data" "$SEED_DIR/"

# The volume LABEL must be exactly `cidata` — that string is how NoCloud finds
# the seed, and a correctly-populated ISO under any other label is invisible.
# Getting this wrong does not fail: cloud-init falls back to DataSourceNone,
# reports success, and hands back a stock image with none of our changes in it.
if command -v cloud-localds >/dev/null 2>&1; then
  cloud-localds "$SEED_ISO" "$SEED_DIR/user-data" "$SEED_DIR/meta-data"
elif command -v genisoimage >/dev/null 2>&1; then
  genisoimage -output "$SEED_ISO" -volid cidata -joliet -rock \
    "$SEED_DIR/user-data" "$SEED_DIR/meta-data" >/dev/null 2>&1
elif command -v mkisofs >/dev/null 2>&1; then
  mkisofs -output "$SEED_ISO" -volid cidata -joliet -rock \
    "$SEED_DIR/user-data" "$SEED_DIR/meta-data" >/dev/null 2>&1
elif command -v xorriso >/dev/null 2>&1; then
  xorriso -as mkisofs -output "$SEED_ISO" -volid cidata -joliet -rock \
    "$SEED_DIR/user-data" "$SEED_DIR/meta-data" >/dev/null 2>&1
elif command -v hdiutil >/dev/null 2>&1; then
  # macOS with no cloud-image tooling installed. Set every volume name this
  # accepts: -default-volume-name alone has been observed not to reach the
  # ISO9660 volume id, which is the one NoCloud actually reads.
  rm -f "$SEED_ISO"
  hdiutil makehybrid -o "$SEED_ISO" -iso -joliet \
    -default-volume-name cidata \
    -iso-volume-name cidata \
    -joliet-volume-name cidata \
    "$SEED_DIR" >/dev/null
else
  echo "need one of: cloud-localds, genisoimage, mkisofs, xorriso, hdiutil" >&2
  echo "(to build the cloud-init seed)" >&2
  exit 1
fi

# Verify the label before spending ten minutes finding out it was wrong.
if command -v file >/dev/null 2>&1; then
  if ! file "$SEED_ISO" | grep -qi "cidata"; then
    echo "the cloud-init seed did not come out labelled 'cidata':" >&2
    file "$SEED_ISO" >&2
    echo "The guest would ignore it and build an unmodified image." >&2
    exit 1
  fi
fi

echo "==> running the customisation boot (this installs packages; ~10 minutes)"
ACCEL=tcg
[[ "$(uname -s)" == "Darwin" ]] && ACCEL=hvf
[[ -r /dev/kvm ]] && ACCEL=kvm

MACHINE_ARGS=()
if [[ "$ARCH" == "arm64" ]]; then
  MACHINE_ARGS=(-machine virt,highmem=on -cpu host)
  if [[ ! -f "$WORK_DIR/edk2.fd" ]]; then
    # aarch64 needs UEFI firmware; the cloud image has no BIOS path.
    #
    # Look next to the qemu binary FIRST. Firmware ships with QEMU, so its own
    # prefix is the one location that is right on every install (Homebrew, Nix,
    # a distro package, a hand-built tree) — a hardcoded list of distro paths
    # is wrong on whichever host you did not think of.
    # Ask QEMU where its own data directories are (`-L help` prints them).
    # This is the only method that survives every install layout: a Nix or
    # Homebrew binary on PATH is a SYMLINK into a versioned store, so
    # `dirname $(command -v qemu)/..` lands on the profile directory, which
    # holds the binary but none of the firmware.
    FW_DIRS=()
    while IFS= read -r line; do
      [[ -d "$line" ]] && FW_DIRS+=("$line")
    done < <("$QEMU_BIN" -L help 2>/dev/null || true)

    # Fallback for a QEMU too old to answer, plus the usual distro locations.
    QEMU_REAL="$(command -v "$QEMU_BIN")"
    while [[ -L "$QEMU_REAL" ]]; do
      QEMU_LINK="$(readlink "$QEMU_REAL")"
      case "$QEMU_LINK" in
        /*) QEMU_REAL="$QEMU_LINK" ;;
        *)  QEMU_REAL="$(dirname "$QEMU_REAL")/$QEMU_LINK" ;;
      esac
    done
    FW_DIRS+=(
      "$(cd "$(dirname "$QEMU_REAL")/.." && pwd)/share/qemu"
      /opt/homebrew/share/qemu
      /usr/local/share/qemu
      /usr/share/qemu
      /usr/share/AAVMF
      /usr/share/edk2/aarch64
    )

    FW=""
    for dir in "${FW_DIRS[@]}"; do
      for name in edk2-aarch64-code.fd AAVMF_CODE.fd QEMU_EFI.fd; do
        if [[ -f "$dir/$name" ]]; then
          FW="$dir/$name"
          break 2
        fi
      done
    done
    if [[ -z "$FW" ]]; then
      echo "could not find aarch64 UEFI firmware (edk2-aarch64-code.fd)." >&2
      echo "It ships with QEMU; looked in:" >&2
      printf '  %s\n' "${FW_DIRS[@]}" >&2
      echo "  macOS:  brew install qemu" >&2
      echo "  Debian: sudo apt-get install qemu-efi-aarch64" >&2
      exit 1
    fi
    echo "    firmware: $FW"
    cp "$FW" "$WORK_DIR/edk2.fd"
    # `cp` carries the source mode across, and firmware shipped by a read-only
    # package store (Nix, or a locked-down /usr/share) is mode 444 — so the
    # copy is not writable by us even though we own it.
    chmod u+w "$WORK_DIR/edk2.fd"
    # pflash wants a fixed 64 MiB region and QEMU refuses to start on a short
    # one. Most builds ship it already padded, so only extend when it is
    # actually short — and size it in plain bytes, because `bs=1m` is a BSD
    # spelling that GNU dd rejects outright (and on a Mac with coreutils on
    # PATH, `dd` is GNU).
    FW_BYTES="$(wc -c < "$WORK_DIR/edk2.fd" | tr -d ' ')"
    if [[ "$FW_BYTES" -lt 67108864 ]]; then
      if ! dd if=/dev/zero of="$WORK_DIR/edk2.fd" bs=1048576 seek=64 count=0 \
          conv=notrunc 2>/dev/null; then
        echo "could not pad the UEFI firmware to 64 MiB" >&2
        echo "  file: $WORK_DIR/edk2.fd ($FW_BYTES bytes)" >&2
        exit 1
      fi
    fi
  fi
  MACHINE_ARGS+=(-drive "if=pflash,format=raw,readonly=on,file=$WORK_DIR/edk2.fd")
fi

# The guest's console goes to a file rather than to this terminal. A build is
# ~10 minutes of apt output nobody reads, but when it DOES fail the reason is
# in there, and `-nographic` (which wires the console to stdio) fails outright
# when this script runs without a terminal — from CI, or from a background
# shell, which is exactly when you most need the log.
BOOT_LOG="$WORK_DIR/boot.log"
echo "    console log: $BOOT_LOG"

# The guest ends with `poweroff`, so QEMU exiting IS the success signal. A
# guest that wedges would otherwise hang here forever, so cap it: `timeout` is
# not on a stock macOS, hence the explicit watchdog.
BUILD_TIMEOUT="${CC_RIG_BUILD_TIMEOUT:-2400}"
set +e
"$QEMU_BIN" \
  -accel "$ACCEL" \
  "${MACHINE_ARGS[@]}" \
  -m 4096 -smp 4 \
  -display none \
  -serial "file:$BOOT_LOG" \
  -drive "file=$OUT_IMG,if=virtio,format=qcow2" \
  -drive "file=$SEED_ISO,if=virtio,format=raw,readonly=on" \
  -netdev user,id=net0 -device virtio-net-pci,netdev=net0 &
QEMU_PID=$!

( sleep "$BUILD_TIMEOUT"; kill -0 "$QEMU_PID" 2>/dev/null && {
    echo "==> build exceeded ${BUILD_TIMEOUT}s; stopping the guest" >&2
    kill "$QEMU_PID" 2>/dev/null
  } ) &
WATCHDOG_PID=$!

wait "$QEMU_PID"
QEMU_RC=$?
kill "$WATCHDOG_PID" 2>/dev/null
wait "$WATCHDOG_PID" 2>/dev/null
set -e

if [[ $QEMU_RC -ne 0 ]]; then
  echo >&2
  echo "==> the customisation boot failed (qemu exit $QEMU_RC)" >&2
  echo "==> last 40 lines of the guest console:" >&2
  tail -40 "$BOOT_LOG" >&2 2>/dev/null || echo "  (no console output)" >&2
  # Keep the log: WORK_DIR is cleaned up on exit, and the one artifact worth
  # having after a failure is the reason it failed.
  cp "$BOOT_LOG" "$OUT_DIR/$IMAGE_ID-failed-boot.log" 2>/dev/null || true
  echo >&2
  echo "Full log: $OUT_DIR/$IMAGE_ID-failed-boot.log" >&2
  # A crashed or timed-out boot leaves a half-written image that is still a
  # valid qcow2, so it would import without complaint and fail at the first
  # agent call. Same reasoning as the marker check below.
  rm -f "$OUT_IMG"
  exit 1
fi

# Did the guest actually apply our config? A boot that never found the seed is
# the failure mode that matters here: cloud-init treats "no datasource" as "no
# work", exits 0, and leaves a stock image that boots fine and has none of the
# guest agent in it — which then fails much later, inside a rig, as a mystery.
if ! grep -q "CC_RIG_BUILD_OK" "$BOOT_LOG" 2>/dev/null; then
  echo >&2
  echo "==> the guest booted but never applied the build config." >&2
  if grep -qE "DataSourceNone|Used fallback datasource" "$BOOT_LOG" 2>/dev/null
  then
    echo "    cloud-init did not find the seed (it fell back to no" >&2
    echo "    datasource), so the image is unmodified stock Ubuntu." >&2
    echo "    The seed volume label must be exactly 'cidata'." >&2
  else
    echo "    The completion marker never reached the console." >&2
  fi
  cp "$BOOT_LOG" "$OUT_DIR/$IMAGE_ID-failed-boot.log" 2>/dev/null || true
  echo "    Full log: $OUT_DIR/$IMAGE_ID-failed-boot.log" >&2
  # Do not leave a plausible-looking image behind: it would import cleanly and
  # fail at the first agent call.
  rm -f "$OUT_IMG"
  exit 1
fi

# cloud-init reports its own failures through the exit status of the units it
# ran, which a `poweroff` at the end of runcmd throws away, so check the log.
#
# Only the part BEFORE the marker counts. Our last runcmd is `poweroff`, and
# tearing down while cloud-init is still logging makes Python print an
# "Exception ignored in atexit callback" traceback that ends in `SystemExit: 0`
# — a clean exit, emitted on a perfectly good build, and only on some runs. A
# check that fires on it fails builds at random, which is worse than not
# checking: it teaches you to ignore the checker.
sed "/CC_RIG_BUILD_OK/q" "$BOOT_LOG" > "$WORK_DIR/pre-marker.log" 2>/dev/null || true
# Scoped to OUR units and cloud-init itself: a stock Ubuntu boot routinely
# fails benign units (fwupd-refresh needs egress it doesn't have) and a check
# that fires on those fails good builds at random — which teaches you to
# ignore the checker.
if grep -qE "Failed to (start|run)[^\n]*(cc-|cloud-init)|cloud-init.*(CRITICAL|Traceback)" \
    "$WORK_DIR/pre-marker.log" 2>/dev/null; then
  echo >&2
  echo "==> the guest booted but cloud-init reported failures:" >&2
  grep -nE "Failed to (start|run)[^\n]*(cc-|cloud-init)|cloud-init.*(CRITICAL|Traceback)" \
    "$WORK_DIR/pre-marker.log" >&2 | head -20
  cp "$BOOT_LOG" "$OUT_DIR/$IMAGE_ID-failed-boot.log" 2>/dev/null || true
  echo "Full log: $OUT_DIR/$IMAGE_ID-failed-boot.log" >&2
  exit 1
fi

echo "==> compacting"
qemu-img convert -O qcow2 -c "$OUT_IMG" "$OUT_IMG.compact"
mv "$OUT_IMG.compact" "$OUT_IMG"

# Prove the image WORKS, not merely that it built. cloud-init applying every
# line and the guest agent actually serving are different claims, and only the
# second one is what a rig needs.
if [[ "${CC_RIG_SKIP_VERIFY:-0}" != "1" ]]; then
  echo "==> verifying the guest agent answers"
  if ! "$(dirname "$0")/verify_image.sh" "$OUT_IMG"; then
    echo >&2
    echo "==> the image built but its guest agent does not serve; not" >&2
    echo "    publishing it. Re-run with CC_RIG_SKIP_VERIFY=1 to keep it" >&2
    echo "    anyway for debugging." >&2
    exit 1
  fi
fi

echo
echo "Built: $OUT_IMG"
echo
echo "Import it in the app:"
echo "  Settings → Server → Enclosures → $IMAGE_ID → Import"
echo "  Path: $OUT_IMG"
