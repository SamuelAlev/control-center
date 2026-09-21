#!/usr/bin/env bash
#
# Builds the rig desktop qcow2 from the Ubuntu cloud image (Computer surface
# only). Customisation runs inside a throwaway VM. Seed volume label must be
# exactly `cidata`. Firmware via `qemu -L help` (not dirname of a symlink).
# Usage: scripts/rigs/build_image.sh cc-desktop-linux
#

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
# Cloud images ship small and grow on first boot; a desktop plus a compiler toolchain needs room.
qemu-img resize "$OUT_IMG" 16G >/dev/null

# ── What goes in ────────────────────────────────────────────────────────────
# Base: the SSH server worktree sync tars through, the git credential helper's
# dependencies, the tiny capture agent the host's guest-agent client talks
# to on :7811 (`python3-pil`), and the same GitHub-hosted-runner CLI baseline
# the terminal (exec) guest warms. Keep the CLI names in lockstep with
# `kSmolvmExecPackages` in
# packages/cc_infra/lib/src/rigs/smolvm_enclosure_backend.dart — a Computer
# tab and a terminal tab should not disagree about what "a basic toolchain"
# means. Language toolcaches (Node, Go, Java) and Docker stay out: those
# are versioned, huge, and Docker needs a nested daemon this VM does not
# run. `netcat` is virtual on Ubuntu 24.04; `netcat-openbsd` is the package.
COMMON_PACKAGES="openssh-server python3-pil \
acl aria2 autoconf automake binutils bison brotli bzip2 \
ca-certificates cmake curl dnsutils dpkg-dev fakeroot file flex \
g++ gcc git git-lfs gnupg iproute2 iputils-ping jq less \
libffi-dev libicu-dev libsqlite3-dev libssl-dev libtool libyaml-dev \
locales lsof lz4 m4 make nano net-tools netcat-openbsd ninja-build \
openssh-client p7zip-full parallel patch patchelf pigz pkg-config \
procps python-is-python3 python3 python3-pip python3-venv rsync \
shellcheck socat sqlite3 strace sudo swig tar time tree tzdata \
unzip wget xz-utils zip zlib1g-dev zstd"

# Desktop guest packages: XFCE + three browsers (Chrome for Testing / Firefox
# tarball / Epiphany — Ubuntu snap stubs fail under User=xinit). No GNOME
# (needs GL). xclip owns X selections (clipboard/DnD). fonts-noto-color-emoji
# for browsers; PulseAudio + pacat for virtual mic.
EXTRA_PACKAGES="xserver-xorg xinit x11-xserver-utils x11-utils xdotool xclip scrot ffmpeg feh openbox xfce4 xfce4-terminal network-manager dbus-user-session pulseaudio pulseaudio-utils libnss3 libnspr4 libdbus-glib-1-2 libxt6 libpci3 fonts-liberation fonts-noto-color-emoji libgbm1 libatk-bridge2.0-0 libxcomposite1 libxdamage1 libxrandr2 libxss1 libxtst6 libcups2t64 libasound2t64 epiphany-browser"

# Pinned guest browsers. Bump a version and BOTH of its hashes together.
# Firefox: https://ftp.mozilla.org/pub/firefox/releases/<ver>/SHA256SUMS
# Chromium: https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json
FIREFOX_VERSION="156.0"
CHROMIUM_VERSION="153.0.8010.52"
case "$ARCH" in
  arm64)
    FIREFOX_PLATFORM="linux-aarch64"
    FIREFOX_SHA256="7dd9425eafa0decf61c0f6bc56dc71cba84595495dc01395d3eea38a18aaf710"
    CHROMIUM_PLATFORM="linux-arm64"
    CHROMIUM_SHA256="794441f3254273eb30d710b3eaab3cd1c7bbf1c88a40275470f6cee350881ce5"
    ;;
  *)
    FIREFOX_PLATFORM="linux-x86_64"
    FIREFOX_SHA256="1d44cd02351c307c3e19061ea2a4d18a30f236e6be862b94f2282564afdb0167"
    CHROMIUM_PLATFORM="linux64"
    CHROMIUM_SHA256="e66f66d4802a46d4a022667e668aa950e277cadbfbed4b3777915b47413a0ef9"
    ;;
