#!/usr/bin/env bash
#
# Prepares the mobile rig surface: an Android SDK, a system image and a virtual
# device the server can drive over adb.
#
# The mobile surface is the odd one out. The computer surface boots a qcow2 we
# build (scripts/rigs/build_image.sh) and the terminal and browser surfaces
# boot digest-pinned OCI images smolvm pulls — every one of them an artifact
# the app manages. Android is not an image we can ship: the emulator, its
# system images and their licences come from Google's SDK, so the honest thing
# is to install that SDK rather than to pretend there is a "download" button
# for it.
#
#   scripts/rigs/setup_android.sh          # install the SDK + create a device
#   scripts/rigs/setup_android.sh start    # boot the device and wait for it
#   scripts/rigs/setup_android.sh status   # what is installed / running
#
# Nothing here runs as root and nothing is installed outside the SDK directory.

set -euo pipefail

COMMAND="${1:-install}"

# ── Where the SDK lives ─────────────────────────────────────────────────────
# Respect an existing install before inventing a second one: an operator who
# has Android Studio already has several GB of system images, and a private
# copy under our own directory would download all of it again.
if [[ -n "${ANDROID_HOME:-}" ]]; then
  SDK_ROOT="$ANDROID_HOME"
elif [[ -n "${ANDROID_SDK_ROOT:-}" ]]; then
  SDK_ROOT="$ANDROID_SDK_ROOT"
elif [[ -d "$HOME/Library/Android/sdk" ]]; then
  SDK_ROOT="$HOME/Library/Android/sdk"
elif [[ -d "$HOME/Android/Sdk" ]]; then
  SDK_ROOT="$HOME/Android/Sdk"
elif [[ "$(uname -s)" == "Darwin" ]]; then
  SDK_ROOT="$HOME/Library/Android/sdk"
else
  SDK_ROOT="$HOME/Android/Sdk"
fi

AVD_NAME="${CC_RIG_AVD:-cc_rig}"

case "$(uname -m)" in
  arm64|aarch64) ABI="arm64-v8a" ;;
  *)             ABI="x86_64" ;;
esac

# API 34 (Android 14): current enough that a modern app runs, old enough that
# the system image is published for both ABIs.
API_LEVEL="${CC_RIG_ANDROID_API:-34}"
SYSTEM_IMAGE="system-images;android-$API_LEVEL;google_apis;$ABI"

SDKMANAGER="$SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"
AVDMANAGER="$SDK_ROOT/cmdline-tools/latest/bin/avdmanager"
ADB="$SDK_ROOT/platform-tools/adb"
EMULATOR="$SDK_ROOT/emulator/emulator"

have() { command -v "$1" >/dev/null 2>&1; }

# ── status ──────────────────────────────────────────────────────────────────
if [[ "$COMMAND" == "status" ]]; then
  echo "SDK root:      $SDK_ROOT"
  echo "sdkmanager:    $([[ -x "$SDKMANAGER" ]] && echo yes || echo no)"
  echo "adb:           $([[ -x "$ADB" ]] && echo yes || echo "$(have adb && echo "on PATH" || echo no)")"
  echo "emulator:      $([[ -x "$EMULATOR" ]] && echo yes || echo no)"
  if [[ -x "$EMULATOR" ]]; then
    echo "AVDs:          $("$EMULATOR" -list-avds 2>/dev/null | tr '\n' ' ')"
  fi
  if [[ -x "$ADB" ]]; then
    echo "devices:"
    "$ADB" devices | tail -n +2 | sed '/^$/d;s/^/  /'
  fi
  exit 0
fi

# ── start ───────────────────────────────────────────────────────────────────
if [[ "$COMMAND" == "start" ]]; then
  [[ -x "$EMULATOR" ]] || { echo "no emulator installed; run: $0" >&2; exit 1; }
  # `start` talks to adb on every path below, so check it here rather than
  # letting the first use fail as "command not found" after the emulator has
  # already been launched into the background.
  [[ -x "$ADB" ]] || { echo "no adb installed; run: $0" >&2; exit 1; }
  if "$ADB" devices | tail -n +2 | grep -q "device$"; then
    echo "A device is already attached. Settings → Server → Enclosures will"
    echo "show the mobile surface as available."
    exit 0
  fi
  AVD="$("$EMULATOR" -list-avds 2>/dev/null | head -1)"
  [[ -n "$AVD" ]] || { echo "no AVD to start; run: $0" >&2; exit 1; }
  echo "Starting $AVD…"
  # Detached with no window: the server talks to it over adb, and a stray
  # emulator window on the operator's desktop is not part of the deal.
  nohup "$EMULATOR" -avd "$AVD" -no-window -no-audio -no-boot-anim \
    >/tmp/cc-rig-emulator.log 2>&1 &
  echo "Waiting for it to come up (this takes a minute)…"
  "$ADB" wait-for-device
  # wait-for-device returns as soon as adb can talk to it, which is well before
  # the framework is up; asking a half-booted device for a view dump fails in
  # ways that look like our bug rather than like an unfinished boot.
  for _ in $(seq 1 120); do
    if [[ "$("$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]]; then
      echo "Ready. The mobile surface is now available."
      exit 0
    fi
    sleep 2
  done
  echo "The device attached but never finished booting; see /tmp/cc-rig-emulator.log" >&2
  exit 1
