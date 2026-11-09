import 'dart:async';

import 'package:cc_connect_core/cc_connect_core.dart' show ConnectOAuthLane;
import 'package:cc_data/cc_data.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:control_center/features/auth/presentation/widgets/sign_in_copy.dart';
import 'package:control_center/features/auth/providers/provider_sign_in_controller.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _url = 'https://provider.example/authorize?state=s1';

SignInAttempt _attempt(
  String loginId, {
  ConnectOAuthLane lane = ConnectOAuthLane.github,
  SignInLaneMode mode = SignInLaneMode.own,
  SignInAttemptStatus status = SignInAttemptStatus.pending,
  SignInFailure? error,
  SignInFailure? codeError,
  String account = '',
  Duration expiresIn = const Duration(minutes: 10),
}) => SignInAttempt(
  loginId: loginId,
  lane: lane,
  mode: mode,
  url: _url,
  expiresAt: DateTime.now().toUtc().add(expiresIn),
  status: status,
  account: account,
  error: error,
  codeError: codeError,
);

/// Records every `oauth.*` call; each answer is whatever the test set last.
class _FakeSignIn implements RemoteProviderSignIn {
  final List<(String, Map<String, Object?>)> calls = [];

  SignInAttempt Function(ConnectOAuthLane lane)? onBegin;
  SignInAttempt Function(String loginId)? onStatus;
  SignInAttempt Function(String loginId, String code)? onComplete;

  Iterable<Map<String, Object?>> argsOf(String op) =>
      calls.where((c) => c.$1 == op).map((c) => c.$2);

  @override
  Future<SignInAttempt> begin(
    ConnectOAuthLane lane, {
    String? workspaceId,
  }) async {
    calls.add(('begin', {'lane': lane, 'workspace_id': workspaceId}));
    return onBegin!(lane);
  }

  @override
  Future<SignInAttempt> status(String loginId, {String? workspaceId}) async {
    calls.add(('status', {'login_id': loginId, 'workspace_id': workspaceId}));
    return onStatus!(loginId);
  }

  @override
  Future<SignInAttempt> complete({
    required String loginId,
    required String code,
    String? workspaceId,
  }) async {
    calls.add((
      'complete',
      {'login_id': loginId, 'code': code, 'workspace_id': workspaceId},
    ));
    return onComplete!(loginId, code);
  }

  @override
  Future<List<SignInLaneInfo>> lanes({String? workspaceId}) async => const [];

  @override
  Future<List<ProviderConnection>> connections({String? workspaceId}) async =>
      const [];

  @override
  Future<void> disconnect(ConnectOAuthLane lane, {String? workspaceId}) async {}
}

