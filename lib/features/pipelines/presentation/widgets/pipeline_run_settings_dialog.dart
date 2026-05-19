import 'package:cc_domain/features/pipelines/domain/entities/pipeline_input.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/max_parallel_runs_field.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_input_field_dialog.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// What the run-settings dialog hands back to its caller: the edited input
/// list and the template's run-concurrency cap (null = unlimited). Both are
/// template fields, so the caller folds them into its draft and saves.
typedef PipelineRunSettingsResult = ({
  List<PipelineInput> inputs,
  int? maxParallelRuns,
});

/// Opens the manual-run settings for a template. Returns the edited settings
/// (to be applied to the draft + saved by the caller), or null if dismissed.
///
/// The "allow manual run" toggle persists immediately (it manages a `manual`
/// [PipelineTrigger]); the input-field and concurrency edits are returned for
/// the caller to fold into the template on save.
Future<PipelineRunSettingsResult?> showPipelineRunSettingsDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String workspaceId,
  required String templateId,
  required List<PipelineInput> inputs,
  required int? maxParallelRuns,
}) {
  return showCcDialog<PipelineRunSettingsResult>(
    context: context,
    builder: (ctx) => _RunSettingsDialog(
      workspaceId: workspaceId,
      templateId: templateId,
      initialInputs: inputs,
      initialMaxParallelRuns: maxParallelRuns,
    ),
  );
}

class _RunSettingsDialog extends ConsumerStatefulWidget {
  const _RunSettingsDialog({
    required this.workspaceId,
    required this.templateId,
    required this.initialInputs,
    required this.initialMaxParallelRuns,
  });

  final String workspaceId;
  final String templateId;
  final List<PipelineInput> initialInputs;
  final int? initialMaxParallelRuns;

  @override
  ConsumerState<_RunSettingsDialog> createState() => _RunSettingsDialogState();
}

class _RunSettingsDialogState extends ConsumerState<_RunSettingsDialog> {
  late List<PipelineInput> _inputs = [...widget.initialInputs];
  late final TextEditingController _maxParallelCtrl = TextEditingController(
    text: widget.initialMaxParallelRuns?.toString() ?? '',
  );
  String? _maxParallelError;

  @override
  void dispose() {
    _maxParallelCtrl.dispose();
    super.dispose();
  }

  /// Closes with the edited settings, or surfaces a validation error and stays
  /// open. A blank cap means unlimited — the only way to express "no cap", so
  /// it is not an error.
  void _submit() {
    final parsed = parseMaxParallelRuns(_maxParallelCtrl.text);
    if (parsed.isInvalid) {
      setState(
        () => _maxParallelError = AppLocalizations.of(
          context,
        ).pipelineRunSettingsMaxParallelInvalid,
      );
      return;
    }
    Navigator.pop(context, (inputs: _inputs, maxParallelRuns: parsed.value));
  }

  Future<void> _setManual(bool allow) async {
    final repo = ref.read(pipelineTriggerRepositoryProvider);
    final current = ref
        .read(
          manualTriggerForTemplateProvider((
            workspaceId: widget.workspaceId,
            templateId: widget.templateId,
          )),
        )
        .value;
    if (allow) {
      if (current == null) {
        await repo.insert(
          PipelineTrigger(
            id: const Uuid().v4(),
            eventType: PipelineTrigger.manualEventType,
            templateId: widget.templateId,
            workspaceId: widget.workspaceId,
            enabled: true,
          ),
        );
      } else if (!current.enabled) {
        await repo.update(current.copyWith(enabled: true));
      }
    } else if (current != null) {
      await repo.deleteById(context.currentWorkspaceId!, current.id);
    }
  }

  Future<void> _addOrEdit({PipelineInput? existing, int? index}) async {
    final result = await showInputFieldDialog(
      context: context,
      initial: existing,
    );
    if (result == null) {
      return;
    }
    setState(() {
      if (index == null) {
        _inputs = [..._inputs, result];
      } else {
        _inputs = [..._inputs]..[index] = result;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final manualAsync = ref.watch(
      manualTriggerForTemplateProvider((
        workspaceId: widget.workspaceId,
        templateId: widget.templateId,
      )),
    );
    final manualOn = manualAsync.value?.enabled ?? false;

    return CcDialog(
      title: l10n.pipelineRunSettingsTitle,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 460),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CcSwitch(value: manualOn, onChanged: _setManual),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.pipelineRunSettingsAllow,
                          style: TextStyle(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          l10n.pipelineRunSettingsAllowHelp,
                          style: TextStyle(
                            color: tokens.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28, child: Center(child: CcDivider())),
              Text(
                l10n.pipelineRunSettingsConcurrencyTitle,
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              MaxParallelRunsField(
                controller: _maxParallelCtrl,
                errorText: _maxParallelError,
                onChanged: (_) {
                  if (_maxParallelError != null) {
                    setState(() => _maxParallelError = null);
                  }
                },
              ),
              const SizedBox(height: 28, child: Center(child: CcDivider())),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.pipelineRunSettingsInputsTitle,
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  CcButton(
                    onPressed: _addOrEdit,
                    size: CcButtonSize.sm,
                    variant: CcButtonVariant.secondary,
                    icon: AppIcons.plus,
                    child: Text(l10n.pipelineRunSettingsAddInput),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_inputs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    l10n.pipelineRunSettingsNoInputs,
                    style: TextStyle(color: tokens.textTertiary, fontSize: 13),
                  ),
                )
              else
                for (var i = 0; i < _inputs.length; i++)
                  _InputRow(
                    input: _inputs[i],
                    onEdit: () => _addOrEdit(existing: _inputs[i], index: i),
                    onDelete: () =>
                        setState(() => _inputs = [..._inputs]..removeAt(i)),
                  ),
            ],
          ),
        ),
      ),
      actions: [
        CcButton(
          onPressed: () => Navigator.pop(context),
          variant: CcButtonVariant.secondary,
          child: Text(l10n.cancel),
        ),
        CcButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}

class _InputRow extends StatelessWidget {
  const _InputRow({
    required this.input,
    required this.onEdit,
    required this.onDelete,
  });

  final PipelineInput input;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  input.required ? '${input.label} *' : input.label,
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${input.key} · ${input.type.name}',
                  style: TextStyle(color: tokens.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
          CcIconButton(
            icon: AppIcons.pencil,
            size: CcButtonSize.sm,
            tooltip: l10n.edit,
            onPressed: onEdit,
          ),
          CcIconButton(
            icon: AppIcons.trash2,
            size: CcButtonSize.sm,
            tooltip: l10n.delete,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
