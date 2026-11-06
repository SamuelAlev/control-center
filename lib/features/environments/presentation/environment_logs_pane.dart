import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_feedback.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/live_log_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A logs tab's body from its [args], or an empty state when they name another
/// workspace or are incomplete.
Widget environmentLogsTabBody(Map<String, Object?> args, String? workspaceId) {
  final tabWorkspaceId = args['workspaceId'] as String?;
  final spaceId = args['spaceId'] as String?;
  final target = args['target'] as String?;
  if (tabWorkspaceId == null ||
      tabWorkspaceId != workspaceId ||
      spaceId == null ||
      target == null) {
    return const SizedBox.shrink();
  }
  return EnvironmentLogsPane(
    workspaceId: tabWorkspaceId,
    spaceId: spaceId,
    target: target,
  );
}

/// The live output of one process or service.
///
/// A restored tab comes back here and only subscribes: an environment that is
/// down shows as such, and nothing starts because a layout was reopened.
class EnvironmentLogsPane extends ConsumerWidget {
  /// Creates an [EnvironmentLogsPane].
  const EnvironmentLogsPane({
    super.key,
    required this.workspaceId,
    required this.spaceId,
    required this.target,
  });

  /// The owning workspace.
  final String workspaceId;

  /// The space whose environment this reads.
  final String spaceId;

  /// A component id or a service name.
  final String target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final logs = ref.watch(
      environmentLogLinesProvider((
        workspaceId: workspaceId,
        spaceId: spaceId,
        target: target,
      )),
    );
    final lines = logs.value ?? const <String>[];
    if (logs.hasError && lines.isEmpty) {
      return CcEmptyState(
        icon: AppIcons.scrollText,
        message: l10n.environmentLogsGone,
      );
    }
    return LiveLogView(
      title: Text(
        target,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: CcFonts.code(
          textStyle: CcTypography.caption.copyWith(color: t.textTertiary),
        ),
      ),
      lines: lines,
      emptyMessage: l10n.environmentLogsWaiting,
      onCopy: (text) => copyEnvironmentText(context, text),
    );
  }
}
