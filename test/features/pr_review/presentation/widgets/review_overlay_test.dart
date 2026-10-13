import 'dart:async';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/pending_review_comment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/text_draft_provider.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/widgets/review_overlay.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _prNumber = 7;

final _repo = Repo(
  id: 'r1',
  name: 'control-center',
  path: '/tmp/cc',
  remoteOwner: 'acme',
  remoteName: 'control-center',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

final _pr = PullRequest(
  id: _prNumber,
  number: _prNumber,
  title: 'A change',
  body: '',
  state: PrState.open,
  isDraft: false,
  author: null,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  repoFullName: 'acme/control-center',
  htmlUrl: 'https://github.com/acme/control-center/pull/$_prNumber',
  headSha: 'deadbeef',
);

/// The PR identity ReviewOverlayButton's keyed providers use.
const _prRef = (
  workspaceId: 'ws',
  repoFullName: 'acme/control-center',
  number: _prNumber,
);

class _ReviewRepository extends EmptyPrReviewRepository {
  String? saved;
  String? submittedBody;
  Future<void> Function()? submitAction;

  @override
  Future<String?> getDraft(int prNumber) async => saved;

  @override
  Future<void> upsertDraft(int prNumber, String text) async {
    saved = text;
  }

  @override
  Future<void> clearDraft(int prNumber) async {
    saved = null;
  }

  @override
  Future<void> submitReview({
    required int prNumber,
    required String event,
    String? body,
    List<PendingReviewComment> comments = const [],
  }) async {
    submittedBody = body;
    await submitAction?.call();
  }
}

const _reviewDraftKey = (
  workspaceId: 'ws',
  surface: 'pr-review-body',
  destination: ('acme/control-center', _prNumber),
);

Widget _wrap() {
  return ProviderScope(
    overrides: [
      codeFontFamilyProvider.overrideWithValue('Fira Code'),
      prRepoRowProvider(_prRef).overrideWith((ref) => _repo),
      prRepositoryProvider(
        _prRef,
      ).overrideWith((ref) => const EmptyPrReviewRepository()),
      prReviewRepositoryProvider.overrideWith(
        (ref) => const EmptyPrReviewRepository(),
      ),
      prDetailProvider(_prRef).overrideWith((ref) => Stream.value(_pr)),
      prReviewsProvider(
        _prRef,
      ).overrideWith((ref) => Stream.value(const <PrReviewSubmission>[])),
      currentUserLoginProvider.overrideWithValue('operator'),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: CcTheme(
        data: CcThemeData.light(),
        child: Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ReviewOverlayButton(
                pr: _pr,
                prRef: _prRef,
                owner: 'acme',
                repo: 'control-center',
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openAndAssertVerdictRowFits(
  WidgetTester tester,
  double width,
) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_wrap());
  await tester.pump();

  await tester.tap(find.text('Review'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));

  expect(find.text('Finish your review'), findsOneWidget);
  expect(find.text('Approve'), findsOneWidget);
  expect(find.text('Request changes'), findsOneWidget);
  expect(find.text('Comment'), findsOneWidget);
  // All three verdicts sit on ONE row, which must lay out without overflow at
  // the overlay's width, in English and (with longer labels) translated
  // locales.
  expect(tester.takeException(), isNull);
}

void main() {
  group('ReviewOverlayButton', () {
    testWidgets('the verdict row fits on a wide window', (tester) async {
      await _openAndAssertVerdictRowFits(tester, 1400);
    });

    testWidgets('the verdict row fits on a narrow window', (tester) async {
      await _openAndAssertVerdictRowFits(tester, 800);
    });
  });

  group('Review body session draft', () {
    testWidgets(
      'closing and remounting retain the body without server overwrite',
      (tester) async {
        final repository = _ReviewRepository()..saved = 'older server text';
        final visible = ValueNotifier(true);
        addTearDown(visible.dispose);
        final container = ProviderContainer(
          overrides: [
            codeFontFamilyProvider.overrideWithValue('Fira Code'),
            prRepoRowProvider(_prRef).overrideWith((ref) => _repo),
            prRepositoryProvider(_prRef).overrideWith((ref) => repository),
            prReviewRepositoryProvider.overrideWith((ref) => repository),
            prDetailProvider(_prRef).overrideWith((ref) => Stream.value(_pr)),
            prReviewsProvider(
              _prRef,
            ).overrideWith((ref) => Stream.value(const <PrReviewSubmission>[])),
            currentUserLoginProvider.overrideWithValue('operator'),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: CcTheme(
                data: CcThemeData.light(),
                child: CcToastScope(
                  child: Scaffold(
                    body: ValueListenableBuilder<bool>(
                      valueListenable: visible,
                      builder: (_, shown, _) => shown
                          ? ReviewOverlayButton(
                              pr: _pr,
                              prRef: _prRef,
                              owner: 'acme',
                              repo: 'control-center',
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Review'));
        await tester.pump();
        final draft = container.read(
          textDraftControllerProvider(_reviewDraftKey),
        );
        await tester.pump();
        expect(draft.text, 'older server text');
        draft.text = 'session review with ![asset](url)';
        await tester.tap(find.text('Review'));
        await tester.pump();
        await tester.tap(find.text('Review'));
        await tester.pump();
        expect(draft.text, 'session review with ![asset](url)');
        visible.value = false;
        await tester.pump();
        visible.value = true;
        await tester.pump();
        await tester.tap(find.text('Review'));
        await tester.pump();
        expect(draft.text, 'session review with ![asset](url)');
      },
    );

    testWidgets(
      'failed verdict retains draft; success clears only submitted text',
      (tester) async {
        final repository = _ReviewRepository();
        final pending = Completer<void>();
        repository.submitAction = () => pending.future;
        final container = ProviderContainer(
          overrides: [
            codeFontFamilyProvider.overrideWithValue('Fira Code'),
            prRepoRowProvider(_prRef).overrideWith((ref) => _repo),
            prRepositoryProvider(_prRef).overrideWith((ref) => repository),
            prReviewRepositoryProvider.overrideWith((ref) => repository),
            prDetailProvider(_prRef).overrideWith((ref) => Stream.value(_pr)),
            prReviewsProvider(
              _prRef,
            ).overrideWith((ref) => Stream.value(const <PrReviewSubmission>[])),
            currentUserLoginProvider.overrideWithValue('operator'),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: CcTheme(
                data: CcThemeData.light(),
                child: CcToastScope(
                  child: Scaffold(
                    body: ReviewOverlayButton(
                      pr: _pr,
                      prRef: _prRef,
                      owner: 'acme',
                      repo: 'control-center',
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        final draft = container.read(
          textDraftControllerProvider(_reviewDraftKey),
        );
        await tester.tap(find.text('Review'));
        await tester.pump();
        draft.text = 'first verdict';
        await tester.tap(find.text('Comment'));
        await tester.pump();
        draft.text = 'newer edit';
        pending.complete();
        await tester.pump();
        expect(repository.submittedBody, 'first verdict');
        expect(draft.text, 'newer edit');
        await tester.tap(find.text('Review'));
        await tester.pump();
        repository.submitAction = () async => throw StateError('offline');
        await tester.tap(find.text('Comment'));
        await tester.pump();
        expect(draft.text, 'newer edit');
        await tester.tap(find.text('Review'));
        await tester.pump();
        repository.submitAction = null;
        await tester.tap(find.text('Comment'));
        await tester.pump();
        expect(draft.text, isEmpty);
      },
    );
  });
}
