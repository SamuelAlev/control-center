import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/core/domain/repositories/commit_signing_key_repository.dart';
import 'package:cc_domain/core/domain/value_objects/commit_signing_key.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/commit_signing_key_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:control_center/shared/widgets/demo_unavailable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_wrap.dart';

const _publicKey =
    'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl';
const _fingerprint = 'SHA256:Zx3cZ0Ezk4mNfa/0n1nZ1PKqKvJm1nQ8mH8a3eS1YkE';

CommitSigningKey _key() => CommitSigningKey(
  publicKey: _publicKey,
  fingerprint: _fingerprint,
  createdAt: DateTime.utc(2026, 11, 10, 9, 30),
);

/// The caller's key on a pretend server.
class _Keys implements CommitSigningKeyRepository {
  CommitSigningKey? key;
  Object? readError;
  Object? createError;
  Completer<void>? readGate;
  int reads = 0;
  int creates = 0;
  int deletes = 0;

  @override
  Future<CommitSigningKey?> get() async {
    reads++;
    await readGate?.future;
    if (readError case final error?) {
      throw error;
    }
    return key;
  }

  @override
  Future<CommitSigningKey> create() async {
    creates++;
    if (createError case final error?) {
      throw error;
    }
    return key = _key();
  }

  @override
  Future<bool> delete() async {
    deletes++;
    final had = key != null;
    key = null;
    return had;
  }
}

Widget _wrap(_Keys keys, {bool demo = false, TextDirection? textDirection}) =>
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        isDemoServerProvider.overrideWith((ref) => demo),
        commitSigningKeyRepositoryProvider.overrideWithValue(keys),
      ],
      child: testWrap(
        const SingleChildScrollView(child: CommitSigningKeySection()),
        isDemo: demo,
        textDirection: textDirection,
      ),
    );

