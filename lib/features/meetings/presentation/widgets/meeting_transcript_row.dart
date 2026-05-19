import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_segment.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_format.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// One transcript line: a monospaced timestamp beside a speaker label and the
/// transcribed text. Once diarization has run a segment carries a
/// [MeetingSegment.speakerLabel] (e.g. `Person 1`); that label — or the name the
/// user gave it — is shown in place of the coarse "You" / "Others". The
/// unlabeled local mic stays orange "You" with a faint accent wash. Tapping a
/// diarized label invokes [onRenameSpeaker]. An optional [query] highlights
/// matches.
class MeetingTranscriptRow extends StatelessWidget {
  /// Creates a [MeetingTranscriptRow].
  const MeetingTranscriptRow({
    super.key,
    required this.speaker,
    required this.startMs,
    required this.text,
    this.speakerLabel,
    this.speakerName,
    this.onRenameSpeaker,
    this.query = '',
    this.timeColumnWidth = 58,
    this.compact = false,
  });

  /// Builds a row from a [MeetingSegment].
  MeetingTranscriptRow.fromSegment(
    MeetingSegment segment, {
    super.key,
    this.speakerName,
    this.onRenameSpeaker,
    this.query = '',
    this.timeColumnWidth = 58,
    this.compact = false,
  })  : speaker = segment.speaker,
        startMs = segment.startMs,
        text = segment.text,
        speakerLabel = segment.speakerLabel;

  /// Which channel the line came from.
  final MeetingSpeaker speaker;

  /// Offset from meeting start, in milliseconds.
  final int startMs;

  /// The transcribed text.
  final String text;

  /// The diarized speaker label (e.g. `Person 1`), or null before diarization.
  final String? speakerLabel;

  /// The user-assigned name for [speakerLabel], when renamed. Overrides the
  /// label in the displayed speaker name.
  final String? speakerName;

  /// Invoked when the user taps a diarized speaker label to rename it. Null
  /// disables renaming (e.g. the notes-pane reference list).
  final VoidCallback? onRenameSpeaker;

  /// Whether to use tighter padding (notes-pane reference list).
  final bool compact;

  /// Case-insensitive substring to highlight, if any.
  final String query;

  /// Width of the leading timestamp column.
  final double timeColumnWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    final label = speakerLabel;
    // Diarized rows show their speaker identity (neutral); only the unlabeled
    // local mic keeps the orange "You" accent.
    final isMe = speaker == MeetingSpeaker.me && label == null;
    final speakerColor = isMe ? ds.accent : ds.fg;
    final dotColor = isMe ? ds.accent : ds.muted;
    final who = label != null
        ? meetingSpeakerDisplay(label, speakerName, l10n)
        : (speaker == MeetingSpeaker.me
            ? l10n.meetingSpeakerMe
            : l10n.meetingSpeakerOthers);

    final canRename = label != null && onRenameSpeaker != null;
    Widget speakerText = Text(
      who,
      style: meetingMono(context, fontSize: 11, color: speakerColor),
    );
    if (canRename) {
      speakerText = Tooltip(
        message: l10n.meetingRenameSpeakerTooltip,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onRenameSpeaker,
            child: speakerText,
          ),
        ),
      );
    }

    return Container(
      color: isMe ? ds.accent.withValues(alpha: 0.035) : null,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.md : AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: timeColumnWidth,
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                MeetingFormat.stamp(startMs),
                style: meetingMono(context, fontSize: 11),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    speakerText,
                  ],
                ),
                const SizedBox(height: 3),
                _HighlightedText(
                  text: text,
                  query: query,
                  color: ds.fg,
                  highlight: ds.brightYellow,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The name to show for a diarized speaker [label]: the user's [displayName]
/// when set, else the localized "Person N" form (so `Person 1` reads as
/// "Personne 1" in French), else the raw label.
String meetingSpeakerDisplay(
  String label,
  String? displayName,
  AppLocalizations l10n,
) {
  if (displayName != null && displayName.trim().isNotEmpty) {
    return displayName.trim();
  }
  final match = RegExp(r'^Person (\d+)$').firstMatch(label);
  if (match != null) {
    return l10n.meetingSpeakerPerson(int.parse(match.group(1)!));
  }
  return label;
}

/// Renders [text] with case-insensitive [query] matches wrapped in a highlight.
class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
    required this.color,
    required this.highlight,
  });

  final String text;
  final String query;
  final Color color;
  final Color highlight;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(fontSize: 14, height: 1.55, color: color);
    final q = query.trim();
    if (q.isEmpty) {
      return Text(text, style: base);
    }
    final lower = text.toLowerCase();
    final needle = q.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;
    while (true) {
      final idx = lower.indexOf(needle, start);
      if (idx < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + needle.length),
        style: TextStyle(backgroundColor: highlight, color: const Color(0xFF1F1F1F)),
      ));
      start = idx + needle.length;
    }
    return Text.rich(TextSpan(style: base, children: spans));
  }
}
