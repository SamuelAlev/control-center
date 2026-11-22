import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/space_access_refusal.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/failure_message.dart';
import 'package:control_center/shared/widgets/transcript/util/script_status_line.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// The transcript's run state for a recorded [status], so a record and the
/// `repl` row it came from read the same tag.
ScriptRunState scriptRunStateOf(CodeExecutionStatus status) => switch (status) {
  CodeExecutionStatus.running => ScriptRunState.running,
  CodeExecutionStatus.completed => ScriptRunState.completed,
  CodeExecutionStatus.failed => ScriptRunState.failed,
  CodeExecutionStatus.timedOut => ScriptRunState.timedOut,
  CodeExecutionStatus.cancelled => ScriptRunState.cancelled,
  CodeExecutionStatus.memoryExceeded => ScriptRunState.memoryExceeded,
  CodeExecutionStatus.outputExceeded => ScriptRunState.outputExceeded,
  CodeExecutionStatus.sandboxError => ScriptRunState.sandboxError,
  CodeExecutionStatus.refused => ScriptRunState.refused,
};

/// Why a script that did not complete ended, in one sentence, read from its
/// record's `error_kind` (a fixed vocabulary the host chooses) and, for a
/// script that threw, the name of its error ([errorName], which the script
/// chose: shown as a name, never as a sentence of its own). Null for a kind
/// a recorded script cannot have (the refusal kinds: a refused script is not
/// recorded) or one this client does not know, which the page then shows as
/// its raw value alone.
String? codeExecutionEndReason(
  AppLocalizations l10n,
  String kind, {
  String? errorName,
}) => switch (kind) {
  CodeExecutionErrorKind.scriptError =>
    errorName == null || errorName.trim().isEmpty
        ? l10n.codeExecutionEndedScriptError
        : l10n.codeExecutionEndedScriptErrorNamed(errorName.trim()),
  CodeExecutionErrorKind.stalled => l10n.codeExecutionEndedStalled,
  CodeExecutionErrorKind.cpu => l10n.codeExecutionEndedCpu,
  CodeExecutionErrorKind.heap => l10n.codeExecutionEndedHeap,
  CodeExecutionErrorKind.output => l10n.codeExecutionEndedOutput,
  CodeExecutionErrorKind.deadline => l10n.codeExecutionEndedDeadline,
  CodeExecutionErrorKind.cancelled => l10n.codeExecutionEndedCancelled,
  CodeExecutionErrorKind.shutdown => l10n.codeExecutionEndedShutdown,
  CodeExecutionErrorKind.serverStopped => l10n.codeExecutionEndedServerStopped,
  CodeExecutionErrorKind.internal => l10n.codeExecutionEndedInternal,
  CodeExecutionErrorKind.start => l10n.codeExecutionEndedStart,
  CodeExecutionErrorKind.lockdown => l10n.codeExecutionEndedLockdown,
  CodeExecutionErrorKind.exited => l10n.codeExecutionEndedExited,
  CodeExecutionErrorKind.protocol ||
  CodeExecutionErrorKind.frameTooLarge ||
  CodeExecutionErrorKind.callCap ||
  CodeExecutionErrorKind.outputOverrun ||
  CodeExecutionErrorKind.storeOverrun ||
  CodeExecutionErrorKind.stdinStalled =>
    l10n.codeExecutionEndedRunnerBrokeRules,
  CodeExecutionErrorKind.unresponsive => l10n.codeExecutionEndedUnresponsive,
  CodeExecutionErrorKind.hostError => l10n.codeExecutionEndedHostError,
  _ => null,
};

/// How one nested call ended, in words.
String nestedCallStatusLabel(AppLocalizations l10n, NestedCallStatus s) =>
    switch (s) {
      NestedCallStatus.completed => l10n.codeExecutionCallCompleted,
      NestedCallStatus.failed => l10n.codeExecutionCallFailed,
      NestedCallStatus.denied => l10n.codeExecutionCallDenied,
      NestedCallStatus.cancelled => l10n.codeExecutionCallCancelled,
      NestedCallStatus.timedOut => l10n.codeExecutionCallTimedOut,
      NestedCallStatus.unknownTool => l10n.codeExecutionCallUnknownTool,
      NestedCallStatus.invalidArgs => l10n.codeExecutionCallInvalidArgs,
    };

