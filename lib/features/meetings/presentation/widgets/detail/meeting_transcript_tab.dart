import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_segment.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_transcript_row.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:control_center/shared/widgets/segmented_toggle.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Speaker scope for the transcript tab.
enum MeetingSpeakerFilter {
  /// Show every speaker.
  everyone,

  /// Show only the local user (mic).
  me,

  /// Show only the other participants (system audio).
  them,
}

/// The Transcript tab: a search field + speaker filter over the full,
/// speaker-attributed transcript.
class MeetingTranscriptTab extends StatefulWidget {
  /// Creates a [MeetingTranscriptTab].
  const MeetingTranscriptTab({super.key, required this.segments});

  /// The full set of transcript segments (oldest first).
  final List<MeetingSegment> segments;

  @override
  State<MeetingTranscriptTab> createState() => _MeetingTranscriptTabState();
}

class _MeetingTranscriptTabState extends State<MeetingTranscriptTab> {
  final _searchController = TextEditingController();
  String _query = '';
  MeetingSpeakerFilter _speaker = MeetingSpeakerFilter.everyone;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onQueryChanged)
      ..dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    if (_query != _searchController.text) {
      setState(() => _query = _searchController.text);
    }
  }

  bool _matches(MeetingSegment s) {
    switch (_speaker) {
      case MeetingSpeakerFilter.me:
        if (s.speaker != MeetingSpeaker.me) {
          return false;
        }
      case MeetingSpeakerFilter.them:
        if (s.speaker != MeetingSpeaker.them) {
          return false;
        }
      case MeetingSpeakerFilter.everyone:
        break;
    }
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty && !s.text.toLowerCase().contains(q)) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    final rows = widget.segments.where(_matches).toList();

    return SectionCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppRadii.brLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Toolbar(
              controller: _searchController,
              speaker: _speaker,
              onSpeakerChanged: (s) => setState(() => _speaker = s),
            ),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xxxl,
                ),
                child: Center(
                  child: Text(
                    l10n.meetingTranscriptEmpty,
                    style: TextStyle(color: ds.muted),
                  ),
                ),
              )
            else
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  Divider(height: 1, thickness: 1, color: ds.borderSecondary),
                MeetingTranscriptRow.fromSegment(rows[i], query: _query),
              ],
          ],
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.controller,
    required this.speaker,
    required this.onSpeakerChanged,
  });

  final TextEditingController controller;
  final MeetingSpeakerFilter speaker;
  final ValueChanged<MeetingSpeakerFilter> onSpeakerChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ds.borderSecondary)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 260,
            child: FTextField(
              control: FTextFieldControl.managed(controller: controller),
              hint: l10n.meetingTranscriptSearchHint,
              size: FTextFieldSizeVariant.sm,
              prefixBuilder: (context, style, _) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(LucideIcons.search, size: 14, color: ds.muted),
              ),
              clearable: (value) => value.text.isNotEmpty,
            ),
          ),
          const Spacer(),
          SegmentedToggle<MeetingSpeakerFilter>(
            value: speaker,
            onChanged: onSpeakerChanged,
            segments: [
              (
                value: MeetingSpeakerFilter.everyone,
                label: l10n.meetingSpeakerEveryone,
              ),
              (value: MeetingSpeakerFilter.me, label: l10n.meetingSpeakerMe),
              (
                value: MeetingSpeakerFilter.them,
                label: l10n.meetingSpeakerOthers,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
