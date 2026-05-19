import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cc_domain/features/rigs/domain/value_objects/enclosure_backend.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_capabilities.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_image_settings.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/rigs/qemu_enclosure_backend.dart'
    show RigLaunchException, RigToolException;
import 'package:cc_infra/src/rigs/rig_browser_defaults.dart';
import 'package:cc_infra/src/rigs/rig_exec_defaults.dart'
    show kExecRigAptMirrors;
import 'package:cc_infra/src/rigs/rig_machine.dart';
import 'package:cc_infra/src/rigs/rig_ports.dart' show kRigPortMuxGuestPort;
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// The OCI image every exec (terminal) rig boots, pinned by digest.
///
/// Ubuntu 24.04 — the same userland the old qcow2 exec image booted, so the
/// enclosed terminal keeps `apt` and a glibc baseline. The stock image ships
/// neither git nor curl; [kSmolvmExecInit] installs them on first start (the
/// machine's overlay persists them afterwards). The digest is the Docker Hub
/// index digest, so one pin serves both arm64 and x64 hosts; smolvm resolves
/// it through its default registry.
const String kSmolvmExecImage =
    'ubuntu:24.04@sha256:d78ab76437b1afc5f01e223d6bf0172763f404bb166441328845adbef44518cb';

/// The OCI image every browser rig boots, pinned by digest.
///
/// `chromedp/headless-shell` — the Chromium build made exactly for CDP-driven
/// use: the browser is baked in (nothing is installed at boot, so there is no
/// first-start package race) and socat is baked in beside it, because current
/// Chromium ignores `--remote-debugging-address` and binds DevTools to
/// loopback unconditionally (chromedp/docker-headless-shell#31: "the Chrome
/// developers really don't like debugging servers on anything
/// non-localhost"). The workload mirrors the image's own entrypoint
/// (`/headless-shell/run.sh`): socat fronts the loopback-bound DevTools on
/// the guest NIC, which is the only place a host `-p` forward can land. The
/// digest is the Docker Hub index digest; one pin serves both arm64 and x64
/// hosts.
const String kSmolvmBrowserImage =
    'chromedp/headless-shell:stable'
    '@sha256:2d349b544a1ea6b5b5fd7c0fe99215ff662339c57407ee2e8c0a11af93516b04';

/// The OCI image the Firefox and WebKit browser rigs boot, pinned by digest.
///
/// Debian 13 (trixie), the SLIM base — 28 MB against the 924 MB of the only
/// maintained Firefox automation image on Docker Hub, and there is no
/// maintained WebKit one at all. Neither engine can use a baked image the way
/// Chromium does, for reasons that are properties of the engines rather than
/// of packaging:
///
///  * Firefox's remote agent binds guest LOOPBACK unconditionally, so a
///    browser rig needs a relay in the guest whatever image it boots — and
///    `socat` is what the ports feature (`rig_ports.dart`) already runs inside
///    every browser guest for its reverse tunnels. An image with Firefox and
///    no socat does not remove the install step; it just makes it a bigger
///    download.
///  * WebKitGTK ships its driver and MiniBrowser as distribution packages and
///    needs an X server to render into. That is `apt`, on any base.
///
/// So both engines take the same small base and the same one-time
/// `apt-get install`, warmed into a pack after the first boot exactly like
/// the exec image. Trixie also matters for a reason that is not size: its
/// `firefox-esr` is the 140 ESR line, and `browsingContext.traverseHistory`
/// — which is the entire back/forward button — landed in Firefox 129.
const String kSmolvmDebianBrowserImage =
    'debian:trixie-slim'
    '@sha256:3a39a0592364683e6bab97937b72cad5a8fa6dcbbee90edb3bb48c7f8e94f258';

/// The Debian mirrors a Firefox or WebKit guest reaches while it warms.
///
/// Image maintenance, the same class as the registry hosts: it buys the
/// packages the engine IS, and nothing the workload later does goes through
/// this list. Once the pack is built no rig contacts them again.
const List<String> kBrowserRigAptMirrors = [
  'deb.debian.org',
  'security.debian.org',
  'cloudfront.debian.net',
];

/// The packages each browser engine needs on top of the Debian base.
///
/// `socat` is in every set: it is the guest half of the ports feature's
/// reverse tunnels, and on Firefox it is also the relay that makes the
/// loopback-bound remote agent reachable from a host forward.
const Map<RigBrowserEngine, List<String>> kBrowserEnginePackages = {
  RigBrowserEngine.firefox: ['firefox-esr', 'socat', 'ca-certificates'],
  RigBrowserEngine.webkit: [
    'webkit2gtk-driver',
    'xvfb',
    'socat',
    'ca-certificates',
  ],
};

/// The guest port each engine's automation endpoint answers on.
///
/// 9222 in every case, because that is the guest side of the ONE forward a
/// browser machine gets and smolvm's `-p` set is immutable once a machine
/// runs. What differs is what sits there: Chromium and Firefox have a socat
/// relay in front of a loopback-bound endpoint, WebKit's driver binds it
/// directly.
const int kBrowserRigGuestPort = 9222;

/// The loopback port each engine's endpoint ACTUALLY listens on inside the
/// guest, behind the relay.
///
/// Load-bearing for Firefox and nothing else: its remote agent rejects a
/// WebSocket upgrade whose `Host` header names a port other than its own
/// (with a bare 400 and no explanation), so the client has to send this port
/// rather than the one it dialled. WebKit's driver binds the guest NIC itself
/// and has no relay, so its two ports are the same.
int browserRigEndpointPort(RigBrowserEngine engine) =>
    engine == RigBrowserEngine.webkit ? kBrowserRigGuestPort : 9223;

/// The image a browser rig boots for [engine].
String smolvmBrowserImageFor(RigBrowserEngine engine) =>
    engine == RigBrowserEngine.chromium
    ? kSmolvmBrowserImage
    : kSmolvmDebianBrowserImage;

/// The first-start package install for [engine], or null when its image is
/// fully baked.
///
/// Idempotent by construction: the `command -v` gate makes a warm start a
/// no-op and the machine's overlay keeps the packages across restarts, so
/// this runs once per machine and — via the warm pack — effectively once per
/// host.
String? smolvmBrowserInitFor(RigBrowserEngine engine) {
  final packages = kBrowserEnginePackages[engine];
  if (packages == null) {
    return null;
  }
  // The probe is the ENGINE's binary, not the package name: `apt-get install`
  // succeeding is not the same claim as "the browser is here", and a
  // half-warmed template that passed on the package name is exactly what a
  // pack would then cache for every later rig.
  final probe = switch (engine) {
    RigBrowserEngine.firefox => 'firefox-esr',
    RigBrowserEngine.webkit => 'WebKitWebDriver',
    RigBrowserEngine.chromium => 'true',
  };
  return '(command -v $probe >/dev/null 2>&1 && '
      'command -v socat >/dev/null 2>&1 || '
      '(apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install '
      '-y -qq --no-install-recommends ${packages.join(' ')}))';
}

/// Where the worktree lands inside an exec guest. Matches the QEMU rigs.
const String kSmolvmGuestWorkdir = '/home/cc/work';

/// The machine-name prefix every rig machine carries.
///
/// Names are unique per rig (the rig id is a uuid), and the sweep never
/// deletes by name alone — labels decide — so a user's own `ccrig-whatever`
/// is not ours to reap.
const String kSmolvmMachinePrefix = 'ccrig-';

/// The label marking a machine as owned by this application. A machine
/// without it is never touched by the sweep, whatever it is named.
const String kSmolvmOwnerLabel = 'cc-owner';

/// The label carrying the owning server's data directory, so two servers on
/// one host (different data dirs) never reap each other's machines.
const String kSmolvmDataDirLabel = 'cc-data-dir';

/// The label carrying the rig id a machine serves.
const String kSmolvmRigLabel = 'cc-rig';

/// The owner label value this backend writes and sweeps.
const String kSmolvmOwnerValue = 'control-center';

/// The registry hosts every image machine may reach to pull its pinned
/// image.
///
/// smolvm's guest agent does the pull, from inside the gated network — a
/// machine created without these can never boot an unpulled image. This is
/// image maintenance traffic, not workload policy (same class as the base
/// image itself): both pinned images live on Docker Hub, whose pull path is
/// `docker.io` (index/registry/auth — host entries match subdomains) plus
/// the blob CDN. Anything the workload itself reaches still requires an
/// explicit allowlist entry.
const List<String> kSmolvmRegistryHosts = [
  'docker.io',
  'production.cloudflare.docker.com',
];

/// The init command every exec machine runs on every start.
///
/// Idempotent by construction: the `command -v` gate makes a warm start a
/// no-op, and the machine's persistent overlay keeps the packages across
/// restarts. apt needs the Ubuntu mirrors, which the exec allowlist
/// (`execRigEgressAllowlist`) already carries. socat is what the port mux and
/// the reverse tunnels (`rig_ports.dart`) run on, so it installs beside git.
const String kSmolvmExecInit =
    'mkdir -p $kSmolvmGuestWorkdir && '
    '(command -v git >/dev/null 2>&1 && command -v curl >/dev/null 2>&1 && '
    'command -v socat >/dev/null 2>&1 || '
    '(apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install '
    '-y -qq --no-install-recommends git curl socat ca-certificates))';