/// The glyph beside a nested call's status, so the outcome survives
/// grayscale: a check, a cross, a shield for a refusal, a stop sign, a clock.
IconData nestedCallStatusIcon(NestedCallStatus s) => switch (s) {
  NestedCallStatus.completed => AppIcons.check,
  NestedCallStatus.denied => AppIcons.shield,
  NestedCallStatus.cancelled => AppIcons.circleSlash,
  NestedCallStatus.timedOut => AppIcons.clock,
  NestedCallStatus.failed ||
  NestedCallStatus.unknownTool ||
  NestedCallStatus.invalidArgs => AppIcons.x,
};

/// The color of that glyph.
Color nestedCallStatusColor(DesignSystemTokens t, NestedCallStatus s) =>
    switch (s) {
      NestedCallStatus.completed => t.fgSuccessPrimary,
      NestedCallStatus.denied ||
      NestedCallStatus.timedOut => t.fgWarningPrimary,
      NestedCallStatus.cancelled => t.textTertiary,
      NestedCallStatus.failed ||
      NestedCallStatus.unknownTool ||
      NestedCallStatus.invalidArgs => t.textErrorPrimary,
    };

/// What the gate decided for a nested call, or that the call never reached
/// it (an unknown tool, arguments that were not an object).
String gateDecisionLabel(AppLocalizations l10n, NestedCallGateDecision? d) =>
    switch (d) {
      NestedCallGateDecision.allowed => l10n.codeExecutionGateAllowed,
      NestedCallGateDecision.approved => l10n.codeExecutionGateApproved,
      NestedCallGateDecision.denied => l10n.codeExecutionGateDenied,
      null => l10n.codeExecutionGateNotReached,
    };

/// A duration in milliseconds, in the reader's locale: `840 ms`, `2.4 s`,
/// `3 min 05 s`.
String formatScriptDuration(AppLocalizations l10n, int ms) {
  if (ms < 1000) {
    return l10n.codeModeUnitMilliseconds(
      NumberFormat.decimalPattern(l10n.localeName).format(ms),
    );
  }
  if (ms < 60000) {
    final seconds = NumberFormat.decimalPatternDigits(
      locale: l10n.localeName,
      decimalDigits: 1,
    ).format(ms / 1000);
    return l10n.codeModeUnitSeconds(seconds);
  }
  final minutes = ms ~/ 60000;
  final seconds = (ms % 60000) ~/ 1000;
  return l10n.codeModeUnitMinutesSeconds(
    NumberFormat.decimalPattern(l10n.localeName).format(minutes),
    NumberFormat('00', l10n.localeName).format(seconds),
  );
}

/// The `data.kind` values `codeMode.setWorkspaceSetting` refuses with.
abstract final class CodeModeRefusalKinds {
  /// A limit the server does not know.
  static const limitUnknown = 'code_mode_limit_unknown';

  /// A limit outside its bound.
  static const limitOutOfRange = 'code_mode_limit_out_of_range';

  /// A setting key the server does not know.
  static const unknownSetting = 'code_mode_unknown_setting';
}

/// The sentence for a refused code mode settings write, read by `data.kind`;
/// anything else falls back to [failureMessage].
String codeModeWriteFailure(AppLocalizations l10n, Object error) =>
    switch (refusalKindOf(error)) {
      CodeModeRefusalKinds.limitUnknown => l10n.codeModeRefusedLimitUnknown,
      CodeModeRefusalKinds.limitOutOfRange =>
        l10n.codeModeRefusedLimitOutOfRange,
      CodeModeRefusalKinds.unknownSetting => l10n.codeModeRefusedUnknownSetting,
      _ => failureMessage(l10n, error),
    };

/// Why an execution record could not be opened, in words.
///
/// Its source and output are content of the space its run worked in, so the
/// server refuses it the way it refuses opening that space: by kind, which
/// [spaceAccessFailureOf] words. A space whose gate refuses without a kind
/// (a pull request review space) still reads as "you cannot read that
/// space", never as a blank page.
String codeExecutionLoadFailure(AppLocalizations l10n, Object error) {
  final space = spaceAccessFailureOf(l10n, error);
  if (space != null) {
    return space.message;
  }
  if (error is RemoteRpcException && error.code == RpcErrorCodes.unauthorized) {
    return l10n.codeExecutionRefusedSpace;
  }
  return failureMessage(l10n, error);
}
