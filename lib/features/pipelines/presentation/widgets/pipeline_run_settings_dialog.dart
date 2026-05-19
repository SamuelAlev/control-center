import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_input.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';

/// Opens the manual-run settings for a template. Returns the edited input list
/// (to be applied to the draft + saved by the caller), or null if dismissed.
///
/// The "allow manual run" toggle persists immediately (it manages a `manual`
/// [PipelineTrigger]); only the input-field edits are returned for the caller
/// to fold into the template on save.
Future<List<PipelineInput>?> showPipelineRunSettingsDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String workspaceId,
  required String templateId,
  required List<PipelineInput> inputs,
}) {
  return showCcDialog<List<PipelineInput>>(
    context: context,
    builder: (ctx) => _RunSettingsDialog(
      workspaceId: workspaceId,
      templateId: templateId,
      initialInputs: inputs,
    ),
  );
}

class _RunSettingsDialog extends ConsumerStatefulWidget {
  const _RunSettingsDialog({
    required this.workspaceId,
    required this.templateId,
    required this.initialInputs,
  });

  final String workspaceId;
  final String templateId;
  final List<PipelineInput> initialInputs;

  @override
  ConsumerState<_RunSettingsDialog> createState() => _RunSettingsDialogState();
}

class _RunSettingsDialogState extends ConsumerState<_RunSettingsDialog> {
  late List<PipelineInput> _inputs = [...widget.initialInputs];

