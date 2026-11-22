import 'dart:math' as math;

import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// The unit a limit is edited in. The server stores milliseconds and bytes;
/// a person thinks in seconds and mebibytes, and every bound is a whole
/// number of these units, so nothing is lost converting.
enum CodeModeLimitUnit {
  /// Seconds (stored as milliseconds).
  seconds(1000),

  /// Mebibytes (stored as bytes).
  mebibytes(1024 * 1024),

  /// Tool calls.
  calls(1),

  /// Model tokens.
  tokens(1);

  const CodeModeLimitUnit(this.factor);

  /// Stored value per unit.
  final int factor;

  /// The short unit shown after the number in the field.
  String suffix(AppLocalizations l10n) => switch (this) {
    CodeModeLimitUnit.seconds => l10n.codeModeSuffixSeconds,
    CodeModeLimitUnit.mebibytes => l10n.codeModeSuffixMebibytes,
    CodeModeLimitUnit.calls => l10n.codeModeSuffixCalls,
    CodeModeLimitUnit.tokens => l10n.codeModeSuffixTokens,
  };
}

/// One adjustable limit as the settings form edits it.
class CodeModeLimitSpec {
  /// Creates a spec. [ceiling] (stored units) lowers the domain's ceiling to
  /// one the server owner set for every workspace.
  const CodeModeLimitSpec(this.bound, this.unit, {this.ceiling});

  /// The domain's bound: key, default, floor and ceiling (stored units).
  final CodeModeLimitBound bound;

  /// The unit it is edited in.
  final CodeModeLimitUnit unit;

  /// The server owner's ceiling, in stored units, when lower than the
  /// domain's; null for none.
  final int? ceiling;

  /// The key the server stores it under.
  String get key => bound.key;

  /// The value a script gets when the workspace sets none, in the edited
  /// unit: the default, held to [max] (the server holds it there too).
  int get defaultValue => math.min(bound.defaultValue ~/ unit.factor, max);

  /// The lowest value a workspace may set, in the edited unit.
  int get min => bound.floor ~/ unit.factor;

  /// The highest value a workspace may set, in the edited unit: the domain's
  /// ceiling, or the server owner's when that is lower.
  int get max => math.max(
    min,
    math.min(bound.ceiling, ceiling ?? bound.ceiling) ~/ unit.factor,
  );

  /// [stored] (server units) in the edited unit.
  int display(int stored) => stored ~/ unit.factor;

  /// The field's label.
  String label(AppLocalizations l10n) => switch (bound.key) {
    'wall_clock_ms' => l10n.codeModeLimitWallClock,
    'cpu_ms' => l10n.codeModeLimitCpu,
    'heap_bytes' => l10n.codeModeLimitHeap,
    'max_nested_calls' => l10n.codeModeLimitNestedCalls,
    'max_in_flight_calls' => l10n.codeModeLimitInFlight,
    _ => l10n.codeModeLimitOutputTokens,
  };

  /// One sentence on what the limit bounds.
  String description(AppLocalizations l10n) => switch (bound.key) {
    'wall_clock_ms' => l10n.codeModeLimitWallClockHelp,
    'cpu_ms' => l10n.codeModeLimitCpuHelp,
    'heap_bytes' => l10n.codeModeLimitHeapHelp,
    'max_nested_calls' => l10n.codeModeLimitNestedCallsHelp,
    'max_in_flight_calls' => l10n.codeModeLimitInFlightHelp,
    _ => l10n.codeModeLimitOutputTokensHelp,
  };

  /// The default and the bounds, under the field.
  String range(AppLocalizations l10n) {
    final n = NumberFormat.decimalPattern(l10n.localeName);
    return l10n.codeModeLimitRange(
      n.format(defaultValue),
      n.format(min),
      n.format(max),
    );
  }

  /// Why [text] cannot be stored, or null when it can.
  String? validate(AppLocalizations l10n, String text) {
    final value = parse(text);
    if (value == null || value < min || value > max) {
      final n = NumberFormat.decimalPattern(l10n.localeName);
      return l10n.codeModeLimitOutOfRange(n.format(min), n.format(max));
    }
    return null;
  }

  /// [text] as a whole number in the edited unit, or null when it is not
  /// one. The field accepts digits only, so there are no separators to read.
  int? parse(String text) => int.tryParse(text.trim());
}

/// Every limit a workspace may adjust, in the order the status reports them,
/// with the memory limit held to the server owner's heap ceiling
/// ([maxHeapBytes], from `codeMode.status`): the server clamps every
/// script's heap to it, so a higher value could be stored but never used.
List<CodeModeLimitSpec> codeModeLimitSpecs({required int maxHeapBytes}) => [
  for (final spec in kCodeModeLimitSpecs)
    if (spec.bound.key == CodeModeLimits.heap.key)
      CodeModeLimitSpec(spec.bound, spec.unit, ceiling: maxHeapBytes)
    else
      spec,
];

/// Every limit a workspace may adjust, in the order the status reports them,
/// with the domain's own bounds.
const List<CodeModeLimitSpec> kCodeModeLimitSpecs = [
  CodeModeLimitSpec(CodeModeLimits.wallClock, CodeModeLimitUnit.seconds),
  CodeModeLimitSpec(CodeModeLimits.nestedCalls, CodeModeLimitUnit.calls),
  CodeModeLimitSpec(CodeModeLimits.inFlightCalls, CodeModeLimitUnit.calls),
  CodeModeLimitSpec(CodeModeLimits.outputTokens, CodeModeLimitUnit.tokens),
  CodeModeLimitSpec(CodeModeLimits.heap, CodeModeLimitUnit.mebibytes),
  CodeModeLimitSpec(CodeModeLimits.cpu, CodeModeLimitUnit.seconds),
];

/// The stored value of [spec] in [limits] (server units).
int codeModeLimitValue(CodeModeLimits limits, CodeModeLimitSpec spec) =>
    limits.toJson()[spec.key]!;