/// The git credential helper installed into every exec guest.
///
/// Speaks git's credential-helper protocol: git pipes `host=...` on stdin and
/// reads `username=`/`password=` back. The helper asks the host's guest
/// credential service — reachable at guest loopback because the ports service
/// plants a REVERSE TUNNEL there (`rig_ports.dart`); smolvm's filtered NIC
/// cannot dial host loopback on its own, which is the measured opposite of
/// what this comment used to claim — per operation, so no durable credential
/// ever sits in the guest. The `CC_RIG_ID` /
/// `CC_RIG_SECRET` / `CC_BROKER_PORT` env it reads is injected at create time
/// (the secret via `--secret-file`, so only the reference is persisted in
/// smolvm's machine record).
///
/// The field extraction is sed, not a JSON parser: the values are produced by
/// our own broker and are token strings by construction (no quotes, no
/// backslashes, no newlines), and a guest that corrupts them only breaks its
/// own push. Any failure exits 0 with no output, which is git's signal to
/// fall back to prompting — the same behaviour the QEMU image's python helper
/// has.
const String kSmolvmCredentialHelper = r'''
#!/bin/sh
[ "$1" = "get" ] || exit 0
host=
while IFS= read -r line; do
  [ -z "$line" ] && break
  case $line in host=*) host=${line#host=} ;; esac
done
[ -n "$host" ] || exit 0
[ -n "$CC_RIG_SECRET" ] || exit 0
resp=$(curl -fsS -m 15 -X POST \
  "http://127.0.0.1:${CC_BROKER_PORT}/credential" \
  -H 'Content-Type: application/json' \
  -d "{\"rig_id\":\"$CC_RIG_ID\",\"secret\":\"$CC_RIG_SECRET\",\"host\":\"$host\"}" \
  2>/dev/null) || exit 0
username=$(printf '%s' "$resp" | sed -n 's/.*"username":"\([^"]*\)".*/\1/p')
password=$(printf '%s' "$resp" | sed -n 's/.*"password":"\([^"]*\)".*/\1/p')
[ -n "$username" ] && printf 'username=%s\n' "$username"
[ -n "$password" ] && printf 'password=%s\n' "$password"
exit 0
''';

/// Maps one entry of the rig egress-allowlist vocabulary to a smolvm
/// `--allow-host` argument, or null when it cannot be expressed.
///
/// smolvm has no wildcard syntax, and its host entries already match
/// subdomains (allowing `github.com` admits `api.github.com` — verified
/// against smolvm 1.8.x). So:
///
///  * `example.com` → `example.com`.
///  * `*.example.com` (subdomains only, apex excluded) → `example.com`, which
///    also admits the apex: the smallest faithful widening available, and the
///    apex of an allowlisted domain is the operator's own site far more often
///    than it is a threat.
///  * `bedrock.*.amazonaws.com` (a MIDDLE-label wildcard) → **null**. The only
///    smolvm entry that would cover it is `amazonaws.com`, which admits every
///    S3 bucket in the world — the exact over-grant the middle-label form was
///    introduced to remove. Widening an entry until it fits the tool is how a
///    narrow rule becomes a broad one without anybody deciding to broaden it,
///    so this drops it instead and the caller logs which host went missing.
String? mapSmolvmAllowlistEntry(String entry) {
  if (entry.startsWith('*.')) {
    final rest = entry.substring(2);
    return rest.contains('*') ? null : rest;
  }
  return entry.contains('*') ? null : entry;
}

/// The smolvm machine name for [rigId].
String smolvmMachineNameFor(String rigId) => '$kSmolvmMachinePrefix$rigId';

/// The pack-cache file name for [image].
///
/// Keyed on a hash of the FULL reference (digest included): bumping a pinned
/// image changes the name, so a stale pack can never serve a new pin — it
/// just stops being referenced and the sweep collects it.
String smolvmPackFileName(String image, {String variant = ''}) =>
    'pack-'
    '${sha256.convert(utf8.encode('$image$variant')).toString().substring(0, 16)}'
    '.smolmachine';

/// The pack VARIANT a spec's machine warms into.
///
/// Firefox and WebKit boot the same Debian base and differ only in what their
/// first start installs, so the image reference alone does not identify the
/// pack: warming Firefox and then booting WebKit from that pack gives a
/// machine with no WebKit in it, and the failure appears as a driver that
/// never answers. The variant is what keeps the two caches apart.
String smolvmPackVariantFor(RigSpec spec) {
  if (spec.isExec || spec.surface != RigSurface.browser) {
    return '';
  }
  return spec.browserEngine == RigBrowserEngine.chromium
      ? ''
      : spec.browserEngine.wire;
}

/// The VM data directory a failed `machine delete` could not remove, or null
/// when [stderr] is not that failure.
///
/// Confined to smolvm's own VM store on purpose: the path feeds a recursive
/// `chmod`, and a corrupted (or hostile) error message must not be able to
/// aim it anywhere else on the host.
String? smolvmBlockedDeletePath(String stderr) {
  final match = RegExp(
    r'delete machine data: (.+?): Permission denied',
  ).firstMatch(stderr);
  final path = match?.group(1);
  if (path == null ||
      !path.contains('${p.separator}smolvm${p.separator}vms${p.separator}')) {
    return null;
  }
  return path;
}

/// The persistent workload command a browser machine runs on every start.
///
/// Two processes, mirroring the image's own entrypoint: socat listens on the
/// guest NIC at 9222 — the only address a host `-p` forward can reach — and
/// relays each connection to headless-shell's DevTools on guest loopback
/// 9223. Chromium ignores `--remote-debugging-address` (DevTools binds
/// loopback, full stop), so without the relay the forward black-holes and
/// the rig never reports ready. socat accepts before Chromium listens; in
/// `fork` mode each such connection fails on its own, which the readiness
/// poll reads as "not up yet" and retries — no start-order race.
///
/// `exec` keeps headless-shell the workload's main process: if the browser
/// ever exits the machine stops and the rig is reported dead, instead of
/// wedging behind a still-live relay.
List<String> buildSmolvmBrowserWorkload(
  RigDisplaySize display, {
  String? tlsSpkiFingerprint,
  RigBrowserHomeTheme? homeTheme,
}) {
  // One string, built outside the argv list: adjacent string literals inside
  // a list literal are a lint here.
  final script =
      '${_writeHomePageCommand(RigBrowserEngine.chromium, homeTheme)}; '
      'socat TCP4-LISTEN:9222,fork TCP4:127.0.0.1:9223 & '
      'exec /headless-shell/headless-shell '
      '--remote-debugging-port=9223 '
      // NO `--remote-allow-origins=*`. That flag exists for BROWSER-context
      // clients, which send an `Origin` header; the host's Dart `WebSocket`
      // sends none, so Chromium's origin check never applies to us and the
      // wildcard buys nothing. What it does buy, with DevTools forwarded to a
      // host port, is admission for a cross-origin WebSocket drive-by from
      // any local page that can reach that port — a full remote-control
      // space into the rig, handed out for a check we do not need.
      '--no-sandbox '
      '--disable-dev-shm-usage '
      '--no-first-run '
      // Dev domains resolve to guest loopback WITHOUT DNS: the egress
      // filter's DNS gate cannot answer for `myapp.test`, and `.test` is
      // reserved for exactly this (RFC 2606). `*.localhost` is already
      // loopback per spec; stating it keeps the two dev TLDs symmetrical.
      // The loopback connect then lands on the reverse-tunnel listeners the
      // ports service plants (`rig_ports.dart`) — port 80 of which is the
      // Host-header domain router. No space after the comma: Chromium's rule
      // parser trims, but keeping it tight avoids any parser ambiguity.
      '"--host-resolver-rules=MAP *.test 127.0.0.1,MAP *.localhost 127.0.0.1" '
      // HTTPS for the dev domains. The image ships no certificate tooling and
      // has no egress to fetch any, so the host's dev CA cannot be installed
      // into a guest trust store; instead the browser pins the SPKI hash of
      // the host's dev leaf KEY. Narrow on purpose: only certificates
      // carrying that exact public key are treated as valid — TLS to any
      // real site still validates normally, so this is not the blanket
      // ignore-certificate-errors hammer. The value is a PUBLIC-key hash;
      // no secret rides the command line.
      '${tlsSpkiFingerprint == null ? '' : '"--ignore-certificate-errors-spki-list=$tlsSpkiFingerprint" '}'
      '--use-gl=angle '
      '--use-angle=swiftshader '
      '--user-data-dir=/tmp/cc-profile '
      '--window-size=${display.width},${display.height} '
      '$kBrowserRigHomeUrl';
  return ['bash', '-c', script];
}

/// Where each browser rig writes its self-contained welcome page.
///
/// One shell fragment, shared by all three workloads: the HTML travels
/// base64'd so nothing in it is at the mercy of shell quoting, and `/tmp` is
/// tmpfs and always writable. The page is [engine]'s own — each engine's
/// "new tab" carries that browser's mark and protocol, because which browser
/// a rig runs is the entire reason it exists. The old default pointed at an
/// external CDN-fronted site, which the deny-by-default egress gate silently
/// refused (rotated CDN IP), leaving a "Ready" rig showing a blank white
/// page; `file://` needs no egress and no DNS, and always renders.
String _writeHomePageCommand(
  RigBrowserEngine engine,
  RigBrowserHomeTheme? homeTheme,
) {
  final homeB64 = base64Encode(
    utf8.encode(browserRigHomeHtml(engine, theme: homeTheme)),
  );
  return 'echo $homeB64 | base64 -d > $kBrowserRigHomePath';
}

