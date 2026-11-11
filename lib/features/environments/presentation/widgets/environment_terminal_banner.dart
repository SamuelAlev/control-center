import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Why a terminal opened by itself: a start needs a person, and this is where
/// it waits for them.
///
/// Follows the environment rather than the tab. While the start waits here it
/// says what for; once the tool has what it needed it says the start carries
/// on, since the terminal has gone quiet and the rest happens elsewhere; and
/// on a tab restored later it says nothing.
class EnvironmentStartTerminalBanner extends ConsumerStatefulWidget {
  /// Creates an [EnvironmentStartTerminalBanner].
  const EnvironmentStartTerminalBanner({
    super.key,
    required this.workspaceId,
    required this.spaceId,
    this.sessionId,
  });

  /// The owning workspace.
  final String workspaceId;

  /// The terminal's space.
  final String spaceId;

  /// The session this tab shows, when it is known.
  final String? sessionId;

  @override
  ConsumerState<EnvironmentStartTerminalBanner> createState() =>
      _EnvironmentStartTerminalBannerState();
}

class _EnvironmentStartTerminalBannerState
    extends ConsumerState<EnvironmentStartTerminalBanner> {
  /// Whether this tab has shown the start waiting on it. Only then does "done
  /// here" mean anything: a tab restored after the fact never waited.
  bool _waited = false;

  @override
  Widget build(BuildContext context) {
    final environment = ref.watch(
      spaceEnvironmentProvider((
        workspaceId: widget.workspaceId,
        spaceId: widget.spaceId,
      )),
    );
    final waiting = environment?.interactiveComponent;
    final here =
        waiting != null &&
        (widget.sessionId == null || waiting.sessionId == widget.sessionId);
    if (here) {
      _waited = true;
    } else if (!(environment?.status.isBusy ?? false)) {
      _waited = false;
    }
    if (!here && !_waited) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: SizedBox(
        width: double.infinity,
        child: here
            ? CcAlert(
                variant: CcAlertVariant.warning,
                title: l10n.environmentStartTerminalReason,
                description: Text(
                  [
                    ?waiting.detail,
                    l10n.environmentStartTerminalHint,
                  ].join('\n'),
                ),
              )
            : CcAlert(title: l10n.environmentStartTerminalDone),
      ),
    );
  }
}

/// A one-line note on a terminal that started before its space's environment.
///
/// The server hands a shell the environment's variables when it spawns, so
/// such a terminal has none of them: `docker compose ps` there targets nothing.
/// The fix is a fresh shell, which [onOpenFresh] opens.
class EnvironmentTerminalBanner extends ConsumerWidget {
  /// Creates an [EnvironmentTerminalBanner].
  const EnvironmentTerminalBanner({
    super.key,
    required this.workspaceId,
    required this.spaceId,
    required this.startedAt,
    required this.onOpenFresh,
  });

  /// The owning workspace.
  final String workspaceId;

  /// The terminal's space.
  final String spaceId;

  /// When the shell started, or null before it has.
  final DateTime? startedAt;

  /// Opens a new terminal in the same space.
  final VoidCallback onOpenFresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final started = startedAt;
    if (started == null || workspaceId.isEmpty || spaceId.isEmpty) {
      return const SizedBox.shrink();
    }
    final environment = ref.watch(
      spaceEnvironmentProvider((workspaceId: workspaceId, spaceId: spaceId)),
    );
    if (environment == null || !environment.createdAt.isAfter(started)) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.sm,
        end: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: t.bgSecondary,
        border: Border(bottom: BorderSide(color: t.borderSecondary)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.environmentTerminalStale,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: CcTypography.caption.copyWith(color: t.textSecondary),
            ),
          ),
          CcButton(
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            onPressed: onOpenFresh,
            child: Text(l10n.environmentTerminalFresh),
          ),
        ],
      ),
    );
  }
}