  Future<void> _setManual(bool allow) async {
    final repo = ref.read(pipelineTriggerRepositoryProvider);
    final current = ref
        .read(manualTriggerForTemplateProvider((
          workspaceId: widget.workspaceId,
          templateId: widget.templateId,
        )))
        .value;
    if (allow) {
      if (current == null) {
        await repo.insert(PipelineTrigger(
          id: const Uuid().v4(),
          eventType: PipelineTrigger.manualEventType,
          templateId: widget.templateId,
          workspaceId: widget.workspaceId,
          enabled: true,
        ));
      } else if (!current.enabled) {
        await repo.update(current.copyWith(enabled: true));
      }
    } else if (current != null) {
      await repo.deleteById(current.id);
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
    final manualAsync = ref.watch(manualTriggerForTemplateProvider((
      workspaceId: widget.workspaceId,
      templateId: widget.templateId,
    )));
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
                  CcSwitch(
                    value: manualOn,
                    onChanged: _setManual,
                  ),
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
              const Divider(height: 28),
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
                    icon: LucideIcons.plus,
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
                    style: TextStyle(
                      color: tokens.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                )
              else
                for (var i = 0; i < _inputs.length; i++)
                  _InputRow(
                    input: _inputs[i],
                    onEdit: () => _addOrEdit(existing: _inputs[i], index: i),
                    onDelete: () => setState(
                      () => _inputs = [..._inputs]..removeAt(i),
                    ),
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
        CcButton(
          onPressed: () => Navigator.pop(context, _inputs),
          child: Text(l10n.save),
        ),
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
                  style: TextStyle(
                    color: tokens.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          CcIconButton(
            icon: LucideIcons.pencil,
            size: CcButtonSize.sm,
            onPressed: onEdit,
          ),
          CcIconButton(
            icon: LucideIcons.trash2,
            size: CcButtonSize.sm,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

/// Opens the editor for a single input field, returning the built
/// [PipelineInput] or null if cancelled.
Future<PipelineInput?> showInputFieldDialog({
  required BuildContext context,
  PipelineInput? initial,
}) {
  return showCcDialog<PipelineInput>(
    context: context,
    builder: (ctx) => _InputFieldDialog(
      initial: initial,
    ),
  );
}

class _InputFieldDialog extends StatefulWidget {
  const _InputFieldDialog({
    this.initial,
  });

  final PipelineInput? initial;

  @override
  State<_InputFieldDialog> createState() => _InputFieldDialogState();
}

class _InputFieldDialogState extends State<_InputFieldDialog> {
  late final TextEditingController _keyCtrl;
  late final TextEditingController _labelCtrl;
  late final TextEditingController _defaultCtrl;
  late final TextEditingController _helpCtrl;
  late final TextEditingController _placeholderCtrl;
  late final TextEditingController _optionsCtrl;
  late PipelineInputType _type;
  late bool _required;
  late bool _defaultBool;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _keyCtrl = TextEditingController(text: i?.key ?? '');
    _labelCtrl = TextEditingController(
      text: (i != null && i.label != i.key) ? i.label : '',
    );
    _defaultCtrl = TextEditingController(
      text: (i?.type == PipelineInputType.boolean)
          ? ''
          : (i?.defaultValue?.toString() ?? ''),
    );
    _helpCtrl = TextEditingController(text: i?.helpText ?? '');
    _placeholderCtrl = TextEditingController(text: i?.placeholder ?? '');
    _optionsCtrl = TextEditingController(text: i?.options.join(', ') ?? '');
    _type = i?.type ?? PipelineInputType.text;
    _required = i?.required ?? false;
    _defaultBool = i?.defaultValue == true;
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _labelCtrl.dispose();
    _defaultCtrl.dispose();
    _helpCtrl.dispose();
    _placeholderCtrl.dispose();
    _optionsCtrl.dispose();
    super.dispose();
  }

  PipelineInput? _build() {
    final key = _keyCtrl.text.trim();
    if (key.isEmpty) {
      return null;
    }
    final options = _type == PipelineInputType.select
        ? _optionsCtrl.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList()
        : const <String>[];
    Object? defaultValue;
    switch (_type) {
      case PipelineInputType.boolean:
        defaultValue = _defaultBool;
      case PipelineInputType.number:
        defaultValue = num.tryParse(_defaultCtrl.text.trim());
      case PipelineInputType.repo:
        // The repo is chosen at run time from the workspace's repos; no
        // authored default.
        defaultValue = null;
      case PipelineInputType.text:
      case PipelineInputType.multiline:
      case PipelineInputType.select:
        final t = _defaultCtrl.text.trim();
        defaultValue = t.isEmpty ? null : t;
    }
    final label = _labelCtrl.text.trim();
    final help = _helpCtrl.text.trim();
    final placeholder = _placeholderCtrl.text.trim();
    return PipelineInput(
      key: key,
      label: label.isEmpty ? null : label,
      type: _type,
      required: _required,
      defaultValue: defaultValue,
      helpText: help.isEmpty ? null : help,
      placeholder: placeholder.isEmpty ? null : placeholder,
      options: options,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final typeOptions = <CcSelectOption<PipelineInputType>>[
      CcSelectOption(
        value: PipelineInputType.text,
        label: l10n.pipelineInputTypeText,
      ),
      CcSelectOption(
        value: PipelineInputType.multiline,
        label: l10n.pipelineInputTypeMultiline,
      ),
      CcSelectOption(
        value: PipelineInputType.number,
        label: l10n.pipelineInputTypeNumber,
      ),
      CcSelectOption(
        value: PipelineInputType.boolean,
        label: l10n.pipelineInputTypeBoolean,
      ),
      CcSelectOption(
        value: PipelineInputType.select,
        label: l10n.pipelineInputTypeSelect,
      ),
      CcSelectOption(
        value: PipelineInputType.repo,
        label: l10n.pipelineInputTypeRepo,
      ),
    ];

    return CcDialog(
      title: l10n.pipelineInputEditTitle,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 460),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LabeledField(
                label: l10n.pipelineInputKeyLabel,
                tokens: tokens,
                description: l10n.pipelineInputKeyHelp,
                child: CcTextField(
                  controller: _keyCtrl,
                  hintText: 'repoFullName',
                ),
              ),
              const SizedBox(height: 12),
              _LabeledField(
                label: l10n.pipelineInputLabelLabel,
                tokens: tokens,
                child: CcTextField(controller: _labelCtrl),
              ),
              const SizedBox(height: 12),
              _LabeledField(
                label: l10n.pipelineInputTypeLabel,
                tokens: tokens,
                child: CcSelect<PipelineInputType>(
                  options: typeOptions,
                  value: _type,
                  onChanged: (t) => setState(() => _type = t),
                ),
              ),
              if (_type == PipelineInputType.select) ...[
                const SizedBox(height: 12),
                _LabeledField(
                  label: l10n.pipelineInputOptionsLabel,
                  tokens: tokens,
                  child: CcTextField(
                    controller: _optionsCtrl,
                    hintText: 'docs, security, standard',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (_type == PipelineInputType.boolean)
                Row(
                  children: [
                    CcSwitch(
                      value: _defaultBool,
                      onChanged: (v) => setState(() => _defaultBool = v),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.pipelineInputDefaultLabel,
                      style: TextStyle(color: tokens.textPrimary),
                    ),
                  ],
                )
              else if (_type != PipelineInputType.repo)
                _LabeledField(
                  label: l10n.pipelineInputDefaultLabel,
                  tokens: tokens,
                  child: CcTextField(
                    controller: _defaultCtrl,
                    keyboardType: _type == PipelineInputType.number
                        ? TextInputType.number
                        : null,
                  ),
                ),
              const SizedBox(height: 12),
              _LabeledField(
                label: l10n.pipelineInputPlaceholderLabel,
                tokens: tokens,
                child: CcTextField(controller: _placeholderCtrl),
              ),
              const SizedBox(height: 12),
              _LabeledField(
                label: l10n.pipelineInputHelpLabel,
                tokens: tokens,
                child: CcTextField(controller: _helpCtrl),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CcCheckbox(
                    value: _required,
                    onChanged: (v) => setState(() => _required = v),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.pipelineInputRequiredLabel,
                    style: TextStyle(color: tokens.textPrimary),
                  ),
                ],
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
        CcButton(
          onPressed: () {
            final built = _build();
            if (built != null) {
              Navigator.pop(context, built);
            }
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// A form field with a label above it (and an optional help line below),
/// providing a consistent label/description layout for fields that don't
/// render their own.
class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.tokens,
    required this.child,
    this.description,
  });

  final String label;
  final DesignSystemTokens tokens;
  final Widget child;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: tokens.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        child,
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: TextStyle(color: tokens.textTertiary, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