/// The persistent workload a FIREFOX browser machine runs on every start.
///
/// Three things here were each paid for once and must not be undone:
///
///  * **`mkdir -p` the profile.** Firefox does not create a `--profile`
///    directory that does not exist. It does not complain either: it falls
///    back to a default profile and — the part that matters — never starts
///    its remote agent at all. Nothing listens on the debug port, the rig
///    times out on readiness, and the only symptom is silence. This one line
///    is the difference between a working Firefox rig and one that never
///    boots.
///  * **The socat relay.** The remote agent binds guest loopback and Firefox
///    has no flag to change that (`--remote-debugging-port=0.0.0.0:9333` is
///    parsed as invalid and falls back to a loopback default). The relay on
///    the guest NIC is the only address a host `-p` forward can reach.
///  * **`--remote-allow-hosts`.** Firefox validates the `Host` header. The
///    entries are host NAMES; the port is checked separately and always
///    against the agent's own, which is why the client sends the guest-side
///    port rather than the one it dialled.
///
/// `exec` keeps Firefox the workload's main process: if the browser exits the
/// machine stops and the rig is reported dead, instead of wedging behind a
/// still-live relay.
List<String> buildSmolvmFirefoxWorkload(
  RigDisplaySize display, {
  RigBrowserHomeTheme? homeTheme,
}) {
  final endpoint = browserRigEndpointPort(RigBrowserEngine.firefox);
  final script =
      '${_writeHomePageCommand(RigBrowserEngine.firefox, homeTheme)}; '
      'mkdir -p /tmp/cc-profile; '
      'socat TCP4-LISTEN:$kBrowserRigGuestPort,fork '
      'TCP4:127.0.0.1:$endpoint & '
      'exec firefox-esr '
      '--headless '
      '--profile /tmp/cc-profile '
      '--remote-debugging-port=$endpoint '
      '--remote-allow-hosts=127.0.0.1,localhost '
      '--window-size=${display.width},${display.height} '
      '$kBrowserRigHomeUrl';
  return ['bash', '-c', script];
}

/// The persistent workload a WEBKIT browser machine runs on every start.
///
/// WebKitGTK has no headless mode: `MiniBrowser` renders into an X display or
/// it does not run, so an Xvfb server comes up first and the driver launches
/// the browser into it. `WebKitWebDriver` DOES take a `--host`, so unlike the
/// other two engines it binds the guest NIC itself and needs no relay for its
/// own traffic — socat is still installed, because the ports feature runs its
/// reverse tunnels on it.
///
/// No page is opened here. Classic WebDriver launches the browser when a
/// SESSION is created, so there is nothing to navigate until the host
/// attaches; the service points the fresh session at the welcome page, which
/// is why the page is still written to disk at boot.
List<String> buildSmolvmWebkitWorkload(
  RigDisplaySize display, {
  RigBrowserHomeTheme? homeTheme,
}) {
  final script =
      '${_writeHomePageCommand(RigBrowserEngine.webkit, homeTheme)}; '
      'Xvfb :99 -screen 0 ${display.width}x${display.height}x24 '
      '-nolisten tcp & '
      // The driver races Xvfb's socket otherwise, and a MiniBrowser launched
      // against a display that is not up yet fails the session rather than
      // retrying.
      'for i in \$(seq 1 40); do [ -e /tmp/.X11-unix/X99 ] && break; '
      'sleep 0.25; done; '
      'export DISPLAY=:99; '
      'exec WebKitWebDriver --host=0.0.0.0 --port=$kBrowserRigGuestPort';
  return ['bash', '-c', script];
}

/// The workload for [engine].
List<String> buildSmolvmBrowserWorkloadFor(
  RigBrowserEngine engine,
  RigDisplaySize display, {
  String? tlsSpkiFingerprint,
  RigBrowserHomeTheme? homeTheme,
}) => switch (engine) {
  RigBrowserEngine.chromium => buildSmolvmBrowserWorkload(
    display,
    tlsSpkiFingerprint: tlsSpkiFingerprint,
    homeTheme: homeTheme,
  ),
  RigBrowserEngine.firefox => buildSmolvmFirefoxWorkload(
    display,
    homeTheme: homeTheme,
  ),
  RigBrowserEngine.webkit => buildSmolvmWebkitWorkload(
    display,
    homeTheme: homeTheme,
  ),
};

/// Everything the create-argv builder needs, so the command line is a pure
/// function of data rather than of a live machine — the same discipline as
/// `QemuLaunchPlan`, and for the same reason: a rig cannot be booted in CI,
/// but the flags that decide whether the guest is network-isolated absolutely
/// must be testable.
class SmolvmLaunchPlan {
  /// Creates a [SmolvmLaunchPlan].
  const SmolvmLaunchPlan({
    required this.rigId,
    required this.spec,
    required this.image,
    required this.dataDir,
    this.packPath,
    this.devtoolsHostPort,
    this.portMuxHostPort,
    this.secretFilePath,
    this.credentialPort,
    this.devTlsSpkiFingerprint,
  });

  /// This plan with the pack discarded — the registry fallback for a pack
  /// that turned out to be unusable.
  SmolvmLaunchPlan withoutPack() => SmolvmLaunchPlan(
    rigId: rigId,
    spec: spec,
    image: image,
    dataDir: dataDir,
    devtoolsHostPort: devtoolsHostPort,
    portMuxHostPort: portMuxHostPort,
    secretFilePath: secretFilePath,
    credentialPort: credentialPort,
    devTlsSpkiFingerprint: devTlsSpkiFingerprint,
  );

  /// The rig this machine will serve.
  final String rigId;

  /// What to boot and what it may reach.
  final RigSpec spec;

  /// The digest-pinned OCI image reference.
  final String image;

  /// A locally cached pre-extracted pack of [image], or null when none has
  /// been built yet.
  ///
  /// When set, the machine is created `--from` this file instead of
  /// `--image`: measured on this host, extracting the pinned Ubuntu image
  /// into a fresh machine costs 22–25s PER MACHINE even with every blob
  /// already in smolvm's local cache (the cost is flattening, not the
  /// network), while a pre-extracted pack boots the identical machine in
  /// ~7s. The pack is a cache of public image bytes, not policy: every
  /// other flag on the command line is byte-identical either way.
  final String? packPath;

  /// The owning server's data directory (sweep ownership label).
  final String dataDir;

  /// Host loopback port forwarded to the guest's DevTools relay (browser
  /// rigs only).
  final int? devtoolsHostPort;

  /// Host loopback port forwarded to the guest's port MUX (exec rigs only).
  ///
  /// Allocated at create time because smolvm's `-p` set is immutable while a
  /// machine runs: this single forward is what makes every FUTURE guest port
  /// reachable without a restart (see `rig_ports.dart`).
  final int? portMuxHostPort;

  /// The 0600 host file holding the per-rig broker secret, handed over by
  /// reference (`--secret-file`), never by value.
  final String? secretFilePath;

  /// Host loopback port of the credential broker, or null when the broker is
  /// not running (the guest then holds no way to mint, which is the correct
  /// floor).
  final int? credentialPort;

  /// SPKI fingerprint of the host's dev-domain TLS leaf key (browser rigs
  /// only), or null when the host has no TLS material. A hash of a PUBLIC
  /// key — the private half never enters a guest.
  final String? devTlsSpkiFingerprint;

  /// Whether this is a terminal/exec machine rather than a browser one.
  bool get isExec => spec.isExec;

  /// Which browser this machine boots, when it is a browser machine.
  RigBrowserEngine get engine => spec.browserEngine;

  /// Whether this machine installs its browser on first start rather than
  /// booting a fully baked image.
  bool get warmsPackages =>
      !isExec && kBrowserEnginePackages.containsKey(engine);
}

