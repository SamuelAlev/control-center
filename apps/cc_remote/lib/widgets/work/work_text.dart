import 'package:cc_remote/format.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/work_kind_text.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// Text that came from an agent, a tool or a forge, made inert for display:
/// control and bidirectional-override characters are replaced so the text
/// cannot reorder the line around it. It is shown as plain text, never as
/// markdown or the label of a control.
String inertText(String raw, {bool singleLine = false}) {
  final out = StringBuffer();
  for (final rune in raw.runes) {
    final isBidi =
        (rune >= 0x202A && rune <= 0x202E) ||
        (rune >= 0x2066 && rune <= 0x2069) ||
        rune == 0x200E ||
        rune == 0x200F ||
        rune == 0x061C;
    final isNewline = rune == 0x0A;
    final isControl =
        (rune < 0x20 && rune != 0x09 && !isNewline) ||
        (rune >= 0x7F && rune < 0xA0);
    if (isBidi || isControl || (singleLine && isNewline)) {
      out.write(singleLine && isNewline ? ' ' : '�');
    } else {
      out.writeCharCode(rune);
    }
  }
  return out.toString();
}

/// A server instant (UTC on the wire) in the viewer's zone: the clock time
/// today, the short date and clock time otherwise.
String workTime(BuildContext context, DateTime at) =>
    sameDay(at, DateTime.now())
    ? clockTime(context, at)
    : '${shortDate(context, at)} ${clockTime(context, at)}';

/// A command, trigger, path or raw kind in code style.
class WorkCode extends StatelessWidget {
  const WorkCode(this.text, {super.key, this.maxLines});

  final String text;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    // RTL carve-out: commands, triggers and machine kinds read left to right.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        inertText(text),
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
        style: CcTypography.monoNum.copyWith(color: t.textPrimary),
      ),
    );
  }
}

/// Text an agent or a tool wrote, quoted under a heading: plain text marked
/// off by a hairline so it never reads as the app's own words.
class WorkQuote extends StatelessWidget {
  const WorkQuote(this.text, {super.key, this.maxLines});

  final String text;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return DecoratedBox(
      decoration: BoxDecoration(
        border: BorderDirectional(start: BorderSide(color: t.lineStrong)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 10),
        child: Text(
          inertText(text),
          maxLines: maxLines,
          overflow: maxLines == null ? null : TextOverflow.ellipsis,
          style: CcTypography.bodySm.copyWith(color: t.textSecondary),
        ),
      ),
    );
  }
}

/// A sentence for a known kind, or the generic lead-in with the raw kind in
/// code style when this version does not name it.
class WorkKindLine extends StatelessWidget {
  const WorkKindLine({
    super.key,
    required this.sentence,
    required this.kind,
    this.lead,
    this.color,
  });

  final String? sentence;
  final String kind;
  final String? lead;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final style = CcTypography.bodySm.copyWith(color: color ?? t.textSecondary);
    if (sentence != null) return Text(sentence!, style: style);
    return Wrap(
      spacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          lead ?? AppLocalizations.of(context).workKindUnknown,
          style: style,
        ),
        WorkCode(kind),
      ],
    );
  }
}

/// A failed action: the refusal's sentence, or the generic lead-in and the
/// raw kind, in the danger text color.
class WorkFailureLine extends StatelessWidget {
  const WorkFailureLine({
    super.key,
    required this.error,
    this.schedule = false,
  });

  final Object error;
  final bool schedule;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final failure = workFailure(
      AppLocalizations.of(context),
      error,
      schedule: schedule,
    );
    return WorkKindLine(
      sentence: failure.code == null ? failure.text : null,
      kind: failure.code ?? '',
      lead: failure.text,
      color: t.textErrorPrimary,
    );
  }
}
