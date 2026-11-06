import 'dart:async';

import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_feedback.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_host_setup.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_start_dialog.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Called with what the person chose on the Start form.
typedef EnvironmentStartCallback =
    Future<void> Function(
      BuildContext context,
      String definitionId,
      Map<String, dynamic> options,
    );

/// Forwards Start for a space that already exists.
Future<void> forwardEnsure(
  BuildContext context,
  WidgetRef ref,
  EnvironmentSpaceKey key, {
  required String definitionId,
  required Map<String, dynamic> options,
}) async {
  final followUp = HostSetupFollowUp.of(context, ref);
  SpaceEnvironment? started;
  await runEnvironmentAction(context, ref, key, 'start', (repository) async {
    started = await repository.ensure(
      key.workspaceId,
      key.spaceId,
      definitionId: definitionId,
      options: options,
    );
  });
  if (started != null) {
    await followUp.after(key, started!);
  }
}

/// The checks of [definitionId] that fail, or none when they can't be read.
///
/// Checks are admin-gated, so a member gets none rather than an error.
Future<List<String>> _failingChecks(
  WidgetRef ref,
  String workspaceId,
  String definitionId,
) async {
  try {
    final checks = await ref
        .read(environmentRepositoryProvider)
        .check(workspaceId, definitionId);
    return [
      for (final check in checks)
        if (!check.ok) check.label,
    ];
  } on Object {
    return const [];
  }
}

/// Runs the Start flow: the form when there is something to choose or a check
/// fails, otherwise straight to [onStart].
Future<void> beginEnvironmentStart(
  BuildContext context,
  WidgetRef ref, {
  required String workspaceId,
  required List<EnvironmentDefinitionRecord> definitions,
  required EnvironmentStartCallback onStart,
  Map<String, dynamic> initialOptions = const {},
}) async {
  final only = definitions.length == 1 ? definitions.single : null;
  if (only != null &&
      (environmentDefinitionOf(only)?.options.isEmpty ?? true) &&
      (await _failingChecks(ref, workspaceId, only.id)).isEmpty) {
    if (context.mounted) {
      await onStart(context, only.id, const {});
    }
    return;
  }
  if (!context.mounted) {
    return;
  }
  final choice = await showEnvironmentStartDialog(
    context,
    workspaceId: workspaceId,
    definitions: definitions,
    initialOptions: initialOptions,
  );
  if (choice != null && context.mounted) {
    await onStart(context, choice.definitionId, choice.options);
  }
}

/// What a space shows before anything is running.
class EnvironmentStartPanel extends ConsumerStatefulWidget {
  /// Creates an [EnvironmentStartPanel].
  const EnvironmentStartPanel({
    super.key,
    required this.workspaceId,
    required this.definitions,
    required this.onStart,
    this.busy = false,
  });

  /// The owning workspace.
  final String workspaceId;

  /// What the space may start.
  final List<EnvironmentDefinitionRecord> definitions;

  /// Forwards Start.
  final EnvironmentStartCallback onStart;

  /// Shows Start's spinner.
  final bool busy;

  @override
  ConsumerState<EnvironmentStartPanel> createState() =>
      _EnvironmentStartPanelState();
}

class _EnvironmentStartPanelState extends ConsumerState<EnvironmentStartPanel> {
  /// Set from the press until the flow returns, so a second tap while the
  /// checks run or the form is up starts nothing.
  bool _opening = false;

  Future<void> _start(List<EnvironmentDefinitionRecord> startable) async {
    if (_opening) {
      return;
    }
    setState(() => _opening = true);
    try {
      await beginEnvironmentStart(
        context,
        ref,
        workspaceId: widget.workspaceId,
        definitions: startable,
        onStart: widget.onStart,
      );
    } finally {
      if (mounted) {
        setState(() => _opening = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final startable = widget.definitions.where(environmentHasStack).toList();
    if (startable.isEmpty) {
      return Text(
        l10n.environmentNoStack,
        style: CcTypography.caption.copyWith(color: t.textTertiary),
      );
    }
    // Disabled while the form is up, spinning only while a start is in flight.
    final busy = widget.busy || _opening;
    return Row(
      children: [
        Expanded(
          child: Text(
            startable.length == 1
                ? startable.single.name
                : l10n.environmentDefinitionCount(startable.length),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CcTypography.bodySm.copyWith(color: t.textSecondary),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        CcButton(
          size: CcButtonSize.sm,
          icon: AppIcons.play,
          loading: widget.busy,
          onPressed: busy ? null : () => unawaited(_start(startable)),
          child: Text(l10n.startLabel),
        ),
      ],
    );
  }
}