esac
FIREFOX_URL="https://ftp.mozilla.org/pub/firefox/releases/${FIREFOX_VERSION}/${FIREFOX_PLATFORM}/en-US/firefox-${FIREFOX_VERSION}.tar.xz"
CHROMIUM_URL="https://storage.googleapis.com/chrome-for-testing-public/${CHROMIUM_VERSION}/${CHROMIUM_PLATFORM}/chrome-${CHROMIUM_PLATFORM}.zip"
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
  # Production rigs attach a CCRIG seed, not a cloud-init datasource. The
  # verifier does attach cidata for diagnostics, so relying on cloud-init's
  # fallback DHCP made verification pass while real desktop rigs had no
  # connection at all. This profile is the one authoritative NIC setup.
  - path: /etc/netplan/60-cc-rig.yaml
    permissions: '0600'
    content: |
      network:
        version: 2
        renderer: NetworkManager
        ethernets:
          rig:
            match:
              name: "en*"
            dhcp4: true
            dhcp6: false
            optional: false
  - path: /etc/cloud/cloud.cfg.d/99-cc-rig-network.cfg
    permissions: '0644'
    content: |
      network:
        config: disabled
  # needrestart runs from apt's post-invoke and will restart cloud-final
  # while the package module is still inside it, which cloud-init then
  # reports as "Failure when attempting to install packages" even though
  # dpkg finished. List-only: a build must not bounce its own units.
  - path: /etc/needrestart/conf.d/cc-build.conf
    permissions: '0644'
    content: |
      \$nrconf{restart} = 'l';
  # The guest agent: capture, mode-set and the clipboard, and deliberately
  # UNPRIVILEGED. Input injection is the hypervisor's job (QMP), so nothing in
  # here can synthesize a keystroke even if the guest is compromised — and the
  # clipboard does not change that. Owning an X selection is something any
  # ordinary client does; it moves DATA, never events.
  - path: /usr/local/bin/cc-guest-agent
    permissions: '0755'
    content: |
      #!/usr/bin/env python3
      """Capture, audio, and display mode-set for a Control Center rig.

      Speaks the small HTTP protocol GuestAgentClient expects on :7811.
        GET  /health          JSON display width and height
        GET  /version         JSON protocol and agent
        GET  /frame           JPEG still
        GET  /stream          concatenated JPEGs, close-delimited
        GET  /audio           MP3, close-delimited
        GET  /clipboard       JSON text, image, files
        POST /microphone      PCM16 input for the guest
        POST /display         JSON width and height
        POST /clipboard       JSON ok
      Every request must carry the per-VM bearer token from the seed image.
      """
      import base64, hmac, http.server, json, os, queue, socketserver
      import subprocess, sys, threading, time

      # Bumped whenever this agent's protocol changes. The host reads it from
      # /version and can then tell an OLD image from a BROKEN one, which are
      # different problems with different fixes.
      #   1 -> capture, display mode-set, audio
      #   2 -> + /clipboard (text, image/png, text/uri-list; CLIPBOARD,
      #        PRIMARY and XdndSelection)
      #   3 -> shared MJPEG capture and PCM16 microphone input
      #   4 -> microphone capture sessions (stale chunks/end are ignored)
      PROTOCOL = 4
      AGENT_BUILD = "cc-guest-agent/4"

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

      _streams = {}
      _streams_lock = threading.Lock()

      class MjpegProducer:
          """One ffmpeg capture shared by viewers with identical settings."""
          def __init__(self, key, command):
              self.key = key
              self.subscribers = set()
              self.lock = threading.Lock()
              self.proc = subprocess.Popen(
                  command, env={**os.environ, "DISPLAY": ":0"},
                  stdout=subprocess.PIPE)
              threading.Thread(target=self._run, daemon=True).start()
          def subscribe(self):
              inbox = queue.Queue(maxsize=1)
              # Caller holds _streams_lock. Every attach/detach therefore takes
              # locks in the same order: registry, then producer.
              with self.lock:
                  self.subscribers.add(inbox)
              return inbox

          def unsubscribe(self, inbox):
              # The last-subscriber decision and registry removal are one
              # critical section. Releasing self.lock before taking
              # _streams_lock let a reconnect attach to this producer after it
              # looked empty but before it was removed; this thread then killed
              # the new viewer's encoder.
              with _streams_lock:
                  with self.lock:
                      self.subscribers.discard(inbox)
                      if self.subscribers:
                          return
                      if _streams.get(self.key) is not self:
                          return
                      del _streams[self.key]
              try:
                  self.proc.kill()
              except Exception:
                  pass

          def _publish(self, frame):
              with self.lock:
                  subscribers = tuple(self.subscribers)
              for inbox in subscribers:
                  try:
                      inbox.put_nowait(frame)
                  except queue.Full:
                      try:
                          inbox.get_nowait()
                      except queue.Empty:
                          pass
                      try:
                          inbox.put_nowait(frame)
                      except queue.Full:
                          pass

          def _run(self):
              pending = bytearray()
              try:
                  while True:
                      chunk = self.proc.stdout.read1(65536)
                      if not chunk:
                          break
                      pending.extend(chunk)
                      while True:
                          start = pending.find(b"\xff\xd8")
                          if start < 0:
                              if len(pending) > 1:
                                  del pending[:-1]
                              break
                          end = pending.find(b"\xff\xd9", start + 2)
                          if end < 0:
                              if start:
                                  del pending[:start]
                              if len(pending) > 32 * 1024 * 1024:
                                  pending.clear()
                              break
                          self._publish(bytes(pending[start:end + 2]))
                          del pending[:end + 2]
              finally:
                  try:
                      self.proc.kill()
                      self.proc.wait(timeout=5)
                  except Exception:
                      pass
                  with _streams_lock:
                      if _streams.get(self.key) is self:
                          del _streams[self.key]
                  with self.lock:
                      subscribers = tuple(self.subscribers)
                  for inbox in subscribers:
                      try:
                          inbox.put_nowait(None)
                      except queue.Full:
                          try:
                              inbox.get_nowait()
                              inbox.put_nowait(None)
                          except (queue.Empty, queue.Full):
                              pass

      def subscribe_mjpeg(width, height, fps, qv, dw, dh):
          key = (width, height, fps, qv, dw, dh)
          with _streams_lock:
              producer = _streams.get(key)
              if producer is None:
                  producer = MjpegProducer(key, [
                      "ffmpeg", "-loglevel", "quiet",
                      "-f", "x11grab", "-framerate", str(fps),
                      "-video_size", f"{dw}x{dh}", "-i", ":0",
                      "-vf", scale_filter(width, height),
                      "-q:v", str(qv), "-f", "mjpeg",
                      "-flush_packets", "1", "-",
                  ])
                  _streams[key] = producer
              return producer, producer.subscribe()

      _microphone_lock = threading.Lock()
      _microphone_proc = None
      _microphone_session = None
      _microphone_last_write = 0.0

      def close_microphone():
          global _microphone_proc
          proc, _microphone_proc = _microphone_proc, None
          if proc is None:
              return
          try:
              proc.stdin.close()
          except Exception:
              pass
          try:
              proc.kill()
              proc.wait(timeout=5)
          except Exception:
              pass

      def feed_microphone(raw, rate, channels, session, start=False, end=False):
          global _microphone_proc, _microphone_last_write, _microphone_session
          if not session:
              raise ValueError("microphone session is required")
          with _microphone_lock:
              if start:
                  close_microphone()
                  _microphone_session = session
                  _microphone_last_write = time.monotonic()
                  return
              # A replacement capture announces itself with start=1 before
              # sending PCM. Delayed chunks and end markers from the replaced
              # HTTP client are acknowledged but cannot touch the new process.
              if session != _microphone_session:
                  return
              if end:
                  close_microphone()
                  _microphone_session = None
                  return
              if _microphone_proc is None or _microphone_proc.poll() is not None:
                  close_microphone()
                  _microphone_proc = subprocess.Popen([
                      "pacat", "--playback", "--device=ccin",
                      "--rate", str(rate), "--format=s16le",
                      "--channels", str(channels), "--latency-msec=50",
                  ], stdin=subprocess.PIPE)
              _microphone_proc.stdin.write(raw)
              _microphone_proc.stdin.flush()
              _microphone_last_write = time.monotonic()

      def microphone_watchdog():
          while True:
              time.sleep(1)
              with _microphone_lock:
                  if (_microphone_proc is not None
                          and time.monotonic() - _microphone_last_write > 2):
                      close_microphone()

      threading.Thread(target=microphone_watchdog, daemon=True).start()

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
                  # Identical viewers share one encoder. Each subscriber keeps
                  # only the newest COMPLETE JPEG, so a slow socket adds
                  # neither a second x11grab nor unbounded latency.
                  fps = max(1, min(60, int(args.get("fps", 15))))
                  width = int(args.get("w", 1280))
                  height = int(args.get("h", 800))
                  qv = max(2, 31 - int(args.get("q", 70)) * 30 // 100)
                  dw, dh = display_size()
                  try:
                      producer, inbox = subscribe_mjpeg(
                          width, height, fps, qv, dw, dh)
                  except Exception as e:
                      self._send_json(500, {"error": str(e)})
                      return
                  self._open_stream("video/x-motion-jpeg")
                  try:
                      while True:
                          frame = inbox.get()
                          if frame is None:
                              return
                          self.wfile.write(frame)
                          self.wfile.flush()
                  except (BrokenPipeError, ConnectionResetError):
                      return
                  except Exception:
                      return
                  finally:
                      producer.unsubscribe(inbox)
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
              path, _, query = self.path.partition("?")
              args = dict(p.split("=", 1) for p in query.split("&") if "=" in p)
              if path == "/microphone":
                  try:
                      length = int(self.headers.get("Content-Length", 0))
                  except ValueError:
                      length = -1
                  if length < 0:
                      self._send_json(411, {
                          "error": "Content-Length is required"}); return
                  if length > 128 * 1024:
                      self.close_connection = True
                      self._send_json(413, {
                          "error": "microphone chunk too large"}); return
                  rate = max(8000, min(48000, int(args.get("rate", 16000))))
                  channels = max(1, min(2, int(args.get("channels", 1))))
                  try:
                      feed_microphone(
                          self.rfile.read(length), rate, channels,
                          args.get("session", ""),
                          start=args.get("start") == "1",
                          end=args.get("end") == "1")
                      self._send_json(200, {"ok": True})
                  except Exception as e:
                      self._send_json(500, {"error": str(e)})
                  return
              if path == "/clipboard":
                  self._post_clipboard(); return
              if path != "/display":
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
      # Restricted rigs route desktop apps through the host proxies.
      # Unrestricted rigs have direct slirp egress; leaving the baked proxy
      # variables in place would force Chromium through a policy lane the user
      # explicitly bypassed and can leave it waiting on a dead guestfwd.
      if jq -e '.unrestricted_network == true' /etc/cc-rig.json >/dev/null; then
        sed -i '/^\(http_proxy\|https_proxy\|HTTP_PROXY\|HTTPS_PROXY\|ALL_PROXY\|all_proxy\|no_proxy\|NO_PROXY\)=/d' /etc/environment
        {
          echo "unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY"
          echo "unset ALL_PROXY all_proxy no_proxy NO_PROXY"
        } > /etc/profile.d/cc-rig-proxy.sh
      else
        {
          echo "export http_proxy=\$(jq -r '.http_proxy' /etc/cc-rig.json)"
          echo "export https_proxy=\\\$http_proxy"
          echo "export HTTP_PROXY=\\\$http_proxy"
          echo "export HTTPS_PROXY=\\\$http_proxy"
          echo "export ALL_PROXY=\$(jq -r '.socks_proxy' /etc/cc-rig.json)"
        } > /etc/profile.d/cc-rig-proxy.sh
      fi

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
      Environment=PULSE_SERVER=unix:/run/user/1000/pulse/native
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
      export PATH="/usr/local/bin:/usr/bin:/bin:\$PATH"
      # No blanking, no DPMS: a rig that turns its own screen off looks like
      # a broken stream.
      # Start one persistent PulseAudio server before any desktop app. The
      # browser and the guest agent are the same user and therefore share this
      # socket; relying on whichever client happens to autospawn first left the
      # browser connected to no usable output on some boots.
      pulseaudio --start --exit-idle-time=-1 2>/dev/null || true
      # Same env the wrappers inject, so a terminal in this session can
      # launch the /opt browsers without GPU or a working user-namespace
      # sandbox.
      export MOZ_WEBRENDER=0
      export MOZ_ACCELERATED=0
      export MOZ_DISABLE_CONTENT_SANDBOX=1
      export MOZ_DISABLE_AUTO_UPDATE=1
      export LIBGL_ALWAYS_SOFTWARE=1
      export WEBKIT_DISABLE_SANDBOX=1
      export WEBKIT_DISABLE_COMPOSITING_MODE=1
      xset s off -dpms 2>/dev/null || true
      dbus-update-activation-environment --systemd DISPLAY XAUTHORITY \\
        XDG_CURRENT_DESKTOP XDG_SESSION_TYPE MOZ_WEBRENDER \\
        MOZ_DISABLE_CONTENT_SANDBOX LIBGL_ALWAYS_SOFTWARE \\
        WEBKIT_DISABLE_SANDBOX WEBKIT_DISABLE_COMPOSITING_MODE \\
        2>/dev/null || true
      if command -v startxfce4 >/dev/null 2>&1; then
        export XDG_CURRENT_DESKTOP=XFCE
        startxfce4
      fi
      xsetroot -solid "#1c2226"
      [ -f /usr/share/backgrounds/cc-rig.jpg ] && \\
        command -v feh >/dev/null && \\
        feh --bg-fill /usr/share/backgrounds/cc-rig.jpg &
      exec openbox-session

  # Audio has two virtual devices and no virtio-sound hardware. ccout is the
  # guest's output sink; the agent records its monitor for the viewer. ccin is
  # fed by the viewer's microphone; its monitor is the guest's default
  # source, so apps see it as an ordinary microphone.
  - path: /etc/pulse/default.pa.d/cc-rig.pa
    permissions: '0644'
    content: |
      load-module module-null-sink sink_name=ccout sink_properties=device.description=CC-rig-output
      load-module module-null-sink sink_name=ccin sink_properties=device.description=CC-rig-input
      set-default-sink ccout
      set-default-source ccin.monitor

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

  # Three windowed engines, none of them Ubuntu's snap stubs. The dock globe
  # is exo-open --launch WebBrowser and stays Firefox (the helper below).
  # Chromium, Firefox and WebKit each have their own wrapper + desktop file
  # so Applications → Internet can open the engine you meant.
  - path: /usr/local/bin/cc-firefox
    permissions: '0755'
    content: |
      #!/bin/bash
      if [ ! -x /opt/firefox/firefox ]; then
        echo "cc-firefox: Firefox is not installed at /opt/firefox" >&2
        exit 127
      fi
      export MOZ_WEBRENDER="\${MOZ_WEBRENDER:-0}"
      export MOZ_ACCELERATED="\${MOZ_ACCELERATED:-0}"
      export MOZ_DISABLE_CONTENT_SANDBOX="\${MOZ_DISABLE_CONTENT_SANDBOX:-1}"
      export MOZ_DISABLE_AUTO_UPDATE="\${MOZ_DISABLE_AUTO_UPDATE:-1}"
      export LIBGL_ALWAYS_SOFTWARE="\${LIBGL_ALWAYS_SOFTWARE:-1}"
      exec /opt/firefox/firefox "\$@"
  - path: /usr/local/bin/cc-chromium
    permissions: '0755'
    content: |
      #!/bin/bash
      if [ ! -x /opt/chromium/chrome ]; then
        echo "cc-chromium: Chromium is not installed at /opt/chromium" >&2
        exit 127
      fi
      export LIBGL_ALWAYS_SOFTWARE="\${LIBGL_ALWAYS_SOFTWARE:-1}"
      export VK_ICD_FILENAMES="\${VK_ICD_FILENAMES:-/dev/null}"
      ozone=x11
      for arg in "\$@"; do
        case "\$arg" in
          --headless|--headless=*|--dump-dom) ozone=headless ;;
        esac
      done
      if [ -z "\${DISPLAY:-}" ]; then
        ozone=headless
      fi
      exec /opt/chromium/chrome --no-sandbox --disable-dev-shm-usage --disable-gpu --disable-features=Vulkan --enable-unsafe-swiftshader --use-gl=angle --use-angle=swiftshader --ozone-platform="\$ozone" --no-first-run --no-default-browser-check --disable-search-engine-choice-screen "\$@"
  - path: /usr/local/bin/cc-webkit
    permissions: '0755'
    content: |
      #!/bin/bash
      if ! command -v epiphany >/dev/null 2>&1; then
        echo "cc-webkit: epiphany (WebKitGTK) is not installed" >&2
        exit 127
      fi
      export WEBKIT_DISABLE_SANDBOX="\${WEBKIT_DISABLE_SANDBOX:-1}"
      export WEBKIT_DISABLE_COMPOSITING_MODE="\${WEBKIT_DISABLE_COMPOSITING_MODE:-1}"
      exec epiphany "\$@"
  - path: /usr/local/bin/cc-web-browser
    permissions: '0755'
    content: |
      #!/bin/bash
      exec /usr/local/bin/cc-firefox "\$@"
  - path: /usr/share/xfce4/helpers/cc-web-browser.desktop
    permissions: '0644'
    content: |
      [Desktop Entry]
      Version=1.0
      Icon=/opt/firefox/browser/chrome/icons/default/default128.png
      Type=X-XFCE-Helper
      Name=Web Browser
      StartupNotify=true
      X-XFCE-Binaries=cc-web-browser;
      X-XFCE-Category=WebBrowser
      X-XFCE-Commands=%B;
      X-XFCE-CommandsWithParameter=%B "%s";
  - path: /etc/xdg/xfce4/helpers.rc
    permissions: '0644'
    content: |
      WebBrowser=cc-web-browser
      FileManager=Thunar
      TerminalEmulator=xfce4-terminal
  - path: /usr/share/applications/cc-web-browser.desktop
    permissions: '0644'
    content: |
      [Desktop Entry]
      Type=Application
      Name=Web Browser
      Exec=/usr/local/bin/cc-web-browser %U
      Icon=/opt/firefox/browser/chrome/icons/default/default128.png
      Terminal=false
      NoDisplay=true
      Categories=Network;WebBrowser;
      MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
      StartupNotify=true
  - path: /usr/share/applications/cc-chromium.desktop
    permissions: '0644'
    content: |
      [Desktop Entry]
      Type=Application
      Name=Chromium
      Comment=Chrome for Testing
      Exec=/usr/local/bin/cc-chromium %U
      Icon=/opt/chromium/product_logo_48.png
      Terminal=false
      Categories=Network;WebBrowser;
      MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
      StartupNotify=true
  - path: /usr/share/applications/cc-firefox.desktop
    permissions: '0644'
    content: |
      [Desktop Entry]
      Type=Application
      Name=Firefox
      Exec=/usr/local/bin/cc-firefox %U
      Icon=/opt/firefox/browser/chrome/icons/default/default128.png
      Terminal=false
      Categories=Network;WebBrowser;
      MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
      StartupNotify=true
  - path: /usr/share/applications/cc-webkit.desktop
    permissions: '0644'
    content: |
      [Desktop Entry]
      Type=Application
      Name=WebKit
      Comment=GNOME Web (WebKitGTK)
      Exec=/usr/local/bin/cc-webkit %U
      Icon=org.gnome.Epiphany
      Terminal=false
      Categories=Network;WebBrowser;
      MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
      StartupNotify=true
  - path: /etc/xdg/mimeapps.list
    permissions: '0644'
    content: |
      [Default Applications]
      text/html=cc-web-browser.desktop
      x-scheme-handler/http=cc-web-browser.desktop
      x-scheme-handler/https=cc-web-browser.desktop

  # Tarball Firefox reads /etc/firefox/policies and installdir/distribution.
  # Empty OverrideFirstRunPage turns about:welcome off; DontCheckDefaultBrowser
  # is the startup prompt; SkipTermsOfUse is the ToU gate on 136+.
  - path: /etc/firefox/policies/policies.json
    permissions: '0644'
    content: |
      {
        "policies": {
          "DontCheckDefaultBrowser": true,
          "OverrideFirstRunPage": "",
          "OverridePostUpdatePage": "",
          "SkipTermsOfUse": true,
          "DisableProfileImport": true,
          "UserMessaging": {
            "WhatsNew": false,
            "MoreFromMozilla": false,
            "SkipOnboarding": true,
            "Locked": true
          }
        }
      }
  # Chrome for Testing reads /etc/opt/chrome_for_testing, not /etc/opt/chrome.
  # DefaultBrowserSettingEnabled false is the prompt; the wrapper also passes
  # --no-first-run and --no-default-browser-check. initial_preferences is the
  # first-run file next to the binary (copied after the zip is extracted).
  - path: /etc/opt/chrome_for_testing/policies/managed/cc-rig.json
    permissions: '0644'
    content: |
      {
        "DefaultBrowserSettingEnabled": false,
        "BrowserSignin": 0,
        "PromotionalTabsEnabled": false,
        "WelcomePageOnOSUpgradeEnabled": false,
        "PrivacySandboxPromptEnabled": false
      }
  - path: /etc/opt/chrome/policies/managed/cc-rig.json
    permissions: '0644'
    content: |
      {
        "DefaultBrowserSettingEnabled": false,
        "BrowserSignin": 0,
        "PromotionalTabsEnabled": false,
        "WelcomePageOnOSUpgradeEnabled": false,
        "PrivacySandboxPromptEnabled": false
      }
  - path: /etc/chromium/policies/managed/cc-rig.json
    permissions: '0644'
    content: |
      {
        "DefaultBrowserSettingEnabled": false,
        "BrowserSignin": 0,
        "PromotionalTabsEnabled": false,
        "WelcomePageOnOSUpgradeEnabled": false,
        "PrivacySandboxPromptEnabled": false
      }
  - path: /usr/share/cc-rig/chromium-initial-preferences
    permissions: '0644'
    content: |
      {
        "distribution": {
          "skip_first_run_ui": true,
          "make_chrome_default": false,
          "make_chrome_default_for_user": false,
          "import_bookmarks": false,
          "import_history": false,
          "suppress_first_run_bubble": true,
          "suppress_first_run_default_browser_prompt": true
        },
        "first_run_tabs": []
      }
  - path: /usr/share/glib-2.0/schemas/99-cc-rig.gschema.override
    permissions: '0644'
    content: |
      [org.gnome.Epiphany]
      ask-for-default=false

  - path: /etc/systemd/system/cc-x11.service
    content: |
      [Unit]
      Description=Control Center rig desktop
      After=cc-rig-seed.service
      [Service]
      # This is a system service with User=cc, not a PAM login. systemd does
      # not read /etc/environment for it automatically, so without this the
      # desktop and every browser launched inside it bypass the only permitted
      # egress path and have no network under QEMU's restrict=on.
      EnvironmentFile=-/etc/environment
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
  # Egress proxy for every runtime desktop session. cc-x11.service reads this
  # file explicitly through EnvironmentFile (it is a system service, not a PAM
  # login); shells receive the same values through profile.d. Append it after
  # package installation, not in write_files: these per-rig proxy addresses do
  # not exist during the BUILD boot (open NAT, no guestfwd), and baking them
  # earlier pointed apt/snapd at a proxy that was not there — the snap store
  # retried for 40 minutes and the build died on its watchdog.
  # Remove the builder boot's datasource-generated profile. Runtime networking
  # must come only from 60-cc-rig.yaml so a diagnostic cidata cannot make a
  # broken production image appear healthy.
  - rm -f /etc/netplan/50-cloud-init.yaml
  - netplan generate
  - systemctl enable NetworkManager.service
  # Firefox and Chromium archives ride on a second ISO labelled CCBROWSERS,
  # not on cidata. Stuffing those ~230 MB zips into the NoCloud volume made
  # cloud-init find the disk, run local/network, and never apply user-data.
  # Filenames are ISO 9660 8.3 (firefox.txz, chrome.zip): hdiutil's ISO has
  # Joliet but no Rock Ridge, so a name with two dots was mangled on the
  # guest mount. WebKit is Epiphany from apt.
  # The volume is often already mounted at /mnt/ccbrowsers; a second mount
  # is ignored and extract still runs.
  - sh -c 'mkdir -p /mnt/ccbrowsers /opt; mount -o ro /dev/disk/by-label/CCBROWSERS /mnt/ccbrowsers; tar -C /opt -xf /mnt/ccbrowsers/firefox.txz && unzip -q -o /mnt/ccbrowsers/chrome.zip -d /opt && test -d /opt/chrome-linux-arm64 && mv /opt/chrome-linux-arm64 /opt/chromium; test -d /opt/chrome-linux64 && mv /opt/chrome-linux64 /opt/chromium; test -x /opt/firefox/firefox && test -x /opt/chromium/chrome && ln -sfn /opt/firefox/firefox /usr/local/bin/firefox && chmod -R a+rX /opt/firefox /opt/chromium'
  - sh -c 'mkdir -p /opt/firefox/distribution /opt/chromium/policies/managed && cp /etc/firefox/policies/policies.json /opt/firefox/distribution/policies.json && cp /etc/opt/chrome_for_testing/policies/managed/cc-rig.json /opt/chromium/policies/managed/cc-rig.json && cp /usr/share/cc-rig/chromium-initial-preferences /opt/chromium/initial_preferences && glib-compile-schemas /usr/share/glib-2.0/schemas'
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
  - sh -c 'update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/local/bin/cc-web-browser 200'
  - sh -c 'update-alternatives --install /usr/bin/gnome-www-browser gnome-www-browser /usr/local/bin/cc-web-browser 200'
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
  # Only emit the completion marker when the three browsers actually landed.
  # cloud-init string runcmds do not abort the rest of the list, so a failed
  # extract used to still print CC_RIG_BUILD_OK and ship a desktop with no
  # /opt/firefox.
  - sh -c 'if test -x /opt/firefox/firefox && test -x /opt/chromium/chrome && command -v epiphany >/dev/null; then echo "CC_RIG_BUILD_OK ${IMAGE_ID}" > /dev/console; else echo "CC_RIG_BUILD_FAIL browsers" > /dev/console; ls -la /dev/disk/by-label /mnt/ccbrowsers /opt > /dev/console 2>&1; fi'
  - poweroff
