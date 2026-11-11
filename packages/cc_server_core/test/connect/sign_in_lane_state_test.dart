import 'dart:io';

import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/connect/sign_in_service.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:test/test.dart';

/// A Connect whose verified config and config state are scripted.
final class _ScriptedConnect extends ConnectClient {
  _ScriptedConnect(ConnectSettings settings)
    : super(settings: settings, trustedRootKeys: const []);

  ConnectConfig? config;
  ConnectConfigState Function(ConnectTarget target)? state;

  @override
  Future<ConnectConfig?> usableConfig(ConnectTarget target) async => config;

  @override
  Future<ConnectConfigState> configState(
    ConnectTarget target, {
    bool refresh = false,
  }) async => state?.call(target) ?? ConnectConfigState(target: target);
}

/// A GitHub lane whose own app and Connect permission are scripted; the
/// routing rules themselves live in the real lanes and [ConnectRoute].
final class _Lane implements SignInLaneBinding {
  _Lane(this._connect);

  final ConnectClient _connect;
  Object? ownAppError;

  @override
  ConnectOAuthLane get lane => ConnectOAuthLane.github;

  @override
  Future<OwnOAuthApp?> ownApp(String? workspaceId) async {
    final error = ownAppError;
    if (error != null) {
      throw error;
    }
    return null;
  }

  @override
  Future<bool> allowsConnect(String? workspaceId) async =>
      !(await _connect.routeFor(workspaceId)).workspaceOwnApps;

  @override
  Future<String?> slotFor(String? workspaceId) async =>
      (await _connect.routeFor(workspaceId)).workspaceSlot ? workspaceId : null;

  @override
  Future<Set<String>> accountHolders(String accountId) async => const {};

  @override
  Future<void> revokeOwnGrant(ProviderToken token, String? slot) async {}

  @override
  Future<SignInIdentity> identify(String accessToken) =>
      throw UnimplementedError();

  @override
  Future<void> store(SignInResult result) async {}

  @override
  Future<LaneConnection?> connection(String userId, String? workspaceId) async =>
      null;

  @override
  Future<void> disconnect(String userId, String? workspaceId) async {}

  @override
  Future<int> offboard({String? userId, String? workspaceId}) async => 0;

  @override
  Future<List<SealRequest>> connectSeals(
    String connectOrigin,
    List<String> workspaceIds,
  ) async => const [];
}

Workspace _workspace(
  String id, {
  WorkspaceConnectMode mode = WorkspaceConnectMode.inherit,
  String url = '',
}) => Workspace(
  id: id,
  name: id,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  connectMode: mode,
  connectUrl: url,
);

ConnectConfig _config({bool github = true}) => ConnectConfig(
  epoch: 1,
  issuedAt: DateTime.utc(2026, 11, 8),
  github: github
      ? const GitHubLaneConfig(appId: 1, clientId: 'Iv1test', appSlug: 'cc')
      : null,
);