/// Builds the `smolvm machine create` argument vector for [plan].
///
/// The security load-bearing invariants, pinned by
/// `smolvm_enclosure_backend_test.dart`:
///
///  * `--outbound-localhost-only` is ALWAYS present and bare `--net` never
///    is: the guest's only unconditional route out is host loopback (the
///    credential broker), everything else goes through the allowlist.
///  * Every allowlist entry becomes its own `--allow-host`, and the Docker
///    Hub pull path is unioned in: the guest agent pulls the machine's image
///    through this same gate, so a machine without it can never boot an
///    image that is not already cached.
///  * The broker secret travels by `--secret-file` reference, never as an
///    env value smolvm would persist in its machine record.
List<String> buildSmolvmCreateArgs(SmolvmLaunchPlan plan) {
  final isExec = plan.isExec;
  final dropped = <String>[];
  final allowlist = <String>{
    for (final entry in plan.spec.egressAllowlist)
      if (mapSmolvmAllowlistEntry(entry) case final mapped?)
        mapped
      else
        ...() {
          dropped.add(entry);
          return const <String>[];
        }(),
    // Image maintenance, not workload policy: the guest agent pulls the
    // machine's image through this same gate, so without the registry hosts
    // a machine can never boot an image that is not already cached. Derived
    // from the image REFERENCE — a workspace's custom image may live on a
    // different registry than the pinned defaults.
    ...registryHostsForImageRef(plan.image),
    // Same class, one step further along: an engine whose image is a bare
    // Debian needs the archives to become that engine at all. Only for the
    // engines that install — a Chromium rig never gets these.
    if (plan.warmsPackages) ...kBrowserRigAptMirrors,
  };
  if (dropped.isNotEmpty) {
    // Said out loud, because a silently missing host reads to whoever hits it
    // as a mysterious guest network failure.
    CcInfraLog.warning(
      'rig/smolvm: ${dropped.join(', ')} cannot be expressed as a smolvm '
      '--allow-host (it uses a middle-label wildcard and smolvm has no '
      'wildcard syntax), so ${dropped.length == 1 ? 'it is' : 'they are'} not '
      'reachable from this machine.',
    );
  }
  return [
    'machine', 'create',
    '--name', smolvmMachineNameFor(plan.rigId),
    // A cached pre-extracted pack when one exists, the registry reference
    // otherwise. Everything below is identical either way — the pack is a
    // faster way to the same bytes, never a different policy.
    if (plan.packPath != null) ...[
      '--from',
      plan.packPath!,
    ] else ...[
      '--image',
      plan.image,
    ],
    '--cpus', '${plan.spec.cpuCount}',
    '--mem', '${plan.spec.memoryMb}',
    // Disk. An exec machine holds a worktree and a package overlay; a
    // browser machine that installs its engine on first start needs an
    // overlay to install INTO, and without one the apt write fails inside a
    // guest whose only symptom is a browser that never appears. A baked
    // browser image needs neither.
    if (isExec) ...[
      '--storage',
      '8',
      '--overlay',
      '16',
    ] else if (plan.warmsPackages) ...[
      '--storage',
      '8',
      '--overlay',
      '8',
    ],
    // Labels are the sweep's ownership proof. A machine without them is not
    // ours, whatever it is named.
    '--label', '$kSmolvmOwnerLabel=$kSmolvmOwnerValue',
    '--label', '$kSmolvmDataDirLabel=${plan.dataDir}',
    '--label', '$kSmolvmRigLabel=${plan.rigId}',
    '--label', 'cc-surface=${isExec ? 'exec' : 'browser'}',
    if (!isExec) ...['--label', 'cc-engine=${plan.engine.wire}'],
    '--outbound-localhost-only',
    for (final host in allowlist) ...['--allow-host', host],
    if (plan.devtoolsHostPort != null) ...[
      '-p',
      '${plan.devtoolsHostPort}:$kBrowserRigGuestPort',
    ],
    if (plan.portMuxHostPort != null) ...[
      '-p',
      '${plan.portMuxHostPort}:$kRigPortMuxGuestPort',
    ],
    if (plan.secretFilePath != null) ...[
      '--secret-file',
      'CC_RIG_SECRET=${plan.secretFilePath}',
    ],
    if (plan.credentialPort != null) ...[
      '-e',
      'CC_BROKER_PORT=${plan.credentialPort}',
      '-e',
      'CC_RIG_ID=${plan.rigId}',
    ],
    // Exec guests bootstrap git/curl on first start. A CHROMIUM browser guest
    // boots a fully baked image and installs nothing — the pinned image
    // exists to remove that race. Firefox and WebKit have no equivalent
    // baked image (see [kSmolvmDebianBrowserImage]), so they take the same
    // gated one-time install, which the warm pack then makes a one-time cost
    // per HOST rather than per rig.
    if (isExec) ...[
      '--init',
      kSmolvmExecInit,
    ] else if (smolvmBrowserInitFor(plan.engine) case final init?) ...[
      '--init',
      init,
    ],
    if (!isExec) ...[
      '--',
      ...buildSmolvmBrowserWorkloadFor(
        plan.engine,
        plan.spec.display,
        tlsSpkiFingerprint: plan.devTlsSpkiFingerprint,
        homeTheme: plan.spec.homeTheme,
      ),
    ],
  ];
}

/// One machine row from `smolvm machine ls --json`.
class SmolvmMachineInfo {
  /// Creates a [SmolvmMachineInfo].
  const SmolvmMachineInfo({
    required this.name,
    required this.state,
    required this.labels,
    this.pid,
  });

  /// The machine's name.
  final String name;

  /// Its lifecycle state (`created`, `running`, `stopped`, …).
  final String state;

  /// Operator- and owner-attached labels.
  final Map<String, String> labels;

  /// The VMM process id while running.
  final int? pid;

  /// Whether the VMM is up.
  bool get running => state == 'running' && pid != null;
}

/// Parses the `smolvm machine ls --json` output.
///
/// Tolerant by design: unknown fields are ignored and a malformed document
/// reads as "no machines" rather than throwing — a sweep that cannot parse
/// the listing must not delete anything, but it also must not crash the
/// service's start.
List<SmolvmMachineInfo> parseSmolvmMachineList(String jsonText) {
  final Object? decoded;
  try {
    decoded = jsonDecode(jsonText);
  } on Object {
    return const [];
  }
  if (decoded is! List) {
    return const [];
  }
  return [
    for (final entry in decoded)
      if (entry is Map && entry['name'] is String)
        SmolvmMachineInfo(
          name: entry['name'] as String,
          state: entry['state'] as String? ?? '',
          labels: {
            if (entry['labels'] is Map)
              for (final l in (entry['labels'] as Map).entries)
                if (l.key is String && l.value is String)
                  l.key as String: l.value as String,
          },
          pid: entry['pid'] is int ? entry['pid'] as int : null,
        ),
  ];
}

/// A booted smolvm machine and everything needed to drive it.
class SmolvmMachine implements RigMachine {
  /// Creates a [SmolvmMachine].
  SmolvmMachine({
    required this.rigId,
    required this.name,
    required this.process,
    required this.guestSecret,
    required this.runtimeDir,
    required this.display,
    this.devtoolsPort,
    this.automationGuestPort,
    this.portMuxHostPort,
    this.engine = RigBrowserEngine.chromium,
  });

  @override
  final String rigId;

  /// The smolvm machine name (`ccrig-<rigId>`).
  final String name;

  /// The held `machine exec` sentinel whose exit reports the machine's death.
  @override
  final Process process;

  @override
  final String guestSecret;

  /// Per-rig scratch directory (the broker-secret file). Removed with the
  /// machine; the machine's own disks live in smolvm's store and go with
  /// `machine delete`.
  final String runtimeDir;

  /// Host loopback port forwarded to the guest's automation endpoint, when
  /// this is a browser rig.
  final int? devtoolsPort;

  /// The port that endpoint believes it serves, INSIDE the guest.
  ///
  /// Not the same as [devtoolsPort] whenever a relay sits between them, and
  /// not cosmetic: Firefox refuses a WebSocket upgrade whose `Host` header
  /// names any other port, so the client has to be told the guest-side one.
  final int? automationGuestPort;

  /// Which browser the machine is running, when it is a browser machine.
  /// Picks the protocol client the service attaches.
  final RigBrowserEngine engine;

  /// Host loopback port forwarded to the guest's port mux, when this is an
  /// exec (terminal) rig. What `RigPortsService` bridges through.
  final int? portMuxHostPort;

  @override
  RigDisplaySize display;

  /// Whether the rig is marked parked.
  ///
  /// A smolvm machine does not actually stop vCPUs on park: idle vCPU threads
  /// already sleep in the hypervisor and the virtio balloon hands back the
  /// memory the guest is not using, so there is nothing to reclaim the way
  /// QMP `stop` reclaims it. The flag exists so the reaper's park-then-close
  /// cadence and the "parked" badge keep working.
  @override
  bool parked = false;
}

/// A process-runner seam so lifecycle tests can drive [SmolvmEnclosureBackend]
/// without a hypervisor.
typedef SmolvmRunFn =
    Future<ProcessResult> Function(String executable, List<String> arguments);

/// Boots and tears down smolvm-backed rigs (exec/terminal and browser).
///
/// Owns nothing the CLI does not own: the machines, their disks and their
/// VMM processes live in smolvm's store, so this class's state on disk is one
/// 0600 secret file per rig. It deliberately does NOT own policy, exactly
/// like its QEMU sibling: what a rig may reach, who may drive it and how long
/// it lives are decided above and handed down.
class SmolvmEnclosureBackend {
  /// Creates a [SmolvmEnclosureBackend].
  ///
  /// [binaryPath] overrides resolution (tests, packaged installs); when null
  /// the probe searches PATH and the two well-known install locations.
  /// [runFn] is the test seam for the CLI's run-shaped calls.
  SmolvmEnclosureBackend({
    required String dataDir,
    String? binaryPath,
    SmolvmRunFn? runFn,
    Duration runtimeDirGrace = _defaultRuntimeDirGrace,
  }) : _runtimeRoot = p.join(dataDir, 'rigs', 'smolvm'),
       _dataDir = dataDir,
       _binaryOverride = binaryPath,
       _runFn = runFn,
       _runtimeDirGrace = runtimeDirGrace;

  final String _runtimeRoot;
  final String _dataDir;
  final String? _binaryOverride;
  final SmolvmRunFn? _runFn;
  final Duration _runtimeDirGrace;

  /// Host port of the credential-broker endpoint.
  ///
  /// The broker stays SHARED across rigs: every request carries the per-rig
  /// secret, so the endpoint itself does not need to know which machine is
  /// calling to enforce per-rig policy.
  int? credentialPort;

  /// SPKI fingerprint of the host's dev-domain TLS leaf key, set by the rig
  /// service once the material exists. Browser workloads pin it so
  /// `https://myapp.test` inside the guest is trusted; null leaves the flag
  /// off and dev domains route over plain HTTP only.
  String? devTlsSpkiFingerprint;

