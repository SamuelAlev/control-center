import 'dart:io';

import 'package:cc_connect_core/cc_connect_core.dart' show ConnectOAuthLane;
import 'package:cc_domain/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:cc_server_core/src/catalog/connect_ops.dart';
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/connect/google_sign_in_lane.dart';
import 'package:cc_server_core/src/connect/klipy_gifs.dart';
import 'package:cc_server_core/src/connect/linear_clients.dart';
import 'package:cc_server_core/src/connect/linear_sign_in_lane.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/google_calendar_server.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:cc_server_core/src/identity/workspace_provider_app_settings.dart';
import 'package:rhttp/rhttp.dart' show ClientSettings;
import 'package:test/test.dart';

/// The Connect choice decides whether this server's own apps apply: only
/// "Use my own apps" (`off`, or `unset`) puts them in force. With a hosted or
/// custom Connect they are kept but every lane ignores them; a workspace's
/// own app applies in every mode.
void main() {
  late Directory dir;
  late FileSecretsStore secrets;
  late ConnectSettings connect;
  late ProviderAppSettings apps;
  late WorkspaceProviderAppSettings workspaceApps;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('cc_own_apps_choice_');
    secrets = FileSecretsStore(dataDir: dir.path);
    connect = ConnectSettings(secrets: secrets);
    apps = ProviderAppSettings(
      secrets: secrets,
      ownAppsActive: connect.serverOwnAppsActive,
    );
    connect.addListener(apps.connectChoiceChanged);
    workspaceApps = WorkspaceProviderAppSettings(secrets);
    await apps.save(
      ProviderApp.google,
      clientId: 'server.apps.googleusercontent.com',
      clientSecret: 'g-secret',
    );
    await apps.save(
      ProviderApp.linear,
      clientId: 'server-linear',
      apiKey: 'lin_api_server',
    );
  });

  tearDown(() => dir.deleteSync(recursive: true));

  group('hosted or custom Connect', () {
    setUp(() => connect.setChoice(ConnectMode.hosted));

    test('ignores every stored server app, keeping it', () async {
      for (final provider in [ProviderApp.google, ProviderApp.linear]) {
        expect(await apps.oauthCredentials(provider), isNull);
        final status = await apps.status(provider);
        expect(status.active, isFalse);
        expect(status.state, OwnAppState.complete, reason: 'still stored');
        expect(status.effectiveState, OwnAppState.none);
        expect(status.canSignIn, isFalse);
        expect(status.toJson()['active'], isFalse);
      }
      expect(await apps.linearApiKey(), isEmpty);
      expect(await apps.githubApp(), isNull);
    });

    test('a half-configured server app is no setup error either', () async {
      await apps.save(ProviderApp.github, appId: '42');
      expect(await apps.oauthCredentials(ProviderApp.github), isNull);
    });

    test('the sign-in lanes route through Connect', () async {
      final google = GoogleSignInLane(
        apps: apps,
        workspaceApps: workspaceApps,
        accounts: _accounts(secrets),
      );
      final linear = _linearLane(apps, workspaceApps, secrets);
      expect(await google.ownApp('ws-1'), isNull);
      expect(await linear.ownApp('ws-1'), isNull);
      expect(await google.allowsConnect('ws-1'), isTrue);
    });

    test("a workspace's own app still applies", () async {
      await workspaceApps.save('ws-own', WorkspaceAppProvider.google, {
        'client_id': 'ws.apps.googleusercontent.com',
        'client_secret': 'ws-secret',
      });
      await workspaceApps.save('ws-own', WorkspaceAppProvider.linear, {
        'client_id': 'ws-linear',
        'api_key': 'lin_api_ws',
      });
      final google = GoogleSignInLane(
        apps: apps,
        workspaceApps: workspaceApps,
        accounts: _accounts(secrets),
      );
      expect(
        (await google.ownApp('ws-own'))!.clientId,
        'ws.apps.googleusercontent.com',
      );
      expect(
        (await _linearLane(
          apps,
          workspaceApps,
          secrets,
        ).ownApp('ws-own'))!.clientId,
        'ws-linear',
      );
      final linear = _linearClients(apps, workspaceApps, secrets);
      expect(await linear.appAuthorization('ws-own'), 'lin_api_ws');
      expect(await linear.appAuthorization('ws-other'), isNull);
    });

    test('connect status reports no lane as own', () async {
      final lanes = await connectLaneStatuses(
        apps: apps,
        config: null,
        klipy: null,
      );
      for (final lane in lanes) {
        expect(lane.source, isNot(ConnectLaneSource.own), reason: lane.lane);
        expect(lane.error, isEmpty, reason: lane.lane);
      }
    });

    test(
      'the Klipy environment key is ignored, a workspace key is not',
      () async {
        final klipy = _Klipy();
        await workspaceApps.save('ws-own', WorkspaceAppProvider.klipy, {
          'app_key': 'WS-KEY',
        });
        final gifs = KlipyGifs(
          connect: ConnectClient(settings: connect),
          ownAppKey: 'ENV-KEY',
          workspaceApps: workspaceApps,
          transport: () => klipy.client,
        );
        expect(await gifs.source(), isNot(KlipyLaneSource.own));
        await gifs.search('ws-own', 'cats');
        expect(klipy.paths, ['/api/v1/WS-KEY/gifs/search']);
      },
    );
  });

  group('"Use my own apps"', () {
    for (final mode in [ConnectMode.off, ConnectMode.unset]) {
      test('${mode.name}: the stored server apps apply', () async {
        await connect.setChoice(mode);
        expect(
          (await apps.oauthCredentials(ProviderApp.google))!.clientId,
          'server.apps.googleusercontent.com',
        );
        expect(
          (await apps.oauthCredentials(ProviderApp.linear))!.clientId,
          'server-linear',
        );
        expect(await apps.linearApiKey(), 'lin_api_server');
        expect((await apps.status(ProviderApp.linear)).active, isTrue);
        final lanes = await connectLaneStatuses(
          apps: apps,
          config: null,
          klipy: null,
        );
        expect({
          for (final l in lanes) l.lane: l.source,
        }, containsPair('google', ConnectLaneSource.own));
      });
    }

    test('the Klipy environment key applies', () async {
      await connect.setChoice(ConnectMode.off);
      final klipy = _Klipy();
      final gifs = KlipyGifs(
        connect: ConnectClient(settings: connect),
        ownAppKey: 'ENV-KEY',
        transport: () => klipy.client,
      );
      expect(await gifs.source(), KlipyLaneSource.own);
      await gifs.trending('ws-1');
      expect(klipy.paths, ['/api/v1/ENV-KEY/gifs/trending']);
    });
  });

  test('changing the choice tells every own-app listener', () async {
    final heard = <ProviderApp>[];
    apps.addListener(heard.add);
    await connect.setChoice(ConnectMode.hosted);
    expect(heard.toSet(), ProviderApp.values.toSet());
  });
}

