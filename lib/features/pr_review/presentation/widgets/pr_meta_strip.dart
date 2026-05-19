import 'dart:async';

import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/utils/relative_time.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/providers/github_user_profile_provider.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// A compact metadata strip rendered above the PR description: the author
/// (avatar + display name + `@login`) on one side and the head → base branch
/// refs on the other, each branch click-to-copy.
class PrMetaStrip extends ConsumerWidget {
  /// Creates a [PrMetaStrip].
  const PrMetaStrip({super.key, required this.pr});

  /// The pull request whose author and branches are shown.
  final PullRequest pr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final codeFont = ref.watch(codeFontFamilyProvider);

    final children = <Widget>[];

    final author = pr.author;
    if (author != null && author.login.isNotEmpty) {
      children.add(_AuthorBadge(author: author, tokens: tokens));
    }

    if (pr.createdAt != null || pr.updatedAt != null) {
      children.add(
        _Timestamps(
          createdAt: pr.createdAt,
          updatedAt: pr.updatedAt,
          tokens: tokens,
        ),
      );
    }

    if (pr.headRef.isNotEmpty || pr.baseRef.isNotEmpty) {
      children.add(
        _BranchPair(
          headRef: pr.headRef,
          baseRef: pr.baseRef,
          tokens: tokens,
          codeFont: codeFont,
        ),
      );
    }

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ),
    );
  }
}

/// Avatar + display name + `@login` for the PR author. The display name is
/// resolved lazily from the user's profile; until it loads (or when GitHub
/// has none) only the `@login` shows.
class _AuthorBadge extends ConsumerWidget {
  const _AuthorBadge({required this.author, required this.tokens});

  final PrUser author;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final displayName = ref
        .watch(githubUserProfileProvider(author.login))
        .maybeWhen(
          data: (p) => (p?.name.isNotEmpty ?? false) ? p!.name : null,
          orElse: () => null,
        );

    final children = <Widget>[
      GitHubUserAvatar(
        login: author.login,
        avatarUrl: author.avatarUrl,
        size: 22,
      ),
      const SizedBox(width: AppSpacing.sm),
    ];

    if (displayName != null) {
      children.addAll([
        Text(
          displayName,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: tokens.textPrimary,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '@${author.login}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: tokens.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ]);
    } else {
      children.add(
        Text(
          '@${author.login}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: tokens.textPrimary,
          ),
        ),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}

/// "Opened {rel} · Updated {rel}" — relative times for creation and last
/// activity, each tooltipped with its absolute, locale-formatted date. The
/// "Updated" segment is dropped when it would duplicate the "Opened" time
/// (i.e. there's been no activity since the PR was created).
class _Timestamps extends StatelessWidget {
  const _Timestamps({
    required this.createdAt,
    required this.updatedAt,
    required this.tokens,
  });

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();

    final segments = <Widget>[];
    if (createdAt != null) {
      segments.add(
        _TimestampSegment(
          label: l10n.openedAgo(formatRelative(createdAt)),
          absolute: _absolute(createdAt!, locale),
          tokens: tokens,
        ),
      );
    }
    if (updatedAt != null && updatedAt != createdAt) {
      if (segments.isNotEmpty) {
        segments.add(_Separator(tokens: tokens));
      }
      segments.add(
        _TimestampSegment(
          label: l10n.updatedAgo(formatRelative(updatedAt)),
          absolute: _absolute(updatedAt!, locale),
          tokens: tokens,
        ),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: segments);
  }

  String _absolute(DateTime dt, String locale) =>
      DateFormat.yMMMMd(locale).add_jm().format(dt.toLocal());
}

/// A single relative-time label whose tooltip reveals the absolute date.
class _TimestampSegment extends StatelessWidget {
  const _TimestampSegment({
    required this.label,
    required this.absolute,
    required this.tokens,
  });

  final String label;
  final String absolute;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: absolute,
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: tokens.textTertiary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// A muted "·" dot separating timestamp segments.
class _Separator extends StatelessWidget {
  const _Separator({required this.tokens});

  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Text(
        '·',
        style: TextStyle(color: tokens.fgQuaternary, fontSize: 12),
      ),
    );
  }
}

/// The head and base branch refs with a direction arrow (head merges into
/// base). Either ref may be absent when the PR wasn't fully enriched.
class _BranchPair extends StatelessWidget {
  const _BranchPair({
    required this.headRef,
    required this.baseRef,
    required this.tokens,
    required this.codeFont,
  });

  final String headRef;
  final String baseRef;
  final DesignSystemTokens tokens;
  final String codeFont;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasBoth = headRef.isNotEmpty && baseRef.isNotEmpty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (headRef.isNotEmpty)
          _CopyableBranchChip(
            branch: headRef,
            tokens: tokens,
            codeFont: codeFont,
            tooltip: l10n.copyHeadBranchTooltip,
          ),
        if (hasBoth) ...[
          const SizedBox(width: AppSpacing.xs),
          Icon(AppIcons.arrowRight, size: 14, color: tokens.fgQuaternary),
          const SizedBox(width: AppSpacing.xs),
        ],
        if (baseRef.isNotEmpty)
          _CopyableBranchChip(
            branch: baseRef,
            tokens: tokens,
            codeFont: codeFont,
            tooltip: l10n.copyBaseBranchTooltip,
          ),
      ],
    );
  }
}

/// A pill showing a branch ref in the code font. Clicking it copies the ref to
/// the clipboard and flashes a checkmark + "copied" tooltip for ~1.4s.
class _CopyableBranchChip extends StatefulWidget {
  const _CopyableBranchChip({
    required this.branch,
    required this.tokens,
    required this.codeFont,
    required this.tooltip,
  });

  final String branch;
  final DesignSystemTokens tokens;
  final String codeFont;
  final String tooltip;

  @override
  State<_CopyableBranchChip> createState() => _CopyableBranchChipState();
}

class _CopyableBranchChipState extends State<_CopyableBranchChip> {
  bool _copied = false;
  bool _hovered = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.branch));
    if (!mounted) {
      return;
    }
    setState(() => _copied = true);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final l10n = AppLocalizations.of(context);

    return Tooltip(
      message: _copied ? l10n.copied : widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: _copy,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: _hovered ? tokens.bgTertiary : tokens.bgSecondary,
              border: Border.all(color: tokens.borderSecondary),
              borderRadius: AppRadii.brSm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _copied ? AppIcons.check : AppIcons.gitBranch,
                  size: 12,
                  color: _copied
                      ? tokens.fgSuccessSecondary
                      : tokens.fgQuaternary,
                ),
                const SizedBox(width: AppSpacing.xs),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(
                    widget.branch,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: widget.codeFont,
                      fontSize: 12,
                      height: 1.2,
                      color: tokens.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
