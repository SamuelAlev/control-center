import 'package:cc_domain/core/domain/value_objects/code_edge_kind.dart';
import 'package:cc_domain/core/domain/value_objects/code_symbol_kind.dart';
import 'package:cc_infra/src/code_graph/code_extractor.dart';
import 'package:cc_natives/cc_natives.dart';
import 'package:test/test.dart';

/// Exercises the pure capture-name → symbol/edge mapping in [CodeExtractor].
/// The extractor is language-agnostic and driven by tree-sitter query captures,
/// so feeding synthetic [QueryMatch] lists pins the capture contract
/// (`<kind>.def`, `<kind>.name`, `extends.name`, `call.name`, …) that the
/// `.scm` query files must emit.

const _ws = 'ws';
const _repo = 'repo';
const _file = 'lib/foo.dart';

QueryCapture _c(
  String name,
  String text, {
  int startLine = 1,
  int endLine = 1,
  int startByte = 0,
  int endByte = 0,
}) => QueryCapture(
  name: name,
  text: text,
  startLine: startLine,
  endLine: endLine,
  startByte: startByte,
  endByte: endByte,
);

void main() {
  const extractor = CodeExtractor();

  group('CodeExtractor.extractFromMatches — definitions', () {
    test('builds a symbol per <kind>.def + <kind>.name pair', () {
      final res = extractor.extractFromMatches(
        workspaceId: _ws,
        repoId: _repo,
        filePath: _file,
        languageId: 'dart',
        matches: [
          [
            _c('class.def', 'class A', startByte: 0, endByte: 100),
            _c('class.name', 'A', startByte: 6, endByte: 7),
          ],
        ],
      );
      expect(res.symbols, hasLength(1));
      expect(res.symbols.single.kind, CodeSymbolKind.classKind);
      expect(res.symbols.single.name, 'A');
      expect(res.symbols.single.qualifiedName, 'A');
      expect(res.symbols.single.language, 'dart');
      expect(res.symbols.single.filePath, _file);
    });

    test('a def with no name capture becomes <anonymous>', () {
      final res = extractor.extractFromMatches(
        workspaceId: _ws,
        repoId: _repo,
        filePath: _file,
        languageId: 'dart',
        matches: [
          [_c('function.def', 'fn', startByte: 0, endByte: 10)],
        ],
      );
      expect(res.symbols.single.name, '<anonymous>');
      expect(res.symbols.single.kind, CodeSymbolKind.function);
    });

    test('skips a def whose prefix is not a known kind', () {
      final res = extractor.extractFromMatches(
        workspaceId: _ws,
        repoId: _repo,
        filePath: _file,
        languageId: 'dart',
        matches: [
          [
            _c('mystery.def', 'x', startByte: 0, endByte: 5),
            _c('mystery.name', 'x'),
          ],
        ],
      );
      expect(res.symbols, isEmpty);
    });

    test('skips a match with no def capture', () {
      final res = extractor.extractFromMatches(
        workspaceId: _ws,
        repoId: _repo,
        filePath: _file,
        languageId: 'dart',
        matches: [
          [_c('call.name', 'foo')],
        ],
      );
      expect(res.symbols, isEmpty);
    });

    test('qualifies nested members under their container', () {
      // A class spans bytes 0..1000; a method inside it spans 10..50.
      final res = extractor.extractFromMatches(
        workspaceId: _ws,
        repoId: _repo,
        filePath: _file,
        languageId: 'dart',
        matches: [
          [
            _c('class.def', 'class C', startByte: 0, endByte: 1000),
            _c('class.name', 'C'),
          ],
          [
            _c('method.def', 'm', startByte: 10, endByte: 50),
            _c('method.name', 'm'),
          ],
        ],
      );
      expect(
        res.symbols.map((s) => s.qualifiedName),
        containsAll(['C', 'C.m']),
      );
      final method = res.symbols.firstWhere((s) => s.name == 'm');
      expect(method.parentName, 'C');
    });

    test('maps every known kind prefix', () {
      final cases = {
        'class': CodeSymbolKind.classKind,
        'mixin': CodeSymbolKind.mixin,
        'extension': CodeSymbolKind.extension,
        'enum': CodeSymbolKind.enumKind,
        'function': CodeSymbolKind.function,
        'method': CodeSymbolKind.method,
        'getter': CodeSymbolKind.getter,
        'setter': CodeSymbolKind.setter,
        'constructor': CodeSymbolKind.constructor,
        'field': CodeSymbolKind.field,
        'variable': CodeSymbolKind.variable,
        'typedef': CodeSymbolKind.typedefKind,
      };
      for (final entry in cases.entries) {
        final res = extractor.extractFromMatches(
          workspaceId: _ws,
          repoId: _repo,
          filePath: _file,
          languageId: 'dart',
          matches: [
            [
              _c('${entry.key}.def', 'x', startByte: 0, endByte: 5),
              _c('${entry.key}.name', 'x'),
            ],
          ],
        );
        expect(
          res.symbols.single.kind,
          entry.value,
          reason: '${entry.key} should map to ${entry.value}',
        );
      }
    });
  });

  group('CodeExtractor.extractFromMatches — edges', () {
    test(
      'extends/implements/mixesin edges resolve to the source container',
      () {
        final res = extractor.extractFromMatches(
          workspaceId: _ws,
          repoId: _repo,
          filePath: _file,
          languageId: 'dart',
          matches: [
            [
              _c('class.def', 'class A', startByte: 0, endByte: 200),
              _c('class.name', 'A'),
              _c('extends.name', 'Base'),
              _c('implements.name', 'I'),
              _c('mixesin.name', 'M'),
            ],
          ],
        );
        final kinds = res.edges.map((e) => e.kind).toSet();
        expect(
          kinds,
          containsAll([
            CodeEdgeKind.extendsType,
            CodeEdgeKind.implementsType,
            CodeEdgeKind.mixesIn,
          ]),
        );
        // All three edges resolve to the class A symbol as their source.
        final aId = res.symbols.single.id;
        for (final e in res.edges) {
          expect(e.sourceSymbolId, aId);
        }
      },
    );

    test('call edges attach to the innermost callable container', () {
      final res = extractor.extractFromMatches(
        workspaceId: _ws,
        repoId: _repo,
        filePath: _file,
        languageId: 'dart',
        matches: [
          [
            _c('class.def', 'class C', startByte: 0, endByte: 500),
            _c('class.name', 'C'),
          ],
          [
            _c('method.def', 'm', startByte: 10, endByte: 100),
            _c('method.name', 'm'),
          ],
          // A call at byte 20 falls inside method m (10..100).
          [_c('call.name', 'helper', startByte: 20, endByte: 25)],
        ],
      );
      final call = res.edges.firstWhere((e) => e.kind == CodeEdgeKind.calls);
      final methodId = res.symbols.firstWhere((s) => s.name == 'm').id;
      expect(call.sourceSymbolId, methodId);
      expect(call.targetName, 'helper'); // unresolved
      expect(call.targetSymbolId, isNull);
    });

    test('call edges resolve targets defined in the same file', () {
      final res = extractor.extractFromMatches(
        workspaceId: _ws,
        repoId: _repo,
        filePath: _file,
        languageId: 'dart',
        matches: [
          [
            _c('function.def', 'fn', startByte: 0, endByte: 10),
            _c('function.name', 'fn'),
          ],
          [_c('call.name', 'fn', startByte: 50, endByte: 52)],
        ],
      );
      final call = res.edges.single;
      expect(call.targetSymbolId, isNotNull); // resolved
      expect(call.targetName, isNull);
    });

    test('edges with empty targets are dropped', () {
      final res = extractor.extractFromMatches(
        workspaceId: _ws,
        repoId: _repo,
        filePath: _file,
        languageId: 'dart',
        matches: [
          [_c('call.name', '', startByte: 0, endByte: 1)],
        ],
      );
      expect(res.edges, isEmpty);
    });

    test('duplicate edges (same source/target/kind) are deduped', () {
      final res = extractor.extractFromMatches(
        workspaceId: _ws,
        repoId: _repo,
        filePath: _file,
        languageId: 'dart',
        matches: [
          [
            _c('function.def', 'fn', startByte: 0, endByte: 10),
            _c('function.name', 'fn'),
          ],
          [_c('call.name', 'fn', startByte: 50, endByte: 52)],
          [_c('call.name', 'fn', startByte: 60, endByte: 62)],
        ],
      );
      expect(
        res.edges.where((e) => e.kind == CodeEdgeKind.calls),
        hasLength(1),
      );
    });

    test('import.uri edges are stripped of surrounding quotes', () {
      final res = extractor.extractFromMatches(
        workspaceId: _ws,
        repoId: _repo,
        filePath: _file,
        languageId: 'dart',
        matches: [
          [_c('import.uri', "'package:foo/foo.dart'")],
        ],
      );
      final edge = res.edges.single;
      expect(edge.kind, CodeEdgeKind.imports);
      expect(edge.targetName, 'package:foo/foo.dart');
    });

    test('an import.uri edge with no surrounding quotes is kept as-is', () {
      final res = extractor.extractFromMatches(
        workspaceId: _ws,
        repoId: _repo,
        filePath: _file,
        languageId: 'dart',
        matches: [
          [_c('import.uri', './relative.dart')],
        ],
      );
      expect(res.edges.single.targetName, './relative.dart');
    });

    group('external module imports are not persisted as edges', () {
      // Measured on a real index, package imports (`react`, `vitest`, …) were
      // 30% of ALL edge rows while being invisible to every graph query — an
      // unresolved edge never binds and nothing reads it back.
      test('JS-family bare specifiers (node_modules) are dropped', () {
        for (final uri in [
          'react',
          'vitest',
          '@frontify/foo',
          '@frontify/foo/sub',
          'lodash/merge',
          'node:fs',
        ]) {
          for (final language in ['typescript', 'tsx', 'javascript']) {
            final res = extractor.extractFromMatches(
              workspaceId: _ws,
              repoId: _repo,
              filePath: _file,
              languageId: language,
              matches: [
                [_c('import.uri', "'$uri'")],
              ],
            );
            expect(
              res.edges,
              isEmpty,
              reason: '$uri in $language should be treated as external',
            );
          }
        }
      });

      test('JS-family relative/absolute/subpath imports are kept', () {
        for (final uri in ['./util', '../lib/x', '/abs/path', '#internal']) {
          final res = extractor.extractFromMatches(
            workspaceId: _ws,
            repoId: _repo,
            filePath: _file,
            languageId: 'typescript',
            matches: [
              [_c('import.uri', "'$uri'")],
            ],
          );
          expect(
            res.edges.single.targetName,
            uri,
            reason: '$uri is a repo-local specifier and must survive',
          );
        }
      });

      test('dart: SDK imports are dropped, package:/relative survive', () {
        final sdk = extractor.extractFromMatches(
          workspaceId: _ws,
          repoId: _repo,
          filePath: _file,
          languageId: 'dart',
          matches: [
            [_c('import.uri', "'dart:core'")],
          ],
        );
        expect(sdk.edges, isEmpty);

        final pkg = extractor.extractFromMatches(
          workspaceId: _ws,
          repoId: _repo,
          filePath: _file,
          languageId: 'dart',
          matches: [
            [_c('import.uri', "'package:foo/foo.dart'")],
          ],
        );
        expect(pkg.edges.single.targetName, 'package:foo/foo.dart');
      });

      test('PHP use targets are never filtered at extraction', () {
        // A `use` target is a symbol name that genuinely binds when the
        // definition is in the repo; extraction cannot tell vendor from app
        // namespace, so the decision belongs to the post-resolution prune.
        final res = extractor.extractFromMatches(
          workspaceId: _ws,
          repoId: _repo,
          filePath: 'src/foo.php',
          languageId: 'php',
          matches: [
            [_c('import.uri', 'PHPUnit\\Framework\\TestCase')],
            [_c('import.uri', 'App\\Domain\\Thing')],
          ],
        );
        expect(res.edges, hasLength(2));
        expect(
          res.edges.map((e) => e.targetName),
          containsAll([
            'PHPUnit\\Framework\\TestCase',
            'App\\Domain\\Thing',
          ]),
        );
      });
    });

    test(
      'an extends edge with no enclosing container falls back to file node',
      () {
        final res = extractor.extractFromMatches(
          workspaceId: _ws,
          repoId: _repo,
          filePath: _file,
          languageId: 'dart',
          matches: [
            [_c('extends.name', 'Base', startByte: 5, endByte: 9)],
          ],
        );
        expect(res.edges.single.kind, CodeEdgeKind.extendsType);
        expect(
          res.edges.single.sourceSymbolId,
          codeFileNodeId(_ws, _repo, _file),
        );
      },
    );
  });
}
