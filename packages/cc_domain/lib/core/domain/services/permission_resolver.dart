import 'package:cc_domain/core/domain/entities/role_definition.dart';
import 'package:cc_domain/core/domain/value_objects/permission.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';

/// The resource an authorization question is about, when it is narrower than
/// the workspace (today: one repo — the only resource-level grant that
/// exists).
class ResourceRef {
  /// A repo-scoped resource requiring at least [level].
  const ResourceRef.repo(this.repoId, {this.level = RepoGrantLevel.read})
    : kind = 'repo';

  /// The resource kind (`repo`).
  final String kind;

  /// The resource id.
  final String repoId;

  /// The grant level the operation needs on it.
  final RepoGrantLevel level;
}

/// Why a permission check answered the way it did — carried into the audit
/// row so a denial can be explained without re-deriving it.
enum PermissionSource {
  /// The role (preset or custom) granted or refused it.
  role,

  /// A per-repo grant granted or refused it.
  grant,

  /// The caller is not a member of the workspace at all.
  membership,
}

/// The outcome of a `can(...)` check.
class PermissionVerdict {
  /// An allow.
  const PermissionVerdict.allow(this.source)
    : allowed = true,
      reason = null;

  /// A denial with a human-readable [reason].
  const PermissionVerdict.deny(this.source, this.reason) : allowed = false;

  /// Whether the action is permitted.
  final bool allowed;

  /// Which layer decided.
  final PermissionSource source;

  /// The denial reason (null on allow).
  final String? reason;
}

/// The principal an authorization question is asked about.
class PermissionPrincipal {
  /// Creates a principal context.
  const PermissionPrincipal({
    required this.userId,
    required this.role,
    this.repoGrants = const {},
    this.orgId,
  });

  /// The acting user.
  final String userId;

  /// Their resolved role in the workspace, or null when not a member.
  final RoleDefinition? role;

  /// Their per-repo grants in the workspace (absent = [RepoGrantLevel.none]).
  final Map<String, RepoGrantLevel> repoGrants;

  /// The organization the workspace belongs to, when the install has an org
  /// layer. Always null self-hosted today — carried so the hosted tier can
  /// resolve org-level roles without reshaping every call site.
  final String? orgId;
}

/// The single human-side authorization decision point.
///
/// `can(principal, permission, resource)` replaces `if (role.isAdmin)` and
/// `role.atLeast(floor)` scattered across the op surface. The point is not
/// that today's answers change — the parity ratchet asserts they do NOT, for
/// every op × preset — but that ONE function now decides, so custom roles,
/// per-resource grants and (later) org-scoped roles are a change here rather
/// than a sweep of hundreds of call sites.
///
/// Pure and `const`-constructible: no I/O, no clock, no storage. The caller
/// resolves the principal (membership + grants) and hands it in.
class PermissionResolver {
  /// Creates a [PermissionResolver].
  const PermissionResolver();

  /// The built-in presets, in privilege order.
  static const List<WorkspaceRole> presets = WorkspaceRole.values;

  /// Whether [principal] may exercise [permission], optionally on
  /// [resource].
  ///
  /// Order is membership → role → resource grant, so the most fundamental
  /// refusal wins and the audit row names the layer that decided. Owners and
  /// admins hold every repo grant implicitly, exactly as the pre-catalog
  /// dispatcher did.
  PermissionVerdict can(
    PermissionPrincipal principal,
    Permission permission, {
    ResourceRef? resource,
  }) {
    final role = principal.role;
    if (role == null) {
      return const PermissionVerdict.deny(
        PermissionSource.membership,
        'Not a member of this workspace',
      );
    }
    if (!role.grants(permission)) {
      return PermissionVerdict.deny(
        PermissionSource.role,
        'Operation requires the ${permission.wire} permission',
      );
    }
    if (resource != null && !role.basePreset.isAdmin) {
      final held = principal.repoGrants[resource.repoId] ?? RepoGrantLevel.none;
      if (!held.atLeast(resource.level)) {
        return PermissionVerdict.deny(
          PermissionSource.grant,
          'No ${resource.level.wireName} access to this repo',
        );
      }
      return const PermissionVerdict.allow(PermissionSource.grant);
    }
    return const PermissionVerdict.allow(PermissionSource.role);
  }

  /// Convenience: the boolean form.
  bool allows(
    PermissionPrincipal principal,
    Permission permission, {
    ResourceRef? resource,
  }) => can(principal, permission, resource: resource).allowed;
}
