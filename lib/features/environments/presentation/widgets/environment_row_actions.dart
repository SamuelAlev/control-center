import 'dart:async';

import 'package:cc_data/cc_data.dart' show RpcEnvironmentRepository;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_feedback.dart';
import 'package:control_center/features/environments/providers/environment_actions.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The actions at the end of a row: compact icons, each named by its tooltip
/// and accessible label, so a narrow sidebar never wraps them under the text.
class EnvironmentRowActions extends StatelessWidget {
  /// Creates an [EnvironmentRowActions].
  const EnvironmentRowActions({super.key, required this.children});

  /// The buttons.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => children.isEmpty
      ? const SizedBox.shrink()
      : Row(mainAxisSize: MainAxisSize.min, children: children);
}

/// Opens something, a tab or a dialog, without changing the environment.
class EnvironmentOpenButton extends StatelessWidget {
  /// Creates an [EnvironmentOpenButton].
  const EnvironmentOpenButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  /// What it opens.
  final String label;

  /// Its glyph.
  final IconData icon;

  /// Null disables it.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => CcIconButton(
    icon: icon,
    size: CcButtonSize.sm,
    tooltip: label,
    onPressed: onPressed,
  );
}

/// Forwards one action to the server, spinning while it runs.
class EnvironmentActionButton extends ConsumerWidget {
  /// Creates an [EnvironmentActionButton].
  const EnvironmentActionButton({
    super.key,
    required this.spaceKey,
    required this.actionKey,
    required this.label,
    required this.icon,
    required this.action,
    this.enabled = true,
  });

  /// The space acted on.
  final EnvironmentSpaceKey spaceKey;

  /// Its key in [environmentActionsProvider], so a second press is a no-op.
  final String actionKey;

  /// What it does.
  final String label;

  /// Its glyph.
  final IconData icon;

  /// The call.
  final Future<void> Function(RpcEnvironmentRepository repository) action;

  /// Whether it may run now.
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final running = ref
        .watch(environmentActionsProvider(spaceKey))
        .contains(actionKey);
    return CcIconButton(
      icon: icon,
      size: CcButtonSize.sm,
      tooltip: label,
      loading: running,
      onPressed: enabled && !running
          ? () => unawaited(
              runEnvironmentAction(context, ref, spaceKey, actionKey, action),
            )
          : null,
    );
  }
}

/// The two halves of a component row: what it says, and what it offers.
enum EnvironmentBodyPart {
  /// Facts and sub-rows, under the header.
  details,

  /// Icon actions, at the end of the header.
  actions,
}
