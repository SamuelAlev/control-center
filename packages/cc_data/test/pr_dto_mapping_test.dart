import 'package:cc_data/src/repositories/pr_dto_mapping.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/src/dtos/dtos.dart';
import 'package:test/test.dart';

/// Exercises the pure `*FromWireDto` mappers in `pr_dto_mapping.dart`.
void main() {
  group('pullRequestFromWireDto', () {
    test('maps every field', () {
      final pr = pullRequestFromWireDto(
        PullRequestDto(
          id: 1,
          number: 42,
          title: 'Fix',
          body: 'body',
          state: 'open',
          isDraft: false,
          repoFullName: 'o/r',
          htmlUrl: 'https://x',
          author: PrUserDto(login: 'sam', avatarUrl: 'a'),
          createdAt: '2026-01-01T00:00:00Z',
          nodeId: 'n',
          headSha: 'abc',
          baseRef: 'main',
          headRef: 'feature',
        ),
      );
      expect(pr.number, 42);
      expect(pr.title, 'Fix');
      expect(pr.author?.login, 'sam');
      expect(pr.headSha, 'abc');
      expect(pr.baseRef, 'main');
    });

    test('tolerates null author and dates', () {
      final pr = pullRequestFromWireDto(
        PullRequestDto(
          id: 1,
          number: 1,
          title: 't',
          body: '',
          state: 'closed',
          isDraft: false,
          repoFullName: 'o/r',
          htmlUrl: 'u',
        ),
      );
      expect(pr.author, isNull);
      expect(pr.createdAt, isNull);
    });
  });

  group('prFileFromWireDto', () {
    test('maps every field', () {
      final f = prFileFromWireDto(
        PrFileDto(
          filename: 'lib/x.dart',
          status: 'modified',
          additions: 10,
          deletions: 2,
          patch: '@@ -1 +1 @@',
        ),
      );
      expect(f.filename, 'lib/x.dart');
      expect(f.status, PrFileStatus.modified);
      expect(f.additions, 10);
      expect(f.deletions, 2);
      expect(f.patch, '@@ -1 +1 @@');
    });
  });

  group('prCommitFromWireDto', () {
    test('maps every field', () {
      final c = prCommitFromWireDto(
        PrCommitDto(
          sha: 'abc123',
          message: 'fix',
          author: PrUserDto(login: 'sam', avatarUrl: ''),
        ),
      );
      expect(c.sha, 'abc123');
      expect(c.message, 'fix');
      expect(c.author?.login, 'sam');
    });

    test('tolerates null author', () {
      final c = prCommitFromWireDto(PrCommitDto(sha: 'x', message: 'm'));
      expect(c.author, isNull);
    });
  });
}
