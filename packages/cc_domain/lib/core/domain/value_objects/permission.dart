import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';

/// What a permission lets a principal DO within its domain, coarsest last.
///
/// Four tiers, not one per verb: the catalog is DERIVED from the op surface
/// (~550 ops), so a finer axis would produce a permission list no human can
/// hold in their head and no admin can meaningfully edit.
///
/// [own] exists because the role ladder has five rungs and collapsing the top
/// two would WIDEN access: `workspace.transferOwnership` and
/// `workspace.import` are owner-floored, and mapping them onto `administer`
/// would have handed every admin a permission the dispatcher refuses them.
/// The parity ratchet caught exactly that.
enum PermissionTier {
  /// Read the domain's data.
  read(0),

  /// Create / update / delete within the domain (ordinary collaboration).
  write(1),

  /// Govern the domain: its policy, its membership, its destructive verbs.
  administer(2),

  /// Reserved to the workspace owner (ownership handover, whole-workspace
  /// import).
  own(3);

  const PermissionTier(this.rank);

  /// Order: higher includes lower (`administer` implies `write` implies
  /// `read`).
  final int rank;

  /// Whether this tier includes [other].
  bool includes(PermissionTier other) => rank >= other.rank;

  /// Parses a wire tier name, or null.
  static PermissionTier? fromWire(String value) {
    for (final tier in PermissionTier.values) {
      if (tier.name == value) {
        return tier;
      }
    }
    return null;
  }
}

/// One entry in the permission catalog: `<domain>:<tier>` — e.g.
/// `tickets:write`, `members:administer`.
///
/// **The catalog is DERIVED, never hand-annotated.** A [Permission] is
/// computed from an op's name prefix and its effective role floor
/// (`Permission.forOp` in cc_host), so every one of the ~550 declared ops
/// carries one without anybody typing it. That is deliberate: the property
/// that keeps this surface honest is that a NEW op is gated by default, and a
/// model requiring 550 hand annotations would drift within one release.
///
/// The catalog lives in CODE (pinned by a ratchet test), not in a table: it
/// must be identical on every install running the same binary. A table would
/// let an install's stored catalog desync from the code that enforces it,
/// which is unsupportable and a real security risk. Role DEFINITIONS are
/// data; the vocabulary they are written in is code.
class Permission implements Comparable<Permission> {
  /// Creates a permission for [domain] at [tier].
  const Permission(this.domain, this.tier);

  /// The op-name prefix this permission governs (`tickets`, `members`,
  /// `server_settings`).
  final String domain;

  /// What it allows within that domain.
  final PermissionTier tier;

  /// The stable wire form, `domain:tier`.
  String get wire => '$domain:${tier.name}';

  /// Parses a `domain:tier` wire string, or null when malformed/unknown.
  static Permission? fromWire(String value) {
    final sep = value.indexOf(':');
    if (sep <= 0 || sep == value.length - 1) {
      return null;
    }
    final tier = PermissionTier.fromWire(value.substring(sep + 1));
    if (tier == null) {
      return null;
    }
    return Permission(value.substring(0, sep), tier);
  }

  /// The built-in role floor this permission corresponds to — the bridge that
  /// makes the preset roles byte-identical to the pre-catalog behavior:
  /// `read → guest`, `write → member`, `administer → admin`, `own → owner`.
  WorkspaceRole get impliedMinRole => switch (tier) {
    PermissionTier.read => WorkspaceRole.guest,
    PermissionTier.write => WorkspaceRole.member,
    PermissionTier.administer => WorkspaceRole.admin,
    PermissionTier.own => WorkspaceRole.owner,
  };

  @override
  bool operator ==(Object other) =>
      other is Permission && other.domain == domain && other.tier == tier;

  @override
  int get hashCode => Object.hash(domain, tier);

  @override
  int compareTo(Permission other) {
    final byDomain = domain.compareTo(other.domain);
    return byDomain != 0 ? byDomain : tier.rank.compareTo(other.tier.rank);
  }

  @override
  String toString() => wire;
}
