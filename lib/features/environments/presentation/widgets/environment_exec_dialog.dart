import 'package:cc_domain/features/environments/domain/ports/environment_port.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_feedback.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Runs a one-shot command in one of [services].
Future<void> showEnvironmentExecDialog(
  BuildContext context, {
  required EnvironmentSpaceKey spaceKey,
  required List<String> services,
}) => showCcDialog<void>(
  context: context,
  builder: (_) => EnvironmentExecForm(spaceKey: spaceKey, services: services),
);

/// The exec form and what the command printed.
class EnvironmentExecForm extends ConsumerStatefulWidget {
  /// Creates an [EnvironmentExecForm].
  const EnvironmentExecForm({
    super.key,
    required this.spaceKey,
    required this.services,
  });

  /// The space it runs in.
  final EnvironmentSpaceKey spaceKey;

  /// Where the command can run.
  final List<String> services;

  @override
  ConsumerState<EnvironmentExecForm> createState() =>
      _EnvironmentExecFormState();
}

class _EnvironmentExecFormState extends ConsumerState<EnvironmentExecForm> {
  final _command = TextEditingController();
  late String _service = widget.services.first;
  bool _busy = false;
  EnvironmentExecResult? _result;
  String? _error;

  @override
  void dispose() {
    _command.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final text = _command.text.trim();
    if (text.isEmpty || _busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(environmentRepositoryProvider)
          .exec(
            widget.spaceKey.workspaceId,
            widget.spaceKey.spaceId,
            service: _service,
            // Through sh, so a person can pipe and quote as they would at a
            // prompt. The service's image is the one shell that is certain.
            command: ['sh', '-c', text],
          );
      if (mounted) {
        setState(() => _result = result);
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = environmentFailureMessage(error));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final result = _result;
    final output = result == null
        ? ''
        : [
            result.stdout,
            result.stderr,
          ].where((part) => part.isNotEmpty).join('\n');
    return CcDialog(
      title: l10n.environmentExecTitle,
      onClose: () => Navigator.of(context).pop(),
      maxWidth: 560,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.services.length > 1) ...[
            CcSelect<String>(
              label: l10n.environmentService,
              value: _service,
              options: [
                for (final service in widget.services)
                  CcSelectOption(value: service, label: service),
              ],
              onChanged: (value) => setState(() => _service = value),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          // RTL carve-out: a shell command reads left to right.
          Directionality(
            textDirection: TextDirection.ltr,
            child: CcTextField(
              controller: _command,
              label: l10n.shellCommand,
              autofocus: true,
              errorText: _error,
              onSubmitted: (_) => _run(),
            ),
          ),
          if (result != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.environmentExitCode(result.exitCode),
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: SingleChildScrollView(
                // RTL carve-out: command output is a log.
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    output,
                    style: CcFonts.code(
                      textStyle: CcTypography.caption.copyWith(
                        color: t.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        CcButton(
          onPressed: _busy ? null : _run,
          loading: _busy,
          child: Text(l10n.environmentRun),
        ),
      ],
    );
  }
}
