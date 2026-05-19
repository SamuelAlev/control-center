/// The privilege tier of a connected RPC session, derived from the paired
/// device's `platform`.
///
/// Authentication (the PSK handshake) proves a session *is* a paired device;
/// this gates *what* that device may do. A first-party Control Center client
/// ([fullClient], a web/desktop app) may invoke privileged ops — notably the
/// `pairing.*` device-management ops that mint PSKs and revoke devices. A
/// companion phone ([phone], the cc_remote PWA) must never reach those: a phone
/// that somehow obtained a PSK still authenticates as `platform=ios/android →
/// [phone]` and is denied before the handler runs (defense in depth — the PSK
/// gates *authentication*, this gates *privilege*).
enum SessionCapability {
  /// A first-party Control Center client (web / desktop). Full privilege.
  fullClient,

  /// A companion phone (cc_remote). Restricted — cannot manage pairings.
  phone;

  /// Derives the capability from a paired device's `platform` string. Unknown
  /// or companion platforms resolve to [phone] (least privilege — fail closed).
  static SessionCapability fromPlatform(String? platform) => switch (platform) {
    'web' || 'desktop' => SessionCapability.fullClient,
    _ => SessionCapability.phone,
  };
}
