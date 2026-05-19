/// A capability an install may or may not be entitled to.
///
/// Named after what the operator gets, not after a plan — plans are a
/// commercial packaging decision that changes; the capability set is what the
/// code branches on.
enum Entitlement {
  /// Workspace-defined custom roles (`roles.*`).
  customRoles('custom_roles'),

  /// SCIM 2.0 user provisioning + deprovisioning.
  scimProvisioning('scim_provisioning'),

  /// Streaming the audit trail to an external SIEM.
  auditStreaming('audit_streaming'),

  /// The install-wide managed policy clamp.
  managedPolicy('managed_policy'),

  /// Organizations above workspaces (hosted tier).
  organizations('organizations');

  const Entitlement(this.wire);

  /// Stable wire name.
  final String wire;
}

/// Whether this install may use a given capability.
///
/// **Self-hosted is entitled to everything.** This port exists so the hosted
/// offering can gate a capability WITHOUT the gate being a runtime `if` a
/// client could probe or a flag a client could flip: the composition root
/// consults it when REGISTERING ops, so an unentitled capability's ops are
/// genuinely absent and the dispatcher answers `opUnknown` — the same
/// structural absence the demo profile uses.
///
/// The line the packaging holds: never gate a SAFETY control. The guardrail
/// engine, the audit log and its local export, fixed roles and per-repo
/// grants are unconditional. What a paid tier buys is administering those
/// controls at scale — provisioning, streaming, custom roles, org-wide
/// policy — never the controls themselves. A free tier that is less SAFE is
/// a product bug, and a prospect who finds the audit log behind a paywall
/// reads it as extortion.
abstract interface class EntitlementsPort {
  /// Whether [entitlement] is available on this install.
  bool has(Entitlement entitlement);
}

/// The self-hosted implementation: everything is available.
class AllEntitlements implements EntitlementsPort {
  /// Creates an [AllEntitlements].
  const AllEntitlements();

  @override
  bool has(Entitlement entitlement) => true;
}
