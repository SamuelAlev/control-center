import 'dart:async';
import 'dart:io';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/oauth/harness_oauth_broker.dart';
import 'package:cc_harness_runtime/src/oauth/oauth_provider.dart';
import 'package:cc_harness_runtime/src/oauth/pkce.dart';
import 'package:test/test.dart';

/// A fake OAuth provider that does not bind a real port — exchange / refresh
/// return scripted results.
class _FakeProvider implements HarnessOAuthProvider {
  _FakeProvider({
    required this.providerId,
    this.callbackPort = 1,
    this.authUrl = 'https://provider.example/authorize',
    ProviderCredential? Function()? exchangeResult,
    ProviderCredential? Function(ProviderCredential)? refreshResult,
    Object? exchangeError,
  }) : callbackPath = '/cb',
       _exchangeResult = exchangeResult,
       _refreshResult = refreshResult,
       _exchangeError = exchangeError;

  @override
  final String providerId;
  @override
  final int callbackPort;
  @override
  final String callbackPath;
  final String authUrl;

  final ProviderCredential? Function()? _exchangeResult;
  final ProviderCredential? Function(ProviderCredential)? _refreshResult;
  final Object? _exchangeError;

  @override
  String buildAuthUrl({required Pkce pkce, required String state}) =>
      '$authUrl?state=$state&code_challenge=${pkce.challenge}';

  @override
  Future<ProviderCredential> exchange({
    required String code,
    required Pkce pkce,
  }) async {
    if (_exchangeError != null) {
      throw _exchangeError;
    }
    return _exchangeResult?.call() ??
        ProviderCredential(
          providerId: providerId,
          method: HarnessAuthMethod.oauth,
          accessToken: 'token-$code',
          email: 'user@example.com',
        );
  }

