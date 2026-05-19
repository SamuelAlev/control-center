#!/usr/bin/env bash
#
# Boots a built rig image and checks that its guest agent actually answers.
#
# `build_image.sh` proves cloud-init RAN — it does not prove the result works.
# The two are genuinely different: an image can apply every line of config and
# still ship an agent that dies on startup, which is exactly what shipped once
# (the seed file landed 0600 root while the agent runs unprivileged, so it
# crash-looped and the host waited out its whole 120s timeout on every rig).
# That failure is invisible until a rig is opened, and by then the image looks
# fine and the fault looks like the host's.
#
#   scripts/rigs/verify_image.sh build/rig-images/cc-desktop-linux-arm64.qcow2
#
# Exits non-zero and prints the guest's own journal when the agent is not
# serving, so a failure names itself instead of needing this dance by hand.

set -euo pipefail

IMAGE="${1:-}"
if [[ -z "$IMAGE" || ! -f "$IMAGE" ]]; then
  echo "usage: $0 <image.qcow2>" >&2
  exit 2
fi

TIMEOUT="${CC_RIG_VERIFY_TIMEOUT:-240}"
AGENT_PORT="${CC_RIG_VERIFY_PORT:-17811}"
SSH_PORT="${CC_RIG_VERIFY_SSH_PORT:-17822}"
TOKEN="verify-$$-$RANDOM"

case "$(uname -m)" in
  arm64|aarch64) QEMU_BIN=qemu-system-aarch64; ARCH=arm64 ;;
  *)             QEMU_BIN=qemu-system-x86_64;  ARCH=amd64 ;;
esac
command -v "$QEMU_BIN" >/dev/null || { echo "missing $QEMU_BIN" >&2; exit 1; }

