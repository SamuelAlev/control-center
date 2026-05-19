import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_domain/features/calendar/domain/services/event_attendee_names.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_speaker_label.dart';
import 'package:cc_domain/features/meetings/domain/services/voice_profile_matching.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_ui_providers.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_transcript_row.dart';
import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Names from the linked calendar [event] the user can pick to label a speaker
/// on [channel]: the other invitees for a `them` speaker, the local user for
/// `me`. De-duplicated, in invitee order; empty when there is no linked event.
/// Pure so the speaker→invitee mapping is unit-testable.
List<String> attendeeNameSuggestions(
  CalendarEvent? event,
  MeetingSpeaker channel,
) =>
    eventAttendeeNames(event, self: channel == MeetingSpeaker.me);

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

  /// Key on the currently-playing row, so playback can scroll it into view (#8).
  final GlobalKey _activeRowKey = GlobalKey();

  /// Last row index auto-scrolled to — guards against re-scrolling every frame.
  int _scrolledToIndex = -1;

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

  /// Renames the speaker behind a diarized [label] on [channel], for the tapped
  /// [segment]. [existing] is the persisted speaker row when one exists (carrying
  /// its voiceprint, prior name, and voice-profile enrollment); it is null when
  /// diarization labeled the segment but never persisted a speaker row — a
  /// whole-speaker rename still proceeds, creating the row by label.
  ///
  /// The dialog's "apply to all blocks" toggle (default off) decides the scope:
  ///
  ///  * **off** — rename just this one transcript line via a per-segment
  ///    override, leaving the speaker's other lines untouched.
  ///  * **on** — rename the whole speaker (every line), clear any per-block
  ///    overrides that would shadow the new name, and run the cross-meeting
  ///    voice-profile bookkeeping (un-enroll the old name, offer to save the
  ///    new) — that voiceprint belongs to the speaker cluster, not one line.
  Future<void> _renameSpeaker({
    required MeetingSegment segment,
    required String label,
    required MeetingSpeaker channel,
    required MeetingSpeakerLabel? existing,
  }) async {
    final l10n = AppLocalizations.of(context);
    final toaster = CcToastScope.of(context);
    // Suggestions are best-effort and must NEVER delay the dialog: read only
    // what the providers have ALREADY loaded (the detail screen already watches
    // the calendar event), with no awaited fetch. A blocking await here could
    // otherwise keep the dialog from ever opening.
    final event = ref
        .read(
          eventForMeetingProvider(
            (workspaceId: widget.workspaceId, meetingId: widget.meetingId),
          ),
        )
        .asData
        ?.value;
    final calendarSuggestions = attendeeNameSuggestions(event, channel);
    // Add cross-meeting voiceprint suggestions: names of saved profiles this
    // speaker's voiceprint plausibly matches (but wasn't confident enough to
    // auto-apply). Surfaced first, ahead of the calendar invitees. Only when a
    // persisted speaker row carries a voiceprint, and only from loaded data.
    final embedding = existing?.embedding;
    var voiceSuggestions = const <String>[];
    if (embedding != null && embedding.isNotEmpty) {
      final profiles =
          ref.read(voiceProfilesProvider(widget.workspaceId)).asData?.value;
      if (profiles != null) {
        voiceSuggestions = suggestedNames(embedding, profiles);
      }
    }
    final suggestions = <String>[
      ...voiceSuggestions,
      for (final name in calendarSuggestions)
        if (!voiceSuggestions.contains(name)) name,
    ];
    // Seed with the line's effective name: its per-block override, else the
    // speaker's group name.
    final currentName = segment.speakerNameOverride ?? existing?.displayName;
    final result = await showCcDialog<_RenameSpeakerResult>(
      context: context,
      builder: (_) => _RenameSpeakerDialog(
        currentName: currentName ?? '',
        fallbackLabel: meetingSpeakerDisplay(label, null, l10n),
        suggestions: suggestions,
      ),
    );
    if (result == null) {
      return; // cancelled
    }
    final trimmed = result.name.trim();
    final meetingRepo = ref.read(meetingRepositoryProvider);

    if (!result.applyToAll) {
      // Rename only this line via a per-segment override (empty clears it,
      // falling back to the speaker's group name).
      try {
        await meetingRepo.setSegmentSpeakerName(
          widget.workspaceId,
          segment.id,
          trimmed.isEmpty ? null : trimmed,
        );
      } on Object {
        toaster.show(
          l10n.meetingRenameSpeakerFailed,
          variant: CcToastVariant.danger,
        );
        return;
      }
      // Still offer to save the voiceprint, but ADDITIVELY: a single-line
      // correction must not disturb the whole speaker's identity or its existing
      // enrollment (only one line was reattributed), so no un-enroll / re-stamp.
      await _offerSaveVoiceProfile(
        name: trimmed,
        embedding: embedding,
        channel: channel,
        label: label,
        repointCluster: false,
      );
      return;
    }

    // Whole-speaker rename: set the group name and clear per-block overrides
    // that would otherwise keep shadowing it.
    try {
      await meetingRepo.renameSpeakerByLabel(
        workspaceId: widget.workspaceId,
        meetingId: widget.meetingId,
        channel: channel,
        label: label,
        // An empty name clears the override, falling back to "Person N".
        displayName: trimmed.isEmpty ? null : trimmed,
      );
      await meetingRepo.clearSpeakerNameOverridesForLabel(
        workspaceId: widget.workspaceId,
        meetingId: widget.meetingId,
        channel: channel,
        label: label,
      );
    } on Object {
      toaster.show(
        l10n.meetingRenameSpeakerFailed,
        variant: CcToastVariant.danger,
      );
      return;
    }

    // Re-point the cluster's voiceprint: the whole speaker is now this name, so
    // un-enroll the old profile and offer to enroll the new (provenance stamped).
    await _offerSaveVoiceProfile(
      name: trimmed,
      embedding: embedding,
      channel: channel,
      label: label,
      repointCluster: true,
      priorProfile: existing?.enrolledProfileName,
    );
  }

  /// Cross-meeting voice-profile bookkeeping for a rename, offered for both
  /// scopes (the voiceprint is the speaker cluster's [embedding]).
  ///
  ///  * [repointCluster] true (whole-speaker rename): the cluster IS this
  ///    [name]. Clearing the name un-enrolls the prior profile; setting one
  ///    re-points the voiceprint — un-enroll [priorProfile] (when it differs),
  ///    enroll [name] on confirm, and stamp the provenance.
  ///  * [repointCluster] false (single line): purely additive — only offer to
  ///    enroll [name] (no un-enroll, no stamp), so correcting one mislabeled
  ///    line never disturbs the cluster's own identity or enrollment.
  ///
  /// A no-op without a captured [embedding]. Best-effort: failures toast but
  /// never undo the rename itself.
  Future<void> _offerSaveVoiceProfile({
    required String name,
    required List<double>? embedding,
    required MeetingSpeaker channel,
    required String label,
    required bool repointCluster,
    String? priorProfile,
  }) async {
    final l10n = AppLocalizations.of(context);
    final toaster = CcToastScope.of(context);
    final meetingRepo = ref.read(meetingRepositoryProvider);
    final voiceRepo = ref.read(voiceProfileRepositoryProvider);

    if (embedding == null || embedding.isEmpty) {
      return;
    }

    // Cleared name on a whole-speaker rename retracts the cluster's identity:
    // drop the voiceprint from the profile it was enrolled into.
    if (name.isEmpty) {
      if (repointCluster && priorProfile != null) {
        try {
          await voiceRepo.unenroll(
            workspaceId: widget.workspaceId,
            displayName: priorProfile,
            sampleEmbedding: embedding,
          );
        } on Object {
          // Best-effort cleanup — never block the rename on it.
        }
        await meetingRepo.setSpeakerEnrolledProfile(
          workspaceId: widget.workspaceId,
          meetingId: widget.meetingId,
          channel: channel,
          label: label,
          profileName: null,
        );
      }
      return;
    }

    if (!mounted) {
      return;
    }
    final save = await showCcDialog<bool>(
      context: context,
      builder: (_) => _SaveVoiceProfileDialog(name: name),
    );
    if (save != true || !mounted) {
      return;
    }
    try {
      // Re-point: this cluster's voiceprint is moving to [name], so remove it
      // from the profile it was previously enrolled into.
      if (repointCluster && priorProfile != null && priorProfile != name) {
        await voiceRepo.unenroll(
          workspaceId: widget.workspaceId,
          displayName: priorProfile,
          sampleEmbedding: embedding,
        );
      }
      await voiceRepo.enroll(
        workspaceId: widget.workspaceId,
        displayName: name,
        sampleEmbedding: embedding,
      );
      if (repointCluster) {
        await meetingRepo.setSpeakerEnrolledProfile(
          workspaceId: widget.workspaceId,
          meetingId: widget.meetingId,
          channel: channel,
          label: label,
          profileName: name,
        );
      }
      toaster.show(l10n.meetingVoiceProfileSaved(name));
    } on Object {
      toaster.show(
        l10n.meetingVoiceProfileSaveFailed,
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

    // Sync with audio playback (#8): find the line currently playing (the last
    // line whose start has been reached), so it can be highlighted, scrolled
    // into view, and tapping any line seeks the audio there.
    final playback = ref.watch(meetingPlaybackProvider);
    var activeIndex = -1;
    if (playback.ready) {
      for (var i = 0; i < rows.length; i++) {
        if (rows[i].startMs <= playback.positionMs) {
          activeIndex = i;
        } else {
          break;
        }
      }
    }
    if (activeIndex >= 0 && activeIndex != _scrolledToIndex) {
      _scrolledToIndex = activeIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _activeRowKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.5,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }

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
                  final isActive = i == activeIndex;
                  // Renaming keys off the visible label, not a persisted speaker
                  // row: a diarized `Person N` is always renameable even if its
                  // speaker row is missing (the rename creates it).
                  return MeetingTranscriptRow.fromSegment(
                    rows[i],
                    key: isActive ? _activeRowKey : null,
                    query: _query,
                    // A per-line override wins over the speaker's group name.
                    speakerName:
                        rows[i].speakerNameOverride ?? speaker?.displayName,
                    active: isActive,
                    onTap: playback.ready
                        ? () => ref
                            .read(meetingPlaybackProvider.notifier)
                            .seekToMs(rows[i].startMs)
                        : null,
                    onRenameSpeaker: label == null
                        ? null
                        : () => _renameSpeaker(
                              segment: rows[i],
                              label: label,
                              channel: rows[i].speaker,
                              existing: speaker,
                            ),
                  );
                }(),
              ],
          ],
        ),
      ),
    );
  }
}