CalendarAccountService _accounts(FileSecretsStore secrets) {
  final store = FileGoogleCredentialsStore(secrets);
  return CalendarAccountService(
    store: store,
    tokens: ServerGoogleTokenManager(
      store: store,
      refresh: (_, _) async => const RefreshUnavailable(),
      installId: (_) async => '',
      ownClientId: (_) async => null,
      allowsConnect: (_) async => true,
    ),
    calendarRepository: _NoCalendar(),
  );
}

LinearSignInLane _linearLane(
  ProviderAppSettings apps,
  WorkspaceProviderAppSettings workspaceApps,
  FileSecretsStore secrets,
) => LinearSignInLane(
  lane: ConnectOAuthLane.linear,
  apps: apps,
  workspaceApps: workspaceApps,
  people: UserCredentialsStore(secrets),
  workspaces: LinearAppGrants(secrets),
);

LinearClients _linearClients(
  ProviderAppSettings apps,
  WorkspaceProviderAppSettings workspaceApps,
  FileSecretsStore secrets,
) => LinearClients(
  people: UserCredentialsStore(secrets),
  workspaces: LinearAppGrants(secrets),
  apps: apps,
  workspaceApps: workspaceApps,
  refresh: (_, _, {slot}) async => const RefreshUnavailable(),
);

/// A Klipy API that answers every call with no results and records paths.
final class _Klipy {
  final paths = <String>[];

  late final client = TestHttpClient(
    settings: const ClientSettings(baseUrl: 'https://api.klipy.com'),
    handler: (request) {
      paths.add(httpRequestUri(request).path);
      return httpTextResponse(request, {
        'data': {'data': <Object?>[]},
      });
    },
  );
}

/// The lanes under test never reach the calendar repository.
final class _NoCalendar implements CalendarRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}