  RigBackendCapabilities? _cachedProbe;
  String? _resolvedBinary;

  /// The smolvm binary the last probe resolved, or null before one.
  ///
  /// Launch resolves it on demand, so a shell argv built after a successful
  /// boot always has it.
  String? get resolvedBinary => _resolvedBinary;

  /// What smolvm can do on this host.
  ///
  /// Cheap by contract — a binary resolution and a `--version` run — because
  /// settings calls it on open. Cached after the first success.
  Future<RigBackendCapabilities> probe({bool refresh = false}) async {
    final cached = _cachedProbe;
    if (cached != null && !refresh) {
      return cached;
    }
    final result = await _probeUncached();
    if (result.available || refresh) {
      _cachedProbe = result;
    }
    return result;
  }

  Future<RigBackendCapabilities> _probeUncached() async {
    final resolved = await _resolveBinary();
    if (resolved == null) {
      return RigBackendCapabilities.unavailable(
        EnclosureBackend.smolvm,
        note:
            'smolvm is not installed, so enclosed terminals and browser rigs '
            'are unavailable.',
        requiresInstall: true,
        installHint: 'curl -sSL https://smolmachines.com/install.sh | bash',
      );
    }
    String? version;
    try {
      final result = await _run(resolved, [
        '--version',
      ], timeout: const Duration(seconds: 15));
      if (result.exitCode == 0) {
        final line = '${result.stdout}'.trim();
        if (line.isNotEmpty) {
          version = line;
        }
      }
    } on Object {
      // A binary that will not report its version is still worth trying.
    }
    _resolvedBinary = resolved;
    return RigBackendCapabilities(
      backend: EnclosureBackend.smolvm,
      available: true,
      surfaces: const {RigSurface.browser},
      // All three, on any host that has smolvm. Nothing about an engine is a
      // host property here — each one is an image pull plus, for two of them,
      // a package install, both of which happen inside the guest. A host that
      // can boot one browser rig can boot all three.
      browserEngines: const {
        RigBrowserEngine.chromium,
        RigBrowserEngine.firefox,
        RigBrowserEngine.webkit,
      },
      supportsTerminals: true,
      note:
          'smolvm microVM (libkrun over the host hypervisor) — sub-second '
          'boot, digest-pinned OCI images that pull on first use. Browser '
          'rigs run Chromium, Firefox or WebKit.',
      version: version,
    );
  }

  /// Boots a rig for [spec] and returns the machine once it answers.
  ///
  /// [imageOverride] is the workspace's own image reference, when one is
  /// configured — validated here again before it touches a command line, and
  /// ignored (loudly) when invalid, because a bad setting must degrade to
  /// the default image rather than brick every terminal in the workspace.
  ///
  /// [onProgress] reports each boot step verbatim to the UI, because a silent
  /// wait and a hang are indistinguishable to the person looking at the
  /// panel.
  Future<SmolvmMachine> launch({
    required String rigId,
    required RigSpec spec,
    String? imageOverride,
    void Function(String step)? onProgress,
  }) async {
    final probeResult = await probe();
    if (!probeResult.available) {
      throw RigLaunchException(
        probeResult.note ?? 'smolvm is not available on this host.',
      );
    }
    final binary = _resolvedBinary!;
    final isExec = spec.isExec;
    final name = smolvmMachineNameFor(rigId);

    onProgress?.call('Preparing the machine');
    final runtimeDir = Directory(p.join(_runtimeRoot, rigId));
    await runtimeDir.create(recursive: true);
    // The directory is about to hold the per-rig broker secret. The file is
    // 0600, but a 0700 directory means a permission slip on any future file
    // in here is not immediately world-readable.
    await _chmod('700', runtimeDir.path);
    final guestSecret = _randomToken();
    final secretPath = p.join(runtimeDir.path, 'broker-secret');
    await File(secretPath).writeAsString(guestSecret);
    // The secret is the ONLY thing gating the broker; at the default umask
    // any local user could read it and mint against the rig's capabilities.
    await _chmod('600', secretPath);

    final engine = spec.browserEngine;
    final devtoolsPort = isExec ? null : await _freePort();
    final portMuxHostPort = isExec ? await _freePort() : null;
    final defaultImage = isExec
        ? kSmolvmExecImage
        : smolvmBrowserImageFor(engine);
    // A workspace's own image, when one is configured AND passes the same
    // validation the settings write applies. Re-validated HERE because the
    // settings store is an opaque key/value space anyone with admin can
    // write through generic ops — this string becomes a host command line,
    // and "the client validated it" is not a boundary.
    String image;
    if (imageOverride == null) {
      image = defaultImage;
    } else if (!isExec && engine != RigBrowserEngine.chromium) {
      // A workspace's custom BROWSER image is a Chromium image: the setting
      // predates engines and the workload command it would boot is
      // headless-shell's. Handing it to Firefox or WebKit would launch a
      // binary that is not there. The override is skipped rather than
      // half-applied, and said out loud so it does not read as ignored
      // silently.
      image = defaultImage;
      CcInfraLog.info(
        'rig/$rigId: the workspace browser image override applies to Chromium '
        'rigs only; booting the pinned ${engine.label} image instead',
      );
    } else if (isValidCustomRigImageRef(imageOverride)) {
      image = imageOverride;
      CcInfraLog.info(
        'rig/$rigId: booting the workspace\'s own '
        '${isExec ? 'terminal' : 'browser'} image ($imageOverride)',
      );
    } else {
      image = defaultImage;
      CcInfraLog.warning(
        'rig/$rigId: ignoring an invalid custom image reference '
        '("$imageOverride"); booting the default instead',
      );
    }
    // Prefer a cached pre-extracted pack: flattening the image into a fresh
    // machine costs 20+ seconds PER MACHINE even with every blob local, and
    // a pack cuts that to single digits. Built in the background after the
    // first registry boot (below), so nothing here ever waits on a pack.
    final packVariant = smolvmPackVariantFor(spec);
    final packPath = packPathFor(image, variant: packVariant);
    final usePack = File(packPath).existsSync();
    final plan = SmolvmLaunchPlan(
      rigId: rigId,
      spec: spec,
      image: image,
      dataDir: _dataDir,
      packPath: usePack ? packPath : null,
      devtoolsHostPort: devtoolsPort,
      portMuxHostPort: portMuxHostPort,
      secretFilePath: secretPath,
      credentialPort: credentialPort,
      devTlsSpkiFingerprint: devTlsSpkiFingerprint,
    );

    try {
      try {
        await _runChecked(
          binary,
          buildSmolvmCreateArgs(plan),
          hint: 'Without a machine definition there is nothing to start.',
          timeout: _startTimeout,
        );
      } on RigToolException catch (e) {
        if (plan.packPath == null) {
          rethrow;
        }
        // A pack that will not create a machine is damaged (a truncated
        // write, a smolvm format bump). Discard it and fall back to the
        // registry — a broken CACHE must never be able to break a boot —
        // then rebuild it in the background like any first boot.
        CcInfraLog.warning(
          'rig/smolvm: cached pack for $image is unusable ($e); rebuilding '
          'from the registry',
        );
        await _deleteFileQuietly(packPath);
        await _deleteQuietly(binary, name);
        await _runChecked(
          binary,
          buildSmolvmCreateArgs(plan.withoutPack()),
          hint: 'Without a machine definition there is nothing to start.',
          timeout: _startTimeout,
        );
      }
      onProgress?.call(
        usePack
            ? 'Starting the microVM (cached image)'
            : 'Starting the microVM (the first boot pulls its image)',
      );
      // The FIRST start pulls the image, so this carries the cold-pull
      // budget rather than the control-plane one.
      await _runChecked(binary, [
        'machine',
        'start',
        '--name',
        name,
      ], timeout: _startTimeout);
      // The image is now fully cached locally, so pre-extract it for every
      // later machine. Deliberately AFTER the start (the expensive pull is
      // done) and fire-and-forget: the pack is an optimisation, and a boot
      // must never wait on — or fail with — its cache.
      if (!File(packPath).existsSync()) {
        unawaited(
          _buildPack(
            binary,
            image,
            variant: packVariant,
            warmInit: isExec ? kSmolvmExecInit : smolvmBrowserInitFor(engine),
            warmMirrors: isExec ? kExecRigAptMirrors : kBrowserRigAptMirrors,
            warmProbe: isExec ? _execWarmProbe : _browserWarmProbe(engine),
          ),
        );
      }

      if (isExec) {
        await _awaitExec(binary, name, onProgress: onProgress);
        if (credentialPort != null) {
          await _installCredentialHelper(binary, name, rigId);
        }
      } else {
        await _awaitBrowser(
          engine,
          devtoolsPort!,
          onProgress: onProgress,
          // A cold Firefox or WebKit machine pulls a base image AND installs
          // the engine before the endpoint can answer, so its budget is the
          // pull budget plus an apt run. A Chromium rig only pulls.
          timeout: kBrowserEnginePackages.containsKey(engine)
              ? const Duration(seconds: 420)
              : const Duration(seconds: 180),
        );
      }

      // The death sentinel: the CLI spawns the VMM detached, so there is no
      // child process of ours whose exit means "the machine died". A held
      // `machine exec` connection is the next best thing — when the VMM goes,
      // it drops.
      final sentinel = await Process.start(binary, [
        'machine',
        'exec',
        '--name',
        name,
        '--',
        'sh',
        '-c',
        'while :; do sleep 3600; done',
      ]);
      unawaited(sentinel.stdout.drain<void>());
      unawaited(sentinel.stderr.drain<void>());

      onProgress?.call('Ready');
      return SmolvmMachine(
        rigId: rigId,
        name: name,
        process: sentinel,
        guestSecret: guestSecret,
        runtimeDir: runtimeDir.path,
        display: spec.display,
        devtoolsPort: devtoolsPort,
        automationGuestPort: isExec ? null : browserRigEndpointPort(engine),
        portMuxHostPort: portMuxHostPort,
        engine: engine,
      );
    } on Object {
      // A failed launch must not leave the machine behind: smolvm's store is
      // global to the host, so a leaked record is visible to — and reusable
      // by — every later rig that happens to compute the same name. Delete
      // what create made, then report.
      await _deleteQuietly(binary, name);
      await _deleteDirQuietly(runtimeDir.path);
      rethrow;
    }
  }

