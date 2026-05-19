import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/material.dart';

/// Wraps a page with a consistent header (title + actions). Breadcrumbs are
/// rendered in the shell title bar — the active route resolves them via the
/// breadcrumb registry, so individual pages no longer publish crumb state.
class PageWrapper extends StatelessWidget {
  /// Creates a [PageWrapper].
  const PageWrapper({
    super.key,
    this.title,
    this.titleWidget,
    required this.child,
    this.subtitle,
    this.overline,
    this.actions,
    this.breadcrumbActions,
  });

  /// The main page title displayed in the header.
  final String? title;

  /// Optional widget rendered in the title slot instead of [title]. Lets a
  /// page put a richer, interactive title (e.g. an inline editor) in the fixed
  /// header row so it stays visible while the body scrolls. Takes precedence
  /// over [title]/[subtitle] when provided.
  final Widget? titleWidget;

  /// Optional subtitle shown below the title.
  final String? subtitle;

  /// Optional widget rendered above the title row (e.g. a status badge and
  /// metadata strip).
  final Widget? overline;

  /// Body content rendered below the header.
  final Widget child;

  /// Optional actions displayed in the right side of the title row.
  final List<Widget>? actions;

  /// Optional actions previously rendered next to the breadcrumb. They now
  /// sit at the top-right of the page header, since the breadcrumb itself
  /// has moved to the title bar.
  final List<Widget>? breadcrumbActions;

  /// The one gap between two page-header actions.
  ///
  /// The header used to splat [actions] straight into the `Row`, so whether
  /// two buttons touched depended on each page remembering to pass its own
  /// spacer — and the agent registry's Org chart / Teams / Add agent trio did
  /// not, so it rendered as one welded slab. Spacing here makes the gap a
  /// property of the header rather than of each caller's diligence; a caller
  /// that wants a TIGHTER cluster (an icon pair that reads as one control)
  /// groups those children in a `Row` of its own and passes that as one action.
  static List<Widget> _spaced(List<Widget> actions) {
    if (actions.length < 2) {
      return actions;
    }
    return [
      for (var i = 0; i < actions.length; i++) ...[
        if (i > 0) const SizedBox(width: AppSpacing.sm),
        actions[i],
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final hasTitle =
        titleWidget != null || (title != null && title!.isNotEmpty);
    final hasHeader = hasTitle || overline != null || breadcrumbActions != null;

    return Column(
      children: [
        if (hasHeader)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ?overline,
                if (hasTitle) ...[
                  if (overline != null) const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child:
                            titleWidget ??
                            PageHeaderText(title: title!, subtitle: subtitle),
                      ),
                      if (breadcrumbActions != null) ...[
                        const SizedBox(width: 16),
                        ..._spaced(breadcrumbActions!),
                        if (actions != null) const SizedBox(width: 8),
                      ],
                      if (actions != null) ..._spaced(actions!),
                    ],
                  ),
                ] else if (breadcrumbActions != null) ...[
                  Row(
                    children: [
                      const Spacer(),
                      ..._spaced(breadcrumbActions!),
                      if (actions != null) ...[
                        const SizedBox(width: 8),
                        ..._spaced(actions!),
                      ],
                    ],
                  ),
                ],
                SizedBox(height: hasTitle ? 24 : 16),
              ],
            ),
          ),
        Expanded(child: child),
      ],
    );
  }
}

/// The standard page-header text block: the title in `headlineMedium`/w700
/// with an optional `bodyMedium` tertiary subtitle 8px below. Shared by
/// [PageWrapper] and full-bleed page heroes (e.g. the inbox hero) so every
/// page header carries the same typography.
class PageHeaderText extends StatelessWidget {
  /// Creates a [PageHeaderText].
  const PageHeaderText({super.key, required this.title, this.subtitle});

  /// The page title.
  final String title;

  /// Optional subtitle shown 8px below the title.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: tokens.textPrimary,
            height: 1.25,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: tokens.textTertiary,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}
