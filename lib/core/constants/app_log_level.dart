import 'package:control_center/l10n/app_localizations.dart';

/// App-wide log level. Controlled from General Settings and persisted via
/// SharedPreferences. Affects every `AppLog` call and the visibility of
/// debug events in the messaging stream.
///
/// Default:
/// - debug builds: [AppLogLevel.debug]
/// - release builds: [AppLogLevel.none]
enum AppLogLevel {
  /// Silence everything.
  none,

  /// Errors only.
  error,

  /// Errors and warnings.
  warning,

  /// General status messages, starts and completions.
  info,

  /// Detailed traces — search results, internal state.
  debug,

  /// Raw dumps and noisy diagnostics. Use sparingly.
  verbose;

  /// Human-readable label for the settings dropdown.
  String get label {
    switch (this) {
      case AppLogLevel.none:
        return 'None';
      case AppLogLevel.error:
        return 'Error';
      case AppLogLevel.warning:
        return 'Warning';
      case AppLogLevel.info:
        return 'Info';
      case AppLogLevel.debug:
        return 'Debug';
      case AppLogLevel.verbose:
        return 'Verbose';
    }
  }

  /// Short helper-text shown under each option in the settings UI.
  String get description {
    switch (this) {
      case AppLogLevel.none:
        return 'No console output at all.';
      case AppLogLevel.error:
        return 'Only unexpected errors and exceptions.';
      case AppLogLevel.warning:
        return 'Adds warnings and recoverable issues.';
      case AppLogLevel.info:
        return 'Adds lifecycle and status messages.';
      case AppLogLevel.debug:
        return 'Adds detailed traces — for development.';
      case AppLogLevel.verbose:
        return 'Everything. Extremely noisy — use for debugging only.';
    }
  }


  /// Localized label for UI contexts where [AppLocalizations] is available.
  String resolvedLabel(AppLocalizations l10n) {
    switch (this) {
      case AppLogLevel.none:
        return l10n.appLogLevelNoneLabel;
      case AppLogLevel.error:
        return l10n.appLogLevelErrorLabel;
      case AppLogLevel.warning:
        return l10n.appLogLevelWarningLabel;
      case AppLogLevel.info:
        return l10n.appLogLevelInfoLabel;
      case AppLogLevel.debug:
        return l10n.appLogLevelDebugLabel;
      case AppLogLevel.verbose:
        return l10n.appLogLevelVerboseLabel;
    }
  }

  /// Localized helper text for UI contexts where [AppLocalizations] exists.
  String resolvedDescription(AppLocalizations l10n) {
    switch (this) {
      case AppLogLevel.none:
        return l10n.appLogLevelNoneDescription;
      case AppLogLevel.error:
        return l10n.appLogLevelErrorDescription;
      case AppLogLevel.warning:
        return l10n.appLogLevelWarningDescription;
      case AppLogLevel.info:
        return l10n.appLogLevelInfoDescription;
      case AppLogLevel.debug:
        return l10n.appLogLevelDebugDescription;
      case AppLogLevel.verbose:
        return l10n.appLogLevelVerboseDescription;
    }
  }

  /// Parses [value] back into a level, defaulting to [none].
  static AppLogLevel fromName(String? value) {
    if (value == null) {
      return AppLogLevel.none;
    }
    for (final l in AppLogLevel.values) {
      if (l.name == value) {
        return l;
      }
    }
    return AppLogLevel.none;
  }
}