  /// Stops [machine] and discards its disks.
  ///
  /// Every step is independent and none may throw out of here: the caller's
  /// only alternative to finishing is leaking a VM. `machine delete -f` takes
  /// the VMM down with the record; the sentinel is killed first so its exit
  /// does not read as an unexpected death.
  Future<void> destroy(SmolvmMachine machine) async {
    machine.process.kill(ProcessSignal.sigkill);
    try {
      await machine.process.exitCode.timeout(const Duration(seconds: 2));
    } on Object {
      // Already gone, or refusing to die — the delete below settles it.
    }
    final binary = _resolvedBinary;
    if (binary != null) {
      await _deleteQuietly(binary, machine.name);
    }
    await _deleteDirQuietly(machine.runtimeDir);
  }

  /// Parks [machine]. See [SmolvmMachine.parked]: a state flip, not a vCPU
  /// stop, because the hypervisor already idles both.
  Future<void> park(SmolvmMachine machine) async {
    machine.parked = true;
  }

  /// Wakes a parked [machine].
  Future<void> wake(SmolvmMachine machine) async {
    machine.parked = false;
  }

  /// Deletes every machine this application owns and prunes stale runtime
  /// directories. Returns how many machines were deleted.
  ///
  /// Ownership is the label pair written at create time, never the name:
  /// `cc-owner=control-center` marks the application and `cc-data-dir` the
  /// server instance, so two servers sharing a host (and smolvm's global
  /// store) never reap each other's machines.
  Future<int> sweepOrphanedRuntimes() async {
    final binary = await _resolveBinary();
    if (binary == null) {
      return 0;
    }
    var removed = 0;
    final result = await _run(binary, [
      'machine',
      'ls',
      '--json',
    ], timeout: const Duration(seconds: 30));
    if (result.exitCode == 0) {
      for (final machine in parseSmolvmMachineList('${result.stdout}')) {
        if (machine.labels[kSmolvmOwnerLabel] != kSmolvmOwnerValue) {
          continue;
        }
        if (machine.labels[kSmolvmDataDirLabel] != _dataDir) {
          continue;
        }
        // Through the healing delete: an orphaned pack-based machine has the
        // same read-only pack layers a live one does, and a sweep that
        // cannot actually remove them reports space reclaimed that was not.
        await _deleteQuietly(binary, machine.name);
        removed++;
      }
    }
    // Runtime dirs hold only the broker-secret file; one whose machine is gone
    // is debris. The machine list above was taken BEFORE any deletion, so a
    // dir whose machine was just swept is collected here too.
    final root = Directory(_runtimeRoot);
    if (root.existsSync()) {
      final liveNames = {
        for (final m in parseSmolvmMachineList(
          '${(await _run(binary, ['machine', 'ls', '--json'], timeout: const Duration(seconds: 30))).stdout}',
        ))
          if (m.name.startsWith(kSmolvmMachinePrefix))
            m.name.substring(kSmolvmMachinePrefix.length),
      };
      await for (final entity in root.list(followLinks: false)) {
        if (entity is! Directory ||
            liveNames.contains(p.basename(entity.path))) {
          continue;
        }
        // A LAUNCH IN FLIGHT looks exactly like debris here: the runtime dir
        // (with the broker secret in it) is written BEFORE `machine create`
        // registers the name, so between those two steps this directory
        // belongs to no live machine. Deleting it takes the secret out from
        // under a boot that is seconds from needing it. The sweep only runs at
        // `start()` today, which is why this has not bitten — but nothing
        // structurally prevents a concurrent one, so young directories are
        // left for the next pass.
        if (_isRecentRuntimeDir(entity.path)) {
          CcInfraLog.debug(
            'rig/smolvm: leaving ${entity.path} for now — no machine claims '
            'it yet, but it was created moments ago and may be a boot in '
            'flight.',
          );
          continue;
        }
        await _deleteDirQuietly(entity.path);
      }
    }
    await _prunePacks();
    return removed;
  }

  // ── Image pack cache ──────────────────────────────────────────────────────

  /// Where the pre-extracted image packs live.
  String get _packsDir => p.join(_dataDir, 'rigs', 'smolvm-packs');

  /// The pack-cache path for [image].
  String packPathFor(String image, {String variant = ''}) =>
      p.join(_packsDir, smolvmPackFileName(image, variant: variant));

  /// The warm-probe for an exec template: the three binaries its init
  /// installs.
  static const String _execWarmProbe =
      'command -v git >/dev/null && command -v curl >/dev/null && '
      'command -v socat >/dev/null';

  /// The warm-probe for a browser template, or null when the engine boots a
  /// baked image and warms nothing.
  ///
  /// Probes the ENGINE's own binary. `apt-get install` exiting 0 is a
  /// different claim from "the browser is here", and a template snapshotted
  /// on the weaker claim caches a broken machine for every later rig.
  static String? _browserWarmProbe(RigBrowserEngine engine) => switch (engine) {
    RigBrowserEngine.chromium => null,
    RigBrowserEngine.firefox =>
      'command -v firefox-esr >/dev/null && command -v socat >/dev/null',
    RigBrowserEngine.webkit =>
      'command -v WebKitWebDriver >/dev/null && command -v Xvfb >/dev/null '
          '&& command -v socat >/dev/null',
  };

  /// Packs currently being built, so two first-boots of one image cannot
  /// race two builders.
  final Set<String> _packsBuilding = {};

  /// Builds the pack for [image] in the background.
  ///
  /// Runs strictly AFTER the image landed in smolvm's local cache (the
  /// machine that triggered it already started), so the flatten is disk
  /// work, not a second download. Written next to its destination and
  /// renamed into place, so a killed build never leaves a file a later boot
  /// would trust. Best-effort throughout: the pack is a cache, and no
  /// failure here may surface anywhere near a boot.
  ///
  /// Two flavours, measured on this host:
  ///
  ///  * The BROWSER image packs directly — it is fully baked, nothing runs
  ///    at boot, so the pack only skips the per-machine layer flatten.
  ///  * The EXEC image packs a WARMED throwaway template: a pristine machine
  ///    is booted, its init installs git/curl/socat into the overlay, and
  ///    THAT machine is snapshotted. Boots from it take ~9s against ~21s
  ///    (the apt install inside every fresh machine's first start was the
  ///    other half of the cost, and it also made first-start depend on the
  ///    Ubuntu mirrors being reachable). The template carries NO secrets, NO
  ///    worktree, no per-rig state — it never gets any: no broker secret, no
  ///    port forwards, nothing synced in — so the snapshot is safe to share
  ///    across every later rig and conversation.
  Future<void> _buildPack(
    String binary,
    String image, {
    String variant = '',
    String? warmInit,
    List<String> warmMirrors = const [],
    String? warmProbe,
  }) async {
    final destination = packPathFor(image, variant: variant);
    // Keyed on image AND variant, like the pack itself: Firefox and WebKit
    // share a base image, and keying on the image alone would have the
    // first of them to boot block the other's pack from ever being built.
    final key = '$image#$variant';
    if (!_packsBuilding.add(key)) {
      return;
    }
    try {
      if (File(destination).existsSync()) {
        return;
      }
      await Directory(_packsDir).create(recursive: true);
      // `pack create -o X` writes an executable stub at X and the actual
      // artifact at X.smolmachine; only the artifact is kept. X must NOT end
      // in `.smolmachine` — the tool refuses an output named like the
      // sidecar it is about to create.
      final stub = p.join(
        _packsDir,
        '.building-${p.basenameWithoutExtension(destination)}',
      );
      final warms = warmInit != null && warmProbe != null;
      final ProcessResult result;
      if (warms) {
        final template = await _buildWarmTemplate(
          binary,
          image,
          init: warmInit,
          mirrors: warmMirrors,
          probe: warmProbe,
        );
        if (template == null) {
          return;
        }
        try {
          result = await _run(binary, [
            'pack',
            'create',
            '--from-vm',
            template,
            '-o',
            stub,
          ], timeout: _packTimeout);
        } finally {
          await _deleteQuietly(binary, template);
        }
      } else {
        result = await _run(binary, [
          'pack',
          'create',
          '--image',
          image,
          '-o',
          stub,
        ], timeout: _packTimeout);
      }
      if (result.exitCode != 0) {
        CcInfraLog.warning(
          'rig/smolvm: pack build for $image failed (exit ${result.exitCode}):'
          ' ${result.stderr}',
        );
        return;
      }
      await File('$stub.smolmachine').rename(destination);
      await _deleteFileQuietly(stub);
      CcInfraLog.info(
        'rig/smolvm: cached $image as a pre-extracted pack '
        '(${p.basename(destination)}) — later machines skip the pull'
        '${warms ? ' and the first-start package install' : ''}',
      );
    } on Object catch (e) {
      CcInfraLog.warning('rig/smolvm: pack build for $image failed: $e');
    } finally {
      _packsBuilding.remove(key);
    }
  }

