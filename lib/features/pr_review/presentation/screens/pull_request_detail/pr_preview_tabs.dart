import 'package:cc_domain/features/pr_review/domain/entities/deployment_preview.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_tab_kinds.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/editor_tab.dart';

/// The PR page's preview tabs: one per detected deploy site, plus the
/// environment's primary endpoint.
///
/// Remembers which it has injected this session, so a re-detection refreshes
/// an *open* tab in place but never re-adds one the reviewer closed.
class PrPreviewTabs {
  final Set<String> _injected = {};

  /// Stable dedup key for a preview's tab, per site or per URL without one.
  static String dedupKey(DeploymentPreview preview) =>
      'pr.preview:${preview.siteName.isNotEmpty ? preview.siteName : preview.url}';

  /// Adds a tab just after Diff, without stealing focus, the first time a
  /// preview is seen; refreshes an open one whose URL moved; never re-adds a
  /// closed one. [label] replaces the detected name, for a preview that isn't
  /// a deploy site.
  void reconcile(
    EditorLayoutController layout,
    AppLocalizations l10n,
    List<DeploymentPreview> previews, {
    String? label,
  }) {
    if (previews.isEmpty) {
      return;
    }
    final openKeys = {
      for (final tab in layout.allTabs())
        if (tab.kind == PrTabKinds.preview) tab.dedupKey,
    };
    for (final preview in previews) {
      final key = dedupKey(preview);
      final firstTime = _injected.add(key);
      if (!firstTime && !openKeys.contains(key)) {
        continue;
      }
      layout.ensureBackgroundTab(
        EditorTab(
          kind: PrTabKinds.preview,
          label:
              label ??
              (preview.siteName.isNotEmpty
                  ? l10n.previewDeploymentTab(preview.siteName)
                  : l10n.previewDeployment),
          icon: PrTabKinds.iconFor(PrTabKinds.preview),
          args: {
            'url': preview.url,
            if (preview.siteName.isNotEmpty) 'site': preview.siteName,
          },
          dedupKey: key,
        ),
        afterKind: PrTabKinds.diff,
      );
    }
  }
}
