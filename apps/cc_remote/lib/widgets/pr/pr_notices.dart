import 'package:cc_domain/features/pr_review/domain/repositories/open_pr_list_repository.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// No forge credential reached the server, so the poller has nothing to poll.
/// Says so instead of rendering a convincing "no open pull requests".
class NoForgeNotice extends StatelessWidget {
  /// Creates a [NoForgeNotice].
  const NoForgeNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return _WarnNotice(
      icon: AppIcons.cloudOff,
      message: AppLocalizations.of(context).noForgeConnected,
    );
  }
}

/// Repos the poller parked as unreachable. Two causes, two messages: the app
/// is not installed on that org, or the installation covering them has been
/// suspended and the queue is last-known data. Naming them is the difference
/// between "this repo has no open PRs" and "this repo was never asked".
///
/// Renders nothing while every repo is reachable so callers can drop it in
/// unconditionally.
class InaccessibleReposNotice extends StatelessWidget {
  /// Creates an [InaccessibleReposNotice] over [repos].
  const InaccessibleReposNotice({super.key, required this.repos});

  /// The repos the server cannot access; empty renders nothing.
  final List<InaccessibleRepo> repos;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final suspended = [
      for (final repo in repos)
        if (repo.isInstallationSuspended) repo,
    ];
    final other = [
      for (final repo in repos)
        if (!repo.isInstallationSuspended) repo,
    ];
    if (suspended.isEmpty && other.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (suspended.isNotEmpty)
          _WarnNotice(
            icon: AppIcons.triangleAlert,
            message: l10n.installationSuspendedNotice(
              _names(
                suspended,
                fallback: l10n.reposUnreadable(suspended.length),
              ),
            ),
          ),
        if (other.isNotEmpty)
          _WarnNotice(
            icon: AppIcons.triangleAlert,
            message: _otherMessage(l10n, other),
          ),
      ],
    );
  }

  String _otherMessage(AppLocalizations l10n, List<InaccessibleRepo> repos) {
    final names = _names(repos);
    return names.isEmpty
        ? l10n.reposUnreadable(repos.length)
        : l10n.reposNotReadable(names);
  }

  String _names(List<InaccessibleRepo> repos, {String fallback = ''}) {
    final names = [
      for (final repo in repos)
        if (repo.repoFullName.isNotEmpty) repo.repoFullName,
    ];
    return names.isEmpty ? fallback : names.join(', ');
  }
}

class _WarnNotice extends StatelessWidget {
  const _WarnNotice({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.warnSoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, size: 16, color: t.textWarningPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: t.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
