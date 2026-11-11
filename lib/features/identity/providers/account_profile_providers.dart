import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/username.dart';
import 'package:cc_domain/core/domain/value_objects/username_check.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The caller's own account row: username, display name, email and avatar
/// as they follow the person everywhere, without any workspace overlay.
///
/// [currentIdentityProvider] carries the ACTIVE workspace's overlay, so it
/// is the wrong source for the account itself: an overlay display name
/// would be saved back as the account's.
final accountProfileProvider =
    AsyncNotifierProvider<AccountProfileNotifier, UserDto>(
      AccountProfileNotifier.new,
    );

/// Reads and saves [accountProfileProvider].
class AccountProfileNotifier extends AsyncNotifier<UserDto> {
  @override
  Future<UserDto> build() async =>
      (await ref.watch(identityRepositoryProvider).me()).user;

  /// Saves the given fields (null leaves one unchanged) and keeps the saved
  /// row. A refused [handle] throws [UsernameRefusedException] and changes
  /// nothing.
  Future<UserDto> save({
    String? handle,
    String? displayName,
    String? email,
    String? avatarRef,
  }) async {
    final user = await ref
        .read(identityRepositoryProvider)
        .updateProfile(
          handle: handle,
          displayName: displayName,
          email: email,
          avatarRef: avatarRef,
        );
    state = AsyncData(user);
    // The overlaid identity inherits these fields wherever the workspace
    // leaves them empty.
    ref.invalidate(currentIdentityProvider);
    return user;
  }
}

/// Whether a username is free for the caller, asked of the server.
///
/// A narrow seam so the live check can be driven by a fake in tests.
final usernameCheckProvider = Provider<Future<UsernameCheck> Function(String)>(
  (ref) => ref.read(identityRepositoryProvider).checkHandle,
);
