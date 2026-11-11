import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:test/test.dart';

void main() {
  group('GitHubInstallationsResponse', () {
    test('round-trips and drops malformed items', () {
      const response = GitHubInstallationsResponse(
        installations: [
          GitHubInstallationView(
            installationId: 77,
            accountId: 500,
            accountLogin: 'acme',
            targetType: 'Organization',
            suspended: true,
          ),
        ],
        updatedSeal: 'v1.a.b',
      );
      final parsed = GitHubInstallationsResponse.fromJson({
        ...response.toJson(),
        'installations': [
          ...(response.toJson()['installations']! as List),
          {'installation_id': 'nope'},
        ],
      });
      expect(parsed.installations.single.accountLogin, 'acme');
      expect(parsed.installations.single.suspended, isTrue);
      expect(response.toJson()['installations'], [
        {
          'installation_id': 77,
          'account_id': 500,
          'account_login': 'acme',
          'target_type': 'Organization',
          'suspended': true,
        },
      ], reason: 'no per-server binding fields on the wire');
      expect(parsed.updatedSeal, 'v1.a.b');
      expect(const GitHubInstallationsResponse(installations: []).toJson(), {
        'installations': <Object?>[],
      });
      expect(
        () => GitHubInstallationsResponse.fromJson(const {}),
        throwsFormatException,
      );
    });
  });

  group('ConnectAck', () {
    test('needs ok:true', () {
      expect(const ConnectAck().toJson(), {'ok': true});
      expect(
        ConnectAck.fromJson(const {
          'ok': true,
          'updated_seal': 's',
        }).updatedSeal,
        's',
      );
      expect(
        () => ConnectAck.fromJson(const {'ok': false}),
        throwsFormatException,
      );
    });
  });

  group('KlipyQuery', () {
    test('search requires a bounded query', () {
      final query = KlipyQuery.fromJson(const {
        'q': '  cats ',
        'page': 2,
        'per_page': 10,
        'locale': 'pt-BR',
      }, requireQuery: true);
      expect(query.query, 'cats');
      expect(query.toJson(), {
        'q': 'cats',
        'page': 2,
        'per_page': 10,
        'locale': 'pt-BR',
      });
      for (final bad in <Map<String, Object?>>[
        {},
        {'q': ''},
        {'q': 'x' * (klipyMaxQueryLength + 1)},
        {'q': 'cats', 'page': 0},
        {'q': 'cats', 'page': 101},
        {'q': 'cats', 'per_page': klipyMaxPerPage + 1},
        {'q': 'cats', 'locale': 'english please'},
        {'q': 'cats', 'page': '2'},
      ]) {
        expect(
          () => KlipyQuery.fromJson(bad, requireQuery: true),
          throwsFormatException,
          reason: '$bad',
        );
      }
    });

    test('trending refuses a query and defaults the page', () {
      final query = KlipyQuery.fromJson(const {}, requireQuery: false);
      expect(query.query, isEmpty);
      expect(query.page, 1);
      expect(query.perPage, 24);
      expect(
        () => KlipyQuery.fromJson(const {'q': 'cats'}, requireQuery: false),
        throwsFormatException,
      );
    });

    test('isKlipyLocale', () {
      expect(isKlipyLocale('en'), isTrue);
      expect(isKlipyLocale('zh_TW'), isTrue);
      expect(isKlipyLocale('yue'), isTrue);
      expect(isKlipyLocale('en-'), isFalse);
      expect(isKlipyLocale('EN'), isFalse);
    });
  });

  group('KlipyGifsResponse', () {
    test('drops GIFs off the Klipy CDN', () {
      final parsed = KlipyGifsResponse.fromJson({
        'gifs': [
          {
            'id': '1',
            'title': 't',
            'width': 1,
            'height': 1,
            'preview_url': 'https://static.klipy.com/1.gif',
            'gif_url': 'https://static.klipy.com/1.gif',
          },
          {
            'id': '2',
            'title': 't',
            'width': 1,
            'height': 1,
            'preview_url': 'https://evil.example/2.gif',
            'gif_url': 'https://static.klipy.com/2.gif',
          },
          {
            'id': '3',
            'title': 't',
            'width': 1,
            'height': 1,
            'preview_url': 'https://api.klipy.com/3.gif',
            'gif_url': 'https://api.klipy.com/3.gif',
          },
        ],
      });
      expect(parsed.gifs.map((g) => g.id), ['1']);
      expect(KlipyGifsResponse.fromJson(parsed.toJson()).gifs, hasLength(1));
    });
  });

  group('ConnectEventsPollResponse', () {
    test('splits events and commands by kind and skips unknown kinds', () {
      final parsed = ConnectEventsPollResponse.fromJson({
        'events': [
          const SlackEventRef(
            eventId: 'Ev1',
            teamId: 'T1',
            eventType: 'app_mention',
          ).toJson(),
          const SlackCommandRef(
            commandId: 'c1',
            teamId: 'T1',
            userId: 'U1',
            channelId: 'C1',
            command: '/cc',
            text: 'hello',
            responseUrl: '',
          ).toJson(),
          {'kind': 'future_thing', 'x': 1},
          'junk',
        ],
      });
      expect(parsed.events.single.eventId, 'Ev1');
      expect(parsed.commands.single.text, 'hello');
      expect(
        () => ConnectEventsPollResponse.fromJson(const {}),
        throwsFormatException,
      );
    });
  });
}