void main() {
  late AppLocalizations l10n;
  late _Keys keys;

  setUpAll(() async {
    l10n = await appLocalizationsDelegate.load(const Locale('en'));
  });

  setUp(() => keys = _Keys());

  testWidgets('without a key it explains signing, states the trust and '
      'offers to create one', (tester) async {
    await tester.pumpWidget(_wrap(keys));
    await tester.pumpAndSettle();

    expect(find.text(l10n.settingsCommitSigningIntro), findsOneWidget);
    expect(find.text(l10n.settingsCommitSigningStatusOff), findsOneWidget);
    // The trust statements are on the page, not in a tooltip.
    expect(find.text(l10n.settingsCommitSigningTrustPrivate), findsOneWidget);
    expect(find.text(l10n.settingsCommitSigningTrustAgents), findsOneWidget);
    expect(find.text(l10n.settingsCommitSigningTrustControl), findsOneWidget);
    expect(find.text(l10n.settingsCommitSigningTrustVerified), findsOneWidget);
    // App commits run no repository hooks; said where commits are explained.
    expect(find.text(l10n.settingsCommitsNoHooks), findsOneWidget);
    expect(find.text(_publicKey), findsNothing);

    await tester.tap(find.text(l10n.settingsCommitSigningCreate));
    await tester.pumpAndSettle();

    expect(keys.creates, 1);
    expect(find.text(l10n.settingsCommitSigningCreated), findsOneWidget);
    expect(find.text(_publicKey), findsOneWidget);
    expect(find.text(l10n.settingsCommitSigningStatusOn), findsOneWidget);
    expect(find.text(l10n.settingsCommitSigningCreate), findsNothing);
  });

  testWidgets('a key shows its public half, fingerprint and where each forge '
      'takes it', (tester) async {
    keys.key = _key();
    await tester.pumpWidget(_wrap(keys));
    await tester.pumpAndSettle();

    expect(find.text(_publicKey), findsOneWidget);
    expect(find.text(_fingerprint), findsOneWidget);
    expect(find.text(l10n.settingsCommitSigningGitHubSteps), findsOneWidget);
    expect(find.text(l10n.settingsCommitSigningGitLabSteps), findsOneWidget);
    expect(find.text(l10n.settingsCommitSigningBitbucketSteps), findsOneWidget);
    expect(find.text(l10n.settingsCommitSigningUnsupported), findsOneWidget);
    expect(find.text(l10n.openOnForge('GitHub')), findsOneWidget);
    expect(find.text(l10n.openOnForge('GitLab')), findsOneWidget);
    // Bitbucket takes no signing key, so there is nowhere to send anyone.
    expect(find.text(l10n.openOnForge('Bitbucket')), findsNothing);
    expect(find.text(l10n.settingsCommitSigningTrustControl), findsOneWidget);
  });

  testWidgets('delete asks first, then leaves commits unsigned', (
    tester,
  ) async {
    keys.key = _key();
    await tester.pumpWidget(_wrap(keys));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text(l10n.settingsCommitSigningDelete));
    await tester.tap(find.text(l10n.settingsCommitSigningDelete));
    await tester.pumpAndSettle();
    expect(find.text(l10n.settingsCommitSigningDeleteTitle), findsOneWidget);
    expect(find.text(l10n.settingsCommitSigningDeleteBody), findsOneWidget);

    await tester.tap(find.text(l10n.cancel));
    await tester.pumpAndSettle();
    expect(keys.deletes, 0);
    expect(find.text(_publicKey), findsOneWidget);

    await tester.ensureVisible(find.text(l10n.settingsCommitSigningDelete));
    await tester.tap(find.text(l10n.settingsCommitSigningDelete));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.settingsCommitSigningDelete).last);
    await tester.pumpAndSettle();

    expect(keys.deletes, 1);
    expect(find.text(l10n.settingsCommitSigningDeleted), findsOneWidget);
    expect(find.text(_publicKey), findsNothing);
    expect(find.text(l10n.settingsCommitSigningCreate), findsOneWidget);
  });

  testWidgets('a refused create says why and shows what is really there', (
    tester,
  ) async {
    keys.createError = RemoteRpcException(
      RpcErrorCodes.validation,
      'You already have a commit signing key.',
    );
    await tester.pumpWidget(_wrap(keys));
    await tester.pumpAndSettle();
    keys.key = _key();

    await tester.tap(find.text(l10n.settingsCommitSigningCreate));
    await tester.pumpAndSettle();

    expect(find.text('You already have a commit signing key.'), findsOneWidget);
    expect(keys.reads, 2);
    expect(find.text(_publicKey), findsOneWidget);
  });

  testWidgets('loading shows a spinner, not an empty card', (tester) async {
    keys.readGate = Completer<void>();
    await tester.pumpWidget(_wrap(keys));
    await tester.pump();

    expect(find.byType(CcSpinner), findsOneWidget);
    expect(find.text(l10n.settingsCommitSigningCreate), findsNothing);

    keys.readGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text(l10n.settingsCommitSigningCreate), findsOneWidget);
  });

  testWidgets('a failed read says so and retries', (tester) async {
    keys.readError = RemoteRpcException(RpcErrorCodes.internalError, 'boom');
    await tester.pumpWidget(_wrap(keys));
    await tester.pumpAndSettle();

    expect(find.text(l10n.settingsCommitSigningLoadFailed('boom')), findsOne);
    expect(find.text(l10n.settingsCommitSigningCreate), findsNothing);

    keys.readError = null;
    await tester.tap(find.text(l10n.retry));
    await tester.pumpAndSettle();
    expect(find.text(l10n.settingsCommitSigningCreate), findsOneWidget);
  });

  testWidgets('a demo server shows the demo notice and never asks', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(keys, demo: true));
    await tester.pumpAndSettle();

    expect(find.byType(DemoUnavailable), findsOneWidget);
    expect(find.text(l10n.settingsCommitSigningCreate), findsNothing);
    expect(keys.reads, 0);
  });

  testWidgets('right to left on a phone: no overflow, machine strings stay '
      'left to right', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    keys.key = _key();
    await tester.pumpWidget(_wrap(keys, textDirection: TextDirection.rtl));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final fingerprint = tester.widget<Text>(find.text(_fingerprint));
    expect(fingerprint.textDirection, TextDirection.ltr);
    final publicKey = tester.widget<Text>(find.text(_publicKey));
    expect(publicKey.textDirection, TextDirection.ltr);
  });
}
