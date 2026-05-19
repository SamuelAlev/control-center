/// A paired remote-control device (a phone) the desktop trusts to drive it.
///
/// Holds **metadata only** — the device id, label, platform, the secure-store
/// key reference for its PSK ([pskRef]), the pinned remote DTLS fingerprint
/// ([remoteFingerprint]), and its [status]. The PSK itself is never carried
/// here; it lives in the platform secure store keyed by [pskRef].
///
/// Devices are deliberately **global**, NOT workspace-scoped: a paired phone
/// spans every workspace (it has its own workspace switcher), so [workspaceId]
/// is merely the workspace that was active at pairing time (a seed for the
/// session binding) and is nullable. This is the documented cross-workspace
/// exception — pairing metadata is not workspace-scoped data.
class PairedDevice {
  /// Creates a [PairedDevice].
  const PairedDevice({
    required this.id,
    required this.label,
    required this.platform,
    required this.pskRef,
    required this.status,
    required this.pairedAt,
    this.workspaceId,
    this.remoteFingerprint,
    this.lastSeenAt,
    this.expiresAt,
  });

  /// Unique device id (generated at pairing; also the broker room code).
  final String id;

  /// Workspace active at pairing time (seed for the session binding). Null when
  /// the device was paired with no active workspace.
  final String? workspaceId;

  /// User-editable label (e.g. "iPhone").
  final String label;

  /// Platform string reported by the phone ("ios", "android", "web").
  final String platform;

  /// Secure-store key referencing this device's PSK (`paired_device_psk_<id>`).
  final String pskRef;

  /// Pinned remote DTLS fingerprint (TOFU on first connect), or null.
  final String? remoteFingerprint;

  /// Pairing status: `pendingConfirm`, `active`, or `revoked`.
  final String status;

  /// When the device was paired.
  final DateTime pairedAt;

  /// When the device last connected, or null.
  final DateTime? lastSeenAt;

  /// When this credential becomes invalid, or null for "no expiry".
  final DateTime? expiresAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PairedDevice &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          label == other.label &&
          platform == other.platform &&
          pskRef == other.pskRef &&
          remoteFingerprint == other.remoteFingerprint &&
          status == other.status &&
          pairedAt == other.pairedAt &&
          lastSeenAt == other.lastSeenAt &&
          expiresAt == other.expiresAt;

  @override
  int get hashCode => Object.hash(
        id,
        workspaceId,
        label,
        platform,
        pskRef,
        remoteFingerprint,
        status,
        pairedAt,
        lastSeenAt,
        expiresAt,
      );
}
