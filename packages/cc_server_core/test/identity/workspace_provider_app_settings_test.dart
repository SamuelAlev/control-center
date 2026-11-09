import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/catalog/workspace_provider_app_ops.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/google_calendar_server.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:cc_server_core/src/identity/workspace_github_app_settings.dart';
import 'package:cc_server_core/src/identity/workspace_provider_app_settings.dart';
import 'package:test/test.dart';

/// A workspace's own Google, Linear and Klipy apps: inherit by default,
/// fail-closed when half-configured, write-only secrets, a change that
/// announces a different app, and nothing that crosses to another workspace.
void main() {
  late Directory dir;
  late FileSecretsStore secrets;
  late WorkspaceProviderAppSettings apps;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cc_ws_provider_apps_');
    secrets = FileSecretsStore(dataDir: dir.path);
    apps = WorkspaceProviderAppSettings(secrets);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('a workspace inherits every provider by default', () async {
    for (final provider in WorkspaceAppProvider.values) {
      final status = await apps.status('ws-a', provider);
      expect(status.mode, WorkspaceAppMode.inherit, reason: provider.wire);
      expect(status.state, OwnAppState.none, reason: provider.wire);
    }
    expect(
      await apps.oauthCredentials('ws-a', WorkspaceAppProvider.google),
      isNull,
    );
    expect(await apps.linearApiKey('ws-a'), isNull);
    expect(await apps.klipyAppKey('ws-a'), isNull);
  });

  test('own mode with a missing field fails closed', () async {
    await apps.setMode(
      'ws-a',
      WorkspaceAppProvider.google,
      WorkspaceAppMode.own,
    );
    await apps.save('ws-a', WorkspaceAppProvider.google, {'client_id': 'id'});
    final status = await apps.status('ws-a', WorkspaceAppProvider.google);
    expect(status.state, OwnAppState.partial);
    expect(status.error, isNotEmpty);
    expect(
      () => apps.oauthCredentials('ws-a', WorkspaceAppProvider.google),
      throwsA(isA<WorkspaceAppIncomplete>()),
    );
    await apps.setMode(
      'ws-a',
      WorkspaceAppProvider.klipy,
      WorkspaceAppMode.own,
    );
    expect(
      () => apps.klipyAppKey('ws-a'),
      throwsA(isA<WorkspaceAppIncomplete>()),
    );
  });

  test(
    'a complete own app resolves; its secrets never reach the wire',
    () async {
      await apps.save('ws-a', WorkspaceAppProvider.google, {
        'client_id': 'id.apps',
        'client_secret': 'shh',
      });
      final creds = await apps.oauthCredentials(
        'ws-a',
        WorkspaceAppProvider.google,
      );
      expect(creds, (clientId: 'id.apps', clientSecret: 'shh'));
      final wire = (await apps.status(
        'ws-a',
        WorkspaceAppProvider.google,
      )).toJson().toString();
      expect(wire, isNot(contains('shh')));
      expect(wire, contains('has_client_secret: true'));
    },
  );

  test('a field the provider does not have is refused', () async {
    expect(
      () => apps.save('ws-a', WorkspaceAppProvider.klipy, {'client_id': 'x'}),
      throwsA(isA<ValidationException>()),
    );
  });

  test('back to the server lane deletes the fields', () async {
    await apps.save('ws-a', WorkspaceAppProvider.linear, {
      'client_id': 'lin',
      'api_key': 'lin_api',
    });
    await apps.setMode(
      'ws-a',
      WorkspaceAppProvider.linear,
      WorkspaceAppMode.inherit,
    );
    expect(
      await secrets.keysMatching(
        (k) => k.startsWith('workspace_provider_app_'),
      ),
      isEmpty,
    );
  });

  test('listeners hear a different app, not a re-entered secret', () async {
    final heard = <(String, WorkspaceAppProvider)>[];
    apps.addListener((ws, p) => heard.add((ws, p)));
    await apps.save('ws-a', WorkspaceAppProvider.google, {
      'client_id': 'one',
      'client_secret': 's1',
    });
    await apps.save('ws-a', WorkspaceAppProvider.google, {
      'client_secret': 's2',
    });
    await apps.save('ws-a', WorkspaceAppProvider.google, {'client_id': 'two'});
    await apps.setMode(
      'ws-a',
      WorkspaceAppProvider.google,
      WorkspaceAppMode.inherit,
    );
    expect(heard, [
      ('ws-a', WorkspaceAppProvider.google),
      ('ws-a', WorkspaceAppProvider.google),
      ('ws-a', WorkspaceAppProvider.google),
    ]);
  });

  group('workspace isolation', () {
    test("workspace A's app is never workspace B's", () async {
      await apps.save('ws-a', WorkspaceAppProvider.google, {
        'client_id': 'a.apps',
        'client_secret': 'a-secret',
      });
      await apps.save('ws-a', WorkspaceAppProvider.klipy, {'app_key': 'A'});
      await apps.save('ws-a', WorkspaceAppProvider.linear, {
        'client_id': 'lin-a',
        'api_key': 'lin_api_a',
      });
      expect(
        await apps.oauthCredentials('ws-b', WorkspaceAppProvider.google),
        isNull,
      );
      expect(await apps.klipyAppKey('ws-b'), isNull);
      expect(await apps.linearApiKey('ws-b'), isNull);
      expect(
        (await apps.status('ws-b', WorkspaceAppProvider.google)).clientId,
        isEmpty,
      );
    });

    test('a workspace id that prefixes another reaches none of its keys', () {
      final key = WorkspaceProviderAppSettings.secretKey(
        'ws_long',
        WorkspaceAppProvider.google,
        'client_id',
      );
      expect(
        WorkspaceProviderAppSettings.isWorkspaceSecret(key, 'ws'),
        isFalse,
      );
      expect(
        WorkspaceProviderAppSettings.isWorkspaceSecret(key, 'ws_long'),
        isTrue,
      );
    });

    test('deleting a workspace deletes its apps, slot grants and calendar '
        'credentials, and nothing of another', () async {
      final people = UserCredentialsStore(secrets);
      final calendar = FileGoogleCredentialsStore(secrets);
      const token = ProviderToken(
        accessToken: 't',
        source: ForgeCredentialSource.oauth,
      );
      for (final ws in ['ws-a', 'ws-b']) {
        await apps.save(ws, WorkspaceAppProvider.klipy, {'app_key': 'k'});
        await people.setTicketToken(
          'alice',
          TicketProvider.linear,
          token,
          workspaceId: ws,
        );
        await calendar.save(
          serverGoogleAccountId(ws, 'a@example.com', userId: 'alice'),
          token,
        );
      }
      await people.setTicketToken('alice', TicketProvider.linear, token);

      await WorkspaceGitHubAppSettings(
        secrets: secrets,
        install: ProviderAppSettings(secrets: secrets),
      ).deleteForWorkspace('ws-a');

      final left = await secrets.keysMatching((_) => true);
      expect(left.where((k) => k.contains('ws-a')), isEmpty);
      // Klipy key + mode marker, the Linear slot grant, the calendar credential.
      expect(left.where((k) => k.contains('ws-b')), hasLength(4));
      expect(left, contains('user_ticket_linear_alice'));
    });
  });

  group('workspaceProviderApps.* ops', () {
    late RepoOpDispatcher dispatcher;
    const roles = {
      'ws-a': {'ada': WorkspaceRole.admin, 'mia': WorkspaceRole.member},
      'ws-b': {'bea': WorkspaceRole.owner},
    };

    setUp(() {
      dispatcher = RepoOpDispatcher(
        registry: RepoOpRegistry(
          buildWorkspaceProviderAppOps(
            apps: apps,
            pairingServerUrl: 'wss://cc.example:9030',
          ),
        ),
        resolveRole: (ws, user) async => roles[ws]?[user],
        workspaceExists: (ws) async => roles.containsKey(ws),
      );
    });

    Future<Map<String, dynamic>> call(
      String op,
      String user,
      Map<String, dynamic> args,
    ) => dispatcher.call(
      id: 1,
      params: {'op': op, 'args': args},
      deviceId: 'dev-$user',
      userId: user,
      sessionCapability: SessionCapability.fullClient,
    );

    int? code(Map<String, dynamic> res) =>
        (res['error'] as Map?)?['code'] as int?;

    test(
      'an admin saves and reads presence flags with callback URLs',
      () async {
        final saved = await call('workspaceProviderApps.save', 'ada', {
          'workspace_id': 'ws-a',
          'provider': 'linear',
          'client_id': 'lin-a',
          'api_key': 'lin_api_a',
        });
        expect(saved['error'], isNull);
        final list = await call('workspaceProviderApps.list', 'ada', {
          'workspace_id': 'ws-a',
        });
        final linear =
            (((list['result'] as Map)['data'] as Map)['apps'] as List)
                .cast<Map<String, Object?>>()
                .firstWhere((a) => a['provider'] == 'linear');
        expect(linear['mode'], 'own');
        expect(linear['has_api_key'], isTrue);
        expect(linear.toString(), isNot(contains('lin_api_a')));
        expect(linear['redirect_uris'], [
          'https://cc.example:9030/oauth/linear/callback',
          'https://cc.example:9030/oauth/linear_app/callback',
        ]);
      },
    );

    test('a member cannot read or change the apps', () async {
      for (final op in [
        'workspaceProviderApps.list',
        'workspaceProviderApps.save',
        'workspaceProviderApps.setMode',
      ]) {
        final res = await call(op, 'mia', {
          'workspace_id': 'ws-a',
          'provider': 'klipy',
          'mode': 'own',
          'app_key': 'x',
        });
        expect(code(res), RpcErrorCodes.unauthorized, reason: op);
      }
      expect(await apps.ownsApp('ws-a', WorkspaceAppProvider.klipy), isFalse);
    });

    test("an owner of B reaches none of A's config", () async {
      await apps.save('ws-a', WorkspaceAppProvider.klipy, {'app_key': 'A'});
      for (final op in [
        'workspaceProviderApps.list',
        'workspaceProviderApps.save',
        'workspaceProviderApps.setMode',
      ]) {
        final res = await call(op, 'bea', {
          'workspace_id': 'ws-a',
          'provider': 'klipy',
          'mode': 'inherit',
          'app_key': 'B',
        });
        expect(code(res), RpcErrorCodes.unauthorized, reason: op);
      }
      expect(await apps.klipyAppKey('ws-a'), 'A');
      // Their own workspace is theirs to change, and stays apart from A.
      await call('workspaceProviderApps.save', 'bea', {
        'workspace_id': 'ws-b',
        'provider': 'klipy',
        'app_key': 'B',
      });
      expect(await apps.klipyAppKey('ws-b'), 'B');
      expect(await apps.klipyAppKey('ws-a'), 'A');
    });

    test('an unknown workspace is refused before any lookup', () async {
      final res = await call('workspaceProviderApps.list', 'ada', {
        'workspace_id': 'ws-ghost',
      });
      expect(code(res), RpcErrorCodes.notFound);
    });
  });
}
