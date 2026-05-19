import 'package:cc_domain/features/rigs/domain/value_objects/enclosure_backend.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';

/// What one enclosure backend can do on this host, right now.
///
/// Shaped like `SandboxBackendCapabilities` on purpose: the same "available /
/// requiresInstall / installHint / note" vocabulary, so the settings surface
/// reads the same for a sandbox and for a rig.
class RigBackendCapabilities {
  /// Creates a [RigBackendCapabilities].
  const RigBackendCapabilities({
    required this.backend,
    required this.available,
    this.surfaces = const {},
    this.browserEngines = const {},
    this.supportsTerminals = false,
    this.requiresInstall = false,
    this.installHint,
    this.note,
    this.missingImages = const [],
    this.version,
  });

  /// An unavailable backend, with the reason and (optionally) how to fix it.
  factory RigBackendCapabilities.unavailable(
    EnclosureBackend backend, {
    required String note,
    bool requiresInstall = false,
    String? installHint,
  }) => RigBackendCapabilities(
    backend: backend,
    available: false,
    requiresInstall: requiresInstall,
    installHint: installHint,
    note: note,
  );

  /// Which backend this describes.
  final EnclosureBackend backend;

  /// Whether it can boot a rig on this host right now.
  final bool available;

  /// The surfaces it can host. A backend can be available for terminals and
  /// still not offer the mobile surface, so this is a set rather than a flag —
  /// the UI hides what a backend structurally cannot do rather than offering
  /// it and failing at boot.
  final Set<RigSurface> surfaces;

  /// Which browsers this backend can boot, when it hosts
  /// [RigSurface.browser] at all.
  ///
  /// A set for the same reason [surfaces] is: the tab menu offers exactly
  /// what the connected server can boot. An entry the server never sends is
  /// an entry the client must not show — a "Firefox (VM)" item on a server
  /// that cannot start one is a button whose only outcome is an error two
  /// minutes later.
  final Set<RigBrowserEngine> browserEngines;

  /// Whether this backend can host an enclosed TERMINAL right now.
  ///
  /// Separate from [surfaces] because the terminal boots the exec image — a
  /// shell with no display — while a surface entry means the INTERACTIVE
  /// image for it is on disk. A host with only the exec image downloaded can
  /// run VM terminals and no `computer_use`, and the UI needs to offer
  /// exactly that.
  final bool supportsTerminals;

  /// True when installing something would flip [available].
  final bool requiresInstall;

  /// The command that would install it, shown verbatim.
  final String? installHint;

  /// Operator-facing note (accelerator in use, why it is unavailable).
  final String? note;

  /// Base images that still need downloading before a surface can be used.
  /// Separate from [requiresInstall]: the toolchain is present, the artifacts
  /// are not, and the fix is a download the user starts, not a package manager.
  final List<String> missingImages;

  /// The detected binary version, when known.
  final String? version;

  /// Whether [surface] can be hosted here right now.
  bool supports(RigSurface surface) => available && surfaces.contains(surface);

  /// Whether [engine] can be booted here right now.
  bool supportsEngine(RigBrowserEngine engine) =>
      supports(RigSurface.browser) && browserEngines.contains(engine);

  /// JSON form for the `rig.detect` RPC op.
  Map<String, dynamic> toJson() => {
    'backend': backend.wire,
    'label': backend.label,
    'available': available,
    'accelerated': backend.isAccelerated,
    // Stated explicitly so the UI can warn rather than let a user assume the
    // mobile surface is contained the way the VM surfaces are.
    'enforcedEgress': backend.hasEnforcedEgress,
    'surfaces': [for (final s in surfaces) s.wire],
    'browserEngines': [for (final e in browserEngines) e.wire],
    'terminals': supportsTerminals,
    'requiresInstall': requiresInstall,
    if (installHint != null) 'installHint': installHint,
    if (note != null) 'note': note,
    if (missingImages.isNotEmpty) 'missingImages': missingImages,
    if (version != null) 'version': version,
  };

