import 'dart:convert';

import 'package:cc_domain/cc_domain.dart'
    show NotFoundException, RepoOpKind, ValidationException;
import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/value_objects/username.dart';
import 'package:cc_host/cc_host.dart'
    show CcHostLog, RepoOp, RepoOpContext, ServerAuthority;
import 'package:cc_server_core/src/catalog/catalog_wire.dart' show userToWire;
import 'package:cc_server_core/src/identity/identity_audit.dart';
import 'package:cc_server_core/src/identity/user_profile_change.dart';

/// `users.updateProfile`: edits the CALLER's own account (`ctx.userId`;
/// no argument can name anyone else). Absent or blank fields stay as they
/// are. A new `handle` is a username the person chose: normalised, checked
/// and written atomically, or refused with a [UsernameRefusedException]
/// (RPC `data.kind` `username_invalid|reserved|taken`).
///
/// A new `email` is the person's word only, so it is not vouched
/// ([User.emailVerified]) and identifies nobody to SSO or SCIM, except for
/// the server owner [serverOwnerUserId]: the root of trust, who configured
/// the identity provider, vouches for their own address. The owner may not
/// take an address another account holds vouched.
///
/// Declared in `remote_rpc_catalog.dart`; the body lives here with the other
/// username ops.
Future<Map<String, Object?>> updateOwnProfile(
  RepoOpContext ctx, {
  required UserRepository users,
  required String? serverOwnerUserId,
  DomainEventBus? eventBus,
}) async {
  final user = await users.getById(ctx.userId);
  if (user == null) {
    throw const NotFoundException('User not found');
  }
  String? optional(String key) {
    final value = ctx.args[key];
    final trimmed = value is String ? value.trim() : '';
    return trimmed.isEmpty ? null : trimmed;
  }

  final requested = optional('handle');
  final email = optional('email');
  final ownerVouches =
      email != null &&
      normalizeEmail(email) != user.email &&
      ctx.userId == serverOwnerUserId;
  if (ownerVouches && await _heldVouchedByOther(users, email, user.id)) {
    throw const ValidationException(
      'That email address belongs to another account',
    );
  }
  try {
    final updated = user.copyWith(
      handle: requested == null ? null : Username.parse(requested).value,
      displayName: optional('display_name'),
      email: email,
      emailVerified: ownerVouches ? true : null,
      avatarRef: optional('avatar_ref'),
      gitAuthorName: optional('git_author_name'),
      gitAuthorEmail: optional('git_author_email'),
    );
    await users.upsert(updated);
    announceUserProfileChange(eventBus, user, updated, at: DateTime.now());
    return {'user': userToWire(updated, includeOnboarding: true)};
  } on UsernameRefusedException catch (e) {
    final shown = requested!.length > 64
        ? '${requested.substring(0, 64)}…'
        : requested;
    CcHostLog.info(
      'identity: username refused user=${ctx.userId} '
      'kind=${e.reason.errorKind} requested=${jsonEncode(shown)}',
    );
    rethrow;
  }
}

/// The username op of a person's own profile.
///
/// - `users.checkHandle {handle}`: live validation for the username field,
///   `{available, normalized, reason?}` with reason `invalid`, `reserved` or
///   `taken`. A name the caller already holds is available.
///
/// Self-service: the person is always `ctx.userId`.
List<RepoOp> buildUserProfileOps({required UserRepository users}) => [
  RepoOp(
    name: 'users.checkHandle',
    kind: RepoOpKind.read,
    workspaceScoped: false,
    handler: (ctx) async {
      final raw = ctx.args['handle'];
      if (raw is! String) {
        throw const ValidationException('handle is required');
      }
      final normalized = Username.normalizeInput(raw);
      var reason = Username.check(normalized);
      if (reason == null) {
        final holder = await users.getByHandle(normalized);
        if (holder != null && holder.id != ctx.userId) {
          reason = UsernameRefusal.taken;
        }
      }
      return {
        'available': reason == null,
        'normalized': normalized,
        'reason': ?reason?.wire,
      };
    },
  ),
];

/// `users.vouchEmail {user_id}`: the server owner vouches for that account's
/// current address, so it identifies the person to SSO and SCIM from now on
/// ([User.emailVerified]). This is how an owner who turns on SSO after
/// inviting people links their existing accounts.
///
/// Owner only (`serverAuthority`). Refuses an account with no address, a
/// deactivated one, and an address another account already holds vouched.
/// Audited as `user.email_vouched` (actor, target), never with the address.
List<RepoOp> buildEmailVouchOps({required UserRepository users}) => [
  RepoOp(
    name: 'users.vouchEmail',
    kind: RepoOpKind.mutate,
    workspaceScoped: false,
    serverAuthority: ServerAuthority.serverOwner,
    requiredArgs: ['user_id'],
    handler: (ctx) async {
      final userId = ctx.args['user_id'];
      if (userId is! String || userId.isEmpty) {
        throw const ValidationException('user_id must be a user id');
      }
      final user = await users.getById(userId);
      if (user == null) {
        throw const NotFoundException('User not found');
      }
      final email = user.email;
      if (email == null || email.isEmpty) {
        throw const ValidationException('This account has no email address');
      }
      if (user.deactivatedAt != null) {
        throw const ValidationException('This account has been deactivated');
      }
      if (await _heldVouchedByOther(users, email, user.id)) {
        throw const ValidationException(
          'That email address belongs to another account',
        );
      }
      final vouched = user.copyWith(emailVerified: true);
      if (!user.emailVerified) {
        await users.upsert(vouched);
      }
      identityAudit(IdentityAuditEvent.emailVouched, {
        'actor_user_id': ctx.userId,
        'user_id': user.id,
      });
      return {'user': userToWire(vouched)};
    },
  ),
];

/// Whether an account other than [userId] holds [email], in any case, vouched.
Future<bool> _heldVouchedByOther(
  UserRepository users,
  String email,
  String userId,
) async => (await users.getAllByEmail(
  email,
)).any((holder) => holder.emailVerified && holder.id != userId);
