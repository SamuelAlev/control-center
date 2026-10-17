import 'package:cc_data/cc_data.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/skills/skill_evaluation_model_fields.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/skill_evaluation/skill_campaign_error.dart';
import 'package:control_center/shared/skill_evaluation/skill_campaign_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

part 'skill_evaluation_dialog_state.dart';

/// Opens an explicit, budgeted paid evaluation; cancelling submits nothing.
Future<SkillCampaignView?> showSkillEvaluationDialog(
  BuildContext context, {
  required String workspaceId,
  required String skillSlug,
  required String currentHash,
  required List<String> availableSkills,
  required List<SkillCampaignView> history,
}) => showCcDialog<SkillCampaignView>(
  context: context,
  builder: (_) => _StartDialog(
    workspaceId: workspaceId,
    skillSlug: skillSlug,
    currentHash: currentHash,
    availableSkills: availableSkills,
    history: history,
  ),
);

class _StartDialog extends ConsumerStatefulWidget {
  const _StartDialog({
    required this.workspaceId,
    required this.skillSlug,
    required this.currentHash,
    required this.availableSkills,
    required this.history,
  });
  final String workspaceId, skillSlug, currentHash;
  final List<String> availableSkills;
  final List<SkillCampaignView> history;
  @override
  ConsumerState<_StartDialog> createState() => _StartDialogState();
}
