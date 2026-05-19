/// Lifecycle policy for paired remote-control devices: how long a pairing offer
/// and an approved credential stay valid, and when an idle device must be
/// re-approved.
///
/// Centralizes the durations so the create path (`generatePairingPayload`), the
/// confirm path (`confirmPairedDevice`), and the desktop connect gates
/// (`RemoteControlServer`) agree on one policy. The point is finding #3: a
/// pairing must not be a *permanent* backdoor — every credential is time-boxed,
/// and an idle approved device drops back to requiring re-approval.
class RemotePairingLifecycle {
  RemotePairingLifecycle._();

  /// How long a freshly-generated, un-confirmed pairing offer stays valid. Past
  /// this, an un-approved device is purged (PSK + row) at the connect gate. Set
  /// to match the QR's advertised ~5-minute window.
  static const Duration pairingOfferWindow = Duration(minutes: 5);

  /// Absolute lifetime of an approved credential, measured from confirmation.
  /// After this the phone must re-pair (the desktop fails it closed).
  static const Duration credentialLifetime = Duration(days: 30);

  /// If an approved device has not connected within this window, its next
  /// connect requires fresh user approval (it is dropped back to
  /// `pendingConfirm`) rather than auto-resuming a long-dormant trust.
  static const Duration reapprovalAfterIdle = Duration(days: 14);

  /// The expiry instant for a new pairing offer, given [now].
  static DateTime offerExpiry(DateTime now) => now.add(pairingOfferWindow);

  /// The expiry instant for a newly-confirmed credential, given [now].
  static DateTime credentialExpiry(DateTime now) => now.add(credentialLifetime);

  /// Whether [expiresAt] (nullable) is in the past relative to [now]. Null means
  /// "no expiry recorded" (a legacy row) and is treated as not expired.
  static bool isExpired(DateTime? expiresAt, DateTime now) =>
      expiresAt != null && now.isAfter(expiresAt);

  /// Whether an approved device last seen at [lastSeenAt] has been idle long
  /// enough to require re-approval on its next connect.
  static bool needsReapproval(DateTime? lastSeenAt, DateTime now) =>
      lastSeenAt != null && now.difference(lastSeenAt) > reapprovalAfterIdle;
}