  @override
  Future<ProviderCredential> refresh(ProviderCredential credential) async {
    return _refreshResult?.call(credential) ??
        credential.copyWith(
          accessToken: 'refreshed-token',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records every save() so the test can assert persisted credentials.
class _RecordingStore implements ProviderCredentialStore {
  final List<ProviderCredential> saved = [];

  @override
  Future<ProviderCredential?> activeCredential(String providerId) async => null;

  @override
  Future<List<ProviderCredential>> credentialsFor(String providerId) async =>
      saved.where((c) => c.providerId == providerId).toList();

  @override
  Future<void> save(ProviderCredential credential) async {
    saved.removeWhere(
      (c) =>
          c.providerId == credential.providerId &&
          c.accountLabel == credential.accountLabel,
    );
    saved.add(credential);
  }

  @override
  Future<void> remove(String providerId, {String? accountLabel}) async {
    saved.removeWhere(
      (c) => c.providerId == providerId && c.accountLabel == accountLabel,
    );
  }
}

/// A fake device-code provider: `authorize` hands back a scripted code, and
/// `poll` walks a scripted script of results one call at a time.
class _FakeDeviceProvider implements HarnessDeviceOAuthProvider {
  _FakeDeviceProvider({
    List<Object?>? pollScript,
    this.expiresIn = const Duration(seconds: 30),
    this.refreshGate,
  }) : _pollScript = pollScript ?? [];

  /// Held open by a test to keep a refresh in flight while a second caller
  /// arrives (single-flight coverage).
  final Future<void>? refreshGate;

  /// How many token exchanges actually reached the provider.
  int refreshes = 0;

  @override
  final String providerId = 'kimi-code';
  final Duration expiresIn;

  /// Per-call results: null keeps polling, a credential completes, a thrown
  /// object fails.
  final List<Object?> _pollScript;
  int polls = 0;

  @override
  Future<HarnessDeviceAuthorization> authorize() async =>
      HarnessDeviceAuthorization(
        deviceCode: 'dev-code',
        userCode: 'AB12-CD34',
        verificationUri: 'https://provider.example/device?user_code=AB12-CD34',
        interval: const Duration(milliseconds: 1),
        expiresIn: expiresIn,
      );

  @override
  Future<ProviderCredential?> poll(String deviceCode) async {
    final next = polls < _pollScript.length ? _pollScript[polls] : null;
    polls++;
    if (next is ProviderCredential) {
      return next;
    }
    if (next != null) {
      throw next;
    }
    return null;
  }

  @override
  Future<ProviderCredential> refresh(ProviderCredential credential) async {
    refreshes++;
    await refreshGate;
    return credential.copyWith(accessToken: 'refreshed-plan-token');
  }
}

HarnessOAuthBroker _broker({
  required _RecordingStore store,
  List<HarnessOAuthProvider>? providers,
  List<HarnessDeviceOAuthProvider>? deviceProviders,
}) => HarnessOAuthBroker(
  store: store,
  providers: providers,
  // Default to none so tests never construct the real Kimi flow.
  deviceProviders: deviceProviders ?? const [],
  // The production floor is a second; tests do not need to wait it out.
  minPollInterval: const Duration(milliseconds: 2),
);

/// Waits for [check] to hold, polling the broker's background flow.
Future<void> _until(bool Function() check, {int timeout = 3000}) async {
  for (var i = 0; i < timeout ~/ 5 && !check(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  group('HarnessOAuthBroker', () {
    test('supports reports known providers only', () {
      final store = _RecordingStore();
      final broker = _broker(
        store: store,
        providers: [_FakeProvider(providerId: 'anthropic', callbackPort: 4321)],
      );
      expect(broker.supports('anthropic'), isTrue);
      expect(broker.supports('ghost'), isFalse);
    });

    group('start', () {
      test('throws for an unsupported provider', () async {
        final store = _RecordingStore();
        final broker = _broker(store: store);
        expect(() => broker.start('ghost'), throwsA(isA<StateError>()));
      });

      test('mints flowId and builds auth url from provider', () async {
        final store = _RecordingStore();
        final broker = _broker(
          store: store,
          providers: [
            _FakeProvider(providerId: 'anthropic', authUrl: 'https://x/y'),
          ],
        );
        final start = await broker.start('anthropic');
        expect(start.flowId, isNotEmpty);
        expect(start.authUrl, startsWith('https://x/y?state='));
        expect(start.authUrl, contains('code_challenge='));
        expect(start.supportsManualPaste, isTrue);
      });
    });

    test('status of an unknown flow is error', () {
      final store = _RecordingStore();
      final broker = _broker(store: store);
      final status = broker.status('ghost');
      expect(status.state, HarnessOAuthState.error);
      expect(status.error, contains('Unknown or expired'));
    });

    test('status of a pending flow is pending', () async {
      final store = _RecordingStore();
      final broker = _broker(
        store: store,
        providers: [_FakeProvider(providerId: 'anthropic')],
      );
      final start = await broker.start('anthropic');
      expect(broker.status(start.flowId).state, HarnessOAuthState.pending);
    });

    group('complete (manual paste)', () {
      test('exchanges the code and persists the credential', () async {
        final store = _RecordingStore();
        final broker = _broker(
          store: store,
          providers: [_FakeProvider(providerId: 'anthropic')],
        );
        final start = await broker.start('anthropic');
        await broker.complete(start.flowId, 'AUTH_CODE');
        final status = broker.status(start.flowId);
        expect(status.state, HarnessOAuthState.completed);
        expect(status.account, 'user@example.com');
        expect(store.saved, hasLength(1));
        expect(store.saved.single.accessToken, 'token-AUTH_CODE');
      });

      test('completing a second time is a no-op', () async {
        final store = _RecordingStore();
        final broker = _broker(
          store: store,
          providers: [_FakeProvider(providerId: 'anthropic')],
        );
        final start = await broker.start('anthropic');
        await broker.complete(start.flowId, 'CODE1');
        await broker.complete(start.flowId, 'CODE2');
        // Only one save (the second complete is a no-op for completed flows).
        expect(store.saved, hasLength(1));
        expect(broker.status(start.flowId).state, HarnessOAuthState.completed);
      });

      test('exchange failure marks the flow as errored', () async {
        final store = _RecordingStore();
        final broker = _broker(
          store: store,
          providers: [
            _FakeProvider(
              providerId: 'anthropic',
              exchangeError: StateError('bad code'),
            ),
          ],
        );
        final start = await broker.start('anthropic');
        await broker.complete(start.flowId, 'CODE');
        final status = broker.status(start.flowId);
        expect(status.state, HarnessOAuthState.error);
        expect(status.error, contains('bad code'));
      });

      test('completing an unknown flow is a no-op', () async {
        final store = _RecordingStore();
        final broker = _broker(store: store);
        await broker.complete('ghost', 'CODE');
        expect(store.saved, isEmpty);
      });
    });

    group('cancel', () {
      test('removes the flow', () async {
        final store = _RecordingStore();
        final broker = _broker(
          store: store,
          providers: [_FakeProvider(providerId: 'anthropic')],
        );
        final start = await broker.start('anthropic');
        await broker.cancel(start.flowId);
        expect(broker.status(start.flowId).state, HarnessOAuthState.error);
      });

      test('canceling an unknown flow is a no-op', () async {
        final store = _RecordingStore();
        final broker = _broker(store: store);
        // Should not throw.
        await broker.cancel('ghost');
      });
    });

    group('refreshIfNeeded', () {
      test('skips when provider is not supported', () async {
        final store = _RecordingStore();
        final broker = _broker(store: store);
        final cred = ProviderCredential(
          providerId: 'ghost',
          method: HarnessAuthMethod.oauth,
          refreshToken: 'r',
          expiresAt: DateTime(2000),
        );
        final out = await broker.refreshIfNeeded(cred);
        expect(identical(out, cred), isTrue);
      });

      test('skips when method is not oauth', () async {
        final store = _RecordingStore();
        final broker = _broker(
          store: store,
          providers: [_FakeProvider(providerId: 'anthropic')],
        );
        final cred = ProviderCredential(
          providerId: 'anthropic',
          method: HarnessAuthMethod.apiKey,
          apiKey: 'k',
          expiresAt: DateTime(2000),
        );
        final out = await broker.refreshIfNeeded(cred);
        expect(identical(out, cred), isTrue);
      });

      test('skips when not yet expired', () async {
        final store = _RecordingStore();
        final broker = _broker(
          store: store,
          providers: [_FakeProvider(providerId: 'anthropic')],
        );
        final cred = ProviderCredential(
          providerId: 'anthropic',
          method: HarnessAuthMethod.oauth,
          refreshToken: 'r',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );
        final out = await broker.refreshIfNeeded(cred);
        expect(identical(out, cred), isTrue);
      });

      test('skips when expiresAt is null', () async {
        final store = _RecordingStore();
        final broker = _broker(
          store: store,
          providers: [_FakeProvider(providerId: 'anthropic')],
        );
        const cred = ProviderCredential(
          providerId: 'anthropic',
          method: HarnessAuthMethod.oauth,
          refreshToken: 'r',
        );
        final out = await broker.refreshIfNeeded(cred);
        expect(identical(out, cred), isTrue);
      });

      test('skips when refreshToken is null', () async {
        final store = _RecordingStore();
        final broker = _broker(
          store: store,
          providers: [_FakeProvider(providerId: 'anthropic')],
        );
        final cred = ProviderCredential(
          providerId: 'anthropic',
          method: HarnessAuthMethod.oauth,
          expiresAt: DateTime(2000),
        );
        final out = await broker.refreshIfNeeded(cred);
        expect(identical(out, cred), isTrue);
      });

      test(
        'refreshes and persists when expired with a refresh token',
        () async {
          final store = _RecordingStore();
          final broker = _broker(
            store: store,
            providers: [_FakeProvider(providerId: 'anthropic')],
          );
          final cred = ProviderCredential(
            providerId: 'anthropic',
            method: HarnessAuthMethod.oauth,
            accessToken: 'old',
            refreshToken: 'r',
            expiresAt: DateTime(2000),
          );
          final out = await broker.refreshIfNeeded(cred);
          expect(out.accessToken, 'refreshed-token');
          expect(store.saved, hasLength(1));
          expect(store.saved.single.accessToken, 'refreshed-token');
        },
      );

      test('returns the original when refresh throws', () async {
        final store = _RecordingStore();
        final broker = _broker(
          store: store,
          providers: [
            _FakeProvider(
              providerId: 'anthropic',
              refreshResult: (_) => throw StateError('refresh failed'),
            ),
          ],
        );
        final cred = ProviderCredential(
          providerId: 'anthropic',
          method: HarnessAuthMethod.oauth,
          accessToken: 'old',
          refreshToken: 'r',
          expiresAt: DateTime(2000),
        );
        final out = await broker.refreshIfNeeded(cred);
        expect(identical(out, cred), isTrue);
      });
    });
  });

  group('HarnessOAuthBroker — device-code flows', () {
    test(
      'start returns the verification URL, the user code, and no paste',
      () async {
        final store = _RecordingStore();
        final device = _FakeDeviceProvider();
        final broker = _broker(store: store, deviceProviders: [device]);
        final start = await broker.start('kimi-code');
        expect(start.flowId, isNotEmpty);
        expect(start.userCode, 'AB12-CD34');
        expect(start.isDeviceCode, isTrue);
        // There is no code to redeem — the flow resolves by polling, so offering
        // a paste box would be a dead end.
        expect(start.supportsManualPaste, isFalse);
        expect(start.authUrl, contains('AB12-CD34'));
        await broker.cancel(start.flowId);
      },
    );

    test('polls until authorized, then persists the credential', () async {
      final store = _RecordingStore();
      const credential = ProviderCredential(
        providerId: 'kimi-code',
        method: HarnessAuthMethod.oauth,
        accessToken: 'plan-token',
        accountLabel: 'Kimi Code plan',
      );
      // Two "still pending" rounds before the user approves.
      final device = _FakeDeviceProvider(pollScript: [null, null, credential]);
      final broker = _broker(store: store, deviceProviders: [device]);
      final start = await broker.start('kimi-code');
      expect(broker.status(start.flowId).state, HarnessOAuthState.pending);
      await _until(() => store.saved.isNotEmpty);
      expect(store.saved.single.accessToken, 'plan-token');
      final status = broker.status(start.flowId);
      expect(status.state, HarnessOAuthState.completed);
      expect(status.account, 'Kimi Code plan');
    });

    test('a terminal provider error fails the flow with its message', () async {
      final store = _RecordingStore();
      final device = _FakeDeviceProvider(
        pollScript: [const HarnessDeviceAuthException('Sign-in was denied.')],
      );
      final broker = _broker(store: store, deviceProviders: [device]);
      final start = await broker.start('kimi-code');
      await _until(
        () => broker.status(start.flowId).state == HarnessOAuthState.error,
      );
      expect(broker.status(start.flowId).error, 'Sign-in was denied.');
      expect(store.saved, isEmpty);
    });

    test('slow_down widens the interval without failing the login', () async {
      final store = _RecordingStore();
      const credential = ProviderCredential(
        providerId: 'kimi-code',
        method: HarnessAuthMethod.oauth,
        accessToken: 'plan-token',
      );
      final device = _FakeDeviceProvider(
        pollScript: [const HarnessDeviceSlowDown(), credential],
        expiresIn: const Duration(seconds: 30),
      );
      final broker = _broker(store: store, deviceProviders: [device]);
      final start = await broker.start('kimi-code');
      // The 5s RFC back-off lands before the 30s device-code deadline.
      await _until(() => store.saved.isNotEmpty, timeout: 12000);
      expect(broker.status(start.flowId).state, HarnessOAuthState.completed);
    });

    test(
      'a transient network error keeps polling instead of aborting',
      () async {
        final store = _RecordingStore();
        const credential = ProviderCredential(
          providerId: 'kimi-code',
          method: HarnessAuthMethod.oauth,
          accessToken: 'plan-token',
        );
        // A blip mid-login must not throw away a login the user is completing.
        final device = _FakeDeviceProvider(
          pollScript: [const SocketException('flaky'), credential],
        );
        final broker = _broker(store: store, deviceProviders: [device]);
        final start = await broker.start('kimi-code');
        await _until(() => store.saved.isNotEmpty);
        expect(broker.status(start.flowId).state, HarnessOAuthState.completed);
      },
    );

    test('cancelling stops the background poll', () async {
      final store = _RecordingStore();
      final device = _FakeDeviceProvider();
      final broker = _broker(store: store, deviceProviders: [device]);
      final start = await broker.start('kimi-code');
      await broker.cancel(start.flowId);
      final after = device.polls;
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(device.polls, lessThanOrEqualTo(after + 1));
      expect(store.saved, isEmpty);
    });

    test('the device code expiring fails the flow', () async {
      final store = _RecordingStore();
      final device = _FakeDeviceProvider(expiresIn: Duration.zero);
      final broker = _broker(store: store, deviceProviders: [device]);
      final start = await broker.start('kimi-code');
      await _until(
        () => broker.status(start.flowId).state == HarnessOAuthState.error,
      );
      expect(broker.status(start.flowId).error, contains('timed out'));
    });

    test('completing a device flow with a pasted code is refused', () async {
      final store = _RecordingStore();
      final broker = _broker(
        store: store,
        deviceProviders: [_FakeDeviceProvider()],
      );
      final start = await broker.start('kimi-code');
      await broker.complete(start.flowId, 'not-a-thing');
      expect(broker.status(start.flowId).state, HarnessOAuthState.error);
      expect(store.saved, isEmpty);
    });

    test('refreshIfNeeded renews an expired device credential', () async {
      final store = _RecordingStore();
      final broker = _broker(
        store: store,
        deviceProviders: [_FakeDeviceProvider()],
      );
      final expired = ProviderCredential(
        providerId: 'kimi-code',
        method: HarnessAuthMethod.oauth,
        accessToken: 'stale',
        refreshToken: 'r1',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      final refreshed = await broker.refreshIfNeeded(expired);
      expect(refreshed.accessToken, 'refreshed-plan-token');
      expect(store.saved.single.accessToken, 'refreshed-plan-token');
    });

    test('force renews a token that has not expired yet', () async {
      // A Kimi Code token lives ~15 minutes; when the API rejects one that our
      // arithmetic still calls valid (clock skew, early revocation), the
      // server's verdict has to win.
      final store = _RecordingStore();
      final device = _FakeDeviceProvider();
      final broker = _broker(store: store, deviceProviders: [device]);
      final live = ProviderCredential(
        providerId: 'kimi-code',
        method: HarnessAuthMethod.oauth,
        accessToken: 'stale',
        refreshToken: 'r1',
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      );

      expect((await broker.refreshIfNeeded(live)).accessToken, 'stale');
      expect(device.refreshes, 0);

      final forced = await broker.refreshIfNeeded(live, force: true);
      expect(forced.accessToken, 'refreshed-plan-token');
      expect(device.refreshes, 1);
    });

    test('concurrent refreshes of one account make a single exchange', () async {
      // A run fans out into parallel subagents that all hit expiry at the same
      // moment. Kimi rotates the refresh token, so racing exchanges would
      // invalidate each other.
      final gate = Completer<void>();
      final store = _RecordingStore();
      final device = _FakeDeviceProvider(refreshGate: gate.future);
      final broker = _broker(store: store, deviceProviders: [device]);
      final expired = ProviderCredential(
        providerId: 'kimi-code',
        method: HarnessAuthMethod.oauth,
        accessToken: 'stale',
        refreshToken: 'r1',
        accountId: 'device-1',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );

      final all = Future.wait([
        broker.refreshIfNeeded(expired),
        broker.refreshIfNeeded(expired),
        broker.refreshIfNeeded(expired),
      ]);
      gate.complete();
      final results = await all;

      expect(device.refreshes, 1);
      expect(store.saved, hasLength(1));
      expect(
        results.map((c) => c.accessToken),
        everyElement('refreshed-plan-token'),
      );

      // The flight is cleared once it settles — a later expiry still refreshes.
      await broker.refreshIfNeeded(expired);
      expect(device.refreshes, 2);
    });

    test('supports covers device providers too', () {
      final broker = _broker(
        store: _RecordingStore(),
        deviceProviders: [_FakeDeviceProvider()],
      );
      expect(broker.supports('kimi-code'), isTrue);
      expect(broker.supports('ghost'), isFalse);
    });
  });
}
