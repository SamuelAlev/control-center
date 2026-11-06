import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/settings/environment_argv_text.dart';
import 'package:control_center/features/environments/presentation/settings/environment_form_fields.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// A command: argv by default, with the shell behind an explicit choice.
class EnvironmentCommandField extends StatelessWidget {
  /// Creates an [EnvironmentCommandField].
  const EnvironmentCommandField({
    super.key,
    required this.form,
    required this.path,
    required this.label,
    this.showHelp = true,
  });

  /// The form.
  final EnvironmentForm form;

  /// Where the command lives.
  final List<Object> path;

  /// The field's name.
  final String label;

  /// Whether to explain the syntax, which a stack of commands says only once.
  final bool showHelp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final value = form.value(path);
    final shellBody = switch (value) {
      final String text => text,
      final Map<dynamic, dynamic> map when map['shell'] is String =>
        map['shell'] as String,
      _ => null,
    };
    if (value is List && value.any((item) => item is! String)) {
      return SettingsField(
        label: label,
        child: Text(
          l10n.environmentsConditionalArgs,
          style: CcTypography.caption.copyWith(color: t.textTertiary),
        ),
      );
    }
    final argv = value is List ? [for (final item in value) '$item'] : null;
    final issue = form.issue(path);
    return SettingsField(
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // RTL carve-out: a command reads left to right in every locale.
          Directionality(
            textDirection: TextDirection.ltr,
            child: shellBody == null
                ? CcTextField(
                    key: form.key([...path, 'argv']),
                    helperText: showHelp ? l10n.environmentsCommandHelp : null,
                    enabled: form.enabled,
                    initialValue: environmentArgvToText(argv ?? const []),
                    errorText: issue,
                    textStyle: environmentCodeStyle(),
                    onChanged: (text) {
                      final parsed = environmentTextToArgv(text);
                      form.notifier.set(path, parsed.isEmpty ? null : parsed);
                    },
                  )
                : CcTextField(
                    key: form.key([...path, 'shell']),
                    helperText: showHelp ? l10n.environmentsShellHelp : null,
                    enabled: form.enabled,
                    errorText: issue,
                    minLines: 2,
                    maxLines: 8,
                    initialValue: shellBody,
                    textStyle: environmentCodeStyle(),
                    onChanged: (text) =>
                        form.notifier.set(path, {'shell': text}),
                  ),
          ),
          const SizedBox(height: AppSpacing.xs),
          CcCheckbox(
            value: shellBody != null,
            label: Text(l10n.environmentsUseShell),
            onChanged: form.enabled
                ? (useShell) {
                    final body = shellBody ?? '';
                    if (useShell != true && body.contains('\n')) {
                      // Lines are the script's structure; splitting them into
                      // arguments would run something else. It stays shell.
                      CcToastScope.maybeOf(
                        context,
                      )?.show(l10n.environmentsShellStays);
                      return;
                    }
                    form.notifier.restructure(
                      path,
                      useShell == true
                          ? {'shell': environmentArgvToText(argv ?? const [])}
                          : environmentTextToArgv(body),
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

/// A map of variables bound to [path].
class EnvironmentVariablesField extends StatelessWidget {
  /// Creates an [EnvironmentVariablesField].
  const EnvironmentVariablesField({
    super.key,
    required this.form,
    required this.path,
  });

  /// The form.
  final EnvironmentForm form;

  /// Where the map lives.
  final List<Object> path;

  @override
  Widget build(BuildContext context) {
    final current = form.value(path);
    return SettingsKeyValueEditor(
      key: form.key(path),
      enabled: form.enabled,
      entries: [
        if (current is Map)
          for (final entry in current.entries)
            SettingsKeyValuePair('${entry.key}', '${entry.value}'),
      ],
      onChanged: (pairs) => form.notifier.set(
        path,
        pairs.isEmpty ? null : {for (final pair in pairs) pair.key: pair.value},
      ),
    );
  }
}
