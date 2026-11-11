import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/username.dart';
import 'package:cc_domain/core/domain/value_objects/username_check.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Where a username being typed stands.
enum UsernameStatus {
  /// The person's own current username, unchanged.
  current,

  /// Waiting for the server to say whether it is free.
  checking,

  /// Free: saving it would succeed right now.
  available,

  /// Breaks the username rule.
  invalid,

  /// Nobody may hold it.
  reserved,

  /// Someone else has it.
  taken,

  /// The check could not be made. Saving is still allowed: the server
  /// decides then.
  unknown;

  /// Whether a save must wait or would be refused.
  bool get blocksSave =>
      this == checking || this == invalid || this == reserved || this == taken;

  static UsernameStatus _of(UsernameRefusal refusal) => switch (refusal) {
    UsernameRefusal.invalid => invalid,
    UsernameRefusal.reserved => reserved,
    UsernameRefusal.taken => taken,
  };
}

/// The live availability of a username being typed.
///
/// The rule is checked on every keystroke; only a name that passes it is
/// sent to the server, after [debounce], and an answer for anything but the
/// latest text is dropped.
class UsernameAvailability extends ChangeNotifier {
  /// Creates the check for a person whose username is `current`.
  UsernameAvailability({
    required this.check,
    required this._current,
    this.debounce = const Duration(milliseconds: 350),
  });

  /// Asks the server about a name.
  final Future<UsernameCheck> Function(String handle) check;

  /// How long typing must pause before the server is asked.
  final Duration debounce;

  String _current;
  String _normalized = '';
  UsernameStatus _status = UsernameStatus.current;
  Timer? _timer;
  int _generation = 0;
  bool _disposed = false;

  /// Where the latest text stands.
  UsernameStatus get status => _status;

  /// What the latest text would be stored as.
  String get normalized => _normalized.isEmpty ? _current : _normalized;

  /// Re-checks after the text changed to [raw].
  void update(String raw) {
    final normalized = Username.normalizeInput(raw);
    _normalized = normalized;
    _timer?.cancel();
    final generation = ++_generation;
    if (normalized == _current) {
      return _set(UsernameStatus.current);
    }
    if (Username.check(normalized) case final refusal?) {
      return _set(UsernameStatus._of(refusal));
    }
    _set(UsernameStatus.checking);
    _timer = Timer(debounce, () async {
      UsernameStatus next;
      try {
        final answer = await check(normalized);
        next = answer.available
            ? UsernameStatus.available
            : UsernameStatus._of(answer.reason ?? UsernameRefusal.invalid);
      } on Object {
        next = UsernameStatus.unknown;
      }
      if (generation == _generation) {
        _set(next);
      }
    });
  }

  /// Records that a save refused the latest text for [reason].
  void refused(UsernameRefusal reason) {
    _timer?.cancel();
    _generation++;
    _set(UsernameStatus._of(reason));
  }

  /// Records that [handle] is now the person's username.
  void saved(String handle) {
    _timer?.cancel();
    _generation++;
    _current = handle;
    _normalized = handle;
    _set(UsernameStatus.current);
  }

  void _set(UsernameStatus status) {
    if (_disposed || status == _status) {
      return;
    }
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}

/// The username input: the text itself stays left to right in every
/// language, with what the server or the rule says about it underneath.
class UsernameField extends StatelessWidget {
  /// Creates a [UsernameField].
  const UsernameField({
    super.key,
    required this.controller,
    required this.availability,
    this.enabled = true,
    this.autofocus = false,
    this.onSubmitted,
  });

  /// The typed text.
  final TextEditingController controller;

  /// The live check, fed by this field.
  final UsernameAvailability availability;

  /// Whether the field takes input.
  final bool enabled;

  /// Whether the field takes focus when shown.
  final bool autofocus;

  /// Called on submit from the keyboard.
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return ListenableBuilder(
      listenable: availability,
      builder: (context, _) {
        final status = availability.status;
        final error = switch (status) {
          UsernameStatus.invalid => l10n.usernameInvalid,
          UsernameStatus.reserved => l10n.usernameReserved,
          UsernameStatus.taken => l10n.usernameTaken,
          _ => null,
        };
        final normalized = availability.normalized;
        final hint = switch (status) {
          UsernameStatus.current => l10n.usernameRule,
          UsernameStatus.checking => l10n.checkingEllipsis,
          UsernameStatus.available =>
            normalized == controller.text.trim()
                ? l10n.usernameAvailable
                : l10n.usernameAvailableAs(normalized),
          UsernameStatus.unknown => l10n.usernameCheckFailed,
          _ => null,
        };
        final glyph = switch (status) {
          UsernameStatus.checking => const CcSpinner(size: 12),
          UsernameStatus.available => Icon(
            AppIcons.circleCheck,
            size: 14,
            color: t.fgSuccessPrimary,
          ),
          UsernameStatus.invalid ||
          UsernameStatus.reserved ||
          UsernameStatus.taken => Icon(
            AppIcons.circleX,
            size: 14,
            color: t.fgErrorPrimary,
          ),
          _ => null,
        };
        return SettingsField(
          label: l10n.usernameLabel,
          layout: SettingsFieldLayout.stacked,
          hint: hint,
          error: error,
          // RTL carve-out: a username is ASCII typed left to right; only its
          // label and the status under it follow the reading direction.
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: CcTextField(
              controller: controller,
              enabled: enabled,
              autofocus: autofocus,
              prefix: Text(
                '@',
                style: CcTypography.bodySm.copyWith(color: t.textTertiary),
              ),
              suffix: glyph == null
                  ? null
                  : Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: AppSpacing.xs,
                      ),
                      child: glyph,
                    ),
              onChanged: availability.update,
              onSubmitted: onSubmitted,
            ),
          ),
        );
      },
    );
  }
}
