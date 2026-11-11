import 'dart:io';

import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/forge/forge_credentials.dart';
import 'package:cc_server_core/src/forge/forge_person_token_check.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 11, 10, 12);
  const person = {'username': 'ada', 'id': 7, 'bot': false};
  Map<String, Object?> self({
    List<String> scopes = const ['api'],
    String? expiresAt = '2027-06-01',
    bool active = true,
    bool revoked = false,
  }) => {
    'scopes': scopes,
    'expires_at': expiresAt,
    'active': active,
    'revoked': revoked,
  };

  PersonTokenVerdict gitlab({
    int? userStatus = 200,
    Object? user = person,
    int? selfStatus = 200,
    Object? token,
  }) => gitLabPersonTokenVerdict(
    userStatus: userStatus,
    user: user,
    selfStatus: selfStatus,
    self: token ?? self(),
    now: now,
  );

  Matcher refused(PersonTokenRefusal reason) =>
      isA<PersonTokenRefused>().having((r) => r.reason, 'reason', reason);

  group('GitLab', () {
    test("a person's token with the api scope is accepted with its "
        'expiry', () {
      final verdict = gitlab() as PersonTokenAccepted;
      expect(verdict.viewer, (login: 'ada', id: '7'));
      expect(verdict.expiresAt, DateTime.utc(2027, 6));
      expect(
        (gitlab(token: self(expiresAt: null)) as PersonTokenAccepted).expiresAt,
        isNull,
      );
    });

    test('a refused or unanswered token is not stored', () {
      expect(
        gitlab(userStatus: 401, user: null),
        refused(PersonTokenRefusal.rejected),
      );
      expect(gitlab(user: null), refused(PersonTokenRefusal.rejected));
      expect(
        gitlab(token: self(revoked: true)),
        refused(PersonTokenRefusal.rejected),
      );
      expect(
        gitlab(token: self(active: false)),
        refused(PersonTokenRefusal.rejected),
      );
      for (final status in [null, 429, 502]) {
        expect(
          gitlab(userStatus: status),
          refused(PersonTokenRefusal.unreachable),
        );
        expect(
          gitlab(selfStatus: status),
          refused(PersonTokenRefusal.unreachable),
        );
      }
    });

    test('a project or group access token is the wrong kind', () {
      final verdict = gitlab(user: {...person, 'bot': true});
      expect(verdict, refused(PersonTokenRefusal.wrongKind));
      expect(
        (verdict as PersonTokenRefused).message,
        contains('automation token'),
      );
      expect(gitlab(selfStatus: 404), refused(PersonTokenRefusal.wrongKind));
    });

    test('a token without the api scope is too narrow', () {
      expect(
        gitlab(token: self(scopes: ['read_api', 'read_user'])),
        refused(PersonTokenRefusal.narrowScope),
      );
    });

    test('an expired token is refused', () {
      expect(
        gitlab(token: self(expiresAt: '2026-11-10')),
        refused(PersonTokenRefusal.expired),
      );
      expect(
        gitlab(token: self(expiresAt: '2025-01-01')),
        refused(PersonTokenRefusal.expired),
      );
      expect(
        gitlab(token: self(expiresAt: 'soon')),
        refused(PersonTokenRefusal.rejected),
      );
    });

    test('a token about to expire is accepted, carrying the date', () {
      final verdict =
          gitlab(token: self(expiresAt: '2026-11-11')) as PersonTokenAccepted;
      expect(verdict.expiresAt, DateTime.utc(2026, 11, 11));
    });
  });

  group('Bitbucket', () {
    const account = {'nickname': 'jdoe', 'account_id': '557057:abc'};
    PersonTokenVerdict bitbucket({
      int? status = 200,
      Object? user = account,
      String? scopes,
    }) =>
        bitbucketPersonTokenVerdict(status: status, user: user, scopes: scopes);

    test('an API token Bitbucket answers for is accepted', () {
      final verdict = bitbucket() as PersonTokenAccepted;
      expect(verdict.viewer, (login: 'jdoe', id: '557057:abc'));
      expect(
        bitbucket(
          scopes: 'read:repository:bitbucket, write:pullrequest:bitbucket',
        ),
        isA<PersonTokenAccepted>(),
      );
    });

    test('a refused token (an expired one included) is not stored', () {
      expect(
        bitbucket(status: 401, user: null),
        refused(PersonTokenRefusal.rejected),
      );
      expect(
        bitbucket(user: {'nickname': 'jdoe'}),
        refused(PersonTokenRefusal.rejected),
      );
      for (final status in [null, 429, 503]) {
        expect(
          bitbucket(status: status),
          refused(PersonTokenRefusal.unreachable),
        );
      }
    });

    test('an access token is the wrong kind, refused without asking', () async {
      final verdict = await checkPersonForgeToken(
        ForgeHost.bitbucket,
        'ATCTT3xFfGN0bare',
      );
      expect(verdict, refused(PersonTokenRefusal.wrongKind));
      expect((verdict as PersonTokenRefused).message, contains('API token'));
    });

    test('a token whose reported scopes cannot write to pull requests is '
        'too narrow', () {
      expect(
        bitbucket(scopes: 'read:repository:bitbucket read:user:bitbucket'),
        refused(PersonTokenRefusal.narrowScope),
      );
    });

    test('Bitbucket does not report an expiry, so none is carried', () {
      expect((bitbucket() as PersonTokenAccepted).expiresAt, isNull);
    });
  });

  group('ForgeCredentials.setToken', () {
    late Directory dir;
    late UserCredentialsStore users;
    const alice = 'user-alice';

    setUp(() {
      dir = Directory.systemTemp.createTempSync('cc_person_token_check_');
      users = UserCredentialsStore(FileSecretsStore(dataDir: dir.path));
    });

    tearDown(() => dir.deleteSync(recursive: true));

    test('a refused token never lands in the slot; the dialog gets the '
        'reason as a code', () async {
      final creds = ForgeCredentials(
        users: users,
        personTokenCheck: (forge, token) async => token == 'glpat-bot'
            ? const PersonTokenRefused(
                PersonTokenRefusal.wrongKind,
                gitLabBotTokenRefusal,
              )
            : const PersonTokenRefused(
                PersonTokenRefusal.unreachable,
                'Try again.',
              ),
      );
      for (final token in ['glpat-bot', 'glpat-unanswered']) {
        await expectLater(
          creds.setToken(ForgeHost.gitlab, token, userId: alice),
          throwsA(isA<ValidationException>()),
        );
      }
      await expectLater(
        creds.setToken(ForgeHost.gitlab, 'glpat-bot', userId: alice),
        throwsA(
          isA<ValidationException>()
              .having((e) => e.message, 'message', gitLabBotTokenRefusal)
              .having((e) => e.code, 'code', 'person_token.wrong_kind'),
        ),
      );
      expect(await users.forgeToken(alice, ForgeHost.gitlab), isNull);
    });

    test('an accepted token is connected at once, with who it is and when '
        'it lapses', () async {
      final expiry = DateTime.now().toUtc().add(const Duration(days: 3));
      var probed = 0;
      final creds = ForgeCredentials(
        users: users,
        viewerProbe: (forge, token) async {
          probed++;
          return null;
        },
        personTokenCheck: (forge, token) async =>
            PersonTokenAccepted((login: 'ada', id: '7'), expiresAt: expiry),
      );
      final connection = await creds.setToken(
        ForgeHost.gitlab,
        'glpat-ada',
        userId: alice,
      );
      expect(connection.status, ForgeConnectionStatus.connected);
      expect(connection.username, 'ada');
      expect(connection.expiresAt, expiry);
      expect(
        ForgeConnection.fromJson(connection.toJson()).expiresAt,
        expiry,
        reason: 'the client sees the date to warn before it',
      );
      expect(probed, 0, reason: 'the check already named the viewer');
      final stored = await users.forgeToken(alice, ForgeHost.gitlab);
      expect(stored?.accountId, '7');
      expect(stored?.expiresAt, expiry);
    });

    test('a token is never stored without a check', () async {
      await expectLater(
        ForgeCredentials(
          users: users,
        ).setToken(ForgeHost.gitlab, 'glpat-ada', userId: alice),
        throwsStateError,
      );
      expect(await users.forgeToken(alice, ForgeHost.gitlab), isNull);
    });
  });
}