CLOUDINIT

printf '#cloud-config\ninstance-id: cc-rig-build\nlocal-hostname: cc-rig-build\n' \
  > "$WORK_DIR/meta-data"

# ── Build the seed and run the one-shot customisation boot ──────────────────
# cidata is user-data + meta-data only. Browser archives go on a second ISO
# labelled CCBROWSERS: a 230 MB NoCloud volume made cloud-init skip applying
# the build config while still booting cleanly.
SEED_DIR="$WORK_DIR/seed"
BROWSERS_DIR="$WORK_DIR/browsers"
mkdir -p "$SEED_DIR" "$BROWSERS_DIR"
cp "$WORK_DIR/user-data" "$WORK_DIR/meta-data" "$SEED_DIR/"

# Firefox and Chromium are fetched HERE and checksummed. The guest only
# extracts; a 403 from Mozilla during the customize boot used to skip
# /opt/firefox while still completing.
echo "==> downloading Firefox ${FIREFOX_VERSION} (${FIREFOX_PLATFORM})"
curl -fSL --retry 5 --retry-delay 2 --progress-bar \
  -o "$BROWSERS_DIR/firefox.txz" "$FIREFOX_URL"
echo "==> downloading Chromium ${CHROMIUM_VERSION} (${CHROMIUM_PLATFORM})"
curl -fSL --retry 5 --retry-delay 2 --progress-bar \
  -o "$BROWSERS_DIR/chrome.zip" "$CHROMIUM_URL"
