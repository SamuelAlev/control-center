import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/focus_mode/providers/focus_mode_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Available session durations.
const _durations = [25, 50, 60, 90, 120];

String _durationLabel(int minutes) {
  if (minutes < 60) {
    return '${minutes}m';
  }
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

/// Dialog for configuring and starting a focus session.
///
/// On confirm, calls [FocusModeNotifier.activateAndFloat].
class FocusConfigDialog extends ConsumerStatefulWidget {
  /// Creates a [FocusConfigDialog].
  const FocusConfigDialog({super.key});

  @override
  ConsumerState<FocusConfigDialog> createState() => _FocusConfigDialogState();
}

class _FocusConfigDialogState extends ConsumerState<FocusConfigDialog> {
  final _goalController = TextEditingController();
  late int _durationMinutes;
  late bool _blockNotifications;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(focusModeProvider);
    _durationMinutes = state.sessionDurationMinutes;
    _blockNotifications = state.blockNotifications;
    _goalController.text = state.goal ?? '';
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_starting) {
      return;
    }
    setState(() => _starting = true);
    final goal = _goalController.text.trim();
    try {
      await ref
          .read(focusModeProvider.notifier)
          .activateAndFloat(
            durationMinutes: _durationMinutes,
            goal: goal.isEmpty ? null : goal,
            blockNotifications: _blockNotifications,
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _starting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final t = tokens;

    return CcDialog(
      maxWidth: 400,
      title: l10n.focusModeConfigTitle,
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Goal field
            Text(
              l10n.focusModeGoalLabel,
              style: CcTypography.caption.copyWith(
                color: t.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Semantics(
              label: l10n.focusModeGoalLabel,
              textField: true,
              child: CcTextField(
                controller: _goalController,
                autofocus: true,
                onSubmitted: (_) => _start(),
                hintText: l10n.focusModeGoalHint,
              ),
            ),
            const SizedBox(height: 16),
            // Duration picker
            Text(
              l10n.focusModeDurationLabel,
              style: CcTypography.caption.copyWith(
                color: t.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _durations.map((d) {
                return CcChip(
                  label: _durationLabel(d),
                  selected: d == _durationMinutes,
                  onTap: () => setState(() => _durationMinutes = d),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Block notifications toggle
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.focusModeBlockNotifications,
                    style: CcTypography.caption.copyWith(
                      color: tokens.textTertiary,
                    ),
                  ),
                ),
                CcSwitch(
                  value: _blockNotifications,
                  onChanged: (v) => setState(() => _blockNotifications = v),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        CcButton(
          onPressed: _starting ? null : _start,
          child: _starting
              ? const CcSpinner(size: 16)
              : Text(l10n.focusModeStartButton),
        ),
      ],
    );
  }
}