WORK_DIR="$(mktemp -d)"
cleanup() {
  [[ -n "${QEMU_PID:-}" ]] && kill "$QEMU_PID" 2>/dev/null || true
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

# ── The per-VM seed, exactly as cc_server builds it ─────────────────────────
mkdir -p "$WORK_DIR/seed" "$WORK_DIR/diag"
ssh-keygen -t ed25519 -N '' -C cc-rig-verify -f "$WORK_DIR/id" >/dev/null 2>&1
cat > "$WORK_DIR/seed/cc-rig.json" <<EOF
{
  "rig_id": "verify",
  "authorized_key": "$(cat "$WORK_DIR/id.pub")",
  "agent_token": "$TOKEN",
  "credential_secret": "verify-secret",
  "egress_allowlist": [],
  "http_proxy": "http://10.0.2.2:18080",
  "socks_proxy": "socks5://10.0.2.2:11080",
  "credential_endpoint": "http://10.0.2.2:18081/credential"
}
EOF

# A second, cidata-labelled seed that dumps the guest's own view to the
# console. cloud-init was cleaned at build time, so it runs again here — which
# means a failure explains itself instead of leaving a silent VM.
cat > "$WORK_DIR/diag/user-data" <<'EOF'
#cloud-config
runcmd:
  - echo "=====CCVERIFY BEGIN=====" > /dev/console
  - ls -l /etc/cc-rig.json > /dev/console 2>&1 || echo "NO SEED" > /dev/console
  - systemctl status cc-guest-agent --no-pager -n 5 > /dev/console 2>&1
  - journalctl -u cc-guest-agent --no-pager -n 25 > /dev/console 2>&1
  # The surface unit too: an image whose agent is healthy can still be useless
  # (X refused a VT, the session died on startup), and only its own journal
  # says which.
  - journalctl -u cc-x11 --no-pager -n 20 > /dev/console 2>&1 || true
  - ss -tlnp > /dev/console 2>&1 || true
  - echo "=====CCVERIFY END=====" > /dev/console
EOF
printf 'instance-id: ccverify\nlocal-hostname: ccverify\n' \
  > "$WORK_DIR/diag/meta-data"

make_iso() { # <dir> <label> <out>
  if command -v cloud-localds >/dev/null 2>&1 && [[ "$2" == "cidata" ]]; then
    cloud-localds "$3" "$1/user-data" "$1/meta-data"
  elif command -v genisoimage >/dev/null 2>&1; then
    genisoimage -output "$3" -volid "$2" -joliet -rock "$1"/* >/dev/null 2>&1
  elif command -v mkisofs >/dev/null 2>&1; then
    mkisofs -output "$3" -volid "$2" -joliet -rock "$1"/* >/dev/null 2>&1
  elif command -v hdiutil >/dev/null 2>&1; then
    rm -f "$3"
    hdiutil makehybrid -o "$3" -iso -joliet \
      -default-volume-name "$2" -iso-volume-name "$2" \
      -joliet-volume-name "$2" "$1" >/dev/null
  else
    echo "no ISO builder available" >&2; exit 1
  fi
}
make_iso "$WORK_DIR/seed" CCRIG "$WORK_DIR/seed.iso"
make_iso "$WORK_DIR/diag" cidata "$WORK_DIR/diag.iso"

# ── Boot a throwaway overlay so verification cannot alter the image ─────────
qemu-img create -f qcow2 -F qcow2 -b "$(cd "$(dirname "$IMAGE")" && pwd)/$(basename "$IMAGE")" \
  "$WORK_DIR/overlay.qcow2" >/dev/null

MACHINE_ARGS=()
if [[ "$ARCH" == "arm64" ]]; then
  FW=""
  while IFS= read -r dir; do
    [[ -f "$dir/edk2-aarch64-code.fd" ]] && { FW="$dir/edk2-aarch64-code.fd"; break; }
  done < <("$QEMU_BIN" -L help 2>/dev/null || true)
  [[ -n "$FW" ]] || { echo "no aarch64 firmware found" >&2; exit 1; }
  cp "$FW" "$WORK_DIR/fw.fd"; chmod u+w "$WORK_DIR/fw.fd"
  MACHINE_ARGS=(-machine virt,highmem=on -cpu host
                -drive "if=pflash,format=raw,readonly=on,file=$WORK_DIR/fw.fd")
fi
ACCEL=tcg
[[ "$(uname -s)" == "Darwin" ]] && ACCEL=hvf
[[ -r /dev/kvm ]] && ACCEL=kvm

BOOT_LOG="$WORK_DIR/boot.log"
echo "==> booting $(basename "$IMAGE") to check its guest agent"
"$QEMU_BIN" -accel "$ACCEL" "${MACHINE_ARGS[@]}" -m 2048 -smp 2 \
  -display none -serial "file:$BOOT_LOG" \
  -drive "file=$WORK_DIR/overlay.qcow2,if=virtio,format=qcow2" \
  -drive "file=$WORK_DIR/seed.iso,if=virtio,format=raw,readonly=on" \
  -drive "file=$WORK_DIR/diag.iso,if=virtio,format=raw,readonly=on" \
  -netdev "user,id=n0,hostfwd=tcp:127.0.0.1:$AGENT_PORT-:7811,hostfwd=tcp:127.0.0.1:$SSH_PORT-:22" \
  -device virtio-net-pci,netdev=n0 \
  -device virtio-gpu-pci -device virtio-tablet-pci -device virtio-keyboard-pci &
# The GPU/input devices mirror the runtime launch: without a virtio-gpu the
# desktop image's X exits "no screens found" and the verifier fails an image
# that is actually fine — there was simply no screen in the VERIFY boot.
QEMU_PID=$!

# ── Poll the agent the same way the host does ──────────────────────────────
deadline=$(( SECONDS + TIMEOUT ))
while (( SECONDS < deadline )); do
  if ! kill -0 "$QEMU_PID" 2>/dev/null; then
    echo "==> the VM exited before its agent answered" >&2
    break
  fi
  # -f so a non-2xx is a failure; the exit status is the whole check, and a
  # pipe here would report the LAST command's status instead of curl's.
  if body=$(curl -fsS -m 5 -H "Authorization: Bearer $TOKEN" \
      "http://127.0.0.1:$AGENT_PORT/health" 2>/dev/null); then
    echo "==> guest agent answered: $body"
    # For the DESKTOP image, /health is not the whole claim: it answers even
    # when X never comes up (the wrapper refuses a non-console X by default),
    # and an image that cannot produce a frame is exactly as broken as one
    # whose agent is down — it just fails later, inside a rig. Keep polling
    # within the same deadline: X starts seconds after the agent does.
    if [[ "$(basename "$IMAGE")" == *desktop* ]]; then
      while (( SECONDS < deadline )); do
        frame_bytes=$(curl -fsS -m 10 -H "Authorization: Bearer $TOKEN" \
          "http://127.0.0.1:$AGENT_PORT/frame?w=320&h=200&q=60" \
          2>/dev/null | wc -c | tr -d ' ') || frame_bytes=0
        if (( frame_bytes > 1000 )); then
          echo "==> capture works ($frame_bytes bytes)"
          # A frame is not a session: GNOME's "Oh no! Something has gone
          # wrong" screen photographs beautifully, and one build shipped
          # because the verifier photographed exactly that. The fail screen
          # has a name in the process table, so ask the guest directly.
          echo "==> checking the session actually survived"
          sleep 15
          session=$(ssh -i "$WORK_DIR/id" -p "$SSH_PORT" \
            -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            -o LogLevel=ERROR -o BatchMode=yes -o ConnectTimeout=10 \
            cc@127.0.0.1 \
            'if pgrep -f "gnome-session-[f]ailed" >/dev/null; then echo WHALE; \
             elif pgrep -x xfce4-session >/dev/null; then echo XFCE; \
             elif pgrep -x gnome-shell >/dev/null; then echo GNOME; \
             elif pgrep -x openbox >/dev/null; then echo OPENBOX; \
             else echo NONE; fi' 2>/dev/null) || session=UNREACHABLE
          case "$session" in
            XFCE)    echo "==> XFCE session is up" ;;
            GNOME)   echo "==> GNOME session is up" ;;
            OPENBOX) echo "==> openbox fallback session is up (the desktop did not start)" ;;
            WHALE)
              echo "==> FAILED: the session collapsed into GNOME's fail" >&2
              echo "==> screen (gnome-session-failed is running)." >&2
              break ;;
            *)
              echo "==> FAILED: no window session process found ($session)." >&2
              break ;;
          esac
          # The clipboard, round-tripped. It is checked HERE rather than
          # assumed from the package list because every way it breaks is
          # invisible from outside: xclip missing, xclip unable to reach :0,
          # or the agent running as a user with no X connection. All three
          # leave /health and /frame perfectly happy and copy/paste dead.
          echo "==> checking the clipboard round-trips"
          probe="ccverify-clipboard-$$"
          if curl -fsS -m 10 -H "Authorization: Bearer $TOKEN" \
               -H 'Content-Type: application/json' \
               -d "{\"text\":\"$probe\"}" \
               "http://127.0.0.1:$AGENT_PORT/clipboard" >/dev/null 2>&1 \
             && curl -fsS -m 10 -H "Authorization: Bearer $TOKEN" \
               "http://127.0.0.1:$AGENT_PORT/clipboard?sel=clipboard" \
               2>/dev/null | grep -q "$probe"; then
            echo "==> clipboard works"
          else
            echo "==> FAILED: the clipboard did not round-trip." >&2
            echo "==> (is xclip installed, and can the agent reach :0?)" >&2
            break
          fi
          echo "OK: $(basename "$IMAGE")"
          exit 0
        fi
        sleep 5
      done
      if (( SECONDS >= deadline )); then
        echo "==> FAILED: the agent serves /health but never produced a frame" >&2
        echo "==> — the X session inside the image is not coming up." >&2
      fi
      break
    fi
    echo "OK: $(basename "$IMAGE")"
    exit 0
  fi
  sleep 5
done

echo >&2
echo "==> FAILED: the guest agent never answered within ${TIMEOUT}s." >&2
# The agent is fail-closed: with no usable seed it answers 503 with a JSON
# cause naming which of the seed failures happened. `-f` above swallows that
# body, so ask once more without it — the reply IS the diagnosis, and it beats
# reading a whole console log to find out the seed never mounted.
if last=$(curl -sS -m 5 -H "Authorization: Bearer $TOKEN" \
    "http://127.0.0.1:$AGENT_PORT/health" 2>&1); then
  [[ -n "$last" ]] && echo "==> the agent's last reply: $last" >&2
fi
echo "==> the guest's own view:" >&2
tr -cd '\11\12\15\40-\176' < "$BOOT_LOG" \
  | sed -n '/CCVERIFY BEGIN/,/CCVERIFY END/p' >&2 || true
FAIL_LOG="$(dirname "$IMAGE")/$(basename "${IMAGE%.qcow2}")-verify-failed.log"
cp "$BOOT_LOG" "$FAIL_LOG" 2>/dev/null || true
echo >&2
echo "Full console log: $FAIL_LOG" >&2
exit 1
