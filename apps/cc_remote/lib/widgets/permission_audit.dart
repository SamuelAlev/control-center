import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_remote/format.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/permission_providers.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Server-authored authorization history, available to workspace admins only.
class PermissionAudit extends ConsumerStatefulWidget {
  const PermissionAudit({super.key, required this.workspaceId});
  final String workspaceId;

  @override
  ConsumerState<PermissionAudit> createState() => _PermissionAuditState();
}

class _PermissionAuditState extends ConsumerState<PermissionAudit> {
  PermissionChainResult? _verification;
  bool _verifying = false;
  String? _error;

  Future<void> _verify() async {
    if (_verifying || !_authorized()) return;
    setState(() {
      _verifying = true;
      _error = null;
      _verification = null;
    });
    try {
      final result = await verifyPermissionChain(ref, widget.workspaceId);
      if (mounted && _authorized()) setState(() => _verification = result);
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  bool _authorized() {
    final role = ref.read(workspaceRoleProvider).asData?.value;
    return (role == WorkspaceRole.owner || role == WorkspaceRole.admin) &&
        ref.read(activeWorkspaceIdProvider).asData?.value == widget.workspaceId;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final audit = ref.watch(permissionAuditProvider(widget.workspaceId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.permissionAuditHeading,
          style: CcTypography.body.copyWith(color: t.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          l.permissionAuditDescription,
          style: CcTypography.bodySm.copyWith(color: t.textTertiary),
        ),
        const SizedBox(height: 8),
        CcButton(
          size: CcButtonSize.lg,
          variant: CcButtonVariant.secondary,
          loading: _verifying,
          onPressed: _verifying ? null : _verify,
          child: Text(l.permissionVerifyChain),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: CcAlert(
              title: l.permissionVerifyFailed,
              description: Text(_error!),
              variant: CcAlertVariant.danger,
            ),
          ),
        if (_verification case final result?)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: CcAlert(
              title: result.intact
                  ? l.permissionChainIntact(
                      _number(context, result.rowsChecked),
                    )
                  : l.permissionChainBroken(
                      _number(context, result.brokenAtSeq ?? 0),
                      result.reason ?? '',
                    ),
              variant: result.intact
                  ? CcAlertVariant.success
                  : CcAlertVariant.danger,
            ),
          ),
        const SizedBox(height: 12),
        switch (audit) {
          AsyncData(value: final entries) =>
            entries.isEmpty
                ? Text(
                    l.permissionAuditEmpty,
                    style: CcTypography.bodySm.copyWith(color: t.textTertiary),
                  )
                : Column(
                    children: [
                      for (final entry in entries.take(50)) _entry(entry, l, t),
                    ],
                  ),
          AsyncError(error: final error) => CcAlert(
            title: l.permissionAuditFailed,
            description: Text('$error'),
            variant: CcAlertVariant.danger,
            action: CcButton(
              size: CcButtonSize.lg,
              variant: CcButtonVariant.secondary,
              onPressed: () =>
                  ref.invalidate(permissionAuditProvider(widget.workspaceId)),
              child: Text(l.retry),
            ),
          ),
          _ => Text(
            l.permissionLoading,
            style: CcTypography.bodySm.copyWith(color: t.textTertiary),
          ),
        },
      ],
    );
  }

  Widget _entry(
    PermissionAuditEntry entry,
    AppLocalizations l,
    DesignSystemTokens t,
  ) {
    final verdict = switch (entry.decision) {
      'allow' => l.permissionAllow,
      'deny' => l.permissionDeny,
      'prompt' => l.permissionAsk,
      _ => entry.decision,
    };
    final extras = [
      entry.actor,
      if (entry.onBehalfOf case final user?) l.permissionOnBehalfOf(user),
      if (entry.prompted) l.permissionPrompted,
      ?entry.surface,
      ?entry.scope,
      ?entry.permission,
      ...entry.classes,
    ].where((s) => s.isNotEmpty).join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.action,
                  style: CcTypography.bodySm.copyWith(color: t.textPrimary),
                ),
              ),
              CcStatusTag(
                label: verdict,
                tone: entry.decision == 'deny'
                    ? CcStatusTone.negative
                    : CcStatusTone.neutral,
              ),
            ],
          ),
          Text(
            extras,
            style: CcTypography.caption.copyWith(color: t.textTertiary),
          ),
          Text(
            '${shortDate(context, entry.occurredAt)} · ${clockTime(context, entry.occurredAt)}',
            style: CcTypography.caption.copyWith(color: t.textTertiary),
          ),
          CcDivider(color: t.borderSoft),
        ],
      ),
    );
  }

  String _number(BuildContext context, int number) =>
      NumberFormat.decimalPattern(
        Localizations.localeOf(context).toLanguageTag(),
      ).format(number);
}