fi

if [[ "$COMMAND" != "install" ]]; then
  echo "usage: $0 [install|start|status]" >&2
  exit 2
fi

# ── install ─────────────────────────────────────────────────────────────────
echo "Android SDK root: $SDK_ROOT"

if ! have java; then
  echo "missing required tool: java (the SDK's command-line tools need a JDK)" >&2
  echo "  macOS:  brew install --cask temurin" >&2
  echo "  Debian: sudo apt-get install default-jdk" >&2
  exit 1
fi

if [[ ! -x "$SDKMANAGER" ]]; then
  echo "Installing the SDK command-line tools…"
  have curl || { echo "missing required tool: curl" >&2; exit 1; }
  have unzip || { echo "missing required tool: unzip" >&2; exit 1; }

  case "$(uname -s)" in
    Darwin) TOOLS_OS=mac ;;
    Linux)  TOOLS_OS=linux ;;
    *) echo "unsupported host for the Android emulator: $(uname -s)" >&2; exit 1 ;;
  esac
  # Pinned rather than "latest": an unpinned bootstrap means the toolchain
  # changes under you between two machines set up a week apart.
  TOOLS_VERSION="${CC_RIG_CMDLINE_TOOLS:-11076708}"
  TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-${TOOLS_OS}-${TOOLS_VERSION}_latest.zip"

  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT
  echo "  $TOOLS_URL"
  curl -fSL --retry 3 -o "$TMP_DIR/tools.zip" "$TOOLS_URL"
  unzip -q "$TMP_DIR/tools.zip" -d "$TMP_DIR"
  # The zip unpacks as `cmdline-tools/`; the SDK expects it at
  # `cmdline-tools/latest/`, and sdkmanager refuses to run from anywhere else.
  mkdir -p "$SDK_ROOT/cmdline-tools"
  rm -rf "$SDK_ROOT/cmdline-tools/latest"
  mv "$TMP_DIR/cmdline-tools" "$SDK_ROOT/cmdline-tools/latest"
fi

echo
echo "Google's SDK requires accepting their licences. Review them as they scroll."
yes | "$SDKMANAGER" --sdk_root="$SDK_ROOT" --licenses >/dev/null || true

echo "Installing platform-tools, the emulator and $SYSTEM_IMAGE…"
echo "(this is a few GB and takes a while)"
"$SDKMANAGER" --sdk_root="$SDK_ROOT" \
  "platform-tools" "emulator" "platforms;android-$API_LEVEL" "$SYSTEM_IMAGE"

if "$EMULATOR" -list-avds 2>/dev/null | grep -qx "$AVD_NAME"; then
  echo "Virtual device '$AVD_NAME' already exists."
else
  echo "Creating virtual device '$AVD_NAME'…"
  # --device names a hardware profile from the installed SDK, and the set
  # varies by SDK version. Falling back to the default profile beats failing
  # the whole setup over a cosmetic screen size.
  if ! echo "no" | "$AVDMANAGER" create avd \
      --name "$AVD_NAME" \
      --package "$SYSTEM_IMAGE" \
      --device "pixel_6" \
      --force 2>/dev/null; then
    echo "  (the pixel_6 profile is not in this SDK; using the default)"
    echo "no" | "$AVDMANAGER" create avd \
      --name "$AVD_NAME" \
      --package "$SYSTEM_IMAGE" \
      --force
  fi
fi

cat <<EOF

Done.

  SDK:     $SDK_ROOT
  device:  $AVD_NAME ($ABI, API $API_LEVEL)

Start it whenever you want the mobile surface:

  $0 start

The server finds this SDK on its own, but only a process that can see it will:
if you launch cc_server from a shell without ANDROID_HOME set, export it first.

  export ANDROID_HOME="$SDK_ROOT"

One caveat worth knowing: the emulator manages its own networking, so the
mobile surface does NOT get the deny-by-default NIC the VM surfaces do. Full
egress enforcement for mobile needs a Linux worker.
EOF
