import 'dart:convert';

import 'package:cc_domain/features/dispatch/domain/value_objects/unattended_policy.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/dispatch/presentation/dispatch_text.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/providers/workspace_settings_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What happens to a request nobody answers: how long a run the server
/// started waits on a person before its approval counts as denied and its
/// question as unanswered, and the hour (in the workspace's schedule zone)
/// the daily digest of what waits goes out. Stored as the workspace setting
/// `unattended_requests`, written by an admin through `workspace_settings.set`
/// (the write the setting's domain type names).
class UnattendedSection extends ConsumerStatefulWidget {
  /// Creates the section.
  const UnattendedSection({
    super.key,
    required this.canEdit,
    required this.zone,
  });

  /// Whether the reader administers the workspace.
  final bool canEdit;

  /// The workspace's schedule zone, the digest hour's zone.
  final String zone;

  @override
  ConsumerState<UnattendedSection> createState() => _UnattendedSectionState();
}

class _UnattendedSectionState extends ConsumerState<UnattendedSection> {
  final _hours = TextEditingController();
  final _digest = TextEditingController();
  UnattendedPolicy? _loaded;
  bool _saving = false;
  String? _error;

  static final int _minHours = UnattendedPolicy.minExpiry.inHours;
  static final int _maxHours = UnattendedPolicy.maxExpiry.inHours;

  @override
  void dispose() {
    _hours.dispose();
    _digest.dispose();
    super.dispose();
  }

  void _load(UnattendedPolicy policy) {
    _loaded = policy;
    _hours.text = '${policy.expiry.inHours}';
    _digest.text = '${policy.digestHour}';
  }

  int? get _stagedHours {
    final v = int.tryParse(_hours.text.trim());
    return v != null && v >= _minHours && v <= _maxHours ? v : null;
  }

  int? get _stagedDigest {
    final v = int.tryParse(_digest.text.trim());
    return v != null && v >= 0 && v <= 23 ? v : null;
  }

  bool get _dirty {
    final p = _loaded;
    return p != null &&
        (_hours.text.trim() != '${p.expiry.inHours}' ||
            _digest.text.trim() != '${p.digestHour}');
  }

  Future<void> _save() async {
    final hours = _stagedHours;
    final digest = _stagedDigest;
    if (hours == null || digest == null) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final policy = UnattendedPolicy(
        expiry: Duration(hours: hours),
        digestHour: digest,
      );
      await setWorkspaceSetting(
        ref,
        unattendedPolicySettingKey,
        jsonEncode(policy.toJson()),
      );
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
    final policy = UnattendedPolicy.fromSetting(
      ref.watch(workspaceSettingProvider(unattendedPolicySettingKey)),
    );
    if (_loaded != policy && !_dirty) {
      _load(policy);
    }
    final enabled = widget.canEdit && !_saving;
    final caption = CcTypography.caption.copyWith(color: ds.textSecondary);
    return SectionCard(
      label: l10n.dispatchUnattendedLabel,
      subtitle: Text(l10n.dispatchUnattendedSubtitle),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SettingsField(
            label: l10n.dispatchUnattendedExpiry,
            description: l10n.dispatchUnattendedExpiryHelp,
            hint: l10n.dispatchUnattendedExpiryRange(_minHours, _maxHours),
            error: _stagedHours == null
                ? l10n.dispatchUnattendedExpiryRange(_minHours, _maxHours)
                : null,
            controlWidth: 200,
            child: CcTextField(
              key: const ValueKey('unattended-expiry'),
              controller: _hours,
              enabled: enabled,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() => _error = null),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SettingsField(
            label: l10n.dispatchDigestHour,
            description: l10n.dispatchDigestHourHelp(widget.zone),
            hint: l10n.dispatchDigestHourRange,
            error: _stagedDigest == null ? l10n.dispatchDigestHourRange : null,
            controlWidth: 200,
            child: CcTextField(
              key: const ValueKey('unattended-digest'),
              controller: _digest,
              enabled: enabled,
              maxLength: 2,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() => _error = null),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (!widget.canEdit)
            Text(l10n.settingsWorkspaceAdminOnly, style: caption)
          else
            SettingsSaveBar(
              dirty: _dirty,
              busy: _saving,
              saveEnabled: _stagedHours != null && _stagedDigest != null,
              error: _error,
              onSave: _save,
              onDiscard: () => setState(() => _load(policy)),
            ),
        ],
      ),
    );
  }
}
