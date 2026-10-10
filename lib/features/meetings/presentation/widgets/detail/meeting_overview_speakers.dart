import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_format.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/features/meetings/presentation/widgets/detail/meeting_overview_section.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_transcript_row.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// One speaker's share of a meeting's talk time.
class MeetingTalkTime {
  /// Creates a [MeetingTalkTime].
  const MeetingTalkTime({
    required this.speaker,
    required this.label,
    required this.spoken,
    required this.share,
  });

  /// The coarse channel the speaker was heard on.
  final MeetingSpeaker speaker;

  /// The diarized label (`Person 1`), or null for an undiarized channel.
  final String? label;

  /// Total time this speaker's segments cover.
  final Duration spoken;

  /// [spoken] as a fraction of everyone's talk time, 0–1.
  final double share;

  /// Groups [segments] by speaker (diarized label, else channel) and sums the
  /// time each one covers, loudest first. Per-line name overrides are ignored:
  /// they rename a single line, not the speaker it belongs to.
  static List<MeetingTalkTime> from(List<MeetingSegment> segments) {
    final totals = <String, int>{};
    final first = <String, MeetingSegment>{};
    for (final s in segments) {
      final key = s.speakerLabel ?? '#${s.speaker.name}';
      final ms = s.endMs - s.startMs;
      totals[key] = (totals[key] ?? 0) + (ms < 0 ? 0 : ms);
      first.putIfAbsent(key, () => s);
    }
    final all = totals.values.fold<int>(0, (a, b) => a + b);
    final result = [
      for (final e in totals.entries)
        MeetingTalkTime(
          speaker: first[e.key]!.speaker,
          label: first[e.key]!.speakerLabel,
          spoken: Duration(milliseconds: e.value),
          share: all == 0 ? 0 : e.value / all,
        ),
    ]..sort((a, b) => b.spoken.compareTo(a.spoken));
    return result;
  }
}

/// Who spoke and for how long, loudest first.
class MeetingOverviewSpeakers extends StatelessWidget {
  /// Creates a [MeetingOverviewSpeakers].
  const MeetingOverviewSpeakers({
    super.key,
    required this.talk,
    required this.names,
  });

  /// Talk time per speaker, as [MeetingTalkTime.from] returns it.
  final List<MeetingTalkTime> talk;

  /// User-given speaker names by diarized label.
  final Map<String, String?> names;

  static const _shown = 6;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    final percent = NumberFormat.percentPattern(
      Localizations.localeOf(context).toString(),
    );
    return MeetingOverviewSection(
      title: l10n.meetingOverviewSpeakers,
      count: talk.isEmpty ? null : talk.length,
      child: talk.isEmpty
          ? MeetingOverviewNote(l10n.meetingOverviewSpeakersEmpty)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final t in talk.take(_shown)) ...[
                  _SpeakerBar(
                    name: t.label != null
                        ? meetingSpeakerDisplay(t.label!, names[t.label], l10n)
                        : (t.speaker == MeetingSpeaker.me
                              ? l10n.meetingSpeakerMe
                              : l10n.meetingSpeakerOthers),
                    spoken: MeetingFormat.clock(t.spoken),
                    share: t.share,
                    shareLabel: percent.format(t.share),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (talk.length > _shown)
                  Text(
                    l10n.meetingOverviewMoreSpeakers(talk.length - _shown),
                    style: meetingMono(context, fontSize: 11, color: ds.muted),
                  ),
              ],
            ),
    );
  }
}

/// A speaker's name and talk time over a hairline bar of their share. The
/// numbers carry the meaning; the bar only makes the split scannable.
class _SpeakerBar extends StatelessWidget {
  const _SpeakerBar({
    required this.name,
    required this.spoken,
    required this.share,
    required this.shareLabel,
  });

  final String name;
  final String spoken;
  final double share;
  final String shareLabel;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.meetingOverviewSpeakerShare(name, shareLabel, spoken),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: ds.fg),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '$spoken · $shareLabel',
                style: meetingMono(context, fontSize: 11, color: ds.muted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 4,
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: ds.hoverStrong)),
                FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: share.clamp(0, 1),
                  child: ColoredBox(color: ds.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
