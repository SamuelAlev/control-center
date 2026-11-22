import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_limits.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/conversation_work_providers.dart';
import 'package:control_center/features/dispatch/presentation/dispatch_text.dart';
import 'package:control_center/features/dispatch/presentation/schedule_text.dart';
import 'package:control_center/features/dispatch/providers/long_work_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The workspace's caps on schedules and watches (`wakeRules.getLimits` /
/// `wakeRules.setLimits`): how many an agent may hold in one conversation,
/// in the workspace, and the workspace in all; the cost cap a schedule gets
/// when it names none; and the zone a cron is read in when it names none
/// (also the zone of the daily digest). An admin edits them; a member reads.
class ScheduleLimitsSection extends ConsumerStatefulWidget {
  /// Creates the section.
  const ScheduleLimitsSection({
    super.key,
    required this.workspaceId,
    required this.limits,
    required this.canEdit,
  });

  /// The workspace.
  final String workspaceId;

  /// The limits as saved.
  final WakeRuleLimits limits;

  /// Whether the reader administers the workspace.
  final bool canEdit;

  @override
  ConsumerState<ScheduleLimitsSection> createState() =>
      _ScheduleLimitsSectionState();
}

class _ScheduleLimitsSectionState extends ConsumerState<ScheduleLimitsSection> {
  final _perConversation = TextEditingController();
  final _perAgent = TextEditingController();
  final _perWorkspace = TextEditingController();
  final _costDollars = TextEditingController();
  final _zone = TextEditingController();
  bool _saving = false;
  String? _error;

  List<TextEditingController> get _all => [
    _perConversation,
    _perAgent,
    _perWorkspace,
    _costDollars,
    _zone,
  ];

  @override
  void initState() {
    super.initState();
    _load();
    for (final c in _all) {
      c.addListener(_changed);
    }
  }

  @override
  void didUpdateWidget(covariant ScheduleLimitsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.limits != widget.limits && !_dirty) {
      _load();
    }
  }

  @override
  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }

  void _changed() => setState(() => _error = null);

  void _load() {
    final l = widget.limits;
    _perConversation.text = '${l.perConversation}';
    _perAgent.text = '${l.perAgent}';
    _perWorkspace.text = '${l.perWorkspace}';
    _costDollars.text = '${(l.costCapMicros / 1000000).round()}';
    _zone.text = l.defaultTimeZone;
  }

  static int? _ranged(TextEditingController c, int max) {
    final v = int.tryParse(c.text.trim());
    return v != null && v >= 1 && v <= max ? v : null;
  }

  int? get _conv =>
      _ranged(_perConversation, WakeRuleLimits.maxPerConversation);
  int? get _agent => _ranged(_perAgent, WakeRuleLimits.maxPerAgent);
  int? get _ws => _ranged(_perWorkspace, WakeRuleLimits.maxPerWorkspace);
  int? get _cost =>
      _ranged(_costDollars, WakeRuleLimits.maxCostCapMicros ~/ 1000000);
  /// The server's last answer for the zone's current text called it
  /// unknown. Read in [build] (asked [cronPreviewDebounce] after the last
  /// keystroke); while that answer is pending the shape alone decides.
  bool _zoneUnknown = false;

  bool get _zoneOk {
    final zone = _zone.text.trim();
    return zone.isNotEmpty && looksLikeZoneName(zone) && !_zoneUnknown;
  }

  bool get _valid =>
      _conv != null &&
      _agent != null &&
      _ws != null &&
      _cost != null &&
      _zoneOk;

  WakeRuleLimits? get _staged => _valid
      ? WakeRuleLimits(
          perConversation: _conv!,
          perAgent: _agent!,
          perWorkspace: _ws!,
          costCapMicros: _cost! * 1000000,
          defaultTimeZone: _zone.text.trim(),
        )
      : null;

  bool get _dirty {
    final l = widget.limits;
    return _perConversation.text.trim() != '${l.perConversation}' ||
        _perAgent.text.trim() != '${l.perAgent}' ||
        _perWorkspace.text.trim() != '${l.perWorkspace}' ||
        _costDollars.text.trim() != '${(l.costCapMicros / 1000000).round()}' ||
        _zone.text.trim() != l.defaultTimeZone;
  }

  Future<void> _save() async {
    final staged = _staged;
    if (staged == null) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(wakeRuleScheduleRepositoryProvider)
          .setLimits(widget.workspaceId, staged);
      ref.invalidate(wakeRuleLimitsProvider(widget.workspaceId));
      if (mounted) {
        CcToastScope.maybeOf(context)?.show(
          AppLocalizations.of(context).saved,
          variant: CcToastVariant.success,
        );
      }
    } on Object catch (e) {
      if (mounted) {
        setState(
          () =>
              _error = dispatchFailureMessage(AppLocalizations.of(context), e),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    final caption = CcTypography.caption.copyWith(color: ds.textSecondary);
    final enabled = widget.canEdit && !_saving;
    final zone = _zone.text.trim();
    _zoneUnknown =
        zone.isNotEmpty &&
        looksLikeZoneName(zone) &&
        ref
                .watch(
                  cronPreviewProvider((
                    workspaceId: widget.workspaceId,
                    expression: '',
                    timeZone: zone,
                  )),
                )
                .value
                ?.zoneKnown ==
            false;
    Widget number(
      TextEditingController c,
      String label,
      String description,
      int max,
      bool ok,
    ) => Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
      child: SettingsField(
        label: label,
        description: description,
        hint: l10n.dispatchLimitRange(max),
        error: ok ? null : l10n.dispatchLimitRange(max),
        controlWidth: 200,
        child: CcTextField(
          controller: c,
          enabled: enabled,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ),
    );
    return SectionCard(
      label: l10n.dispatchLimitsLabel,
      subtitle: Text(l10n.dispatchLimitsSubtitle),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          number(
            _perConversation,
            l10n.dispatchLimitPerConversation,
            l10n.dispatchLimitPerConversationHelp,
            WakeRuleLimits.maxPerConversation,
            _conv != null,
          ),
          number(
            _perAgent,
            l10n.dispatchLimitPerAgent,
            l10n.dispatchLimitPerAgentHelp,
            WakeRuleLimits.maxPerAgent,
            _agent != null,
          ),
          number(
            _perWorkspace,
            l10n.dispatchLimitPerWorkspace,
            l10n.dispatchLimitPerWorkspaceHelp,
            WakeRuleLimits.maxPerWorkspace,
            _ws != null,
          ),
          number(
            _costDollars,
            l10n.dispatchLimitCostCap,
            l10n.dispatchLimitCostCapHelp,
            WakeRuleLimits.maxCostCapMicros ~/ 1000000,
            _cost != null,
          ),
          SettingsField(
            label: l10n.dispatchLimitZone,
            description: l10n.dispatchLimitZoneHelp,
            error: _zoneOk ? null : l10n.scheduleZoneInvalid,
            controlWidth: 200,
            // RTL carve-out: an IANA zone name is an identifier.
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: CcTextField(controller: _zone, enabled: enabled),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (!widget.canEdit)
            Text(l10n.settingsWorkspaceAdminOnly, style: caption)
          else
            SettingsSaveBar(
              dirty: _dirty,
              busy: _saving,
              saveEnabled: _valid,
              error: _error,
              onSave: _save,
              onDiscard: () => setState(_load),
            ),
        ],
      ),
    );
  }
}
