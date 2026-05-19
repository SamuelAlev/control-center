import 'dart:async';

import 'package:cc_domain/core/domain/entities/github_user.dart';
import 'package:cc_infra/cc_infra_web.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/providers/github_user_profile_provider.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:control_center/shared/widgets/github_user_status_badge.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps [child] so hovering it for [showDelay] reveals a compact floating card
/// with the GitHub user's info (name, role, status, location, teams).
///
/// Mirrors [CcTooltip]'s hover mechanism (a [MouseRegion] + dwell [Timer]
/// driving a [CcOverlayAnchor]) but renders a light design-system card instead
/// of the dark tooltip ink. The profile is fetched lazily — only once the card
/// is about to show — via [githubUserProfileProvider], so idle rows cost
/// nothing. GitHub App bots (`login[bot]`) never fetch and never show a card.
/// The card is informational (pointer events pass through it); leaving [child]
/// hides it.
class GitHubUserHoverTarget extends StatefulWidget {
  /// Creates a [GitHubUserHoverTarget] for [login] wrapping [child].
  const GitHubUserHoverTarget({
    super.key,
    required this.login,
    required this.child,
    this.enabled = true,
    this.showDelay = const Duration(milliseconds: 450),
    this.targetAnchor = Alignment.bottomLeft,
    this.followerAnchor = Alignment.topLeft,
  });

  /// The GitHub login whose profile the card shows.
  final String login;

  /// The hover target.
  final Widget child;

  /// When false the card never shows (renders [child] verbatim).
  final bool enabled;

  /// Hover dwell before the card appears.
  final Duration showDelay;

  /// Point on the target the card aligns to.
  final Alignment targetAnchor;

  /// Point on the card aligned to [targetAnchor].
  final Alignment followerAnchor;

  @override
  State<GitHubUserHoverTarget> createState() => _GitHubUserHoverTargetState();
}

class _GitHubUserHoverTargetState extends State<GitHubUserHoverTarget> {
  final CcOverlayController _controller = CcOverlayController();
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  bool get _active =>
      widget.enabled &&
      widget.login.isNotEmpty &&
      !isGitHubBotLogin(widget.login);

  void _onEnter() {
    if (!_active) {
      return;
    }
    _timer?.cancel();
    _timer = Timer(widget.showDelay, _show);
  }

  void _onExit() {
    _timer?.cancel();
    _timer = null;
    _controller.hide();
  }

  void _show() {
    if (mounted) {
      _controller.show();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_active) {
      return widget.child;
    }
    return MouseRegion(
      onEnter: (_) => _onEnter(),
      onExit: (_) => _onExit(),
      child: CcOverlayAnchor(
        controller: _controller,
        targetAnchor: widget.targetAnchor,
        followerAnchor: widget.followerAnchor,
        offset: const Offset(0, 6),
        barrierDismissible: false,
        target: widget.child,
        overlayBuilder: (context, _) => _HoverCardPanel(login: widget.login),
      ),
    );
  }
}

/// The floating card body. A [ConsumerWidget] so it fetches the profile itself
/// (only mounted while the card is open, so the fetch is hover-scoped).
class _HoverCardPanel extends ConsumerWidget {
  const _HoverCardPanel({required this.login});

  final String login;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final async = ref.watch(githubUserProfileProvider(login));

    return IgnorePointer(
      child: _FadeIn(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300, minWidth: 240),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: t.bgPrimary,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: t.borderSecondary),
              boxShadow: AppShadows.golden,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: async.when(
                loading: () => _Body(profile: null, login: login),
                error: (_, _) => _Body(profile: null, login: login),
                data: (profile) => _Body(profile: profile, login: login),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The card contents, shared across loading/data (a null [profile] renders the
/// login-only fallback used while loading or on error).
class _Body extends StatelessWidget {
  const _Body({required this.profile, required this.login});

  final GitHubUserProfile? profile;
  final String login;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);

    final name = (profile?.name.isNotEmpty ?? false)
        ? profile!.name
        : '@$login';
    final role = _role(profile);
    final subtitleParts = <String>[
      if (profile?.name.isNotEmpty ?? false) '@$login',
      ?role,
    ];
    final subtitle = subtitleParts.join(' · ');

    final status = profile?.status;
    final showStatus = status != null && statusHasContent(status);
    final location = profile?.location;
    final hasLocation = location != null && location.trim().isNotEmpty;
    final teams = profile?.orgTeams ?? const <String>[];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GitHubUserAvatar(
              login: login,
              avatarUrl: profile?.avatarUrl,
              size: 40,
              showHoverCard: false,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: t.textTertiary),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (showStatus) ...[
          const SizedBox(height: 12),
          GitHubUserStatusBadge(status: status),
        ],
        if (hasLocation) ...[
          const SizedBox(height: 12),
          _MetaRow(icon: AppIcons.mapPin, text: location.trim()),
        ],
        if (teams.isNotEmpty) ...[
          const SizedBox(height: 12),
          _TeamsSection(teams: teams, label: l10n.teamsSectionLabel),
        ],
      ],
    );
  }

  String? _role(GitHubUserProfile? profile) {
    if (profile == null) {
      return null;
    }
    final bio = profile.bio?.trim();
    if (bio != null && bio.isNotEmpty) {
      // Keep the card compact — first line only.
      final firstLine = bio.split('\n').first.trim();
      return firstLine.isEmpty ? null : firstLine;
    }
    final company = profile.company?.trim();
    if (company != null && company.isNotEmpty) {
      return company.startsWith('@') ? company.substring(1) : company;
    }
    return null;
  }
}

/// An icon + text metadata line (e.g. location).
class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 14, color: t.textTertiary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.5, color: t.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// A labelled wrap of team chips.
class _TeamsSection extends StatelessWidget {
  const _TeamsSection({required this.teams, required this.label});

  final List<String> teams;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(AppIcons.users, size: 13, color: t.textTertiary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: t.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final team in teams)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: t.bgSecondary,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: t.borderSecondary),
                ),
                child: Text(
                  team,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: t.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Fades its child in on mount so the card animates each time it opens (the
/// [CcOverlayAnchor] rebuilds it fresh on show). Suppressed under reduced-motion.
class _FadeIn extends StatefulWidget {
  const _FadeIn({required this.child});

  final Widget child;

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> {
  bool _opaque = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _opaque = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final duration = CcMotion.resolve(context, CcMotion.fast);
    return AnimatedOpacity(
      opacity: _opaque ? 1 : 0,
      duration: duration,
      curve: CcMotion.standard,
      child: widget.child,
    );
  }
}
