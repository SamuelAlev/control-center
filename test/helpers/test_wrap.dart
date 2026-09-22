import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_locales.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider overrides shared by both wrappers.
//
// Deliberately does NOT seed activeWorkspaceIdProvider. These wrappers create
// their own ProviderScope, so an override here would shadow one supplied by an
// enclosing scope — and many tests wrap `testWrap(...)` in a ProviderScope that
// pins a specific workspace id (or a null one, to exercise the pre-context
// surfaces). Tests needing a seeded workspace add `activeWorkspaceIdOverride()`
// from `active_workspace.dart` to their own outer scope instead.
//
// Overrides prReviewRepositoryProvider to EmptyPrReviewRepository and
// activeWorkspace / activeRepo to null so drift database streams (which leave pending timers on
// dispose) are never created. Meeting action items / decisions default to empty
// streams so meeting widgets never open the real drift database.
final _testOverrides = [
  activeWorkspaceProvider.overrideWith((ref) => null),
  activeRepoProvider.overrideWith((ref) => null),
  prReviewRepositoryProvider.overrideWith(
    (ref) => const EmptyPrReviewRepository(),
  ),
  workspacesProvider.overrideWith(
    (ref) => const Stream<List<Workspace>>.empty(),
  ),
  meetingActionItemsProvider.overrideWith((ref, _) => const Stream.empty()),
  meetingDecisionsProvider.overrideWith((ref, _) => const Stream.empty()),
  meetingActionItemStatsProvider.overrideWith((ref, _) => const Stream.empty()),
  meetingDecisionCountsProvider.overrideWith((ref, _) => const Stream.empty()),
];

/// ProviderScope + MaterialApp (l10n) + CcTheme for widget tests.
///
/// [CcToastScope] inside `home` (rebuild-safe). Dialog toasts need
/// [testWrapWithToastOverlay]. [locale] / [textDirection] / [isDemo] optional.
Widget testWrap(
  Widget child, {
  Locale locale = const Locale('en'),
  TextDirection? textDirection,
  bool isDemo = false,
}) {
  Widget home = CcTheme(
    data: CcThemeData.light(),
    child: CcToastScope(child: Scaffold(body: child)),
  );
  if (textDirection != null) {
    home = Directionality(textDirection: textDirection, child: home);
  }
  return ProviderScope(
    overrides: [
      isDemoServerProvider.overrideWith((ref) => isDemo),
      ..._testOverrides,
    ],
    child: MaterialApp(
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate, // ignore: deprecated_member_use
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate, // ignore: deprecated_member_use
      ],
      supportedLocales: kSupportedAppLocales,
      locale: locale,
      home: home,
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
///
/// [locale] / [textDirection] behave as on [testWrap]; the direction override
/// wraps the whole `builder` result so dialogs mounted into the root navigator
/// overlay inherit it too.
Widget testWrapWithToastOverlay(
  Widget child, {
  Locale locale = const Locale('en'),
  TextDirection? textDirection,
  bool isDemo = false,
}) {
  return ProviderScope(
    overrides: [
      isDemoServerProvider.overrideWith((ref) => isDemo),
      ..._testOverrides,
    ],
    child: MaterialApp(
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate, // ignore: deprecated_member_use
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate, // ignore: deprecated_member_use
      ],
      supportedLocales: kSupportedAppLocales,
      locale: locale,
      builder: (context, navigator) {
        Widget wrapped = CcTheme(
          data: CcThemeData.light(),
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) =>
                    CcToastScope(child: navigator ?? const SizedBox.shrink()),
              ),
            ],
          ),
        );
        if (textDirection != null) {
          wrapped = Directionality(
            textDirection: textDirection,
            child: wrapped,
          );
        }
        return wrapped;
      },
      home: Scaffold(body: child),
    ),
  );
}
