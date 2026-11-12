import 'dart:convert';

import 'package:cc_domain/core/domain/ports/database_backup_port.dart';
import 'package:cc_domain/core/domain/ports/import_hold_review.dart';
import 'package:cc_harness/tools.dart' show ActionClass;
import 'package:control_center/features/settings/presentation/widgets/sections/system/guardrail_vocabulary.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/workspace/membership_formatting.dart';
import 'package:control_center/l10n/app_localizations.dart';

/// Names the client already knows, for the people and repositories a held
/// grant is about. Each returns null when it does not know the id; the
/// sentence then shows the raw id.
typedef ImportHoldNames = ({
  String? Function(String userId) person,
  String? Function(String repoId) repo,
});

/// What [hold] would grant to whom, in plain words.
///
/// Built from the held row's own columns, so it says exactly what accepting
/// applies. A kind this build does not know gets one generic sentence.
String importHoldSentence(
  AppLocalizations l10n,
  ImportHoldView hold,
  ImportHoldNames names,
) {
  String person(String? userId) {
    if (userId == null) {
      return '';
    }
    return names.person(userId) ?? userId;
  }

  return switch (hold.kind) {
    ImportHoldKind.actionPolicy => _policySentence(l10n, hold),
    ImportHoldKind.sandboxExecGrant => l10n.importHoldSandboxExec(
      hold.text('path') ?? '',
    ),
    ImportHoldKind.repoGrant => _repoSentence(
      l10n,
      person: person(hold.text('user_id')),
      repo: _repoName(hold.text('repo_id'), names),
      level: hold.text('level'),
    ),
    // The row itself names the member; a name the client knows is newer.
    ImportHoldKind.membershipRole => l10n.importHoldMemberRole(
      names.person(hold.text('user_id') ?? '') ??
          hold.text('display_name') ??
          hold.text('email') ??
          hold.text('user_id') ??
          '',
      workspaceRoleLabel(l10n, hold.text('role') ?? ''),
    ),
    ImportHoldKind.invite => _inviteSentence(l10n, hold),
    null => l10n.importHoldUnknown,
  };
}

/// Where an action-policy hold applies (the workspace, one space, one
/// agent), or null for any other kind.
String? importHoldScope(AppLocalizations l10n, ImportHoldView hold) {
  if (hold.kind != ImportHoldKind.actionPolicy) {
    return null;
  }
  final id = hold.text('scope_id') ?? '';
  return switch (hold.text('scope_type')) {
    'space' => l10n.importHoldScopeSpace(id),
    'agent' => l10n.importHoldScopeAgent(id),
    _ => l10n.importHoldScopeWorkspace,
  };
}

/// Whether accepting [hold] lets something run (an allow or prompt rule, a
/// sandbox exec grant): a security decision, confirmed once before it is
/// applied.
bool importHoldNeedsConfirmation(ImportHoldView hold) =>
    hold.kind == ImportHoldKind.actionPolicy ||
    hold.kind == ImportHoldKind.sandboxExecGrant;

String _policySentence(AppLocalizations l10n, ImportHoldView hold) {
  final classWire = hold.text('action_class');
  final cls = classWire == null ? null : ActionClass.fromWire(classWire);
  final action = cls != null
      ? guardrailClassLabel(l10n, cls)
      : classWire ?? l10n.importHoldCommand(hold.text('command_prefix') ?? '');
  // Only allow and prompt rules are held; anything but an explicit prompt
  // reads as the stronger grant, so nothing is undersold before an accept.
  return hold.text('decision') == 'prompt'
      ? l10n.importHoldPolicyPrompt(action)
      : l10n.importHoldPolicyAllow(action);
}

String _repoName(String? repoId, ImportHoldNames names) =>
    repoId == null ? '' : names.repo(repoId) ?? repoId;

String _repoSentence(
  AppLocalizations l10n, {
  required String person,
  required String repo,
  required String? level,
}) => switch (level) {
  'write' => l10n.importHoldRepoWrite(person, repo),
  'review' => l10n.importHoldRepoReview(person, repo),
  _ => l10n.importHoldRepoOther(person, repo, level ?? ''),
};

String _inviteSentence(AppLocalizations l10n, ImportHoldView hold) {
  final role = workspaceRoleLabel(l10n, hold.text('role') ?? '');
  final elevated = _reposAboveRead(hold.payload['repo_grants_json']);
  return elevated == 0
      ? l10n.importHoldInvite(role)
      : l10n.importHoldInviteWithRepos(elevated, role);
}

/// How many repositories an invite's grants give more than read access to.
/// A value this build cannot read counts as above read, as the server
/// counted it when it held the invite.
int _reposAboveRead(Object? json) {
  if (json is! String || json.isEmpty) {
    return 0;
  }
  try {
    final grants = jsonDecode(json);
    if (grants is! Map) {
      return 0;
    }
    return grants.values.where((level) => level != 'read').length;
  } on FormatException {
    return 0;
  }
}
