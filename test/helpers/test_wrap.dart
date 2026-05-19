import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:control_center/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

/// Wraps a widget with ProviderScope, MaterialApp (including l10n delegates),
/// and FTheme for use in widget tests.
///
/// Overrides [githubAuthTokenProvider] to empty so the GitHub CLI probe
/// (which spawns a process and leaves pending timers) is never triggered.
/// Overrides [prReviewRepositoryProvider] to [EmptyPrReviewRepository] and
/// [activeWorkspaceProvider] / [activeRepoProvider] to null so drift database
/// streams (which leave pending timers on dispose) are never created.
Widget testWrap(Widget child) {
  return ProviderScope(
    overrides: [
      githubAuthTokenProvider.overrideWith((ref) => ''),
      activeWorkspaceProvider.overrideWith((ref) => null),
      activeRepoProvider.overrideWith((ref) => null),
      prReviewRepositoryProvider
          .overrideWith((ref) => const EmptyPrReviewRepository()),
      workspacesProvider.overrideWith(
        (ref) => const Stream<List<Workspace>>.empty(),
      ),
      // Meeting action items / decisions are DB-backed; default them to empty
      // streams so meeting widgets never open the real drift database (which
      // would leave pending timers). Tests that need data override per case.
      meetingActionItemsProvider.overrideWith((ref, _) => const Stream.empty()),
      meetingDecisionsProvider.overrideWith((ref, _) => const Stream.empty()),
      meetingActionItemStatsProvider
          .overrideWith((ref, _) => const Stream.empty()),
      meetingDecisionCountsProvider
          .overrideWith((ref, _) => const Stream.empty()),
    ],
    child: MaterialApp(
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: FTheme(
        data: FThemes.zinc.light.desktop,
        child: Scaffold(body: child),
      ),
    ),
  );
}
