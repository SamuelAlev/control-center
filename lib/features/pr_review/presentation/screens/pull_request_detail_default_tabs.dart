part of 'pull_request_detail_screen.dart';

/// The default PR tabs, in display order.
const List<String> _kinds = [
  PrTabKinds.overview,
  PrTabKinds.diff,
  PrTabKinds.sourceControl,
  PrTabKinds.chat,
  PrTabKinds.actions,
];

EditorLayoutController _seedLayout() {
  final group = EditorTabGroupController();
  for (final kind in _kinds) {
    group.openTab(
      EditorTab(
        kind: kind,
        label: _fallbackLabel(kind),
        icon: PrTabKinds.iconFor(kind),
        dedupKey: kind,
      ),
    );
  }
  group.selectedIndex = 0;
  return EditorLayoutController.single(controller: group);
}

/// English fallback label; the localized label is resolved per-build by the
/// chrome's [EditorChrome.labelFor].
String _fallbackLabel(String kind) => switch (kind) {
  PrTabKinds.overview => 'Overview',
  PrTabKinds.diff => 'Diff',
  PrTabKinds.sourceControl => 'Source control',
  PrTabKinds.chat => 'Chat',
  PrTabKinds.actions => 'Actions',
  _ => 'Review',
};

String _label(String kind, AppLocalizations l10n) => switch (kind) {
  PrTabKinds.overview => l10n.overview,
  PrTabKinds.diff => l10n.diff,
  PrTabKinds.sourceControl => l10n.sourceControl,
  PrTabKinds.chat => l10n.chat,
  PrTabKinds.actions => l10n.actions,
  _ => l10n.review,
};

/// The loading state: the real workbench chrome with the default tab set, each
/// body a tab-shaped skeleton. Rendering the true tab strip (not a faux one)
/// means nothing reflows when the PR arrives — the chrome stays put and only
/// the tab bodies swap from placeholder to content.
class _PrDetailLoadingBody extends StatefulWidget {
  const _PrDetailLoadingBody();

  @override
  State<_PrDetailLoadingBody> createState() => _PrDetailLoadingBodyState();
}

class _PrDetailLoadingBodyState extends State<_PrDetailLoadingBody> {
  late final EditorLayoutController _layout;

  @override
  void initState() {
    super.initState();
    _layout = _seedLayout();
  }

  @override
  void dispose() {
    _layout.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EditorWorkspace(
      layout: _layout,
      chrome: EditorChrome(
        iconFor: PrTabKinds.iconForTab,
        labelFor: (tab) => _label(tab.kind, l10n),
      ),
      buildBody: (tab, {required isVisible}) => switch (tab.kind) {
        PrTabKinds.overview => const PrOverviewSkeleton(),
        PrTabKinds.diff => const PrDiffTabSkeleton(),
        _ => const PrPanelSkeleton(),
      },
    );
  }
}