  /// Reads capabilities from [json] (the client side of `rig.detect`).
  static RigBackendCapabilities fromJson(Map<String, dynamic> json) =>
      RigBackendCapabilities(
        // An unrecognised backend name is a server this build does not fully
        // understand. The enum has no "unknown" member (every switch over it
        // would have to grow a case), so the value falls back — but the entry
        // is forced UNAVAILABLE below and carries a note saying why, because
        // "QEMU with Hypervisor.framework, ready to boot" is an actively
        // wrong claim about a backend we cannot name.
        backend:
            EnclosureBackend.fromWire(json['backend'] as String?) ??
            EnclosureBackend.qemuHvf,
        available:
            EnclosureBackend.fromWire(json['backend'] as String?) != null &&
            (json['available'] as bool? ?? false),
        surfaces: {
          for (final s in (json['surfaces'] as List? ?? const []))
            ?RigSurface.fromWire(s as String?),
        },
        // An OLDER server names no engines while still hosting the browser
        // surface — it only ever had Chromium. Reading that as "no engines"
        // would grey out the browser tab against a server that boots one
        // perfectly well, so the absent field means Chromium rather than
        // nothing. An empty LIST is different and is taken at its word: that
        // is a current server saying it cannot boot any browser.
        browserEngines: json.containsKey('browserEngines')
            ? {
                for (final e in (json['browserEngines'] as List? ?? const []))
                  ?RigBrowserEngine.fromWire(e as String?),
              }
            : const {RigBrowserEngine.chromium},
        supportsTerminals: json['terminals'] as bool? ?? false,
        requiresInstall: json['requiresInstall'] as bool? ?? false,
        installHint: json['installHint'] as String?,
        note: EnclosureBackend.fromWire(json['backend'] as String?) == null
            ? 'This server reports a backend ("${json['backend']}") this '
                  'build does not know. Update the app to use it.'
            : json['note'] as String?,
        missingImages: [
          for (final i in (json['missingImages'] as List? ?? const []))
            if (i is String) i,
        ],
        version: json['version'] as String?,
      );
}

/// The whole host's rig story: every backend, probed.
class RigCapabilities {
  /// Creates a [RigCapabilities].
  const RigCapabilities({required this.backends});

  /// Per-backend results, in preference order (best first).
  final List<RigBackendCapabilities> backends;

  /// Nothing available anywhere.
  static const RigCapabilities none = RigCapabilities(backends: []);

  /// Whether any backend can host [surface].
  bool supports(RigSurface surface) => backends.any((b) => b.supports(surface));

  /// Every browser this host can boot, across all backends.
  Set<RigBrowserEngine> get browserEngines => {
    for (final b in backends)
      if (b.supports(RigSurface.browser)) ...b.browserEngines,
  };

  /// Whether any backend at all is usable.
  bool get anyAvailable => backends.any((b) => b.available);

  /// The backend to use for [surface] — the first available one that supports
  /// it, preferring hardware acceleration.
  ///
  /// Returns null when nothing can host it. The caller must NOT fall back to
  /// "some other surface" on null: an agent that asked for a browser and got a
  /// bare desktop has been lied to.
  RigBackendCapabilities? preferredFor(RigSurface surface) {
    RigBackendCapabilities? slowFallback;
    for (final b in backends) {
      if (!b.supports(surface)) {
        continue;
      }
      if (b.backend.isAccelerated) {
        return b;
      }
      slowFallback ??= b;
    }
    return slowFallback;
  }

  /// JSON form for `rig.detect`.
  Map<String, dynamic> toJson() => {
    'backends': [for (final b in backends) b.toJson()],
  };

  /// Reads capabilities from [json].
  static RigCapabilities fromJson(Map<String, dynamic> json) => RigCapabilities(
    backends: [
      for (final b in (json['backends'] as List? ?? const []))
        if (b is Map)
          RigBackendCapabilities.fromJson(b.cast<String, dynamic>()),
    ],
  );
}