/// The outcome of the rename dialog: the entered [name] (empty clears it) and
/// whether to [applyToAll] blocks from this speaker (vs. just the tapped line).
class _RenameSpeakerResult {
  const _RenameSpeakerResult({required this.name, required this.applyToAll});

  final String name;
  final bool applyToAll;
}

/// A small dialog to rename a diarized speaker (`Person N` → a real name).
/// Returns a [_RenameSpeakerResult] on confirm (empty name clears it), or null
/// on cancel. The "apply to all blocks" checkbox (default off) decides whether
/// the rename touches just the tapped line or the whole speaker.
class _RenameSpeakerDialog extends StatefulWidget {
  const _RenameSpeakerDialog({
    required this.currentName,
    required this.fallbackLabel,
    this.suggestions = const [],
  });

  final String currentName;
  final String fallbackLabel;

  /// Names from the linked calendar event to offer as one-tap fills.
  final List<String> suggestions;

  @override
  State<_RenameSpeakerDialog> createState() => _RenameSpeakerDialogState();
}

class _RenameSpeakerDialogState extends State<_RenameSpeakerDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.currentName);

  /// Default off: a rename touches only the tapped line until the user opts in
  /// to renaming the whole speaker.
  bool _applyToAll = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(
        _RenameSpeakerResult(name: _controller.text, applyToAll: _applyToAll),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
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
              onSubmitted: (_) => _submit(),
            ),
            if (widget.suggestions.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                l10n.meetingSpeakerSuggestFromCalendar,
                style: TextStyle(fontSize: 12, color: ds.muted),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final name in widget.suggestions)
                    _SuggestionChip(
                      label: name,
                      onTap: () => setState(() {
                        _controller.text = name;
                        _controller.selection = TextSelection.collapsed(
                          offset: name.length,
                        );
                      }),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            _ApplyToAllToggle(
              value: _applyToAll,
              onChanged: (v) => setState(() => _applyToAll = v),
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
          onPressed: _submit,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// The "apply to all blocks from this speaker" checkbox row in the rename
/// dialog, with a muted hint clarifying the default (only this line).
class _ApplyToAllToggle extends StatelessWidget {
  const _ApplyToAllToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: CcCheckbox(
              value: value,
              onChanged: onChanged,
              semanticLabel: l10n.meetingRenameSpeakerApplyAll,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.meetingRenameSpeakerApplyAll,
                  style: TextStyle(fontSize: 13, color: ds.fg),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.meetingRenameSpeakerScopeHint,
                  style: TextStyle(fontSize: 11.5, color: ds.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Confirms saving a cross-meeting voice profile after the user names a
/// speaker. Returns true to save, false/null to skip.
class _SaveVoiceProfileDialog extends StatelessWidget {
  const _SaveVoiceProfileDialog({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcDialog(
      title: l10n.meetingSaveVoiceProfileTitle,
      maxWidth: 420,
      content: SizedBox(
        width: 380,
        child: Text(l10n.meetingSaveVoiceProfileBody(name)),
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          size: CcButtonSize.sm,
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.notNow),
        ),
        CcButton(
          size: CcButtonSize.sm,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// A tappable invitee-name chip in the speaker rename dialog.
class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: ds.surface,
          borderRadius: AppRadii.brSm,
          border: Border.all(color: ds.borderSecondary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.userPlus, size: 12, color: ds.accent),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12.5, color: ds.fg)),
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
            child: CcTextField(
              controller: controller,
              hintText: l10n.meetingTranscriptSearchHint,
              prefix: Icon(AppIcons.search, size: 14, color: ds.muted),
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
