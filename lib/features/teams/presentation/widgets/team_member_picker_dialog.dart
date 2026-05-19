import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/avatar_initials.dart';
import 'package:flutter/material.dart';

/// Shows a picker of [candidates] (workspace agents not yet on the team) and
/// returns the agent ids the user chose to add, or `null` if dismissed.
Future<List<String>?> showTeamMemberPickerDialog(
  BuildContext context, {
  required List<Agent> candidates,
}) {
  return showCcDialog<List<String>>(
    context: context,
    builder: (dialogContext) => _MemberPicker(candidates: candidates),
  );
}

class _MemberPicker extends StatefulWidget {
  const _MemberPicker({required this.candidates});

  final List<Agent> candidates;

  @override
  State<_MemberPicker> createState() => _MemberPickerState();
}

class _MemberPickerState extends State<_MemberPicker> {
  final _selected = <String>{};

  void _toggle(String agentId) => setState(() {
    if (!_selected.add(agentId)) {
      _selected.remove(agentId);
    }
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;

    return CcDialog(
      title: l10n.teamAddMemberTitle,
      content: SizedBox(
        width: 440,
        child: widget.candidates.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  l10n.teamNoAgentsToAdd,
                  textAlign: TextAlign.center,
                  style: CcTypography.body.copyWith(
                    color: tokens?.textTertiary,
                  ),
                ),
              )
            : ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.candidates.length,
                  separatorBuilder: (_, _) => const CcDivider(),
                  itemBuilder: (_, i) {
                    final agent = widget.candidates[i];
                    final checked = _selected.contains(agent.id);
                    return CcTappable(
                      onPressed: () => _toggle(agent.id),
                      builder: (_, _) => Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        child: Row(
                          children: [
                            CcCheckbox(
                              value: checked,
                              onChanged: (_) => _toggle(agent.id),
                            ),
                            const SizedBox(width: 12),
                            CcAvatar(
                              size: 30,
                              initials: avatarInitials(agent.name),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    agent.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: tokens?.textPrimary,
                                        ),
                                  ),
                                  if (agent.title.isNotEmpty)
                                    Text(
                                      agent.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: tokens?.textTertiary,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            if (agent.skills.isNotEmpty)
                              Icon(
                                AppIcons.sparkles,
                                size: 14,
                                color: tokens?.fgTertiary,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
      actions: [
        CcButton(
          onPressed: () => Navigator.pop(context),
          variant: CcButtonVariant.ghost,
          child: Text(l10n.cancel),
        ),
        CcButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.pop(context, _selected.toList()),
          child: Text(l10n.teamAddMembersCount(_selected.length)),
        ),
      ],
    );
  }
}
