import 'package:cc_domain/features/plan_studio/domain/entities/playbook.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What a completed [PlaybookRunDialog] returns: the anchor ticket and the
/// resolved parameter values.
class PlaybookRunResult {
  /// Creates a result.
  const PlaybookRunResult({required this.ticketId, required this.args});

  /// The anchor ticket the plan is proposed against.
  final String ticketId;

  /// Parameter values, keyed by parameter name.
  final Map<String, String> args;
}

/// The run-playbook dialog (PRD 17 §10): typed parameter fields + an anchor
/// ticket picker. Running only PROPOSES a plan — the operator approves it in
/// Plan Studio before anything executes.
class PlaybookRunDialog extends ConsumerStatefulWidget {
  /// Creates a [PlaybookRunDialog].
  const PlaybookRunDialog({
    super.key,
    required this.playbook,
    required this.workspaceId,
  });

  /// The playbook to instantiate.
  final Playbook playbook;

  /// The active workspace.
  final String workspaceId;

  @override
  ConsumerState<PlaybookRunDialog> createState() => _PlaybookRunDialogState();
}

class _PlaybookRunDialogState extends ConsumerState<PlaybookRunDialog> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _enumValues = {};
  String? _ticketId;

  @override
  void initState() {
    super.initState();
    for (final p in widget.playbook.params) {
      if (p.type == PlaybookParamType.enumeration) {
        _enumValues[p.name] =
            p.defaultValue ?? (p.choices.isNotEmpty ? p.choices.first : '');
      } else {
        _controllers[p.name] = TextEditingController(
          text: p.defaultValue ?? '',
        );
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tickets =
        ref.watch(workspaceTicketsProvider(widget.workspaceId)).value ??
        const <Ticket>[];
    final openTickets = tickets.where((t) => !t.status.isTerminal).toList();

    return CcDialog(
      title: l10n.planPlaybookRunTitle(widget.playbook.name),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final p in widget.playbook.params) ...[
              _paramField(context, p),
              const SizedBox(height: 12),
            ],
            Text(
              l10n.planPlaybookAnchorTicket,
              style: const TextStyle(
                fontSize: 12,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 6),
            CcSelect<String>(
              value: _ticketId,
              hintText: l10n.planPlaybookPickTicket,
              options: [
                for (final t in openTickets)
                  CcSelectOption(value: t.id, label: t.title),
              ],
              onChanged: (v) => setState(() => _ticketId = v),
            ),
          ],
        ),
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        CcButton(
          onPressed: _ticketId == null ? null : _submit,
          child: Text(l10n.planPlaybookProposeRun),
        ),
      ],
    );
  }

  Widget _paramField(BuildContext context, PlaybookParam p) {
    final l10n = AppLocalizations.of(context);
    final label = p.required ? '${p.name} *' : p.name;
    if (p.type == PlaybookParamType.enumeration && p.choices.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 6),
          CcSelect<String>(
            value: _enumValues[p.name],
            options: [
              for (final c in p.choices) CcSelectOption(value: c, label: c),
            ],
            onChanged: (v) => setState(() => _enumValues[p.name] = v),
          ),
        ],
      );
    }
    String? helper() {
      if (p.description.isNotEmpty) {
        return p.description;
      }
      return switch (p.type) {
        PlaybookParamType.repoRef => l10n.planPlaybookRepoHint,
        PlaybookParamType.agentRef => l10n.planPlaybookAgentHint,
        _ => null,
      };
    }

    return CcTextField(
      controller: _controllers[p.name],
      label: label,
      helperText: helper(),
    );
  }

  void _submit() {
    final args = <String, String>{};
    for (final p in widget.playbook.params) {
      final value = p.type == PlaybookParamType.enumeration
          ? _enumValues[p.name] ?? ''
          : _controllers[p.name]?.text ?? '';
      if (value.isNotEmpty) {
        args[p.name] = value;
      }
    }
    Navigator.of(
      context,
    ).pop(PlaybookRunResult(ticketId: _ticketId!, args: args));
  }
}