void main() {
  late _FakeSignIn repo;
  late List<String> opened;
  late bool browserOpens;

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        providerSignInRepositoryProvider.overrideWithValue(repo),
        externalUrlOpenerProvider.overrideWithValue((url) {
          opened.add(url);
          return browserOpens;
        }),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    repo = _FakeSignIn();
    opened = [];
    browserOpens = true;
  });

  group('own mode', () {
    test('opens the provider, polls every two seconds, stops on success', () {
      fakeAsync((async) {
        var approved = false;
        repo.onBegin = (lane) => _attempt('own-1');
        repo.onStatus = (id) => approved
            ? _attempt(
                id,
                status: SignInAttemptStatus.succeeded,
                account: 'octocat',
              )
            : _attempt(id);
        final c = container();
        final controller = c.read(providerSignInControllerProvider.notifier);
        String? loginId;
        unawaited(
          controller
              .begin(ConnectOAuthLane.github, workspaceId: 'ws-1')
              .then((id) => loginId = id),
        );
        async.flushMicrotasks();
        expect(loginId, 'own-1');
        expect(opened, [_url]);
        expect(controller.startedHere('own-1'), isTrue);
        SignInAttempt? finished;
        unawaited(controller.result('own-1')!.then((a) => finished = a));

        async.elapse(const Duration(milliseconds: 1999));
        expect(repo.argsOf('status'), isEmpty);
        async.elapse(const Duration(milliseconds: 1));
        expect(repo.argsOf('status'), hasLength(1));
        // Every follow-up call carries the scope the attempt started in.
        expect(repo.argsOf('status').single['workspace_id'], 'ws-1');

        approved = true;
        async.elapse(const Duration(seconds: 2));
        expect(finished?.status, SignInAttemptStatus.succeeded);
        expect(finished?.account, 'octocat');
        expect(
          c
              .read(providerSignInControllerProvider)
              .successesFor(ConnectOAuthLane.github),
          1,
        );

        async.elapse(const Duration(seconds: 10));
        expect(repo.argsOf('status'), hasLength(2), reason: 'polling stopped');
      });
    });

    test('a failed attempt reports its reason and counts no success', () {
      fakeAsync((async) {
        repo.onBegin = (lane) => _attempt('own-2');
        repo.onStatus = (id) => _attempt(
          id,
          status: SignInAttemptStatus.failed,
          error: SignInFailure.accessDenied,
        );
        final c = container();
        final controller = c.read(providerSignInControllerProvider.notifier);
        unawaited(controller.begin(ConnectOAuthLane.github));
        async
          ..flushMicrotasks()
          ..elapse(const Duration(seconds: 2));
        final session = c
            .read(providerSignInControllerProvider)
            .sessions['own-2'];
        expect(session?.isTerminal, isTrue);
        expect(session?.attempt.error, SignInFailure.accessDenied);
        expect(
          c
              .read(providerSignInControllerProvider)
              .successesFor(ConnectOAuthLane.github),
          0,
        );
      });
    });

    test('a dropped poll is not a failure until the attempt expires', () {
      fakeAsync((async) {
        repo.onBegin = (lane) => _attempt(
          lane == ConnectOAuthLane.github ? 'live' : 'stale',
          lane: lane,
          expiresIn: lane == ConnectOAuthLane.github
              ? const Duration(minutes: 10)
              : const Duration(seconds: -1),
        );
        repo.onStatus = (id) => throw StateError('connection reset');
        final c = container();
        final controller = c.read(providerSignInControllerProvider.notifier);
        unawaited(controller.begin(ConnectOAuthLane.github));
        unawaited(controller.begin(ConnectOAuthLane.linear));
        async
          ..flushMicrotasks()
          ..elapse(const Duration(seconds: 2));
        final sessions = c.read(providerSignInControllerProvider).sessions;
        expect(sessions['live']?.isTerminal, isFalse);
        expect(sessions['stale']?.attempt.error, SignInFailure.expired);
      });
    });

    test('says when no browser could be opened, so the URL is shown', () {
      fakeAsync((async) {
        browserOpens = false;
        repo.onBegin = (lane) => _attempt('own-3');
        repo.onStatus = _attempt;
        final c = container();
        unawaited(
          c
              .read(providerSignInControllerProvider.notifier)
              .begin(ConnectOAuthLane.github),
        );
        async.flushMicrotasks();
        expect(
          c
              .read(providerSignInControllerProvider)
              .sessions['own-3']
              ?.browserOpened,
          isFalse,
        );
      });
    });
  });

  group('Connect code entry', () {
    late ProviderContainer c;
    late ProviderSignInController controller;

    SignInSession? session() =>
        c.read(providerSignInControllerProvider).sessions['cx-1'];

    Future<void> start({String? workspaceId}) async {
      repo.onBegin = (lane) => _attempt('cx-1', mode: SignInLaneMode.connect);
      c = container();
      controller = c.read(providerSignInControllerProvider.notifier);
      await controller.begin(ConnectOAuthLane.github, workspaceId: workspaceId);
    }

    test('a malformed code is refused here and never sent', () async {
      await start();
      await controller.submitCode('cx-1', 'K7Q2-9WX');
      expect(session()?.codeError, isA<SignInCodeMalformed>());
      expect(repo.argsOf('complete'), isEmpty);
    });

    test('a code the server rejects keeps the attempt open', () async {
      await start();
      repo.onComplete = (id, code) => _attempt(
        id,
        mode: SignInLaneMode.connect,
        codeError: SignInFailure.codeMismatch,
      );
      await controller.submitCode('cx-1', 'k7q2-9wxm');
      final rejected = session()?.codeError;
      expect(rejected, isA<SignInCodeRejected>());
      expect(
        (rejected! as SignInCodeRejected).failure,
        SignInFailure.codeMismatch,
      );
      expect(session()?.isTerminal, isFalse);
      expect(session()?.completing, isFalse);
    });

    test('a failed call is not read as a wrong code', () async {
      await start();
      repo.onComplete = (id, code) =>
          throw RemoteRpcException(-33002, 'This sign-in is no longer valid.');
      await controller.submitCode('cx-1', 'k7q2-9wxm');
      expect(
        (session()!.codeError! as SignInCodeRejected).failure,
        SignInFailure.staleRequest,
      );

      repo.onComplete = (id, code) => throw StateError('socket closed');
      await controller.submitCode('cx-1', 'k7q2-9wxm');
      expect(
        (session()!.codeError! as SignInCodeRejected).failure,
        SignInFailure.providerUnavailable,
      );
    });

    test('a Connect attempt is polled, so a failure elsewhere shows', () {
      fakeAsync((async) {
        repo.onBegin = (lane) => _attempt('cx-3', mode: SignInLaneMode.connect);
        repo.onStatus = (id) => _attempt(
          id,
          mode: SignInLaneMode.connect,
          status: SignInAttemptStatus.failed,
          error: SignInFailure.invalidCode,
        );
        final c = container();
        unawaited(
          c
              .read(providerSignInControllerProvider.notifier)
              .begin(ConnectOAuthLane.github),
        );
        async.elapse(kSignInPollInterval);
        expect(
          c
              .read(providerSignInControllerProvider)
              .sessions['cx-3']
              ?.attempt
              .error,
          SignInFailure.invalidCode,
        );
      });
    });

    test('a typed code is normalised and completes the attempt', () async {
      await start(workspaceId: 'ws-9');
      repo.onComplete = (id, code) => _attempt(
        id,
        mode: SignInLaneMode.connect,
        status: SignInAttemptStatus.succeeded,
        account: 'octocat',
      );
      // Lower case, a dash, and the look-alikes Crockford folds (O → 0,
      // I/L → 1).
      await controller.submitCode('cx-1', 'k7qo-9wxl');
      expect(repo.argsOf('complete').single, {
        'login_id': 'cx-1',
        'code': 'K7Q09WX1',
        'workspace_id': 'ws-9',
      });
      expect(session()?.attempt.status, SignInAttemptStatus.succeeded);
      expect((await controller.result('cx-1'))?.account, 'octocat');
    });

    test('runs out at the attempt expiry', () {
      fakeAsync((async) {
        repo.onBegin = (lane) => _attempt(
          'cx-2',
          mode: SignInLaneMode.connect,
          expiresIn: const Duration(minutes: 5),
        );
        final c = container();
        unawaited(
          c
              .read(providerSignInControllerProvider.notifier)
              .begin(ConnectOAuthLane.google, workspaceId: 'ws-1'),
        );
        async
          ..flushMicrotasks()
          ..elapse(const Duration(minutes: 4));
        Map<String, SignInSession> sessions() =>
            c.read(providerSignInControllerProvider).sessions;
        expect(sessions()['cx-2']?.isTerminal, isFalse);
        async.elapse(const Duration(minutes: 1, seconds: 1));
        expect(sessions()['cx-2']?.attempt.error, SignInFailure.expired);
      });
    });
  });

  group('oauth-done deep link', () {
    test(
      'completes an attempt this client started, in its own scope',
      () async {
        repo.onBegin = (lane) =>
            _attempt('dl-1', lane: lane, mode: SignInLaneMode.connect);
        repo.onComplete = (id, code) => _attempt(
          id,
          lane: ConnectOAuthLane.linear,
          mode: SignInLaneMode.connect,
          status: SignInAttemptStatus.succeeded,
        );
        final c = container();
        final controller = c.read(providerSignInControllerProvider.notifier);
        await controller.begin(ConnectOAuthLane.linear, workspaceId: 'ws-4');

        expect(
          await controller.completeFromDeepLink('dl-1', 'K7Q29WXM'),
          isTrue,
        );
        expect(repo.argsOf('complete').single, {
          'login_id': 'dl-1',
          'code': 'K7Q29WXM',
          'workspace_id': 'ws-4',
        });
        expect(
          c
              .read(providerSignInControllerProvider)
              .successesFor(ConnectOAuthLane.linear),
          1,
        );
      },
    );

    test(
      'refuses a login id this client never started, sending nothing',
      () async {
        final c = container();
        final controller = c.read(providerSignInControllerProvider.notifier);
        expect(
          await controller.completeFromDeepLink('somebody-elses', 'K7Q29WXM'),
          isFalse,
        );
        expect(repo.calls, isEmpty);
      },
    );

    test('ignores a second link for an attempt already over', () async {
      repo.onBegin = (lane) => _attempt('dl-2', mode: SignInLaneMode.connect);
      repo.onComplete = (id, code) => _attempt(
        id,
        mode: SignInLaneMode.connect,
        status: SignInAttemptStatus.succeeded,
      );
      final c = container();
      final controller = c.read(providerSignInControllerProvider.notifier);
      await controller.begin(ConnectOAuthLane.github);
      await controller.completeFromDeepLink('dl-2', 'K7Q29WXM');
      expect(await controller.completeFromDeepLink('dl-2', 'K7Q29WXM'), isTrue);
      expect(repo.argsOf('complete'), hasLength(1));
    });
  });

  group('failure copy', () {
    late AppLocalizations l10n;

    setUpAll(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('every failure code reads as its own sentence, never the code', () {
      final messages = {
        for (final failure in SignInFailure.values)
          failure: signInFailureMessage(l10n, failure, ConnectOAuthLane.github),
      };
      for (final MapEntry(key: failure, value: message) in messages.entries) {
        expect(message, isNotEmpty, reason: failure.name);
        if (failure.wire.contains('_')) {
          expect(message, isNot(contains(failure.wire)), reason: failure.name);
        }
      }
      expect(
        messages.values.toSet(),
        hasLength(SignInFailure.values.length),
        reason: 'two codes share a message',
      );
      expect(
        signInFailureMessage(l10n, null, ConnectOAuthLane.github),
        l10n.signInErrorUnknown,
      );
    });

    test('names the provider the lane signs in to', () {
      expect(
        signInFailureMessage(
          l10n,
          SignInFailure.accessDenied,
          ConnectOAuthLane.google,
        ),
        l10n.signInErrorAccessDenied('Google Calendar'),
      );
    });
  });
}
