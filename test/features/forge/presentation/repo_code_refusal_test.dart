import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:control_center/features/auth/providers/oauth_providers.dart'
    show LaneSignInNeed;
import 'package:control_center/features/forge/presentation/repo_code_refusal.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A refused code read is worded by `data.kind`, naming the forge when
/// `data.forge` does and wording it without one otherwise.
void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  RemoteRpcException refusal(Map<String, Object?> data) =>
      RemoteRpcException(RpcErrorCodes.unauthorized, 'server words', data);

  for (final (data, text) in [
    (
      {'kind': 'forge_cannot_read', 'forge': 'gitlab'},
      "Your GitLab account can't read this repository.",
    ),
    (
      {'kind': 'forge_cannot_read'},
      "Your forge account can't read this repository.",
    ),
    (
      {'kind': 'forge_unconfirmed', 'forge': 'bitbucket'},
      "Couldn't confirm your Bitbucket access. Try again.",
    ),
    (
      {'kind': 'forge_unconfirmed'},
      "Couldn't confirm your forge access. Try again.",
    ),
    (
      {'kind': 'repo_replaced', 'forge': 'github'},
      'This path now points to a different repository on GitHub. A workspace '
          'admin has to relink it before it can be used.',
    ),
    (
      {'kind': 'repo_replaced'},
      'This path now points to a different repository. A workspace admin has '
          'to relink it before it can be used.',
    ),
  ]) {
    test('${data['kind']} with forge ${data['forge']}', () {
      expect(repoCodeRefusalMessage(l10n, refusal(data)), text);
      expect(repoCodeFailureOf(l10n, refusal(data))?.signIn, isNull);
    });
  }

  test('needs_sign_in offers the sign-in its lane names', () {
    final failure = repoCodeFailureOf(
      l10n,
      refusal({'kind': 'needs_sign_in', 'lane': 'github'}),
    );
    expect(
      failure?.message,
      "Sign in to GitHub to see this repository's code.",
    );
    expect(failure?.signIn, isA<LaneSignInNeed>());
  });

  for (final (level, text) in [
    (
      'read',
      "You don't have read access to this repository. A workspace admin can "
          'grant it.',
    ),
    (
      'write',
      'You can read this repository but not change it. A workspace admin can '
          'grant write access.',
    ),
    (
      'review',
      'You can read this repository but not review it. A workspace admin can '
          'grant review access.',
    ),
  ]) {
    test('repo_grant_required at level $level names the missing grant', () {
      final error = refusal({'kind': 'repo_grant_required', 'level': level});
      expect(repoCodeRefusalMessage(l10n, error), text);
      expect(isRepoGrantRefusal(error, level: level), isTrue);
      expect(isRepoAccessRefusal(error), isTrue);
    });
  }

  test('an uncoded unauthorized is no grant refusal', () {
    final error = RemoteRpcException(RpcErrorCodes.unauthorized, 'no');
    expect(repoCodeRefusalMessage(l10n, error), isNull);
    expect(repoRefusalOf(l10n, error), isNull);
    expect(isRepoGrantRefusal(error), isFalse);
    expect(isRepoAccessRefusal(error), isFalse);
  });

  test('anything else is left to the caller', () {
    expect(
      repoCodeFailureOf(
        l10n,
        RemoteRpcException(RpcErrorCodes.validation, 'bad path'),
      ),
      isNull,
    );
    expect(repoCodeFailureOf(l10n, StateError('boom')), isNull);
  });
}
