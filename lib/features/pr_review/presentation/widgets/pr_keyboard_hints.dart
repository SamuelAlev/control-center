import 'dart:io';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// A single keyboard-hint entry: the key-cap glyph(s) and the action they
/// trigger. Multiple [keys] are rendered as adjacent chips.
class PrKeyHint {
  /// Creates a [PrKeyHint].
  const PrKeyHint({required this.keys, required this.label});

  /// One or more key-cap glyphs (e.g. `['J', 'K']` or `['⌘', 'F']`).
  final List<String> keys;

  /// The action the key(s) trigger.
  final String label;
}

/// A quiet footer that teaches a screen's keyboard vocabulary as a row of
/// key-cap chips. Decorative and excluded from the semantics tree — the
/// shortcuts themselves are registered as real keybindings.
class PrKeyboardHints extends StatelessWidget {
  /// Creates a [PrKeyboardHints] from an explicit list of [hints].
  const PrKeyboardHints({super.key, required this.hints});

  /// The queue (PR list) triage vocabulary: move / select / merge / open /
  /// peek.
  factory PrKeyboardHints.queue(AppLocalizations l10n, {Key? key}) {
    return PrKeyboardHints(
      key: key,
      hints: [
        PrKeyHint(keys: const ['J', 'K'], label: l10n.kbMove),
        PrKeyHint(keys: const ['X'], label: l10n.kbSelect),
        PrKeyHint(keys: const ['E'], label: l10n.kbMerge),
        PrKeyHint(keys: const ['↵'], label: l10n.kbOpen),
        PrKeyHint(keys: const ['Space'], label: l10n.kbPeek),
      ],
    );
  }

  /// The user-profile browse vocabulary: move / open / peek / search. No
  /// select or merge — a profile is read-only triage. The search modifier
  /// adapts to the platform (⌘ on macOS, Ctrl elsewhere).
  factory PrKeyboardHints.userProfile(AppLocalizations l10n, {Key? key}) {
    final modifier = Platform.isMacOS ? '⌘' : 'Ctrl';
    return PrKeyboardHints(
      key: key,
      hints: [
        PrKeyHint(keys: const ['J', 'K'], label: l10n.kbMove),
        PrKeyHint(keys: const ['↵'], label: l10n.kbOpen),
        PrKeyHint(keys: const ['Space'], label: l10n.kbPeek),
        PrKeyHint(keys: [modifier, 'F'], label: l10n.kbSearch),
      ],
    );
  }

  /// The PR-detail diff vocabulary: move between files / mark viewed /
  /// collapse / search / switch tabs. The search modifier adapts to the
  /// platform (⌘ on macOS, Ctrl elsewhere).
  factory PrKeyboardHints.diff(AppLocalizations l10n, {Key? key}) {
    final modifier = Platform.isMacOS ? '⌘' : 'Ctrl';
    return PrKeyboardHints(
      key: key,
      hints: [
        PrKeyHint(keys: const ['J', 'K'], label: l10n.kbMove),
        PrKeyHint(keys: const ['V'], label: l10n.kbViewed),
        PrKeyHint(keys: const ['C'], label: l10n.kbCollapse),
        PrKeyHint(keys: [modifier, 'F'], label: l10n.kbSearch),
        PrKeyHint(keys: const ['1', '2'], label: l10n.kbTabs),
      ],
    );
  }

  /// The hints to render, in display order.
  final List<PrKeyHint> hints;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.sm,
        children: [
          for (final hint in hints) _Hint(keys: hint.keys, label: hint.label),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.keys, required this.label});

  final List<String> keys;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final muted = tokens.muted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final k in keys) ...[
          _Kbd(k),
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: muted),
        ),
      ],
    );
  }
}

class _Kbd extends StatelessWidget {
  const _Kbd(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: tokens.panel,
        borderRadius: AppRadii.brSm,
        border: Border.all(color: tokens.borderSecondary),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: tokens.fg,
          fontFamily: 'JetBrains Mono',
          fontSize: 11,
        ),
      ),
    );
  }
}
