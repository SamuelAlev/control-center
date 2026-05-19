import 'package:cc_mcp/src/tools/read/internal_url.dart';
import 'package:cc_mcp/src/tools/read/json_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InternalUrl.parse', () {
    group('skill://', () {
      test('parses simple skill slug', () {
        final result = InternalUrl.parse('skill://code-review');
        expect(result, isA<ParsedUrl>());
        result.fold(
          onError: (e) => fail(e.message),
          onOk: (url) {
            expect(url, isA<SkillUrl>());
            final skill = url as SkillUrl;
            expect(skill.slug, 'code-review');
          },
        );
      });

      test('parses multi-word skill slug', () {
        final result = InternalUrl.parse('skill://flutter-unit-testing');
        expect(result, isA<ParsedUrl>());
        result.fold(
          onError: (e) => fail(e.message),
          onOk: (url) {
            expect((url as SkillUrl).slug, 'flutter-unit-testing');
          },
        );
      });

      test('rejects empty slug', () {
        final result = InternalUrl.parse('skill://');
        expect(result, isA<ParseError>());
      });
    });

    group('rule://', () {
      test('parses rule name', () {
        final result = InternalUrl.parse('rule://code-style');
        expect(result, isA<ParsedUrl>());
        result.fold(
          onError: (e) => fail(e.message),
          onOk: (url) {
            expect((url as RuleUrl).name, 'code-style');
          },
        );
      });

      test('rejects empty name', () {
        final result = InternalUrl.parse('rule://');
        expect(result, isA<ParseError>());
      });
    });

    group('local://', () {
      test('parses simple filename', () {
        final result = InternalUrl.parse('local://PLAN.md');
        expect(result, isA<ParsedUrl>());
        result.fold(
          onError: (e) => fail(e.message),
          onOk: (url) {
            expect((url as LocalUrl).filename, 'PLAN.md');
          },
        );
      });

      test('parses nested path', () {
        final result = InternalUrl.parse('local://subdir/PLAN.md');
        expect(result, isA<ParsedUrl>());
        result.fold(
          onError: (e) => fail(e.message),
          onOk: (url) {
            expect((url as LocalUrl).filename, 'subdir/PLAN.md');
          },
        );
      });

      test('rejects parent-traversal', () {
        final result = InternalUrl.parse('local://../PLAN.md');
        expect(result, isA<ParseError>());
      });
    });

    group('agent://', () {
      test('parses agent id without path', () {
        final result = InternalUrl.parse('agent://reviewer_0');
        expect(result, isA<ParsedUrl>());
        result.fold(
          onError: (e) => fail(e.message),
          onOk: (url) {
            final agent = url as AgentUrl;
            expect(agent.id, 'reviewer_0');
            expect(agent.jsonPath, isNull);
          },
        );
      });

      test('parses agent id with json path', () {
        final result = InternalUrl.parse('agent://reviewer_0/findings/0/path');
        expect(result, isA<ParsedUrl>());
        result.fold(
          onError: (e) => fail(e.message),
          onOk: (url) {
            final agent = url as AgentUrl;
            expect(agent.id, 'reviewer_0');
            expect(agent.jsonPath, 'findings/0/path');
          },
        );
      });

      test('parses agent id with single segment path', () {
        final result = InternalUrl.parse('agent://my-agent/summary');
        expect(result, isA<ParsedUrl>());
        result.fold(
          onError: (e) => fail(e.message),
          onOk: (url) {
            final agent = url as AgentUrl;
            expect(agent.id, 'my-agent');
            expect(agent.jsonPath, 'summary');
          },
        );
      });

      test('rejects empty id', () {
        final result = InternalUrl.parse('agent://');
        expect(result, isA<ParseError>());
      });
    });

    group('artifact://', () {
      test('parses numeric artifact id', () {
        final result = InternalUrl.parse('artifact://42');
        expect(result, isA<ParsedUrl>());
        result.fold(
          onError: (e) => fail(e.message),
          onOk: (url) {
            expect((url as ArtifactUrl).id, 42);
          },
        );
      });

      test('parses zero artifact id', () {
        final result = InternalUrl.parse('artifact://0');
        expect(result, isA<ParsedUrl>());
        result.fold(
          onError: (e) => fail(e.message),
          onOk: (url) {
            expect((url as ArtifactUrl).id, 0);
          },
        );
      });

      test('rejects non-numeric id', () {
        final result = InternalUrl.parse('artifact://abc');
        expect(result, isA<ParseError>());
      });

      test('rejects empty id', () {
        final result = InternalUrl.parse('artifact://');
        expect(result, isA<ParseError>());
      });
    });

    group('mcp://', () {
      test('parses simple uri', () {
        final result = InternalUrl.parse('mcp://tools');
        expect(result, isA<ParsedUrl>());
        result.fold(
          onError: (e) => fail(e.message),
          onOk: (url) {
            expect((url as McpUrl).uri, 'tools');
          },
        );
      });

      test('parses empty uri', () {
        final result = InternalUrl.parse('mcp://');
        expect(result, isA<ParseError>());
      });
    });

    group('memory://', () {
      test('parses root summary', () {
        final result = InternalUrl.parse('memory://root');
        expect(result, isA<ParsedUrl>());
        result.fold(
          onError: (e) => fail(e.message),
          onOk: (url) {
            final mem = url as MemoryUrl;
            expect(mem.kind, MemoryUrlKind.summary);
            expect(mem.slug, isNull);
          },
        );
      });

      test('parses root/MEMORY.md', () {
        final result = InternalUrl.parse('memory://root/MEMORY.md');
        expect(result, isA<ParsedUrl>());
        result.fold(
          onError: (e) => fail(e.message),
          onOk: (url) {
            final mem = url as MemoryUrl;
            expect(mem.kind, MemoryUrlKind.full);
          },
        );
      });

      test('parses skill path', () {
        final result =
            InternalUrl.parse('memory://root/skills/code-review/SKILL.md');
        expect(result, isA<ParsedUrl>());
        result.fold(
          onError: (e) => fail(e.message),
          onOk: (url) {
            final mem = url as MemoryUrl;
            expect(mem.kind, MemoryUrlKind.skill);
            expect(mem.slug, 'code-review');
          },
        );
      });

      test('parses policy path', () {
        final result =
            InternalUrl.parse('memory://root/policies/code-style');
        expect(result, isA<ParsedUrl>());
        result.fold(
          onError: (e) => fail(e.message),
          onOk: (url) {
            final mem = url as MemoryUrl;
            expect(mem.kind, MemoryUrlKind.policy);
            expect(mem.slug, 'code-style');
          },
        );
      });
    });
  });

  group('json_query', () {
    test('parseQuery simple field', () {
      final q = parseQuery('.foo');
      expect(q, ['foo']);
    });

    test('parseQuery nested', () {
      final q = parseQuery('.foo.bar');
      expect(q, ['foo', 'bar']);
    });

    test('parseQuery array index', () {
      final q = parseQuery('.foo[0]');
      expect(q, ['foo', 0]);
    });

    test('parseQuery quoted key', () {
      final q = parseQuery(".foo['special-key']");
      expect(q, ['foo', 'special-key']);
    });
  group('pr://', () {
    test('parses owner/repo/number (none mode)', () {
      final result = InternalUrl.parse('pr://owner/repo/42');
      expect(result, isA<ParsedUrl>());
      result.fold(
        onError: (e) => fail(e.message),
        onOk: (url) {
          final pr = url as PrUrl;
          expect(pr.owner, 'owner');
          expect(pr.repo, 'repo');
          expect(pr.number, 42);
          expect(pr.diffMode, PrDiffMode.none);
          expect(pr.diffFileIndex, isNull);
          expect(pr.includeComments, isTrue);
        },
      );
    });

    test('parses owner/repo/number/diff (fileList mode)', () {
      final result = InternalUrl.parse('pr://owner/repo/42/diff');
      expect(result, isA<ParsedUrl>());
      result.fold(
        onError: (e) => fail(e.message),
        onOk: (url) {
          final pr = url as PrUrl;
          expect(pr.diffMode, PrDiffMode.fileList);
          expect(pr.includeComments, isFalse);
        },
      );
    });

    test('parses owner/repo/number/diff/all (full mode)', () {
      final result = InternalUrl.parse('pr://owner/repo/42/diff/all');
      expect(result, isA<ParsedUrl>());
      result.fold(
        onError: (e) => fail(e.message),
        onOk: (url) {
          final pr = url as PrUrl;
          expect(pr.diffMode, PrDiffMode.full);
          expect(pr.diffFileIndex, isNull);
          expect(pr.includeComments, isFalse);
        },
      );
    });

    test('parses owner/repo/number/diff/N (singleFile mode)', () {
      final result = InternalUrl.parse('pr://owner/repo/42/diff/3');
      expect(result, isA<ParsedUrl>());
      result.fold(
        onError: (e) => fail(e.message),
        onOk: (url) {
          final pr = url as PrUrl;
          expect(pr.diffMode, PrDiffMode.singleFile);
          expect(pr.diffFileIndex, 3);
        },
      );
    });

    test('parses ?comments=false query parameter', () {
      final result = InternalUrl.parse('pr://owner/repo/42?comments=false');
      expect(result, isA<ParsedUrl>());
      result.fold(
        onError: (e) => fail(e.message),
        onOk: (url) {
          final pr = url as PrUrl;
          expect(pr.includeComments, isFalse);
        },
      );
    });

    test('parses ?comments=0 query parameter', () {
      final result = InternalUrl.parse('pr://owner/repo/42?comments=0');
      expect(result, isA<ParsedUrl>());
      result.fold(
        onError: (e) => fail(e.message),
        onOk: (url) {
          final pr = url as PrUrl;
          expect(pr.includeComments, isFalse);
        },
      );
    });

    test('parses ?comments=true query parameter', () {
      final result = InternalUrl.parse('pr://owner/repo/42/diff?comments=true');
      expect(result, isA<ParsedUrl>());
      result.fold(
        onError: (e) => fail(e.message),
        onOk: (url) {
          final pr = url as PrUrl;
          // diff mode overrides comments to false
          expect(pr.includeComments, isFalse);
        },
      );
    });

    test('rejects missing owner/repo/number', () {
      expect(InternalUrl.parse('pr://owner'), isA<ParseError>());
      expect(InternalUrl.parse('pr://owner/repo'), isA<ParseError>());
    });

    test('rejects negative number', () {
      expect(InternalUrl.parse('pr://owner/repo/-1'), isA<ParseError>());
    });

    test('rejects zero number', () {
      expect(InternalUrl.parse('pr://owner/repo/0'), isA<ParseError>());
    });

    test('rejects invalid diff tail', () {
      expect(
        InternalUrl.parse('pr://owner/repo/42/diff/abc'),
        isA<ParseError>(),
      );
    });

    test('rejects too many segments', () {
      expect(
        InternalUrl.parse('pr://owner/repo/42/diff/all/extra'),
        isA<ParseError>(),
      );
    });

    test('rejects non-diff 4th segment', () {
      expect(
        InternalUrl.parse('pr://owner/repo/42/other'),
        isA<ParseError>(),
      );
    });
  });

  group('issue://', () {
    test('parses owner/repo/number', () {
      final result = InternalUrl.parse('issue://octocat/hello/5');
      expect(result, isA<ParsedUrl>());
      result.fold(
        onError: (e) => fail(e.message),
        onOk: (url) {
          final issue = url as IssueUrl;
          expect(issue.owner, 'octocat');
          expect(issue.repo, 'hello');
          expect(issue.number, 5);
        },
      );
    });

    test('rejects missing segments', () {
      expect(InternalUrl.parse('issue://owner'), isA<ParseError>());
      expect(InternalUrl.parse('issue://owner/repo'), isA<ParseError>());
    });

    test('rejects extra segments', () {
      expect(
        InternalUrl.parse('issue://owner/repo/5/extra'),
        isA<ParseError>(),
      );
    });

    test('rejects negative number', () {
      expect(InternalUrl.parse('issue://owner/repo/-1'), isA<ParseError>());
    });

    test('rejects zero number', () {
      expect(InternalUrl.parse('issue://owner/repo/0'), isA<ParseError>());
    });

    test('rejects non-numeric number', () {
      expect(InternalUrl.parse('issue://owner/repo/abc'), isA<ParseError>());
    });
  });

  group('gh://', () {
    test('parses owner/repo/blob/ref/path', () {
      final result = InternalUrl.parse('gh://owner/repo/blob/main/lib/main.dart');
      expect(result, isA<ParsedUrl>());
      result.fold(
        onError: (e) => fail(e.message),
        onOk: (url) {
          final gh = url as GhBlobUrl;
          expect(gh.owner, 'owner');
          expect(gh.repo, 'repo');
          expect(gh.ref, 'main');
          expect(gh.path, 'lib/main.dart');
        },
      );
    });

    test('parses with SHA ref', () {
      final result = InternalUrl.parse(
        'gh://owner/repo/blob/abc123/src/foo.dart',
      );
      expect(result, isA<ParsedUrl>());
      result.fold(
        onError: (e) => fail(e.message),
        onOk: (url) {
          final gh = url as GhBlobUrl;
          expect(gh.ref, 'abc123');
          expect(gh.path, 'src/foo.dart');
        },
      );
    });

    test('rejects missing blob segment', () {
      expect(
        InternalUrl.parse('gh://owner/repo/main/lib/main.dart'),
        isA<ParseError>(),
      );
    });

    test('rejects too few segments', () {
      expect(InternalUrl.parse('gh://owner/repo'), isA<ParseError>());
      expect(InternalUrl.parse('gh://owner'), isA<ParseError>());
    });

    test('rejects path traversal in ref', () {
      expect(
        InternalUrl.parse('gh://owner/repo/blob/../etc/passwd'),
        isA<ParseError>(),
      );
    });
  });

    test('pathToQuery simple', () {
      expect(pathToQuery('/foo/bar/0'), '.foo.bar[0]');
    });

    test('pathToQuery root', () {
      expect(pathToQuery('/'), '');
    });

    test('pathToQuery empty', () {
      expect(pathToQuery(''), '');
    });
  });
}