  /// Boots a pristine template of [image], lets [init] warm the overlay,
  /// verifies with [probe] that the warm actually took, and returns the
  /// STOPPED machine's name ready to snapshot — or null on any failure.
  ///
  /// Used for both kinds of warm start: the exec image's git/curl/socat and a
  /// browser engine's own packages. The template carries NO secrets, NO
  /// worktree and no per-rig state — it never gets any: no broker secret, no
  /// port forwards, nothing synced in — so the snapshot is safe to share
  /// across every later rig and conversation.
  ///
  /// The caller deletes the machine; a builder that dies mid-flight leaves a
  /// labelled machine the next start's orphan sweep collects.
  Future<String?> _buildWarmTemplate(
    String binary,
    String image, {
    required String init,
    required String probe,
    List<String> mirrors = const [],
  }) async {
    // Unique per attempt: two servers with different data dirs share one
    // global machine store, and a fixed name would have them fighting over
    // one record.
    final template =
        'ccpack-tmpl-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
    try {
      await _runChecked(binary, [
        'machine', 'create',
        '--name', template,
        '--image', image,
        '--cpus', '2',
        '--mem', '1024',
        // The same disk shape real exec rigs get, so the snapshot's layout
        // matches what boots from it.
        '--storage', '8', '--overlay', '16',
        // Owned like every rig machine, so a crashed builder's template is
        // swept at the next service start instead of leaking forever.
        '--label', '$kSmolvmOwnerLabel=$kSmolvmOwnerValue',
        '--label', '$kSmolvmDataDirLabel=$_dataDir',
        '--label', 'cc-surface=pack-template',
        // Exactly the egress a real exec rig's warm-up needs and nothing
        // else: apt mirrors for the install, the image's own registry for
        // the pull.
        '--outbound-localhost-only',
        for (final host in {
          ...mirrors,
          ...registryHostsForImageRef(image),
        }) ...['--allow-host', host],
        '--init', init,
      ]);
      // Start blocks until init finishes, but verify anyway: an apt failure
      // exits init non-fatally and a snapshot of a HALF-warm template would
      // cache the breakage for every later rig.
      await _runChecked(binary, [
        'machine',
        'start',
        '--name',
        template,
      ], timeout: _startTimeout);
      final check = await _run(binary, [
        'machine',
        'exec',
        '--name',
        template,
        '--timeout',
        '30s',
        '--',
        'sh',
        '-c',
        probe,
      ]);
      if (check.exitCode != 0) {
        CcInfraLog.warning(
          'rig/smolvm: the template for $image never warmed (are the apt '
          'mirrors reachable?); keeping the plain-boot path',
        );
        await _deleteQuietly(binary, template);
        return null;
      }
      // A snapshot needs a stopped machine.
      await _runChecked(binary, [
        'machine',
        'stop',
        '--name',
        template,
      ], timeout: _deleteTimeout);
      return template;
    } on Object catch (e) {
      CcInfraLog.warning('rig/smolvm: template build for $image failed: $e');
      await _deleteQuietly(binary, template);
      return null;
    }
  }

