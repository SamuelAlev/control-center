import 'dart:io';

import 'package:cc_connect_core/cc_connect_core.dart'
    show ConnectOAuthLane, hostedConnectOrigin;
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:cc_server_core/src/catalog/connect_ops.dart';
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/connect/google_sign_in_lane.dart';
import 'package:cc_server_core/src/connect/klipy_gifs.dart';
import 'package:cc_server_core/src/connect/linear_clients.dart';
import 'package:cc_server_core/src/connect/linear_sign_in_lane.dart';
import 'package:cc_server_core/src/connect/sign_in_service.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/forge/github_client_types.dart';
import 'package:cc_server_core/src/forge/github_lane_resolver.dart';
import 'package:cc_server_core/src/google_calendar_server.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:cc_server_core/src/identity/workspace_provider_app_settings.dart';
import 'package:rhttp/rhttp.dart' show ClientSettings;
import 'package:test/test.dart';

/// The Connect choice decides whether this server's own apps apply: only
/// "Use my own apps" (`off`, or `unset`) puts them in force. With a hosted or
/// custom Connect they are kept but every lane ignores them. A workspace's
/// own choice overrides the server's: its own apps apply only when it chose
/// them, and then nothing else does.
void main() {
  late Directory dir;
  late FileSecretsStore secrets;
  late ConnectSettings connect;
  late ProviderAppSettings apps;
  late WorkspaceProviderAppSettings workspaceApps;
  late Map<String, Workspace> registry;
  late ConnectClient client;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('cc_own_apps_choice_');
    secrets = FileSecretsStore(dataDir: dir.path);
    registry = {
      for (final id in ['ws-1', 'ws-2']) id: _workspace(id),
    };
    connect = ConnectSettings(secrets: secrets)
      ..workspaceLookup = (id) async => registry[id];
    client = ConnectClient(settings: connect, trustedRootKeys: const []);
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
      final google = _googleLane(apps, workspaceApps, secrets, client);
      final linear = _linearLane(apps, workspaceApps, secrets, client);
      expect(await google.ownApp('ws-1'), isNull);
      expect(await linear.ownApp('ws-1'), isNull);
      expect(await google.allowsConnect('ws-1'), isTrue);
    });

    test(
      "a workspace's own app applies only once it chose its own apps",
      () async {
        await _saveWorkspaceApps(workspaceApps, 'ws-1');
        final google = _googleLane(apps, workspaceApps, secrets, client);
        final linear = _linearClients(apps, workspaceApps, secrets, client);
        expect(await google.ownApp('ws-1'), isNull, reason: 'inherits');
        expect(await linear.appAuthorization('ws-1'), isNull);

        registry['ws-1'] = registry['ws-1']!.copyWith(
          connectMode: WorkspaceConnectMode.own,
        );
        expect(
          (await google.ownApp('ws-1'))!.clientId,
          'ws.apps.googleusercontent.com',
        );
        expect(
          (await _linearLane(
            apps,
            workspaceApps,
            secrets,
            client,
          ).ownApp('ws-1'))!.clientId,
          'ws-linear',
        );
        expect(await linear.appAuthorization('ws-1'), 'lin_api_ws');
        expect(await linear.appAuthorization('ws-2'), isNull);
      },
    );

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
      'the Klipy environment key is ignored, a workspace key only in own mode',
      () async {
        final klipy = _Klipy();
        await workspaceApps.save('ws-1', WorkspaceAppProvider.klipy, {
          'app_key': 'WS-KEY',
        });
        registry['ws-1'] = registry['ws-1']!.copyWith(
          connectMode: WorkspaceConnectMode.own,
        );
        final gifs = KlipyGifs(
          connect: client,
          ownAppKey: 'ENV-KEY',
          workspaceApps: workspaceApps,
          transport: () => klipy.client,
        );
        expect(await gifs.source(), isNot(KlipyLaneSource.own));
        expect(await gifs.source('ws-1'), KlipyLaneSource.workspaceOwn);
        await gifs.search('ws-1', 'cats');
        await gifs.search('ws-2', 'cats');
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
        connect: client,
        ownAppKey: 'ENV-KEY',
        transport: () => klipy.client,
      );
      expect(await gifs.source(), KlipyLaneSource.own);
      await gifs.trending('ws-1');
      expect(klipy.paths, ['/api/v1/ENV-KEY/gifs/trending']);
    });
  });

  group('per-workspace choice', () {
    // What each workspace mode resolves to over each server mode.
    for (final server in [ConnectMode.hosted, ConnectMode.off]) {
      for (final mode in WorkspaceConnectMode.values) {
        test('${mode.wireName} over a server on ${server.name}', () async {
          await connect.setChoice(server);
          await _saveWorkspaceApps(workspaceApps, 'ws-1');
          registry['ws-1'] = registry['ws-1']!.copyWith(
            connectMode: mode,
            connectUrl: mode == WorkspaceConnectMode.custom
                ? 'https://connect.example.com'
                : '',
          );
          final inheritsOwnApps =
              mode == WorkspaceConnectMode.inherit && server == ConnectMode.off;
          final own = mode == WorkspaceConnectMode.own;

          final route = await client.routeFor('ws-1');
          expect(route.mode, mode);
          expect(route.serverOwnApps, inheritsOwnApps);
          expect(route.workspaceOwnApps, own);
          // A slot only when the workspace's sign-in target differs from
          // the server's: hosted over a hosted server shares the global one.
          final ownsSlot =
              mode != WorkspaceConnectMode.inherit &&
              !(mode == WorkspaceConnectMode.hosted &&
                  server == ConnectMode.hosted);
          expect(route.workspaceSlot, ownsSlot);
          final target = route.target;
          switch (mode) {
            case WorkspaceConnectMode.inherit:
              expect(target.pinScope, isEmpty);
              expect(target.guarded, isFalse);
              expect(
                target.origin,
                server == ConnectMode.hosted ? hostedConnectOrigin : '',
              );
            case WorkspaceConnectMode.hosted:
              expect(target.origin, hostedConnectOrigin);
              expect(target.pinScope, isEmpty, reason: 'one hosted trust');
            case WorkspaceConnectMode.custom:
              expect(target.origin, 'https://connect.example.com');
              expect(target.pinScope, 'ws-1');
              expect(target.guarded, isTrue);
            case WorkspaceConnectMode.own:
              expect(target.enabled, isFalse);
          }
          expect(route.effectiveMode, switch (mode) {
            WorkspaceConnectMode.own => 'own',
            WorkspaceConnectMode.hosted => 'hosted',
            WorkspaceConnectMode.custom => 'custom',
            WorkspaceConnectMode.inherit =>
              server == ConnectMode.hosted ? 'hosted' : 'server_own',
          });

          final google = _googleLane(apps, workspaceApps, secrets, client);
          final linearLane = _linearLane(apps, workspaceApps, secrets, client);
          final linear = _linearClients(apps, workspaceApps, secrets, client);
          final expectedGoogle = own
              ? 'ws.apps.googleusercontent.com'
              : inheritsOwnApps
              ? 'server.apps.googleusercontent.com'
              : null;
          expect((await google.ownApp('ws-1'))?.clientId, expectedGoogle);
          expect(await google.allowsConnect('ws-1'), !own);
          expect(
            (await linearLane.ownApp('ws-1'))?.clientId,
            own
                ? 'ws-linear'
                : inheritsOwnApps
                ? 'server-linear'
                : null,
          );
          expect(
            await linear.appAuthorization('ws-1'),
            own
                ? 'lin_api_ws'
                : inheritsOwnApps
                ? 'lin_api_server'
                : null,
          );

          // Person grants: the workspace's slot while it owns one, the
          // person's server-wide one otherwise.
          final people = UserCredentialsStore(secrets);
          await people.setTicketToken(
            'alice',
            TicketProvider.linear,
            _linearGrant('global', 'server-linear'),
          );
          await people.setTicketToken(
            'alice',
            TicketProvider.linear,
            _linearGrant('slot', 'ws-linear'),
            workspaceId: 'ws-1',
          );
          expect(
            await linear.personAuthorization('alice', 'ws-1'),
            ownsSlot ? 'Bearer slot' : 'Bearer global',
          );

          // GitHub: the workspace's App only in own mode; the server's App
          // only while inheriting a server on its own apps.
          expect(
            githubLaneFor(
              route,
              workspaceApp: OwnAppState.complete,
              serverApp: OwnAppState.complete,
              connectOffers: true,
            ),
            own
                ? GitHubLane.workspaceApp
                : inheritsOwnApps
                ? GitHubLane.ownApp
                : GitHubLane.connect,
          );
        });
      }
    }

    test('own apps: a partial app is a setup error, a missing one is off, '
        'never a fallback', () async {
      await connect.setChoice(ConnectMode.off);
      registry['ws-1'] = registry['ws-1']!.copyWith(
        connectMode: WorkspaceConnectMode.own,
      );
      final google = _googleLane(apps, workspaceApps, secrets, client);
      final linear = _linearClients(apps, workspaceApps, secrets, client);
      expect(await google.ownApp('ws-1'), isNull);
      expect(await google.allowsConnect('ws-1'), isFalse);
      expect(await linear.appAuthorization('ws-1'), isNull);
      expect(
        githubLaneFor(
          await client.routeFor('ws-1'),
          workspaceApp: OwnAppState.none,
          serverApp: OwnAppState.complete,
          connectOffers: true,
        ),
        GitHubLane.none,
      );

      await workspaceApps.save('ws-1', WorkspaceAppProvider.google, {
        'client_id': 'ws.apps.googleusercontent.com',
      });
      await expectLater(
        google.ownApp('ws-1'),
        throwsA(isA<SignInMisconfigured>()),
      );
    });

    test('an unregistered workspace gets no lane at all', () async {
      await connect.setChoice(ConnectMode.off);
      final route = await client.routeFor('ws-gone');
      expect(route.serverOwnApps, isFalse);
      expect(route.target.enabled, isFalse);
      expect(
        await _googleLane(
          apps,
          workspaceApps,
          secrets,
          client,
        ).ownApp('ws-gone'),
        isNull,
      );
    });

    test('CC_CONNECT_URL blocks a stored hosted or custom choice: nothing '
        'runs, nothing falls back', () async {
      final locked = ConnectSettings(
        secrets: secrets,
        environment: const {'CC_CONNECT_URL': 'off'},
      )..workspaceLookup = (id) async => registry[id];
      final lockedClient = ConnectClient(
        settings: locked,
        trustedRootKeys: const [],
      );
      for (final mode in [
        WorkspaceConnectMode.hosted,
        WorkspaceConnectMode.custom,
      ]) {
        registry['ws-1'] = registry['ws-1']!.copyWith(
          connectMode: mode,
          connectUrl: 'https://connect.example.com',
        );
        final route = await lockedClient.routeFor('ws-1');
        expect(route.blockedByEnvironment, isTrue, reason: mode.wireName);
        expect(route.target.enabled, isFalse);
        expect(route.serverOwnApps, isFalse, reason: 'no fallback');
        expect(route.effectiveMode, 'off');
        expect(route.workspaceSlot, isTrue);
        expect(
          await _googleLane(
            apps,
            workspaceApps,
            secrets,
            lockedClient,
          ).ownApp('ws-1'),
          isNull,
        );
      }
      // The server's own route is untouched by the lock.
      expect((await lockedClient.routeFor('ws-2')).serverOwnApps, isTrue);
    });
  });

  test('changing the choice tells every own-app listener', () async {
    final heard = <ProviderApp>[];
    apps.addListener(heard.add);
    await connect.setChoice(ConnectMode.hosted);
    expect(heard.toSet(), ProviderApp.values.toSet());
  });
}

