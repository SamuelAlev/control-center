import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_kind_text.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/failure_message.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show DateFormat;

/// Agent, tool and server text made safe to show as plain text: control
/// characters (an escape sequence, a bell) and bidirectional overrides (which
/// can make text read differently from what it is) become U+FFFD, and with
/// [singleLine] every line break becomes a space.
///
/// Wake headlines, notes and ask summaries are data, never markup: callers put
/// the result in a [Text], never a markdown or link renderer.
String inertText(String raw, {bool singleLine = false}) {
  final out = StringBuffer();
  for (final rune in raw.runes) {
    final isBreak = rune == 0x0A || rune == 0x0D;
    if (isBreak) {
      out.write(singleLine ? ' ' : '\n');
    } else if (rune == 0x09) {
      out.write(' ');
    } else if (rune < 0x20 ||
        (rune >= 0x7F && rune <= 0x9F) ||
        (rune >= 0x202A && rune <= 0x202E) ||
        (rune >= 0x2066 && rune <= 0x2069)) {
      out.write('\uFFFD');
    } else {
      out.writeCharCode(rune);
    }
  }
  return out.toString();
}

/// A local wall-clock label for [at]: the time alone today, the weekday and
/// date with it otherwise. Times arrive in UTC and show in the viewer's zone.
String workTimeLabel(BuildContext context, DateTime at) {
  final locale = Localizations.localeOf(context).toString();
  final local = at.toLocal();
  final now = DateTime.now();
  final sameDay =
      local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  final time = DateFormat.Hm(locale).format(local);
  return sameDay ? time : '${DateFormat.MMMEd(locale).format(local)} $time';
}

/// A short duration label: `45m`, `3h`, `2d`.
String workDurationLabel(Duration d) => formatCoarseDuration(d);

/// [text] (built from [at]) with the timestamp's hover card and copy.
class WorkTime extends StatelessWidget {
  /// Creates the label.
  const WorkTime({super.key, required this.at, required this.text, this.style});

  /// The instant the label describes.
  final DateTime at;

  /// What the label reads.
  final String text;

  /// Its style.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => AppTimestamp(
    dateTime: at,
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style:
          style ??
          CcTypography.caption.copyWith(color: context.ds.textTertiary),
    ),
  );
}

/// A command, path or raw kind in code style. Always left to right.
class WorkCode extends StatelessWidget {
  /// Creates the code span.
  const WorkCode(this.code, {super.key, this.maxLines = 1});

  /// The code, shown as is (after [inertText]).
  final String code;

  /// Lines before it ellipsizes.
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    // RTL carve-out: commands and machine kinds read left to right.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        inertText(code, singleLine: maxLines == 1),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: CcFonts.code(
          textStyle: CcTypography.caption.copyWith(color: ds.textSecondary),
        ),
      ),
    );
  }
}

/// A sentence for a known kind, or the generic [lead] with the raw [kind] in
/// code style for one this version does not name.
class KindSentence extends StatelessWidget {
  /// Creates the line.
  const KindSentence({
    super.key,
    required this.sentence,
    required this.lead,
    required this.kind,
    this.style,
  });

  /// The localized sentence; null for an unknown kind.
  final String? sentence;

  /// The generic lead-in for an unknown kind.
  final String lead;

  /// The raw kind.
  final String kind;

  /// The sentence's style.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final textStyle =
        style ?? CcTypography.caption.copyWith(color: context.ds.textTertiary);
    final known = sentence;
    if (known != null) {
      return Text(known, style: textStyle);
    }
    return Wrap(
      spacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(lead, style: textStyle),
        WorkCode(kind),
      ],
    );
  }
}

/// The icon for what raised a wake.
IconData wakeOriginIcon(WakeReason reason) => switch (reason) {
  WakeReason.goalContinuation ||
  WakeReason.goalVerification ||
  WakeReason.goalReview => AppIcons.target,
  WakeReason.schedule => AppIcons.calendarClock,
  WakeReason.watch => AppIcons.eye,
  WakeReason.peerReply => AppIcons.reply,
  WakeReason.peerMessage || WakeReason.userMessage => AppIcons.messageCircle,
  WakeReason.childCompleted => AppIcons.checkCheck,
  WakeReason.limitReset => AppIcons.gauge,
  WakeReason.recovery => AppIcons.rotateCcw,
  WakeReason.assignment => AppIcons.userCheck,
  WakeReason.pipelineStep => AppIcons.workflow,
  WakeReason.improvementReview => AppIcons.lightbulb,
};

/// Shows a failed long-running-work action: the refusal's sentence by its
/// `data.kind`, else the shared failure wording.
void showWorkFailure(BuildContext context, Object error) {
  if (!context.mounted) {
    return;
  }
  final l10n = AppLocalizations.of(context);
  final kind = refusalKindOf(error);
  final resetsAt = kind == 'steering_held_by_limit'
      ? DateTime.tryParse(_refusalData(error)?['resets_at'] as String? ?? '')
      : null;
  final message = kind == null
      ? failureMessage(l10n, error)
      : resetsAt != null
      ? l10n.steeringRefusalHeldByLimitAt(workTimeLabel(context, resetsAt))
      : (storageRefusalMessageForKind(l10n, kind) ??
            workRefusalMessage(l10n, kind));
  CcToastScope.maybeOf(context)?.show(message, variant: CcToastVariant.danger);
}

/// A refusal's `data` map, or null for any other error.
Map<Object?, Object?>? _refusalData(Object error) {
  final data = error is RemoteRpcException ? error.data : null;
  return data is Map ? data : null;
}

/// Shows a quiet confirmation of a long-running-work action.
void showWorkNotice(BuildContext context, String message) {
  if (!context.mounted) {
    return;
  }
  CcToastScope.maybeOf(context)?.show(message);
}
