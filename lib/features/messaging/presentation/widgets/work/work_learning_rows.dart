import 'package:cc_domain/cc_domain.dart' show UserDto;
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/utils/money_format.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_row_frame.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A person raised a held pipeline run's cap (`metadata.kind:
/// orchestration_cap_raised`, with `old_micros`, `new_micros`, `user_id`):
/// who, from what, to what.
class CapRaisedRow extends ConsumerWidget {
  /// Creates the row.
  const CapRaisedRow({super.key, required this.message});

  /// The system row.
  final Message message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final meta = message.metadata ?? const <String, dynamic>{};
    final locale = Localizations.localeOf(context).toString();
    String money(Object? micros) => micros is num
        ? fmtMicros(micros.toInt(), decimals: 2, locale: locale)
        : '—';
    final userId = meta['user_id'];
    final users = ref.watch(usersByIdProvider).value;
    final name = userId is String ? _nameOf(users, userId) : null;
    return WorkRowFrame(
      icon: AppIcons.trendingUp,
      sentence: l10n.workFeedCapRaised(
        name == null || name.trim().isEmpty
            ? l10n.workFeedPersonUnknown
            : inertText(name, singleLine: true),
        money(meta['old_micros']),
        money(meta['new_micros']),
      ),
    );
  }
}

String? _nameOf(Map<String, UserDto>? users, String userId) =>
    users?[userId]?.displayName;

/// An accepted skill change could not be finished because the skill changed
/// meanwhile, and the proposal was rolled back (`metadata.kind:
/// improvement_apply_incomplete`, with `proposal_id`, `skill_slug`).
class ApplyIncompleteRow extends StatelessWidget {
  /// Creates the row.
  const ApplyIncompleteRow({
    super.key,
    required this.message,
    required this.workspaceId,
  });

  /// The system row.
  final Message message;

  /// The active workspace.
  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final meta = message.metadata ?? const <String, dynamic>{};
    final skill = meta['skill_slug'];
    final proposalId = meta['proposal_id'];
    return WorkRowFrame(
      icon: AppIcons.triangleAlert,
      sentence: l10n.workFeedApplyIncomplete(
        skill is String && skill.isNotEmpty
            ? inertText(skill, singleLine: true)
            : '—',
      ),
      trailing: proposalId is String && workspaceId.isNotEmpty
          ? CcIconButton(
              icon: AppIcons.externalLink,
              size: CcButtonSize.sm,
              tooltip: l10n.workFeedOpenImprovement,
              onPressed: () =>
                  context.go(improvementRoute(workspaceId, proposalId)),
            )
          : null,
    );
  }
}
