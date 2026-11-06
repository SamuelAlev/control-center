import 'dart:convert';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/settings/environment_editor_state.dart';
import 'package:control_center/features/environments/presentation/settings/environment_form_fields.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The workspace's side of a file-linked definition: which repo each role is,
/// and any other field as JSON. The file's own text is read-only here.
class EnvironmentOverridesForm extends ConsumerStatefulWidget {
  /// Creates an [EnvironmentOverridesForm].
  const EnvironmentOverridesForm({
    super.key,
    required this.form,
    required this.enabled,
  });

  /// The draft.
  final EnvironmentForm form;

  /// False for someone who can read but not change definitions.
  final bool enabled;

  @override
  ConsumerState<EnvironmentOverridesForm> createState() =>
      _EnvironmentOverridesFormState();
}

class _EnvironmentOverridesFormState
    extends ConsumerState<EnvironmentOverridesForm> {
  String? _jsonError;

  void _applyJson(String text) {
    try {
      final decoded = text.trim().isEmpty
          ? <String, dynamic>{}
          : jsonDecode(text);
      if (decoded is! Map) {
        throw const FormatException('{ }');
      }
      widget.form.notifier.replaceOverrides(Map<String, dynamic>.from(decoded));
      widget.form.notifier.setJsonError(null);
      setState(() => _jsonError = null);
    } on FormatException catch (error) {
      widget.form.notifier.setJsonError(error.message);
      setState(() => _jsonError = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final form = widget.form;
    final state = form.state;
    final repos =
        ref.watch(reposForWorkspaceProvider(form.workspaceId)).value ??
        const <Repo>[];
    final roles = form.value(const ['repos']);
    final error = _jsonError;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: SectionCard(
        label: l10n.environmentsOverrides,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.environmentsOverridesHelp, style: CcTypography.caption),
            const SizedBox(height: AppSpacing.md),
            if (roles is Map)
              for (final role in roles.keys)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: CcSelect<String>(
                    key: ValueKey('${state.revision}:override:$role'),
                    label: '$role',
                    enabled: widget.enabled,
                    value:
                        environmentJsonGet(state.overrides, [
                              'repos',
                              '$role',
                              'repoId',
                            ])
                            as String? ??
                        _boundRepo(roles[role]),
                    options: [
                      for (final repo in repos)
                        CcSelectOption(value: repo.id, label: repo.name),
                    ],
                    onChanged: (repoId) => form.notifier.setOverride([
                      'repos',
                      '$role',
                      'repoId',
                    ], repoId),
                  ),
                ),
            // RTL carve-out: JSON reads left to right in every locale.
            Directionality(
              textDirection: TextDirection.ltr,
              child: CcTextField(
                key: ValueKey('${state.revision}:overrides'),
                label: l10n.environmentsTabJson,
                enabled: widget.enabled,
                minLines: 4,
                maxLines: 16,
                initialValue: environmentPrettyJson(state.overrides),
                errorText: error == null
                    ? null
                    : l10n.environmentsJsonInvalid(error),
                onChanged: _applyJson,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The repo id a role in the file names, or null.
String? _boundRepo(Object? role) =>
    role is Map && role['repoId'] is String ? role['repoId'] as String : null;