  /// Removes pack files no pinned image references any more (an image bump
  /// changes the pack name) and the debris of interrupted builds.
  Future<void> _prunePacks() async {
    final dir = Directory(_packsDir);
    if (!dir.existsSync()) {
      return;
    }
    final wanted = {
      smolvmPackFileName(kSmolvmExecImage),
      smolvmPackFileName(kSmolvmBrowserImage),
      for (final engine in RigBrowserEngine.values)
        if (engine != RigBrowserEngine.chromium)
          smolvmPackFileName(
            smolvmBrowserImageFor(engine),
            variant: engine.wire,
          ),
    };
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is File && !wanted.contains(p.basename(entity.path))) {
        CcInfraLog.info(
          'rig/smolvm: pruning stale pack ${p.basename(entity.path)}',
        );
        await _deleteFileQuietly(entity.path);
      }
    }
  }

  Future<void> _deleteFileQuietly(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) {
        await file.delete();
      }
    } on Object catch (e) {
      CcInfraLog.warning('rig/smolvm: could not remove $path: $e');
    }
  }

  /// Waits until `machine exec` answers, which is the exec rig's whole
  /// readiness condition: its shell, the worktree sync and the credential
  /// helper all ride the same space.
  Future<void> _awaitExec(
    String binary,
    String name, {
    void Function(String step)? onProgress,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    final deadline = DateTime.now().add(timeout);
    onProgress?.call('Waiting for the guest to come up');
    Object? lastError;
    while (DateTime.now().isBefore(deadline)) {
      try {
        // `--timeout` bounds the CLI's own wait; the outer deadline is
        // checked only BETWEEN attempts, so without it one wedged exec made
        // the 120 s budget unreachable and the boot hung forever.
        final result = await _run(binary, [
          'machine',
          'exec',
          '--name',
          name,
          '--timeout',
          '10s',
          '--',
          'true',
        ], timeout: const Duration(seconds: 20));
        if (result.exitCode == 0) {
          return;
        }
        lastError = result.stderr;
      } on Object catch (e) {
        lastError = e;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    throw RigLaunchException(
      'The microVM did not answer within ${timeout.inSeconds}s '
      '(last error: $lastError).',
    );
  }

  /// Waits until [engine]'s automation endpoint answers on the forwarded host
  /// port.
  ///
  /// The first start pulls the image (and, for Firefox and WebKit, installs
  /// the engine) before the workload launches, so this is the long pole of a
  /// cold browser rig and the timeout is sized for it.
  ///
  /// Each engine is asked a question only a LIVE endpoint can answer, never
  /// just "does the port accept". That distinction is the whole probe on two
  /// of the three: the guest's socat relay accepts before the browser listens
  /// and drops each such connection on its own, so a bare TCP connect reports
  /// ready mid-boot and the attach that follows fails against nothing.
  Future<void> _awaitBrowser(
    RigBrowserEngine engine,
    int port, {
    void Function(String step)? onProgress,
    Duration timeout = const Duration(seconds: 180),
  }) async {
    final deadline = DateTime.now().add(timeout);
    onProgress?.call('Waiting for ${engine.label}');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    // What to ask, and with which `Host`. Firefox rejects a request whose
    // Host header names a port other than its own — including on plain HTTP —
    // so the probe has to speak to it the same way the client later will, or
    // it measures the relay rather than the browser.
    final (path, hostHeader) = switch (engine) {
      RigBrowserEngine.chromium => ('/json/version', null),
      RigBrowserEngine.firefox => (
        '/',
        '127.0.0.1:${browserRigEndpointPort(engine)}',
      ),
      RigBrowserEngine.webkit => ('/status', null),
    };
    try {
      while (DateTime.now().isBefore(deadline)) {
        try {
          // Per-ATTEMPT deadline, not just a connection timeout. A relay that
          // accepted and then stalled gives a connected socket that never
          // answers — `connectionTimeout` has already been satisfied by then
          // and the loop would wait on that one request forever, never
          // reaching its own deadline.
          final request = await client.get('127.0.0.1', port, path);
          if (hostHeader != null) {
            request.headers.set(HttpHeaders.hostHeader, hostHeader);
          }
          final response = await request.close().timeout(
            const Duration(seconds: 5),
          );
          final body = await response
              .transform(utf8.decoder)
              .join()
              .timeout(const Duration(seconds: 5));
          if (response.statusCode == HttpStatus.ok &&
              _browserReady(engine, body)) {
            return;
          }
        } on Object {
          // Not up yet.
        }
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    } finally {
      client.close(force: true);
    }
    throw RigLaunchException(
      '${engine.label} did not come up within ${timeout.inSeconds}s.',
    );
  }

  /// Whether [body] is an endpoint saying it can take a session.
  ///
  /// WebKit's driver serves `/status` from the moment it binds, while
  /// MiniBrowser may still be waiting on Xvfb — `ready` is the field that
  /// tells the two apart, and attaching before it is true fails the session
  /// with a launch error rather than retrying.
  static bool _browserReady(RigBrowserEngine engine, String body) {
    if (engine != RigBrowserEngine.webkit) {
      return true;
    }
    try {
      final decoded = jsonDecode(body);
      final value = decoded is Map ? decoded['value'] : null;
      return value is Map && value['ready'] == true;
    } on FormatException {
      return false;
    }
  }

  /// Installs the git credential helper into an exec guest.
  ///
  /// Waits for git first: the init command may still be apt-installing it on
  /// a cold machine. The script travels base64'd so nothing in it is at the
  /// mercy of shell quoting.
  Future<void> _installCredentialHelper(
    String binary,
    String name,
    String rigId,
  ) async {
    final encoded = base64Encode(utf8.encode(kSmolvmCredentialHelper));
    // One string, built outside the argv list: adjacent string literals inside
    // a list literal are a lint here.
    final command =
        'while ! command -v git >/dev/null 2>&1; do sleep 2; done; '
        'echo $encoded | base64 -d > /usr/local/bin/git-credential-ccrig && '
        'chmod 755 /usr/local/bin/git-credential-ccrig && '
        'git config --global credential.helper ccrig';
    final result = await _run(binary, [
      'machine',
      'exec',
      '--name',
      name,
      '--timeout',
      '180s',
      '--',
      'sh',
      '-c',
      command,
    ], timeout: const Duration(seconds: 200));
    if (result.exitCode != 0) {
      // Not fatal to the boot: the terminal works without it, only `git push`
      // to a forge does not. Say so, loudly, in the log.
      CcInfraLog.warning(
        'rig/$rigId: credential helper install failed: ${result.stderr}',
      );
    }
  }

  Future<String?> _resolveBinary() async {
    final override = _binaryOverride;
    if (override != null) {
      return override;
    }
    final cached = _resolvedBinary;
    if (cached != null) {
      return cached;
    }
    try {
      final result = await Process.run(Platform.isWindows ? 'where' : 'which', [
        'smolvm',
      ]);
      if (result.exitCode == 0) {
        final path = '${result.stdout}'.split('\n').first.trim();
        if (path.isNotEmpty) {
          return path;
        }
      }
    } on Object {
      // No PATH lookup available; fall through to the well-known locations.
    }
    final home = Platform.environment['HOME'];
    if (home != null) {
      for (final candidate in [
        p.join(home, '.local', 'bin', 'smolvm'),
        p.join(home, '.smolvm', 'smolvm'),
      ]) {
        if (File(candidate).existsSync()) {
          return candidate;
        }
      }
    }
    return null;
  }

  /// Runs a smolvm CLI call under a HARD deadline.
  ///
  /// Every call in this backend goes through here, and every one of them is
  /// bounded. The alternative is not theoretical: `Process.run` waits forever,
  /// so a single wedged CLI invocation — a `machine exec` into a guest whose
  /// init hung, a `machine delete` blocked on a read-only pack layer — hung
  /// the whole path it was on. The boot readiness loop checked its 120 s
  /// deadline only BETWEEN attempts, so one stuck attempt made the deadline
  /// unreachable; teardown and the startup sweep had no deadline at all.
  ///
  /// `Process.run` cannot be cancelled, so the real path starts the process
  /// itself and SIGKILLs it on expiry. A timeout comes back as a synthetic
  /// exit 124 (the conventional code) with a stderr that says so, which every
  /// `exitCode != 0` caller already handles and [_runChecked] turns into a
  /// named [RigToolException].
  Future<ProcessResult> _run(
    String binary,
    List<String> args, {
    Duration timeout = _defaultCliTimeout,
  }) async {
    final runFn = _runFn;
    if (runFn != null) {
      // The test seam answers immediately; the deadline still applies so a
      // fake that never completes cannot hang a test forever.
      return runFn(
        binary,
        args,
      ).timeout(timeout, onTimeout: () => _timedOut(binary, args, timeout));
    }
    final process = await Process.start(binary, args);
    final stdoutFuture = process.stdout.transform(utf8.decoder).join();
    final stderrFuture = process.stderr.transform(utf8.decoder).join();
    try {
      final exitCode = await process.exitCode.timeout(timeout);
      return ProcessResult(
        process.pid,
        exitCode,
        await stdoutFuture,
        await stderrFuture,
      );
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
      // Drain, so the killed child's pipes do not keep this isolate's
      // subscriptions alive.
      unawaited(stdoutFuture.catchError((_) => ''));
      unawaited(stderrFuture.catchError((_) => ''));
      return _timedOut(binary, args, timeout);
    }
  }

  /// The default deadline for a smolvm control-plane call.
  ///
  /// Generous, because these talk to a hypervisor over a local socket and a
  /// slow host is not a broken one — but finite, which is the whole point.
  static const Duration _defaultCliTimeout = Duration(seconds: 60);

  /// The deadline for `machine create` / `machine start`.
  ///
  /// The FIRST start of an image pulls it (hundreds of megabytes over the
  /// network) before the workload launches, so this covers a cold pull on a
  /// slow link rather than the steady-state boot, which is sub-second.
  static const Duration _startTimeout = Duration(minutes: 20);

  /// The deadline for `machine delete`, including the read-only-pack retry.
  static const Duration _deleteTimeout = Duration(minutes: 3);

  /// How long a runtime directory with no machine is left alone.
  ///
  /// Longer than the gap between writing the directory and `machine create`
  /// returning (milliseconds to seconds), far shorter than anything an
  /// operator would notice as a leak. Injectable so a test can assert the
  /// sweep itself rather than wait ten minutes for it.
  static const Duration _defaultRuntimeDirGrace = Duration(minutes: 10);

  /// Whether [path] was created within [_runtimeDirGrace].
  ///
  /// An unreadable timestamp reads as RECENT: "I could not tell" is never a
  /// licence to delete a live rig's broker secret.
  bool _isRecentRuntimeDir(String path) {
    if (_runtimeDirGrace <= Duration.zero) {
      return false;
    }
    try {
      return DateTime.now().difference(Directory(path).statSync().changed) <
          _runtimeDirGrace;
    } on Object {
      return true;
    }
  }

  /// The deadline for building an image pack. Disk work over a
  /// multi-gigabyte rootfs, and entirely off the boot path — but a `pack
  /// create` that never returns would otherwise hold its slot forever.
  static const Duration _packTimeout = Duration(minutes: 30);

  static ProcessResult _timedOut(
    String binary,
    List<String> args,
    Duration timeout,
  ) {
    CcInfraLog.warning(
      'rig/smolvm: `$binary ${args.join(' ')}` exceeded '
      '${timeout.inSeconds}s and was killed.',
    );
    return ProcessResult(
      -1,
      124,
      '',
      'smolvm ${args.join(' ')} timed out after ${timeout.inSeconds}s and was '
          'killed.',
    );
  }

  Future<ProcessResult> _runChecked(
    String binary,
    List<String> args, {
    String? hint,
    Duration timeout = _defaultCliTimeout,
  }) async {
    final ProcessResult result;
    try {
      result = await _run(binary, args, timeout: timeout);
    } on Object catch (e) {
      throw RigToolException(
        tool: 'smolvm',
        arguments: args,
        stderr: '$e',
        hint: hint,
      );
    }
    if (result.exitCode != 0) {
      throw RigToolException(
        tool: 'smolvm',
        exitCode: result.exitCode,
        arguments: args,
        stderr: '${result.stderr}',
        hint: hint,
      );
    }
    return result;
  }

  Future<void> _deleteQuietly(String binary, String name) async {
    try {
      final result = await _run(binary, [
        'machine',
        'delete',
        '--name',
        name,
        '-f',
      ], timeout: _deleteTimeout);
      if (result.exitCode == 0) {
        return;
      }
      // Pack-based machines: the extracted rootfs keeps the image's own
      // modes (0555 directories), and `machine delete` does not force them
      // writable before removing — so the delete fails with EACCES and the
      // machine's multi-gigabyte cache directory leaks, once per rig,
      // forever. The error names the path; make its tree writable and retry.
      final stderr = '${result.stderr}';
      final blockedPath = smolvmBlockedDeletePath(stderr);
      if (blockedPath == null) {
        CcInfraLog.warning('rig/smolvm: delete of $name failed: $stderr');
        return;
      }
      CcInfraLog.info(
        'rig/smolvm: delete of $name hit read-only pack layers; making '
        '$blockedPath writable and retrying',
      );
      await Process.run('chmod', ['-R', 'u+w', blockedPath]);
      final retry = await _run(binary, [
        'machine',
        'delete',
        '--name',
        name,
        '-f',
      ], timeout: _deleteTimeout);
      if (retry.exitCode != 0) {
        // The record may be half-deleted ("vm not found") while the data
        // directory survives. The `name` file inside it is the machine's own
        // self-identification — matching it is what makes removing the tree
        // ourselves safe rather than a guess.
        final marker = File(p.join(blockedPath, 'name'));
        if (marker.existsSync() &&
            marker.readAsStringSync().trim() == name &&
            Directory(blockedPath).existsSync()) {
          await _deleteDirTreeQuietly(blockedPath);
        } else {
          CcInfraLog.warning(
            'rig/smolvm: delete of $name still failing: ${retry.stderr}',
          );
        }
      }
    } on Object catch (e) {
      CcInfraLog.warning('rig/smolvm: delete of $name failed: $e');
    }
  }

  /// Recursively removes a smolvm VM data directory this backend has proven
  /// (by its `name` marker) belongs to a machine of ours.
  Future<void> _deleteDirTreeQuietly(String path) async {
    try {
      await Directory(path).delete(recursive: true);
      CcInfraLog.info('rig/smolvm: reclaimed orphaned machine data at $path');
    } on Object catch (e) {
      CcInfraLog.warning('rig/smolvm: could not remove $path: $e');
    }
  }

  Future<void> _deleteDirQuietly(String path) async {
    try {
      final dir = Directory(path);
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    } on Object catch (e) {
      CcInfraLog.warning('rig/smolvm: could not remove $path: $e');
    }
  }

  Future<int> _freePort() async {
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = socket.port;
    await socket.close();
    return port;
  }

  Future<void> _chmod(String mode, String path) async {
    final result = await Process.run('chmod', [mode, path]);
    if (result.exitCode != 0) {
      throw RigToolException(
        tool: 'chmod',
        exitCode: result.exitCode,
        arguments: [mode, path],
        stderr: '${result.stderr}',
      );
    }
  }

  String _randomToken() {
    final bytes = List<int>.generate(24, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static final Random _random = Random.secure();
}
