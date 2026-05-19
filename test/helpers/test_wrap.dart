import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider overrides shared by both wrappers. Declared as a getter returning an
// inline literal (rather than a `List<Override>`-typed helper) because the
// `Override` type name isn't directly importable here; the literal's element
// type is inferred from the `ProviderScope.overrides` parameter at each use.
//
// Overrides githubAuthTokenProvider to empty so the GitHub CLI probe (which
// spawns a process and leaves pending timers) is never triggered. Overrides
// prReviewRepositoryProvider to EmptyPrReviewRepository and activeWorkspace /
// activeRepo to null so drift database streams (which leave pending timers on
// dispose) are never created. Meeting action items / decisions default to empty
// streams so meeting widgets never open the real drift database.
final _testOverrides = [
  githubAuthTokenProvider.overrideWith((ref) => ''),
  activeWorkspaceProvider.overrideWith((ref) => null),
  activeRepoProvider.overrideWith((ref) => null),
  prReviewRepositoryProvider
      .overrideWith((ref) => const EmptyPrReviewRepository()),
  workspacesProvider.overrideWith(
    (ref) => const Stream<List<Workspace>>.empty(),
  ),
  meetingActionItemsProvider.overrideWith((ref, _) => const Stream.empty()),
  meetingDecisionsProvider.overrideWith((ref, _) => const Stream.empty()),
  meetingActionItemStatsProvider.overrideWith((ref, _) => const Stream.empty()),
  meetingDecisionCountsProvider.overrideWith((ref, _) => const Stream.empty()),
];

/// Wraps a widget with ProviderScope, MaterialApp (including l10n delegates),
/// and CcTheme for use in widget tests.
///
/// [CcToastScope] sits inside `home`, below the navigator's own overlay, so a
/// CcToast raised from the widget-under-test (screen context) resolves a host.
/// This placement is rebuild-safe — unlike wrapping the navigator in an Overlay
/// via `builder`, which strands re-pumped widget trees because
/// `Overlay.initialEntries` is only consumed once. Tests whose toast is raised
/// from a *dialog* context (which mounts into the root navigator overlay, a
/// sibling of `home`) must use [testWrapWithToastOverlay] instead.
Widget testWrap(Widget child) {
  return ProviderScope(
    overrides: _testOverrides,
    child: MaterialApp(
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: CcTheme(
        data: CcThemeData.light(),
        child: CcToastScope(
          child: Scaffold(body: child),
        ),
      ),
    ),
  );
}

/// Like [testWrap], but mounts the [CcToastScope] *above* the navigator's
/// overlay (mirroring the production wiring in `lib/main.dart`) so a CcToast
/// raised from a dialog — shown via `showCcDialog` into the root navigator
/// overlay — resolves a host.
///
/// Use this only for dialog/flyout tests that surface a toast. It is NOT
/// rebuild-safe across `pumpWidget` re-pumps (the toast Overlay strands the
/// previous tree), so never use it for tests that re-pump to exercise
/// `didUpdateWidget`; use [testWrap] there.
Widget testWrapWithToastOverlay(Widget child) {
  return ProviderScope(
    overrides: _testOverrides,
    child: MaterialApp(
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      builder: (context, navigator) => CcTheme(
        data: CcThemeData.light(),
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) =>
                  CcToastScope(child: navigator ?? const SizedBox.shrink()),
            ),
          ],
        ),
      ),
      home: Scaffold(body: child),
    ),
  );
}
