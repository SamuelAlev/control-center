import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_segment.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_speaker_label.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_transcript_row.dart';
import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
/// speaker-attributed transcript. Diarized speakers show their `Person N` label
/// (or the name the user gave them); tapping a label renames the speaker.
class MeetingTranscriptTab extends ConsumerStatefulWidget {
  /// Creates a [MeetingTranscriptTab].
  const MeetingTranscriptTab({
    super.key,
    required this.segments,
    required this.workspaceId,
    required this.meetingId,
  });

  /// The full set of transcript segments (oldest first).
  final List<MeetingSegment> segments;

  /// Owning workspace (for the speaker-rename write).
  final String workspaceId;

  /// The meeting whose speakers can be renamed.
  final String meetingId;

  @override
  ConsumerState<MeetingTranscriptTab> createState() =>
      _MeetingTranscriptTabState();
}

class _MeetingTranscriptTabState extends ConsumerState<MeetingTranscriptTab> {
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

  Future<void> _renameSpeaker(MeetingSpeakerLabel speaker) async {
    final l10n = AppLocalizations.of(context);
    final toaster = CcToastScope.of(context);
    final newName = await showCcDialog<String>(
      context: context,
      builder: (_) => _RenameSpeakerDialog(
        currentName: speaker.displayName ?? '',
        fallbackLabel: meetingSpeakerDisplay(speaker.label, null, l10n),
      ),
    );
    if (newName == null) {
      return; // cancelled
    }
    final trimmed = newName.trim();
    try {
      await ref.read(meetingRepositoryProvider).renameSpeaker(
            workspaceId: widget.workspaceId,
            id: speaker.id,
            // An empty name clears the override, falling back to "Person N".
            displayName: trimmed.isEmpty ? null : trimmed,
          );
    } on Object {
      toaster.show(
        l10n.meetingRenameSpeakerFailed,
        variant: CcToastVariant.danger,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    final rows = widget.segments.where(_matches).toList();

    final speakers = ref
            .watch(meetingSpeakersProvider(
              (workspaceId: widget.workspaceId, meetingId: widget.meetingId),
            ))
            .asData
            ?.value ??
        const <MeetingSpeakerLabel>[];
    final speakerByLabel = <String, MeetingSpeakerLabel>{
      for (final s in speakers) s.label: s,
    };

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
                () {
                  final label = rows[i].speakerLabel;
                  final speaker = label == null ? null : speakerByLabel[label];
                  return MeetingTranscriptRow.fromSegment(
                    rows[i],
                    query: _query,
                    speakerName: speaker?.displayName,
                    onRenameSpeaker:
                        speaker == null ? null : () => _renameSpeaker(speaker),
                  );
                }(),
              ],
          ],
        ),
      ),
    );
  }
}

/// A small dialog to rename a diarized speaker (`Person N` → a real name).
/// Returns the entered text on confirm (empty clears the name), or null on
/// cancel.
class _RenameSpeakerDialog extends StatefulWidget {
  const _RenameSpeakerDialog({
    required this.currentName,
    required this.fallbackLabel,
  });

  final String currentName;
  final String fallbackLabel;

  @override
  State<_RenameSpeakerDialog> createState() => _RenameSpeakerDialogState();
}

class _RenameSpeakerDialogState extends State<_RenameSpeakerDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.currentName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcDialog(
      title: l10n.meetingRenameSpeakerTitle,
      maxWidth: 420,
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.meetingSpeakerNameLabel),
            const SizedBox(height: 6),
            CcTextField(
              controller: _controller,
              hintText: widget.fallbackLabel,
              autofocus: true,
              onSubmitted: (v) => Navigator.of(context).pop(v),
            ),
          ],
        ),
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          size: CcButtonSize.sm,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        CcButton(
          size: CcButtonSize.sm,
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.save),
        ),
      ],
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
            child: CcTextField(
              controller: controller,
              hintText: l10n.meetingTranscriptSearchHint,
              prefix: Icon(LucideIcons.search, size: 14, color: ds.muted),
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
