import 'dart:io';
import 'package:cc_domain/features/auth/domain/entities/github_cli_status.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:flutter_test/flutter_test.dart';

Future<bool> _ghIsAvailable() async {
  try {
    final result = await Process.run('gh', ['--version']);
    return result.exitCode == 0;
  } on ProcessException {
    return false;
  }
}

void main() {
  group('GitHubCliService.probe', () {
    test('isInstalled is true when gh is available', () async {
      final ghAvailable = await _ghIsAvailable();
      if (!ghAvailable) {
        return;
      }

      final service = ProcessGitHubCliService();
      final status = await service.probe();

      expect(status.isInstalled, isTrue);
    });

    test('returns authenticated status when logged in', () async {
      final ghAvailable = await _ghIsAvailable();
      if (!ghAvailable) {
        return;
      }

      final service = ProcessGitHubCliService();
      final status = await service.probe();

      if (status.isAuthenticated) {
        expect(status.username, isNotEmpty);
        expect(status.token, isNotEmpty);
      }
    }, skip: true);
  });

  group('GitHubCliService constructor', () {
    test('service is instantiable', () {
      final service = ProcessGitHubCliService();
      expect(service, isA<ProcessGitHubCliService>());
    });
  });

  group('GitHubCliStatus', () {
    test('defaults are all false/empty', () {
      const status = GitHubCliStatus();
      expect(status.isInstalled, isFalse);
      expect(status.isAuthenticated, isFalse);
      expect(status.username, isEmpty);
      expect(status.token, isEmpty);
    });

    test('equality works', () {
      const a = GitHubCliStatus(isInstalled: true, username: 'u');
      const b = GitHubCliStatus(isInstalled: true, username: 'u');
      const c = GitHubCliStatus(isInstalled: false, username: 'u');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('copyWith preserves unchanged fields', () {
      const status = GitHubCliStatus(isInstalled: true, username: 'dev');
      final copied = status.copyWith(username: 'newdev');
      expect(copied.isInstalled, isTrue);
      expect(copied.username, equals('newdev'));
      expect(copied.token, isEmpty);
    });
  });

  group('_parseUsername regex', () {
    final linePattern = RegExp(
      r'(?:Logged in to\s*[^\s]+\s+(?:as|account)\s+)([^\s]+)',
    );

    test('extracts username when hostname is directly adjacent to "to"', () {
      const input = '✓ Logged in togithub.com account testuser (keyring)';
      final match = linePattern.firstMatch(input);
      expect(match?.group(1), equals('testuser'));
    });

    test('extracts username with "as" keyword', () {
      const input = '✓ Logged in togithub.com as myuser';
      final match = linePattern.firstMatch(input);
      expect(match?.group(1), equals('myuser'));
    });

    test('extracts username from GHE custom host', () {
      const input = '✓ Logged in togithub.mycorp.com account devuser (token)';
      final match = linePattern.firstMatch(input);
      expect(match?.group(1), equals('devuser'));
    });

    test('returns null for unrecognized format', () {
      const input = 'Some random output';
      final match = linePattern.firstMatch(input);
      expect(match, isNull);
    });

    test('returns null for empty string', () {
      final match = linePattern.firstMatch('');
      expect(match, isNull);
    });

    test('extracts username with numbers and hyphens', () {
      const input = '✓ Logged in togithub.com account dev-user123 (keyring)';
      final match = linePattern.firstMatch(input);
      expect(match?.group(1), equals('dev-user123'));
    });

    test('extracts username with trailing format info', () {
      const input =
          '✓ Logged in togithub.com account jdoe (/Users/jdoe/.config/gh/hosts.yml)';
      final match = linePattern.firstMatch(input);
      expect(match?.group(1), equals('jdoe'));
    });

    test('multiline output finds first match', () {
      const input = '''
Some header
✓ Logged in togithub.com account primary (keyring)
✓ Logged in togithub.com account secondary (token)
''';
      final match = linePattern.firstMatch(input);
      expect(match?.group(1), equals('primary'));
    });

    test('returns null without account or as keyword', () {
      const input = '✓ Logged in togithub.com testuser (keyring)';
      final match = linePattern.firstMatch(input);
      expect(match, isNull);
    });

    test('returns null when Logged in to not present', () {
      const input = 'Logged out of github.com account testuser';
      final match = linePattern.firstMatch(input);
      expect(match, isNull);
    });

    test('extracts dot-separated usernames', () {
      const input = '✓ Logged in togithub.com account samuel.alev (keyring)';
      final match = linePattern.firstMatch(input);
      expect(match?.group(1), equals('samuel.alev'));
    });

    test('regex captures only the first username token', () {
      const input = '✓ Logged in togithub.com account user123 extra stuff here';
      final match = linePattern.firstMatch(input);
      expect(match?.group(1), equals('user123'));
    });
  });
}
