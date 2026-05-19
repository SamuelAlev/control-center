// In-app UI component visual diff (PRD 18 §4). The pure-Dart server cannot
// render Flutter widgets in-process, so before/after pixels come from a
// headless `flutter test` golden harness run in the PR's worktree at base and
// head SHAs (a declared host capability). These value objects describe the
// resulting snapshot pair + region diff; image bytes are served via
// `/proxy/media`, never embedded here.
//
// ignore_for_file: sort_constructors_first

import 'package:collection/collection.dart';

/// The lifecycle status of a visual-diff snapshot.
enum VisualDiffStatus {
  /// The component is new (no base render).
  added,

  /// The component changed between base and head.
  changed,

  /// The component was removed (no head render).
  removed,

  /// The operator approved the change as intended (clears the visual gate).
  approved,

  /// The base and head renders are pixel-identical (no visible change).
  unchanged;

  /// The stable wire/storage name.
  String get wireName => name;

  /// Parses a stored/wire name, defaulting to [changed].
  static VisualDiffStatus fromName(String? name) =>
      VisualDiffStatus.values.firstWhere(
        (s) => s.name == name,
        orElse: () => VisualDiffStatus.changed,
      );

  /// Whether this status clears the visual approval gate. [unchanged],
  /// [approved] and [added] clear; [changed] holds until approved; [removed]
  /// holds until approved.
  bool get clearsGate =>
      this == VisualDiffStatus.unchanged ||
      this == VisualDiffStatus.approved ||
      this == VisualDiffStatus.added;
}

/// One render viewport of the golden matrix (PRD 18 clarifications: viewport
/// set {phone, desktop} × {light, dark}).
class VisualDiffVariant {
  /// Creates a [VisualDiffVariant].
  const VisualDiffVariant({
    required this.viewport,
    required this.brightness,
    required this.status,
    this.baseImageRef,
    this.headImageRef,
    this.diffImageRef,
    this.changedRegionPercent = 0.0,
  }) : assert(
         changedRegionPercent >= 0.0 && changedRegionPercent <= 100.0,
         'changedRegionPercent must be in [0, 100]',
       );

  /// Viewport name (`phone` / `desktop`).
  final String viewport;

  /// Brightness (`light` / `dark`).
  final String brightness;

  /// This variant's status.
  final VisualDiffStatus status;

  /// Media ref for the base (pre-change) render, served via `/proxy/media`.
  final String? baseImageRef;

  /// Media ref for the head (post-change) render.
  final String? headImageRef;

  /// Media ref for the changed-region highlight overlay, when computed.
  final String? diffImageRef;

  /// Percentage of pixels that changed (drives the "how big is this change"
  /// signal).
  final double changedRegionPercent;

  /// Builds from JSON.
  factory VisualDiffVariant.fromJson(Map<String, dynamic> json) =>
      VisualDiffVariant(
        viewport: json['viewport'] as String? ?? 'phone',
        brightness: json['brightness'] as String? ?? 'light',
        status: VisualDiffStatus.fromName(json['status'] as String?),
        baseImageRef: json['baseImageRef'] as String?,
        headImageRef: json['headImageRef'] as String?,
        diffImageRef: json['diffImageRef'] as String?,
        changedRegionPercent:
            (json['changedRegionPercent'] as num?)?.toDouble() ?? 0.0,
      );

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'viewport': viewport,
    'brightness': brightness,
    'status': status.wireName,
    if (baseImageRef != null) 'baseImageRef': baseImageRef,
    if (headImageRef != null) 'headImageRef': headImageRef,
    if (diffImageRef != null) 'diffImageRef': diffImageRef,
    'changedRegionPercent': changedRegionPercent,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisualDiffVariant &&
          runtimeType == other.runtimeType &&
          viewport == other.viewport &&
          brightness == other.brightness &&
          status == other.status &&
          baseImageRef == other.baseImageRef &&
          headImageRef == other.headImageRef &&
          diffImageRef == other.diffImageRef &&
          changedRegionPercent == other.changedRegionPercent;

  @override
  int get hashCode => Object.hash(
    viewport,
    brightness,
    status,
    baseImageRef,
    headImageRef,
    diffImageRef,
    changedRegionPercent,
  );
}

/// A visual-diff snapshot for one Widgetbook use-case / component (PRD 18 §4),
/// persisted in `visual_diff_snapshots`.
class VisualDiffSnapshot {
  /// Creates a [VisualDiffSnapshot].
  const VisualDiffSnapshot({
    required this.id,
    required this.workspaceId,
    required this.repoId,
    required this.prExternalId,
    required this.componentKey,
    required this.status,
    this.componentTitle = '',
    this.variants = const [],
    this.headSha,
  }) : assert(componentKey != '', 'componentKey must not be empty');

  /// Row id.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// Owning repo.
  final String repoId;

  /// The PR (space node) this snapshot belongs to.
  final String prExternalId;

  /// Stable key of the Widgetbook use-case / component.
  final String componentKey;

  /// Human-readable component name.
  final String componentTitle;

  /// The aggregate status across all variants.
  final VisualDiffStatus status;

  /// Per-viewport × brightness render variants.
  final List<VisualDiffVariant> variants;

  /// Head SHA this snapshot was computed against.
  final String? headSha;

  /// Whether this snapshot currently holds the visual gate (a change awaiting
  /// approval).
  bool get blocksGate => !status.clearsGate;

  /// The largest changed-region percentage across variants (0 when identical).
  double get maxChangedPercent => variants.isEmpty
      ? 0.0
      : variants
            .map((v) => v.changedRegionPercent)
            .reduce((a, b) => a > b ? a : b);

  /// Builds from JSON.
  factory VisualDiffSnapshot.fromJson(Map<String, dynamic> json) =>
      VisualDiffSnapshot(
        id: json['id'] as String? ?? '',
        workspaceId: json['workspaceId'] as String? ?? '',
        repoId: json['repoId'] as String? ?? '',
        prExternalId: json['prExternalId'] as String? ?? '',
        componentKey: json['componentKey'] as String? ?? '',
        componentTitle: json['componentTitle'] as String? ?? '',
        status: VisualDiffStatus.fromName(json['status'] as String?),
        variants: (json['variants'] as List? ?? const [])
            .whereType<Map>()
            .map((m) => VisualDiffVariant.fromJson(m.cast<String, dynamic>()))
            .toList(),
        headSha: json['headSha'] as String?,
      );

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'workspaceId': workspaceId,
    'repoId': repoId,
    'prExternalId': prExternalId,
    'componentKey': componentKey,
    'componentTitle': componentTitle,
    'status': status.wireName,
    'variants': variants.map((v) => v.toJson()).toList(),
    if (headSha != null) 'headSha': headSha,
  };

  /// Returns a copy with a new [status] (used by the approve gate).
  VisualDiffSnapshot withStatus(VisualDiffStatus status) => VisualDiffSnapshot(
    id: id,
    workspaceId: workspaceId,
    repoId: repoId,
    prExternalId: prExternalId,
    componentKey: componentKey,
    componentTitle: componentTitle,
    status: status,
    variants: variants,
    headSha: headSha,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisualDiffSnapshot &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          repoId == other.repoId &&
          prExternalId == other.prExternalId &&
          componentKey == other.componentKey &&
          componentTitle == other.componentTitle &&
          status == other.status &&
          const ListEquality<VisualDiffVariant>().equals(
            variants,
            other.variants,
          ) &&
          headSha == other.headSha;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    repoId,
    prExternalId,
    componentKey,
    componentTitle,
    status,
    Object.hashAll(variants),
    headSha,
  );
}
