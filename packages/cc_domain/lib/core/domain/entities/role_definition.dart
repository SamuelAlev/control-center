import 'package:cc_domain/core/domain/value_objects/permission.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';

/// A resolvable role: either one of the five built-in presets or a
/// workspace-defined CUSTOM role that subtracts permissions from a preset.
///
/// **Custom roles are subtractive by construction.** A custom role names a
/// [basePreset] and a set of [deniedPermissions] removed from it; it can
/// never grant more than its base. That single property is what makes custom
/// roles a bounded change rather than an audit of the whole surface: every
/// hand-rolled `role.isAdmin` check in the catalog remains a sound upper
/// bound, so they do not all have to migrate on day one.
///
/// `owner` is never a base preset — ownership is a single seat per workspace,
/// transferred explicitly by `workspace.transferOwnership`.
class RoleDefinition {
  /// Creates a role definition.
  const RoleDefinition({
    required this.id,
    required this.name,
    required this.basePreset,
    this.deniedPermissions = const {},
    this.isCustom = false,
  });

  /// A built-in preset role.
  factory RoleDefinition.preset(WorkspaceRole role) => RoleDefinition(
    id: role.wireName,
    name: role.wireName,
    basePreset: role,
  );

  /// Stable id: the preset's wire name, or the custom role's row id.
  final String id;

  /// Display name.
  final String name;

  /// The preset whose permissions this role starts from.
  final WorkspaceRole basePreset;

  /// Permission WIRE NAMES (`domain:tier`) removed from [basePreset]. Empty
  /// for a preset.
  ///
  /// Strings rather than [Permission] values on purpose: this is exactly what
  /// `workspace_roles.denied_permissions` stores (a JSON array), so no
  /// conversion sits between the row and the check — and a `const` Set cannot
  /// hold elements with a custom `==` anyway.
  final Set<String> deniedPermissions;

  /// Whether this is a workspace-defined role (persisted in
  /// `workspace_roles`) rather than a built-in preset.
  final bool isCustom;

  /// The wire value stored in `workspace_members.role`: the preset's name, or
  /// `custom:<id>`.
  ///
  /// An old client parsing `custom:<id>` gets null from
  /// `WorkspaceRole.fromWire` and every caller fails safe to guest — that
  /// fail-safe is load-bearing for rolling this out.
  String get wire => isCustom ? 'custom:$id' : basePreset.wireName;

  /// The `custom:<id>` id carried by [wire], or null when it names a preset.
  static String? customIdOf(String? wire) =>
      wire != null && wire.startsWith('custom:') && wire.length > 7
      ? wire.substring(7)
      : null;

  /// Whether this role grants [permission].
  bool grants(Permission permission) =>
      basePreset.atLeast(permission.impliedMinRole) &&
      !deniedPermissions.contains(permission.wire);

  /// Every permission in [catalog] this role grants.
  Set<Permission> granted(Iterable<Permission> catalog) => {
    for (final p in catalog)
      if (grants(p)) p,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoleDefinition &&
          other.id == id &&
          other.name == name &&
          other.basePreset == basePreset &&
          other.isCustom == isCustom &&
          _sameDenied(other.deniedPermissions);

  bool _sameDenied(Set<String> other) =>
      other.length == deniedPermissions.length &&
      other.every(deniedPermissions.contains);

  @override
  int get hashCode => Object.hash(
    id,
    name,
    basePreset,
    isCustom,
    Object.hashAllUnordered(deniedPermissions),
  );
}
