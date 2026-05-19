import 'package:cc_harness/tools.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/guardrail_vocabulary.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';

/// The agent runners whose enforcement reach we document.
enum _GuardrailAdapter { harness, claudeCli, mcpHttp, sandboxFloor }

/// Where an effect is actually caught for a given adapter.
enum _Enforcement {
  /// The guardrail decision is consulted before the effect (can deny).
  policyGate,

  /// Only the OS/worktree sandbox constrains it — the policy is not consulted.
  sandboxFloor,

  /// Neither the policy engine nor the sandbox can intercept it here; the
  /// declared decision is advisory only.
  notEnforceable,
}

/// The honest coverage map: for each [ActionClass], where each adapter catches
/// it. This is hand-maintained DOCUMENTATION, not resolver output — it must not
/// overclaim. `notEnforceable` means the declared decision is advisory for that
/// runner (the effect happens out of band).
const Map<ActionClass, Map<_GuardrailAdapter, _Enforcement>> _matrix = {
  ActionClass.fileDelete: {
    _GuardrailAdapter.harness: _Enforcement.policyGate,
    _GuardrailAdapter.claudeCli: _Enforcement.sandboxFloor,
    _GuardrailAdapter.mcpHttp: _Enforcement.policyGate,
    _GuardrailAdapter.sandboxFloor: _Enforcement.notEnforceable,
  },
  ActionClass.fileWriteOutsideWorktree: {
    _GuardrailAdapter.harness: _Enforcement.policyGate,
    _GuardrailAdapter.claudeCli: _Enforcement.sandboxFloor,
    _GuardrailAdapter.mcpHttp: _Enforcement.policyGate,
    _GuardrailAdapter.sandboxFloor: _Enforcement.sandboxFloor,
  },
  ActionClass.gitCommit: {
    _GuardrailAdapter.harness: _Enforcement.policyGate,
    _GuardrailAdapter.claudeCli: _Enforcement.sandboxFloor,
    _GuardrailAdapter.mcpHttp: _Enforcement.policyGate,
    _GuardrailAdapter.sandboxFloor: _Enforcement.notEnforceable,
  },
  ActionClass.gitPush: {
    _GuardrailAdapter.harness: _Enforcement.policyGate,
    _GuardrailAdapter.claudeCli: _Enforcement.sandboxFloor,
    _GuardrailAdapter.mcpHttp: _Enforcement.policyGate,
    _GuardrailAdapter.sandboxFloor: _Enforcement.notEnforceable,
  },
  ActionClass.prCreate: {
    _GuardrailAdapter.harness: _Enforcement.policyGate,
    _GuardrailAdapter.claudeCli: _Enforcement.policyGate,
    _GuardrailAdapter.mcpHttp: _Enforcement.policyGate,
    _GuardrailAdapter.sandboxFloor: _Enforcement.notEnforceable,
  },
  ActionClass.prPublish: {
    _GuardrailAdapter.harness: _Enforcement.policyGate,
    _GuardrailAdapter.claudeCli: _Enforcement.policyGate,
    _GuardrailAdapter.mcpHttp: _Enforcement.policyGate,
    _GuardrailAdapter.sandboxFloor: _Enforcement.notEnforceable,
  },
  ActionClass.vendorSyncWrite: {
    _GuardrailAdapter.harness: _Enforcement.policyGate,
    _GuardrailAdapter.claudeCli: _Enforcement.policyGate,
    _GuardrailAdapter.mcpHttp: _Enforcement.policyGate,
    _GuardrailAdapter.sandboxFloor: _Enforcement.notEnforceable,
  },
  ActionClass.networkEgress: {
    _GuardrailAdapter.harness: _Enforcement.policyGate,
    _GuardrailAdapter.claudeCli: _Enforcement.sandboxFloor,
    _GuardrailAdapter.mcpHttp: _Enforcement.notEnforceable,
    _GuardrailAdapter.sandboxFloor: _Enforcement.sandboxFloor,
  },
  ActionClass.secretAccess: {
    _GuardrailAdapter.harness: _Enforcement.policyGate,
    _GuardrailAdapter.claudeCli: _Enforcement.notEnforceable,
    _GuardrailAdapter.mcpHttp: _Enforcement.notEnforceable,
    _GuardrailAdapter.sandboxFloor: _Enforcement.notEnforceable,
  },
  ActionClass.packageInstall: {
    _GuardrailAdapter.harness: _Enforcement.policyGate,
    _GuardrailAdapter.claudeCli: _Enforcement.sandboxFloor,
    _GuardrailAdapter.mcpHttp: _Enforcement.policyGate,
    _GuardrailAdapter.sandboxFloor: _Enforcement.sandboxFloor,
  },
  ActionClass.processSpawn: {
    _GuardrailAdapter.harness: _Enforcement.policyGate,
    _GuardrailAdapter.claudeCli: _Enforcement.sandboxFloor,
    _GuardrailAdapter.mcpHttp: _Enforcement.notEnforceable,
    _GuardrailAdapter.sandboxFloor: _Enforcement.sandboxFloor,
  },
  ActionClass.workspaceMutation: {
    _GuardrailAdapter.harness: _Enforcement.policyGate,
    _GuardrailAdapter.claudeCli: _Enforcement.policyGate,
    _GuardrailAdapter.mcpHttp: _Enforcement.policyGate,
    _GuardrailAdapter.sandboxFloor: _Enforcement.notEnforceable,
  },
  // Rig tools are server-side MCP tools, so the gate is ours whatever runner
  // called them. The sandbox floor is honestly `notEnforceable`: the enclosure
  // is spawned by cc_server, not inside the agent's own sandbox, so an OS
  // sandbox around the agent has nothing to intercept.
  ActionClass.enclosureControl: {
    _GuardrailAdapter.harness: _Enforcement.policyGate,
    _GuardrailAdapter.claudeCli: _Enforcement.policyGate,
    _GuardrailAdapter.mcpHttp: _Enforcement.policyGate,
    _GuardrailAdapter.sandboxFloor: _Enforcement.notEnforceable,
  },
};

