import 'package:cc_domain/core/domain/value_objects/code_symbol_kind.dart';
import 'package:cc_domain/features/code_graph/domain/ports/code_graph_lookup_port.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/diff_symbol_popover.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../helpers/test_wrap.dart';

class _FakeLookup implements CodeGraphLookupPort {
  _FakeLookup(this.result);

  final CodeGraphLookupResult result;
  String? lastName;
  String? lastSpaceId;

  @override
  Future<CodeGraphLookupResult> lookup({
    required String workspaceId,
    required String repoId,
    required String name,
    String? spaceId,
  }) async {
    lastName = name;
    lastSpaceId = spaceId;
    return result;
  }
}

void main() {
  testWidgets('lists candidates, implementations, and the from-base caveat', (
    tester,
  ) async {
    const impl = CodeGraphLookupCandidate(
      id: 'impl-1',
      name: 'Dog',
      qualifiedName: 'animals.Dog',
      kind: CodeSymbolKind.classKind,
      filePath: 'lib/dog.dart',
      startLine: 4,
      endLine: 10,
    );
    const animal = CodeGraphLookupCandidate(
      id: 'cls-1',
      name: 'Animal',
      qualifiedName: 'animals.Animal',
      kind: CodeSymbolKind.classKind,
      filePath: 'lib/animal.dart',
      startLine: 12,
      endLine: 40,
      parentName: 'pkg',
      callerCount: 3,
      implementors: [impl],
    );
    final lookup = _FakeLookup(
      const CodeGraphLookupResult(
        definitions: [animal],
        fromBasePartition: true,
      ),
    );
    String? jumpedPath;
    int? jumpedLine;
    String? openedPath;
    int? openedLine;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [codeGraphLookupProvider.overrideWithValue(lookup)],
        child: testWrap(
          DiffSymbolPopover(
            name: 'Animal',
            workspaceId: 'ws',
            repoId: 'repo',
            spaceId: 'space-1',
            prFilePaths: const {'lib/animal.dart'},
            onJumpToDiff: (path, line) {
              jumpedPath = path;
              jumpedLine = line;
            },
            onOpenInEditor: (path, {int? line}) {
              openedPath = path;
              openedLine = line;
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(lookup.lastName, 'Animal');
    expect(lookup.lastSpaceId, 'space-1');
    expect(find.text(l10n.symbolLookupFromBase), findsOneWidget);
    expect(find.text('animals.Animal'), findsOneWidget);
    expect(find.text(l10n.symbolImplementations), findsOneWidget);
    expect(find.text('animals.Dog'), findsOneWidget);
    expect(find.textContaining(l10n.symbolCallersCount(3)), findsOneWidget);

    await tester.tap(find.text('animals.Animal'));
    await tester.pump();
    expect(jumpedPath, 'lib/animal.dart');
    expect(jumpedLine, 12);

    await tester.tap(find.text('animals.Dog'));
    await tester.pump();
    expect(openedPath, 'lib/dog.dart');
    expect(openedLine, 4);
  });

  testWidgets('shows an empty state when nothing is indexed', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          codeGraphLookupProvider.overrideWithValue(
            _FakeLookup(const CodeGraphLookupResult.empty()),
          ),
        ],
        child: testWrap(
          DiffSymbolPopover(
            name: 'Missing',
            workspaceId: 'ws',
            repoId: 'repo',
            prFilePaths: const {},
            onJumpToDiff: (_, _) {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.symbolLookupNone), findsOneWidget);
  });

  testWidgets('labels candidates recovered from the pull request diff', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          codeGraphLookupProvider.overrideWithValue(
            _FakeLookup(const CodeGraphLookupResult.empty()),
          ),
        ],
        child: testWrap(
          DiffSymbolPopover(
            name: 'fetchUser',
            workspaceId: 'ws',
            repoId: 'repo',
            prFilePaths: const {'src/user.ts'},
            initialResult: const CodeGraphLookupResult(
              fromBasePartition: false,
              fromDiff: true,
              definitions: [
                CodeGraphLookupCandidate(
                  id: 'diff:src/user.ts:1',
                  name: 'fetchUser',
                  qualifiedName: 'fetchUser',
                  kind: CodeSymbolKind.function,
                  filePath: 'src/user.ts',
                  startLine: 1,
                  endLine: 1,
                ),
              ],
            ),
            onJumpToDiff: (_, _) {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.symbolLookupInDiff), findsOneWidget);
    expect(find.text('fetchUser'), findsWidgets);
    expect(find.text(l10n.symbolLookupFromBase), findsNothing);
  });
}