if command -v sha256sum >/dev/null 2>&1; then
  echo "${FIREFOX_SHA256}  $BROWSERS_DIR/firefox.txz" | sha256sum -c
  echo "${CHROMIUM_SHA256}  $BROWSERS_DIR/chrome.zip" | sha256sum -c
else
  actual_ff="$(shasum -a 256 "$BROWSERS_DIR/firefox.txz" | awk '{print $1}')"
  actual_ch="$(shasum -a 256 "$BROWSERS_DIR/chrome.zip" | awk '{print $1}')"
  if [[ "$actual_ff" != "$FIREFOX_SHA256" || "$actual_ch" != "$CHROMIUM_SHA256" ]]; then
    echo "browser archive checksum mismatch" >&2
    echo "  firefox expected $FIREFOX_SHA256 got $actual_ff" >&2
    echo "  chrome  expected $CHROMIUM_SHA256 got $actual_ch" >&2
    exit 1
  fi
  echo "firefox.txz: OK"
  echo "chrome.zip: OK"
fi

# <dir> <label> <out>. The volume LABEL is how the guest finds each disk.
# cidata must be exactly that string or NoCloud falls back to DataSourceNone
# and hands back a stock image. CCBROWSERS is the extract payload only.
make_iso() {
  local src="$1" label="$2" out="$3"
  if command -v cloud-localds >/dev/null 2>&1 && [[ "$label" == "cidata" ]]; then
    cloud-localds "$out" "$src/user-data" "$src/meta-data"
  elif command -v genisoimage >/dev/null 2>&1; then
    genisoimage -output "$out" -volid "$label" -joliet -rock "$src"/* >/dev/null
  elif command -v mkisofs >/dev/null 2>&1; then
    mkisofs -output "$out" -volid "$label" -joliet -rock "$src"/* >/dev/null
  elif command -v xorriso >/dev/null 2>&1; then
    xorriso -as mkisofs -output "$out" -volid "$label" -joliet -rock \
      "$src"/* >/dev/null
  elif command -v hdiutil >/dev/null 2>&1; then
    # macOS with no cloud-image tooling. Set every volume name this accepts:
    # -default-volume-name alone has been observed not to reach the ISO9660
    # volume id, which is the one NoCloud (and udev by-label) actually reads.
    rm -f "$out"
    hdiutil makehybrid -o "$out" -iso -joliet \
      -default-volume-name "$label" \
      -iso-volume-name "$label" \
      -joliet-volume-name "$label" \
      "$src" >/dev/null
  else
    echo "need one of: cloud-localds, genisoimage, mkisofs, xorriso, hdiutil" >&2
    exit 1
  fi
}

SEED_ISO="$WORK_DIR/seed.iso"
BROWSERS_ISO="$WORK_DIR/browsers.iso"
make_iso "$SEED_DIR" cidata "$SEED_ISO"
make_iso "$BROWSERS_DIR" CCBROWSERS "$BROWSERS_ISO"

# Verify the cidata label before spending ten minutes finding out it was wrong.
if command -v file >/dev/null 2>&1; then
  if ! file "$SEED_ISO" | grep -qi "cidata"; then
    echo "the cloud-init seed did not come out labelled 'cidata':" >&2
    file "$SEED_ISO" >&2
    echo "The guest would ignore it and build an unmodified image." >&2
    exit 1
  fi
fi

# A cidata that has grown to archive size is the failure that skipped
# user-data last time. Wallpaper + yaml belong here; the browser zips do not.
SEED_BYTES="$(wc -c < "$SEED_ISO" | tr -d ' ')"
if [[ "$SEED_BYTES" -gt 16777216 ]]; then
  echo "cidata seed is $SEED_BYTES bytes; browser archives must not ride on it." >&2
  echo "  seed: $SEED_ISO" >&2
  exit 1
fi

echo "==> running the customisation boot (this installs packages; ~15 minutes)"
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
  -drive "file=$BROWSERS_ISO,if=virtio,format=raw,readonly=on" \
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
mv -f "$OUT_IMG.compact" "$OUT_IMG"

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