/// A read-only reference table (PRD 24 §4): per adapter, at which layer each
/// [ActionClass] is actually caught (or is not enforceable). Static, honest
/// documentation — NOT resolver output — so an operator knows where a decision
/// is a hard guarantee versus advisory.
class AdapterHonestyMatrixSection extends StatelessWidget {
  /// Creates an [AdapterHonestyMatrixSection].
  const AdapterHonestyMatrixSection({super.key});

  static const double _classColWidth = 210;
  static const double _adapterColWidth = 132;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();

    return SectionCard(
      label: l10n.guardrailAdapterMatrix,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              l10n.guardrailAdapterMatrixDescription,
              style: CcTypography.bodySm.copyWith(color: t.textTertiary),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildTable(l10n, t),
          ),
          const SizedBox(height: AppSpacing.md),
          const CcDivider(),
          const SizedBox(height: AppSpacing.md),
          _buildLegend(l10n, t),
        ],
      ),
    );
  }

  Widget _buildTable(AppLocalizations l10n, DesignSystemTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header.
        Row(
          children: [
            SizedBox(
              width: _classColWidth,
              child: Text(
                l10n.guardrailEffectColumn,
                style: CcTypography.label.copyWith(color: t.textSecondary),
              ),
            ),
            for (final a in _GuardrailAdapter.values)
              SizedBox(
                width: _adapterColWidth,
                child: Text(
                  _adapterLabel(l10n, a),
                  style: CcTypography.label.copyWith(color: t.textSecondary),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final cls in ActionClass.values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: _classColWidth,
                  child: Text(
                    guardrailClassLabel(l10n, cls),
                    style: CcTypography.bodySm.copyWith(color: t.textPrimary),
                  ),
                ),
                for (final a in _GuardrailAdapter.values)
                  SizedBox(
                    width: _adapterColWidth,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _enforcementTag(l10n, _matrix[cls]![a]!),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLegend(AppLocalizations l10n, DesignSystemTokens t) {
    Widget item(_Enforcement e, String help) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _enforcementTag(l10n, e),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              help,
              style: CcTypography.bodySm.copyWith(color: t.textTertiary),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        item(_Enforcement.policyGate, l10n.guardrailEnforcementPolicyGateHelp),
        item(_Enforcement.sandboxFloor, l10n.guardrailEnforcementSandboxHelp),
        item(_Enforcement.notEnforceable, l10n.guardrailEnforcementNoneHelp),
      ],
    );
  }

  Widget _enforcementTag(AppLocalizations l10n, _Enforcement e) =>
      CcStatusTag(label: _enforcementLabel(l10n, e), tone: _enforcementTone(e));

  String _adapterLabel(AppLocalizations l10n, _GuardrailAdapter a) =>
      switch (a) {
        _GuardrailAdapter.harness => l10n.guardrailAdapterHarness,
        _GuardrailAdapter.claudeCli => l10n.guardrailAdapterClaudeCli,
        _GuardrailAdapter.mcpHttp => l10n.guardrailAdapterMcpHttp,
        _GuardrailAdapter.sandboxFloor => l10n.guardrailAdapterSandbox,
      };

  String _enforcementLabel(AppLocalizations l10n, _Enforcement e) =>
      switch (e) {
        _Enforcement.policyGate => l10n.guardrailEnforcementPolicyGate,
        _Enforcement.sandboxFloor => l10n.guardrailEnforcementSandbox,
        _Enforcement.notEnforceable => l10n.guardrailEnforcementNone,
      };

  CcStatusTone _enforcementTone(_Enforcement e) => switch (e) {
    _Enforcement.policyGate => CcStatusTone.positive,
    _Enforcement.sandboxFloor => CcStatusTone.caution,
    _Enforcement.notEnforceable => CcStatusTone.negative,
  };
}
