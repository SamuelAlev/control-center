import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/constants/keybindings.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/kbd.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Shows the keyboard cheat-sheet overlay (PRD 19 §2 — press `?`).
///
/// Reads the SAME [KeybindingRegistry] the dispatcher runs, so it can never
/// drift from what actually fires. It shows the global shortcuts plus the ones
/// scoped to the current screen (derived from the logical route), and on web
/// dims combinations the browser reserves.
void showKeyboardCheatSheet(BuildContext context) {
  final rootContext = rootNavigatorKey.currentContext ?? context;
  // The logical route (workspace prefix stripped) is what screen-scoped
  // bindings are keyed on — mirror the shell's dispatcher feed. The sheet is
  // opened by a *global* shortcut whose context is the root navigator, which
  // sits ABOVE every RouteBase.builder subtree — `GoRouterState.of` throws a
  // GoError there. `GoRouter.maybeOf` works from anywhere under the router, so
  // read the current location off the router itself; with no router (or an
  // unresolved configuration) fall back to '' — the sheet then simply shows
  // the global shortcuts only.
  final router = GoRouter.maybeOf(rootContext);
  final config = router?.routerDelegate.currentConfiguration;
  final location = config == null || config.isEmpty ? '' : config.uri.path;
  final logicalRoute = workspaceShellLogicalRoute(location);

  showCcDialog<void>(
    context: rootContext,
    builder: (_) => _KeyboardCheatSheet(logicalRoute: logicalRoute),
  );
}

class _KeyboardCheatSheet extends StatelessWidget {
  const _KeyboardCheatSheet({required this.logicalRoute});

  final String logicalRoute;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final platform = defaultTargetPlatform;

    final global = KeybindingRegistry.global;
    // Screen bindings: any non-global scope that is a prefix of this route.
    final screen = [
      for (final b in KeybindingRegistry.all)
        if (b.scope != KeybindingRegistry.globalScope &&
            logicalRoute.startsWith(b.scope))
          b,
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 520, maxWidth: 640),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ds.panel,
          borderRadius: AppRadii.brLg,
          border: Border.all(color: ds.borderPrimary),
          boxShadow: AppShadows.golden,
        ),
        child: SizedBox(
          height: 560,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                child: Row(
                  children: [
                    Icon(AppIcons.keyboard, size: 18, color: ds.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.cheatSheetTitle,
                        style: CcTypography.title.copyWith(
                          color: ds.textPrimary,
                        ),
                      ),
                    ),
                    Kbd.symbol(
                      label: 'esc',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const CcDivider(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _Section(
                      title: l10n.cheatSheetGlobal,
                      bindings: global,
                      platform: platform,
                    ),
                    if (screen.isNotEmpty)
                      _Section(
                        title: l10n.cheatSheetThisScreen,
                        bindings: screen,
                        platform: platform,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.bindings,
    required this.platform,
  });

  final String title;
  final List<Keybinding> bindings;
  final TargetPlatform platform;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
          child: Text(
            title.toUpperCase(),
            style: CcTypography.caption.copyWith(
              color: ds.textTertiary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
        ),
        for (final b in bindings)
          _Row(binding: b, platform: platform, l10n: l10n),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.binding,
    required this.platform,
    required this.l10n,
  });

  final Keybinding binding;
  final TargetPlatform platform;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    // On web, a browser-reserved combination can never reach the page — say so
    // instead of implying it works (reserved-key honesty, PRD 19 §2).
    final reserved = kIsWeb && binding.isReservedInBrowser;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              binding.resolvedLabel(l10n),
              style: CcTypography.body.copyWith(
                color: reserved ? ds.textTertiary : ds.textPrimary,
              ),
            ),
          ),
          if (reserved) ...[
            Text(
              l10n.cheatSheetReservedInBrowser,
              style: CcTypography.caption.copyWith(color: ds.textTertiary),
            ),
            const SizedBox(width: 8),
          ],
          Opacity(
            opacity: reserved ? 0.5 : 1,
            child: Kbd.symbol(label: binding.displayLabel(platform)),
          ),
        ],
      ),
    );
  }
}
