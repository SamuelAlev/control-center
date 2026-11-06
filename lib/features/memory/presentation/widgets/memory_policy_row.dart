import 'dart:async';

import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_actions.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_excerpt.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One policy. Its switch is the one thing worth doing without opening it.
class MemoryPolicyRow extends ConsumerWidget {
  /// Creates a [MemoryPolicyRow].
  const MemoryPolicyRow({super.key, required this.policy});

  /// The policy.
  final MemoryPolicy policy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final caption = CcTypography.caption.copyWith(color: t.textTertiary);
    final plain = memoryPlainExcerpt(policy.rule);
    final (:lead, :rest) = memoryLeadSentence(plain);
    final sources = policy.sourceFactIds.length;
    return SettingsEntityRow(
      icon: AppIcons.scale,
      title: lead,
      subtitleWidget: rest.isEmpty
          ? null
          : MemoryExcerpt(
              markdown: policy.rule,
              skip: plain.length - rest.length,
            ),
      tone: policy.active ? null : CcStatusTone.neutral,
      statusLabel: policy.active ? null : l10n.inactive,
      meta: [
        if (policy.requiredRole != null)
          SettingsMetaFact(
            value: policy.requiredRole!.label,
            icon: AppIcons.user,
          ),
        if (sources > 0)
          Text(
            sources == 1
                ? l10n.sourceCount(sources)
                : l10n.sourceCountPlural(sources),
            style: caption,
          ),
      ],
      hoverTrailing: CcIconButton(
        variant: CcButtonVariant.destructive,
        icon: AppIcons.trash2,
        size: CcButtonSize.sm,
        tooltip: l10n.delete,
        onPressed: () => unawaited(deleteMemoryPolicy(context, ref, policy)),
      ),
      trailing: CcTooltip(
        message: policy.active ? l10n.deactivate : l10n.activate,
        child: CcSwitch(
          value: policy.active,
          semanticLabel: l10n.memoryPolicyActive,
          onChanged: (active) =>
              unawaited(setMemoryPolicyActive(ref, policy, active: active)),
        ),
      ),
      onPressed: () => openMemoryPolicy(context, policy),
    );
  }
}
