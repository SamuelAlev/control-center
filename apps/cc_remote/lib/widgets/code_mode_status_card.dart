import 'package:cc_domain/cc_domain.dart' show CodeModeStatusDto;
import 'package:cc_remote/code_mode_providers.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Code mode on this server, read only: whether it runs agents' scripts
/// and, when it does not, why. Every run has `repl` exactly when it does.
/// The limits, and the record of every script, live in the desktop app's
/// workspace settings and observability; the phone has neither surface.
class CodeModeStatusCard extends ConsumerWidget {
  /// Creates the card.
  const CodeModeStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(activeWorkspaceIdProvider).value;
    if (workspace == null || workspace.isEmpty) {
      return const SizedBox.shrink();
    }
    final status = ref.watch(remoteCodeModeStatusProvider(workspace));
    final s = status.value;
    if (s == null) {
      // Loading, not connected, or refused: nothing worth a card.
      return const SizedBox.shrink();
    }
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4),
          child: Text(
            l10n.codeModeTitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: t.fgTertiary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: t.bgSecondary,
            borderRadius: const BorderRadius.all(Radius.circular(2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _Body(status: s),
          ),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.status});

  final CodeModeStatusDto status;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final (label, tone) = status.available
        ? (l10n.codeModeAvailable, CcStatusTone.positive)
        : (l10n.codeModeUnavailable, CcStatusTone.negative);
    final caption = CcTypography.caption.copyWith(
      color: t.textSecondary,
      height: 1.45,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CcStatusTag(label: label, tone: tone),
        if (!status.available) ...[
          const SizedBox(height: 6),
          Text(
            l10n.codeModeUnavailableNote(
              status.reason ?? l10n.codeModeNoReason,
            ),
            style: caption,
          ),
        ],
      ],
    );
  }
}
