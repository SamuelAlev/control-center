import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/ports/environment_port.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:collection/collection.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_option_field.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the Start form returned.
typedef EnvironmentStartChoice = ({
  String definitionId,
  Map<String, dynamic> options,
});

/// Asks which definition to start and with which options.
Future<EnvironmentStartChoice?> showEnvironmentStartDialog(
  BuildContext context, {
  required String workspaceId,
  required List<EnvironmentDefinitionRecord> definitions,
  Map<String, dynamic> initialOptions = const {},
}) => showCcDialog<EnvironmentStartChoice>(
  context: context,
  builder: (_) => EnvironmentStartForm(
    workspaceId: workspaceId,
    definitions: definitions,
    initialOptions: initialOptions,
  ),
);

/// The Start form.
class EnvironmentStartForm extends StatefulWidget {
  /// Creates an [EnvironmentStartForm].
  const EnvironmentStartForm({
    super.key,
    required this.workspaceId,
    required this.definitions,
    this.initialOptions = const {},
  });

  /// The owning workspace.
  final String workspaceId;

  /// What can be started.
  final List<EnvironmentDefinitionRecord> definitions;

  /// Values to start from, such as the ones the environment last used.
  final Map<String, dynamic> initialOptions;

  @override
  State<EnvironmentStartForm> createState() => _EnvironmentStartFormState();
}

class _EnvironmentStartFormState extends State<EnvironmentStartForm> {
  late String _definitionId = widget.definitions.first.id;
  late Map<String, dynamic> _options = _defaults();

  EnvironmentDefinitionRecord get _record =>
      widget.definitions.firstWhere((record) => record.id == _definitionId);

  List<EnvironmentOption> get _fields =>
      environmentDefinitionOf(_record)?.options ?? const [];

  Map<String, dynamic> _defaults() => {
    for (final option in _fields)
      option.key:
          widget.initialOptions[option.key] ??
          option.defaultValue ??
          emptyEnvironmentOptionValue(option),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fields = _fields;
    return CcDialog(
      title: l10n.environmentStartTitle,
      onClose: () => Navigator.of(context).pop(),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.definitions.length > 1) ...[
              CcSelect<String>(
                label: l10n.environmentDefinition,
                value: _definitionId,
                options: [
                  for (final record in widget.definitions)
                    CcSelectOption(value: record.id, label: record.name),
                ],
                onChanged: (value) => setState(() {
                  _definitionId = value;
                  _options = _defaults();
                }),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            for (final option in fields) ...[
              EnvironmentOptionField(
                option: option,
                value: _options[option.key],
                onChanged: (value) =>
                    setState(() => _options[option.key] = value),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            _ChecksPreview(
              key: ValueKey(_definitionId),
              checkKey: (
                workspaceId: widget.workspaceId,
                definitionId: _definitionId,
              ),
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
          onPressed: () => Navigator.of(
            context,
          ).pop((definitionId: _definitionId, options: _options)),
          child: Text(l10n.startLabel),
        ),
      ],
    );
  }
}

/// Failing host checks, shown before a Start that would trip on them.
///
/// Checks are admin-gated, so a member gets no rows rather than an error: the
/// form is still usable, and a real failure lands on the component.
class _ChecksPreview extends ConsumerWidget {
  const _ChecksPreview({super.key, required this.checkKey});

  final EnvironmentDefinitionKey checkKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final failing = ref
        .watch(environmentChecksProvider(checkKey))
        .maybeWhen(
          data: (checks) => checks.whereNot((check) => check.ok).toList(),
          orElse: () => const <EnvironmentCheckResult>[],
        );
    if (failing.isEmpty) {
      return const SizedBox.shrink();
    }
    return CcAlert(
      variant: CcAlertVariant.warning,
      title: l10n.environmentChecksFailing,
      description: Text(failing.map((check) => check.label).join('\n')),
      icon: AppIcons.triangleAlert,
      trailing: Text(
        '${failing.length}',
        style: CcTypography.caption.copyWith(color: t.textSecondary),
      ),
    );
  }
}