Workspace _workspace(String id) => Workspace(
  id: id,
  name: id,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

Future<void> _saveWorkspaceApps(
  WorkspaceProviderAppSettings workspaceApps,
  String workspaceId,
) async {
  await workspaceApps.save(workspaceId, WorkspaceAppProvider.google, {
    'client_id': 'ws.apps.googleusercontent.com',
    'client_secret': 'ws-secret',
  });
  await workspaceApps.save(workspaceId, WorkspaceAppProvider.linear, {
    'client_id': 'ws-linear',
    'api_key': 'lin_api_ws',
  });
}

CalendarAccountService _accounts(FileSecretsStore secrets) {
  final store = FileGoogleCredentialsStore(secrets);
  return CalendarAccountService(
    store: store,
    tokens: ServerGoogleTokenManager(
      store: store,
      refresh: (_, _) async => const RefreshUnavailable(),
      installId: (_, _) async => '',
      ownClientId: (_) async => null,
    ),
    calendarRepository: _NoCalendar(),
  );
}

GoogleSignInLane _googleLane(
  ProviderAppSettings apps,
  WorkspaceProviderAppSettings workspaceApps,
  FileSecretsStore secrets,
  ConnectClient client,
) => GoogleSignInLane(
  apps: apps,
  workspaceApps: workspaceApps,
  accounts: _accounts(secrets),
  route: client.routeFor,
);

LinearSignInLane _linearLane(
  ProviderAppSettings apps,
  WorkspaceProviderAppSettings workspaceApps,
  FileSecretsStore secrets,
  ConnectClient client,
) => LinearSignInLane(
  lane: ConnectOAuthLane.linear,
  apps: apps,
  workspaceApps: workspaceApps,
  people: UserCredentialsStore(secrets),
  workspaces: LinearAppGrants(secrets),
  route: client.routeFor,
);

LinearClients _linearClients(
  ProviderAppSettings apps,
  WorkspaceProviderAppSettings workspaceApps,
  FileSecretsStore secrets,
  ConnectClient client,
) => LinearClients(
  people: UserCredentialsStore(secrets),
  workspaces: LinearAppGrants(secrets),
  apps: apps,
  workspaceApps: workspaceApps,
  route: client.routeFor,
  refresh: (_, _, {slot}) async => const RefreshUnavailable(),
);

ProviderToken _linearGrant(String access, String clientId) => ProviderToken(
  accessToken: access,
  refreshToken: 'lin_refresh',
  expiresAt: DateTime.now().toUtc().add(const Duration(hours: 20)),
  issuedAt: DateTime.now().toUtc(),
  source: ForgeCredentialSource.oauth,
  appId: clientId,
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
