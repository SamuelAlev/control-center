import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/agent_account_pools_tab.dart'
    show AccountLane, accountLaneForAdapter;
import 'package:control_center/features/settings/providers/claude_account_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How many Claude Code logins the operator should be told about for the
/// runner [adapterId] names, or null when there is nothing worth saying.
///
/// A predicate rather than an early return inside the widget: the form's
/// `SettingsGroup` inserts its gap BEFORE each child, so a notice that renders
/// as a zero-size box still spends a full gap and leaves a visible double
/// space between the two fields it sits between. The caller has to be able to
/// omit it entirely.
///
/// [adapterId] is the LIVE selection, not the saved agent's, so the notice
/// lands on the same frame as the choice that caused it.
int? claudeAccountsWorthNoting(WidgetRef ref, String? adapterId) {
  if (accountLaneForAdapter(adapterId) != AccountLane.claudeCode) {
    return null;
  }
  final accounts = ref.watch(claudeAccountCountProvider);
  return accounts > 1 ? accounts : null;
}

/// Says which pool a Claude Code agent's login comes from, when there is more
/// than one login to come from.
///
/// Picking the Claude Code runner quietly decides something the form does not
/// otherwise show: with several logins on the host, WHICH one `claude -p` signs
/// in as is resolved by an account pool, not by anything on this screen. The
/// Accounts tab where that is set only appears under the same condition, so
/// without this the setting is reachable only by noticing a tab appear.
class ClaudeAccountsNotice extends StatelessWidget {
  /// Creates a [ClaudeAccountsNotice] for [accounts] logins.
  const ClaudeAccountsNotice({required this.accounts, super.key});

  /// How many Claude Code logins the host manages. Always more than one —
  /// [claudeAccountsWorthNoting] is what decides that.
  final int accounts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcAlert(
      title: l10n.agentClaudeAccountsNoticeTitle,
      icon: AppIcons.user,
      description: Text(
        l10n.agentClaudeAccountsNoticeBody(accounts),
        style: CcTypography.caption.copyWith(color: context.ds.textSecondary),
      ),
    );
  }
}
