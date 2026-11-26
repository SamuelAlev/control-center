import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// Semantic colors for the meetings views, resolved straight from the
/// design-system tokens ([DesignSystemTokens]).
///
/// Read these (or `context.designSystem`) instead of any inherited Material
/// theme so meetings reads correctly in both themes and stays consistent
/// with the rest of the app. The orange brand signal is [DesignSystemTokens
/// .accent]; status hues come from the `success` / `warn` / `danger` tokens.
extension MeetingTheme on BuildContext {
  // `ds` (the non-null token accessor this file used to declare) now lives in
  // cc_ui's DesignSystemTokensBuildContext extension, so every surface shares
  // one accessor instead of meetings owning a private copy.

  /// The orange brand accent used for counts, the active tab underline, the
  /// "enhanced" pill, decision numbers and the local-speaker label.
  Color get mAccent => ds.accent;

  /// A translucent accent wash for soft accent pills.
  Color get mAccentSoft => ds.accentSoft;

  /// Success green — done status icons and "decoding on-device".
  Color get mSuccess => ds.success;

  /// A translucent success wash.
  Color get mSuccessSoft => ds.successSoft;

  /// Caution amber — the "open action items" signal pill.
  Color get mWarn => ds.warn;

  /// A translucent caution wash.
  Color get mWarnSoft => ds.warnSoft;

  /// Recording / destructive red.
  Color get mDanger => ds.danger;

  /// Neutral chip fill used for count chips (fg @ 8%, per the design system's
  /// "count chips on hover-strong" rule).
  Color get mChipFill => ds.hoverStrong;
}

/// Style for the timestamps, counts and pill labels of the meeting surfaces:
/// small muted text in the UI font, like metadata everywhere else in the app.
TextStyle meetingMeta(
  BuildContext context, {
  double fontSize = 11,
  Color? color,
  FontWeight? fontWeight,
  double letterSpacing = 0,
}) => TextStyle(
  fontSize: fontSize,
  color: color ?? context.ds.muted,
  fontWeight: fontWeight,
  letterSpacing: letterSpacing,
);
