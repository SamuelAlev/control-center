import 'dart:async';

import 'package:control_center/features/pr_review/presentation/widgets/references/commit_reference_chip.dart';
import 'package:control_center/features/pr_review/presentation/widgets/references/pr_reference_chip.dart';
import 'package:control_center/features/pr_review/providers/commit_reference_preview_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_reference_preview_provider.dart';
import 'package:control_center/shared/utils/github_reference_parser.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_wrap.dart';

const _longTitle =
    'Move the review workbench onto the shared composer and drop the old '
    'inline comment editor along with every caller that still reaches it';
const _longRepo = 'a-repository-name-long-enough-to-fill-the-line-by-itself';
const _sha = '0123456789abcdef0123456789abcdef01234567';

/// The chip's real host: an inline placeholder in a narrow markdown line.
Widget _line(Widget chip, {required double width}) {
  return Align(
    alignment: AlignmentDirectional.topStart,
    child: SizedBox(
      width: width,
      child: Text.rich(TextSpan(children: [WidgetSpan(child: chip)])),
    ),
  );
}

Future<void> _pumpPr(
  WidgetTester tester, {
  required String title,
  required String repo,
  required double width,
  bool loading = false,
}) async {
  final key = PrReferenceKey(owner: 'owner', repo: repo, number: 1234);
  await tester.pumpWidget(
    testWrap(
      ProviderScope(
        overrides: [
          prReferencePreviewProvider(key).overrideWith(
            (ref) => loading
                ? Completer<PrPreview?>().future
                : Future.value(
                    PrPreview(
                      title: title,
                      state: 'open',
                      isDraft: false,
                      isMerged: false,
                      htmlUrl: '',
                    ),
                  ),
          ),
        ],
        child: _line(
          PrReferenceChip(
            reference: GitHubPrReference(
              owner: 'owner',
              repo: repo,
              number: 1234,
            ),
            currentOwner: 'owner',
            currentRepo: 'repo',
          ),
          width: width,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('reference chips in a line narrower than their title cap', () {
    testWidgets('a PR chip ellipsizes its title', (tester) async {
      await _pumpPr(tester, title: _longTitle, repo: 'repo', width: 220);

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(PrReferenceChip)).width, lessThan(221));
      expect(find.text('#1234'), findsOneWidget);
    });

    testWidgets('a PR title with inline code ellipsizes too', (tester) async {
      await _pumpPr(
        tester,
        title: 'Rename `SpaceSidebarGroup` then `$_longTitle`',
        repo: 'repo',
        width: 220,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('a long cross-repo suffix fits beside the title', (
      tester,
    ) async {
      await _pumpPr(tester, title: _longTitle, repo: _longRepo, width: 220);

      expect(tester.takeException(), isNull);
    });

    testWidgets('a loading chip fits a long cross-repo suffix', (tester) async {
      await _pumpPr(
        tester,
        title: _longTitle,
        repo: _longRepo,
        width: 220,
        loading: true,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('a commit chip ellipsizes its title', (tester) async {
      const key = CommitReferenceKey(owner: 'owner', repo: 'repo', sha: _sha);
      await tester.pumpWidget(
        testWrap(
          ProviderScope(
            overrides: [
              commitReferencePreviewProvider(key).overrideWith(
                (ref) async =>
                    const CommitPreview(title: _longTitle, shortSha: '0123456'),
              ),
            ],
            child: _line(
              const CommitReferenceChip(
                reference: GitHubCommitReference(
                  owner: 'owner',
                  repo: 'repo',
                  sha: _sha,
                ),
              ),
              width: 220,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('0123456'), findsOneWidget);
    });
  });
}
