import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/settings/environment_form_fields.dart';
import 'package:control_center/features/environments/providers/environment_compose_services.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A compose component: which services run and which ports speak HTTP.
class EnvironmentComposeForm extends ConsumerWidget {
  /// Creates an [EnvironmentComposeForm].
  const EnvironmentComposeForm({
    super.key,
    required this.form,
    required this.path,
  });

  /// The draft.
  final EnvironmentForm form;

  /// Where this component lives.
  final List<Object> path;

  /// The repo the compose file sits in: the role the component names, or the
  /// first one.
  String? _repoId() {
    final repos = form.value(const ['repos']);
    if (repos is! Map || repos.isEmpty) {
      return null;
    }
    final role = form.value([...path, 'cwd', 'role']);
    final bound = repos[role] ?? repos.values.first;
    return bound is Map ? bound['repoId'] as String? : null;
  }

  void _toggle(String key, String service, bool selected) {
    final current = form.strings([...path, key]);
    final next = [
      for (final each in current)
        if (each != service) each,
      if (selected) service,
    ];
    form.notifier.set([...path, key], next.isEmpty ? null : next);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final repoId = _repoId();
    final selected = form.strings([...path, 'services']);
    final http = form.strings([...path, 'http']);
    final file = form.value([...path, 'file']) as String?;
    final cwd = form.value([...path, 'cwd', 'path']) as String?;
    final found = repoId == null || repoId.isEmpty
        ? const AsyncValue<List<EnvironmentComposeService>>.data([])
        : ref.watch(
            environmentComposeServicesProvider((
              workspaceId: form.workspaceId,
              repoId: repoId,
              file: file,
              directory: cwd,
            )),
          );
    final services = [
      ...?found.value,
      // A service the file no longer lists still has to be uncheckable.
      for (final name in selected)
        if (!(found.value ?? const []).any((each) => each.name == name))
          EnvironmentComposeService(name: name),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EnvironmentTextField(
          form: form,
          path: [...path, 'file'],
          label: l10n.environmentsComposeFile,
          hint: 'compose.yaml',
          mono: true,
        ),
        environmentFieldGap,
        SettingsField(
          label: l10n.environmentsComposeServices,
          hint: l10n.environmentsComposeServicesHint,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (found.isLoading) const CcSpinner(size: 14),
              if (!found.isLoading && services.isEmpty)
                Text(
                  l10n.environmentsComposeNoFile,
                  style: CcTypography.caption.copyWith(color: t.textTertiary),
                ),
              for (final service in services)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxs),
                  child: Row(
                    children: [
                      Expanded(
                        child: CcCheckbox(
                          value: selected.contains(service.name),
                          label: Text(service.name),
                          onChanged: form.enabled
                              ? (value) => _toggle(
                                  'services',
                                  service.name,
                                  value == true,
                                )
                              : null,
                        ),
                      ),
                      if (service.ports.isNotEmpty) ...[
                        // RTL carve-out: port numbers are machine values.
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            service.ports.join(', '),
                            style: CcFonts.code(
                              textStyle: CcTypography.caption.copyWith(
                                color: t.textTertiary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        CcCheckbox(
                          value: http.contains(service.name),
                          label: Text(l10n.environmentsComposeHttp),
                          onChanged: form.enabled
                              ? (value) =>
                                    _toggle('http', service.name, value == true)
                              : null,
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
        environmentFieldGap,
        EnvironmentCheckField(
          form: form,
          path: [...path, 'build'],
          label: l10n.environmentsComposeBuild,
          fallback: true,
        ),
        environmentFieldGap,
        EnvironmentNumberField(
          form: form,
          path: [...path, 'timeout'],
          label: l10n.environmentsTimeoutSeconds,
        ),
      ],
    );
  }
}
