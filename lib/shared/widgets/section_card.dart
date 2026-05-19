import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Non-interactive container used for grouped content — the design-system
/// "section" card.
///
/// Mirrors the visual treatment of the dashboard's CPU usage card:
/// `bg-primary` background, `border-secondary` outline, no hover state.
/// A small uppercase label header sits above the content.
///
/// For interactive (clickable) cards that should react to hover, use
/// `AppCard` instead.
class SectionCard extends StatelessWidget {
  /// Creates a new [SectionCard].
  const SectionCard({
    super.key,
    this.label,
    this.title,
    this.subtitle,
    this.trailing,
    this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 16),
    this.headerPadding,
    this.expands = false,
  });

  /// Small uppercase label rendered at the top of the card (e.g. "CPU USAGE",
  /// "READER PREFERENCES"). When provided it is rendered with the dashboard
  /// stat-card treatment: caps + letter-spacing + muted color.
  final String? label;

  /// Optional rich title rendered below [label] (or in place of it). Use this
  /// when you want a normal-cased heading like "Active Processes".
  final Widget? title;

  /// Optional secondary text under [title] / [label].
  final Widget? subtitle;

  /// Optional widget aligned to the right of the header row — typically an
  /// icon or action button.
  final Widget? trailing;

  /// Card body.
  final Widget? child;

  /// Padding around the whole content. Defaults to the dashboard card insets.
  final EdgeInsetsGeometry padding;

  /// Override for the header (label/title/subtitle) padding. When null the
  /// header is laid out inside [padding] with a 12 px gap before [child].
  final EdgeInsetsGeometry? headerPadding;

  /// When true the card fills all available cross-axis space and the [child]
  /// stretches to fill the remaining body area. Useful inside [Expanded] or
  /// [CrossAxisAlignment.stretch] parents.
  final bool expands;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final theme = FTheme.of(context);
    final bg = tokens?.bgPrimary ?? theme.colors.card;
    final border = tokens?.borderSecondary ?? theme.colors.border;

    final hasHeader =
        label != null || title != null || subtitle != null || trailing != null;

    return Container(
      decoration: ShapeDecoration(
        color: bg,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: border, width: theme.style.borderWidth),
          borderRadius: theme.style.borderRadius.lg,
        ),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: expands ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (hasHeader) ...[
              _Header(
                label: label,
                title: title,
                subtitle: subtitle,
                trailing: trailing,
                padding: headerPadding,
              ),
              if (child != null) const SizedBox(height: 12),
            ],
            if (child != null)
              expands ? Expanded(child: child!) : child!,
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.label,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.padding,
  });

  final String? label;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final theme = FTheme.of(context);
    final muted = tokens?.textTertiary ?? theme.colors.mutedForeground;
    final primaryText = tokens?.textPrimary ?? theme.colors.foreground;

    final mainChildren = <Widget>[];

    if (label != null) {
      mainChildren.add(
        Text(
          label!.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: muted,
          ),
        ),
      );
    }

    if (title != null) {
      if (mainChildren.isNotEmpty) {
        mainChildren.add(const SizedBox(height: 6));
      }
      mainChildren.add(
        DefaultTextStyle.merge(
          style: TextStyle(
            fontSize: 16,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: primaryText,
          ),
          child: title!,
        ),
      );
    }

    if (subtitle != null) {
      mainChildren.add(const SizedBox(height: 6));
      mainChildren.add(
        DefaultTextStyle.merge(
          style: TextStyle(fontSize: 13, height: 1.5, color: muted),
          child: subtitle!,
        ),
      );
    }

    final headerBody = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: mainChildren,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );

    return padding == null
        ? headerBody
        : Padding(padding: padding!, child: headerBody);
  }
}

