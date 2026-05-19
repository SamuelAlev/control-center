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

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final hasTitle =
        titleWidget != null || (title != null && title!.isNotEmpty);
    final hasHeader =
        hasTitle || overline != null || breadcrumbActions != null;

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
                        child: titleWidget ??
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title!,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: tokens.textPrimary,
                                    height: 1.25,
                                  ),
                                ),
                                if (subtitle != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    subtitle!,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
                                      color: tokens.textTertiary,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                      ),
                      if (breadcrumbActions != null) ...[
                        const SizedBox(width: 16),
                        ...breadcrumbActions!,
                        if (actions != null) const SizedBox(width: 8),
                      ],
                      ...?actions,
                    ],
                  ),
                ] else if (breadcrumbActions != null) ...[
                  Row(
                    children: [
                      const Spacer(),
                      ...breadcrumbActions!,
                      if (actions != null) ...[
                        const SizedBox(width: 8),
                        ...actions!,
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