void main() {
  late Directory dir;
  late FileSecretsStore secrets;
  late Map<String, Workspace> registry;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cc_sign_in_lane_state_');
    secrets = FileSecretsStore(dataDir: dir.path);
    registry = {};
  });

  tearDown(() => dir.deleteSync(recursive: true));

  ({ProviderSignInService service, _ScriptedConnect connect, _Lane lane})
  build({Map<String, String> environment = const {}}) {
    final settings = ConnectSettings(
      secrets: secrets,
      environment: environment,
    )..workspaceLookup = (id) async => registry[id];
    final connect = _ScriptedConnect(settings);
    final lane = _Lane(connect);
    final service = ProviderSignInService(connect: connect)..register(lane);
    return (service: service, connect: connect, lane: lane);
  }

  Future<SignInLaneState> stateOf(
    ProviderSignInService service, [
    String? workspaceId,
  ]) => service.modeFor(ConnectOAuthLane.github, workspaceId: workspaceId);

  group('oauth.lanes unavailable_reason', () {
    test('no Connect and no own app is not_configured', () async {
      final b = build();
      await b.connect.settings.setChoice(ConnectMode.off);
      final state = await stateOf(b.service);
      expect(state.mode, SignInLaneMode.unavailable);
      expect(state.reason, SignInUnavailableReason.notConfigured);
    });

    test('a half-set-up own app is misconfigured, with the error', () async {
      final b = build();
      b.lane.ownAppError = const SignInMisconfigured('Add the secret.');
      final state = await stateOf(b.service);
      expect(state.reason, SignInUnavailableReason.misconfigured);
      expect(state.error, 'Add the secret.');
    });

    test('a workspace on its own apps without one is own_app_missing', () async {
      registry['ws'] = _workspace('ws', mode: WorkspaceConnectMode.own);
      final b = build();
      expect(
        (await stateOf(b.service, 'ws')).reason,
        SignInUnavailableReason.ownAppMissing,
      );
    });

    test('a custom choice without a usable URL is connect_url_invalid', () async {
      registry['ws'] = _workspace('ws', mode: WorkspaceConnectMode.custom);
      final b = build();
      expect(
        (await stateOf(b.service, 'ws')).reason,
        SignInUnavailableReason.connectUrlInvalid,
      );
    });

    test('CC_CONNECT_URL over a workspace Connect is blocked_by_environment',
        () async {
      registry['ws'] = _workspace('ws', mode: WorkspaceConnectMode.hosted);
      final b = build(environment: const {'CC_CONNECT_URL': 'off'});
      expect(
        (await stateOf(b.service, 'ws')).reason,
        SignInUnavailableReason.blockedByEnvironment,
      );
    });

    test('Connect config problems name their cause', () async {
      final b = build();
      await b.connect.settings.setChoice(ConnectMode.hosted);

      b.connect.state = (target) => ConnectConfigState(
        target: target,
        error: 'hosted_unprovisioned',
      );
      expect(
        (await stateOf(b.service)).reason,
        SignInUnavailableReason.connectUnprovisioned,
      );

      b.connect.state = (target) => ConnectConfigState(
        target: target,
        config: _config(),
        error: 'pins_changed',
        pendingPins: const {'github_app_id': '2'},
      );
      expect(
        (await stateOf(b.service)).reason,
        SignInUnavailableReason.connectPinsPending,
      );

      b.connect.state = (target) =>
          ConnectConfigState(target: target, error: 'unreachable');
      expect(
        (await stateOf(b.service)).reason,
        SignInUnavailableReason.connectUnreachable,
      );
    });

    test('a Connect that does not offer the lane is lane_not_offered', () async {
      final b = build();
      await b.connect.settings.setChoice(ConnectMode.hosted);
      b.connect.config = _config(github: false);
      expect(
        (await stateOf(b.service)).reason,
        SignInUnavailableReason.laneNotOffered,
      );
    });

    test('a usable Connect lane carries no reason', () async {
      final b = build();
      await b.connect.settings.setChoice(ConnectMode.hosted);
      b.connect.config = _config();
      final state = await stateOf(b.service);
      expect(state.mode, SignInLaneMode.connect);
      expect(state.reason, isNull);
    });
  });

  group('slot rule', () {
    test('a hosted workspace on a hosted server shares the global slot',
        () async {
      registry['ws'] = _workspace('ws', mode: WorkspaceConnectMode.hosted);
      final b = build();
      await b.connect.settings.setChoice(ConnectMode.hosted);
      final route = await b.connect.routeFor('ws');
      expect(route.workspaceSlot, isFalse);
      expect(await b.lane.slotFor('ws'), isNull);
    });

    test('a hosted workspace on a server with its own apps gets a slot',
        () async {
      registry['ws'] = _workspace('ws', mode: WorkspaceConnectMode.hosted);
      final b = build();
      await b.connect.settings.setChoice(ConnectMode.off);
      expect((await b.connect.routeFor('ws')).workspaceSlot, isTrue);
      expect(await b.lane.slotFor('ws'), 'ws');
    });

    test('a custom workspace Connect keeps its own slot even at the '
        "server's URL: its trust store is its own", () async {
      registry['ws'] = _workspace(
        'ws',
        mode: WorkspaceConnectMode.custom,
        url: 'https://connect.example.com',
      );
      final b = build();
      await b.connect.settings.setChoice(
        ConnectMode.custom,
        url: 'https://connect.example.com',
      );
      expect((await b.connect.routeFor('ws')).workspaceSlot, isTrue);
    });

    test('own apps always get a slot; inheriting never does', () async {
      registry['own'] = _workspace('own', mode: WorkspaceConnectMode.own);
      registry['inherit'] = _workspace('inherit');
      final b = build();
      await b.connect.settings.setChoice(ConnectMode.hosted);
      expect((await b.connect.routeFor('own')).workspaceSlot, isTrue);
      expect((await b.connect.routeFor('inherit')).workspaceSlot, isFalse);
    });
  });

  group('oauth.status for an unknown attempt', () {
    test('lookup answers null and the wire reads attempt_unknown', () {
      final b = build();
      expect(
        b.service.lookup(
          loginId: 'AAAAAAAAAAAAAAAAAAAAAA',
          userId: 'user-1',
          workspaceId: 'ws',
        ),
        isNull,
      );
      final json = b.service.unknownSignInAttemptJson(
        'AAAAAAAAAAAAAAAAAAAAAA',
        lane: ConnectOAuthLane.github,
      );
      expect(json['status'], 'failed');
      expect(json['error'], SignInFailure.attemptUnknown.wire);
      expect(json['error'], 'attempt_unknown');
      expect(json['lane'], 'github');
      expect(json['login_id'], 'AAAAAAAAAAAAAAAAAAAAAA');
    });
  });
}
