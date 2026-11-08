import 'package:cc_domain/features/settings/domain/entities/claude_session_settings.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/providers/claude_account_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// How the server keeps long Claude Code conversations in check, shown in the
/// Claude Code runner's detail pane.
class ClaudeCompactionSection extends ConsumerStatefulWidget {
  /// Creates a [ClaudeCompactionSection].
  const ClaudeCompactionSection({super.key});

  @override
  ConsumerState<ClaudeCompactionSection> createState() =>
      _ClaudeCompactionSectionState();
}

class _ClaudeCompactionSectionState
    extends ConsumerState<ClaudeCompactionSection> {
  final _window = TextEditingController();
  final _focus = FocusNode();
  ClaudeSessionSettings? _saved;
  bool _invalid = false;
  bool _saveFailed = false;
  int _savesInFlight = 0;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        _commitWindow();
      }
    });
  }

  @override
  void dispose() {
    _window.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Takes what the server holds, unless the operator is mid-edit. What it
  /// reports during a save is about to be out of date.
  void _adopt(ClaudeSessionSettings settings) {
    if (_saved == settings || _savesInFlight > 0) {
      return;
    }
    _saved = settings;
    if (!_focus.hasFocus) {
      _window.text = settings.autoCompactWindow?.toString() ?? '';
    }
  }

  void _commitWindow() {
    final saved = _saved;
    if (saved == null) {
      return;
    }
    final text = _window.text.trim();
    final parsed = int.tryParse(text);
    final valid =
        text.isEmpty ||
        (parsed != null &&
            parsed >= ClaudeSessionSettings.minAutoCompactWindow &&
            parsed <= ClaudeSessionSettings.maxAutoCompactWindow);
    setState(() => _invalid = !valid);
    if (!valid || parsed == saved.autoCompactWindow) {
      return;
    }
    _save(
      ClaudeSessionSettings(
        autoCompactWindow: parsed,
        compactIdleBeforeCacheExpires: saved.compactIdleBeforeCacheExpires,
      ),
    );
  }

  Future<void> _save(ClaudeSessionSettings settings) async {
    final repo = ref.read(claudeAccountsRepositoryProvider);
    final previous = _saved;
    // Held from the start: Enter saves, and the blur that follows must see
    // that value rather than send it a second time.
    _saved = settings;
    _savesInFlight++;
    try {
      await repo.setSessionSettings(settings);
      _savesInFlight--;
      if (!mounted) {
        return;
      }
      setState(() => _saveFailed = false);
      ref.invalidate(claudeSessionSettingsProvider);
    } on Object {
      _savesInFlight--;
      _saved = previous;
      if (mounted) {
        setState(() => _saveFailed = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // The demo refuses these ops: nothing here could be read or saved.
    if (ref.watch(isDemoServerProvider)) {
      return const SizedBox.shrink();
    }
    final settings = ref.watch(claudeSessionSettingsProvider).value;
    if (settings == null) {
      return const SizedBox.shrink();
    }
    _adopt(settings);
    final l10n = AppLocalizations.of(context);
    final numbers = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    final min = numbers.format(ClaudeSessionSettings.minAutoCompactWindow);
    final max = numbers.format(ClaudeSessionSettings.maxAutoCompactWindow);
    return SettingsGroup(
      title: l10n.claudeCompactionTitle,
      description: l10n.claudeCompactionDescription,
      showRule: true,
      gap: AppSpacing.md,
      children: [
        SettingsField(
          label: l10n.claudeAutoCompactLabel,
          hint: l10n.claudeAutoCompactHint(min, max),
          error: _invalid
              ? l10n.claudeAutoCompactInvalid(min, max)
              : _saveFailed
              ? l10n.claudeCompactionSaveFailed
              : null,
          optional: true,
          controlWidth: 160,
          child: CcTextField(
            controller: _window,
            focusNode: _focus,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => _commitWindow(),
          ),
        ),
        SettingsToggle(
          title: l10n.claudeIdleCompactLabel,
          description: l10n.claudeIdleCompactDescription(
            numbers.format(ClaudeSessionSettings.minIdleCompactTokens),
          ),
          value: settings.compactIdleBeforeCacheExpires,
          onChanged: (value) => _save(
            ClaudeSessionSettings(
              autoCompactWindow: (_saved ?? settings).autoCompactWindow,
              compactIdleBeforeCacheExpires: value,
            ),
          ),
        ),
      ],
    );
  }
}
