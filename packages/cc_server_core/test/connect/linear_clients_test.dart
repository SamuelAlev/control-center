import 'dart:io';

import 'package:cc_connect_core/cc_connect_core.dart' show ConnectOAuthLane;
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_server_core/src/connect/linear_clients.dart';
import 'package:cc_server_core/src/connect/linear_sign_in_lane.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:cc_server_core/src/identity/workspace_provider_app_settings.dart';
import 'package:test/test.dart';

ProviderToken _grant(
  String access, {
  DateTime? expiresAt,
  DateTime? issuedAt,
}) => ProviderToken(
  accessToken: access,
  refreshToken: 'lin_refresh',
  expiresAt: expiresAt ?? DateTime.now().toUtc().add(const Duration(hours: 20)),
  issuedAt: issuedAt ?? DateTime.now().toUtc(),
  source: ForgeCredentialSource.oauth,
  appId: 'lin-client',
);

void main() {
  late Directory dir;
  late FileSecretsStore secrets;
  late UserCredentialsStore people;
  late LinearAppGrants workspaces;
  late ProviderAppSettings apps;
  late WorkspaceProviderAppSettings workspaceApps;
  late List<String> revoked;
  late List<(ConnectOAuthLane, String?)> refreshes;
  late RefreshOutcome Function(ProviderToken token) outcome;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cc_linear_clients_');
    secrets = FileSecretsStore(dataDir: dir.path);
    people = UserCredentialsStore(secrets);
    workspaces = LinearAppGrants(secrets);
    apps = ProviderAppSettings(secrets: secrets);
    workspaceApps = WorkspaceProviderAppSettings(secrets);
    revoked = [];
    refreshes = [];
    outcome = (token) => Refreshed(_grant('lin_fresh'));
  });

  tearDown(() => dir.deleteSync(recursive: true));

  LinearClients clients() => LinearClients(
    people: people,
    workspaces: workspaces,
    apps: apps,
    workspaceApps: workspaceApps,
    refresh: (lane, token, {slot}) async {
      refreshes.add((lane, slot));
      return outcome(token);
    },
    revoke: (token) async => revoked.add(token),
  );

  group('who automation writes as', () {
    test("the workspace's app actor, as a bearer token", () async {
      await workspaces.write('ws-1', _grant('lin_app'));
      expect(await clients().appAuthorization('ws-1'), 'Bearer lin_app');
    });

    test('never another workspace\'s app actor', () async {
      await workspaces.write('ws-1', _grant('lin_app'));
      expect(await clients().appAuthorization('ws-2'), isNull);
    });

    test(
      'the service API key, raw, when the workspace has no app actor',
      () async {
        await apps.save(ProviderApp.linear, apiKey: 'lin_api_service');
        expect(await clients().appAuthorization('ws-2'), 'lin_api_service');
      },
    );

    test("never a person's sign-in", () async {
      await people.setTicketToken('alice', TicketProvider.linear, _grant('p'));
      expect(await clients().appAuthorization('ws-1'), isNull);
    });
  });

  group('who a person acts as', () {
    test('their own sign-in', () async {
      await people.setTicketToken('alice', TicketProvider.linear, _grant('p'));
      expect(await clients().personAuthorization('alice', 'ws-1'), 'Bearer p');
      expect(await clients().personAuthorization('bob', 'ws-1'), isNull);
    });

    test('never the app actor or the service key', () async {
      await workspaces.write('ws-1', _grant('lin_app'));
      await apps.save(ProviderApp.linear, apiKey: 'lin_api_service');
      expect(await clients().personAuthorization('alice', 'ws-1'), isNull);
    });
  });

  group('refresh', () {
    test('an expired grant is renewed on use and stored', () async {
      await workspaces.write(
        'ws-1',
        _grant(
          'lin_old',
          expiresAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        ),
      );
      expect(await clients().appAuthorization('ws-1'), 'Bearer lin_fresh');
      expect(refreshes, [(ConnectOAuthLane.linearApp, 'ws-1')]);
      expect((await workspaces.read('ws-1'))!.accessToken, 'lin_fresh');
    });

    test('a refused refresh deletes the grant', () async {
      outcome = (_) => const RefreshRejected();
      await people.setTicketToken(
        'alice',
        TicketProvider.linear,
        _grant(
          'p',
          expiresAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        ),
      );
      expect(await clients().personAuthorization('alice', 'ws-1'), isNull);
      expect(await people.ticketToken('alice', TicketProvider.linear), isNull);
    });

    test('a transient failure keeps the grant', () async {
      outcome = (_) => const RefreshUnavailable();
      await workspaces.write(
        'ws-1',
        _grant(
          'lin_old',
          expiresAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        ),
      );
      await clients().appAuthorization('ws-1');
      expect(await workspaces.read('ws-1'), isNotNull);
    });

    test('the daily sweep renews grants older than twenty days only', () async {
      final old = DateTime.now().toUtc().subtract(const Duration(days: 21));
      await workspaces.write('ws-old', _grant('a', issuedAt: old));
      await workspaces.write('ws-new', _grant('b'));
      await people.setTicketToken(
        'alice',
        TicketProvider.linear,
        _grant('c', issuedAt: old),
      );
      await people.setTicketToken('bob', TicketProvider.linear, _grant('d'));

      expect(await clients().refreshAging(), 2);
      expect(refreshes.toSet(), {
        (ConnectOAuthLane.linearApp, 'ws-old'),
        (ConnectOAuthLane.linear, null),
      });
      expect((await workspaces.read('ws-new'))!.accessToken, 'b');
    });

    test('concurrent callers share one refresh (Linear rotates refresh '
        'tokens)', () async {
      await workspaces.write(
        'ws-1',
        _grant(
          'lin_old',
          expiresAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        ),
      );
      final c = clients();
      final results = await Future.wait([
        c.appAuthorization('ws-1'),
        c.appAuthorization('ws-1'),
      ]);
      expect(results, ['Bearer lin_fresh', 'Bearer lin_fresh']);
      expect(refreshes, hasLength(1));
    });
  });

  group('a workspace on its own Linear app', () {
    Future<void> ownApp(String workspaceId, String clientId) =>
        workspaceApps.save(workspaceId, WorkspaceAppProvider.linear, {
          'client_id': clientId,
        });

    test(
      "reads a person's grant from its own slot, never the global one",
      () async {
        await people.setTicketToken(
          'alice',
          TicketProvider.linear,
          _grant('g'),
        );
        await ownApp('ws-own', 'ws-client');
        expect(await clients().personAuthorization('alice', 'ws-own'), isNull);
        await people.setTicketToken(
          'alice',
          TicketProvider.linear,
          _grant('w').copyWith(appId: 'ws-client'),
          workspaceId: 'ws-own',
        );
        expect(
          await clients().personAuthorization('alice', 'ws-own'),
          'Bearer w',
        );
        // An inheriting workspace still sees the global grant, never ws-own's.
        expect(
          await clients().personAuthorization('alice', 'ws-other'),
          'Bearer g',
        );
      },
    );

    test('clears a grant another client issued', () async {
      await ownApp('ws-own', 'ws-client');
      await workspaces.write('ws-own', _grant('lin_app'));
      expect(await clients().appAuthorization('ws-own'), isNull);
      expect(await workspaces.read('ws-own'), isNull);
    });

    test('uses its own API key, never the server key', () async {
      await apps.save(ProviderApp.linear, apiKey: 'lin_api_server');
      await ownApp('ws-own', 'ws-client');
      expect(await clients().appAuthorization('ws-own'), isNull);
      await workspaceApps.save('ws-own', WorkspaceAppProvider.linear, {
        'api_key': 'lin_api_ws',
      });
      expect(await clients().appAuthorization('ws-own'), 'lin_api_ws');
      expect(await clients().appAuthorization('ws-other'), 'lin_api_server');
    });

    test("refreshes a slot grant against the workspace's slot", () async {
      await ownApp('ws-own', 'ws-client');
      await people.setTicketToken(
        'alice',
        TicketProvider.linear,
        _grant(
          'old',
          expiresAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        ).copyWith(appId: 'ws-client'),
        workspaceId: 'ws-own',
      );
      outcome = (_) => Refreshed(_grant('new').copyWith(appId: 'ws-client'));
      expect(
        await clients().personAuthorization('alice', 'ws-own'),
        'Bearer new',
      );
      expect(refreshes, [(ConnectOAuthLane.linear, 'ws-own')]);
    });

    test('the daily sweep renews aging slot grants too', () async {
      final old = DateTime.now().toUtc().subtract(const Duration(days: 21));
      await people.setTicketToken(
        'alice',
        TicketProvider.linear,
        _grant('c', issuedAt: old),
        workspaceId: 'ws-own',
      );
      expect(await clients().refreshAging(), 1);
      expect(refreshes, [(ConnectOAuthLane.linear, 'ws-own')]);
    });

    test('resetWorkspace drops and revokes only that workspace', () async {
      await people.setTicketToken('alice', TicketProvider.linear, _grant('g'));
      await people.setTicketToken(
        'alice',
        TicketProvider.linear,
        _grant('w'),
        workspaceId: 'ws-own',
      );
      await people.setTicketToken(
        'alice',
        TicketProvider.linear,
        _grant('x'),
        workspaceId: 'ws-x',
      );
      await workspaces.write('ws-own', _grant('app'));
      await workspaces.write('ws-x', _grant('app-x'));

      await clients().resetWorkspace('ws-own');

      expect(revoked.toSet(), {'w', 'app'});
      expect(await workspaces.read('ws-own'), isNull);
      expect(
        await people.ticketToken(
          'alice',
          TicketProvider.linear,
          workspaceId: 'ws-own',
        ),
        isNull,
      );
      expect(await workspaces.read('ws-x'), isNotNull);
      expect(
        await people.ticketToken(
          'alice',
          TicketProvider.linear,
          workspaceId: 'ws-x',
        ),
        isNotNull,
      );
      expect(
        await people.ticketToken('alice', TicketProvider.linear),
        isNotNull,
      );
    });
  });
}
