import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/forge/providers/automation_token_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/failure_message.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asks an admin for a GitLab or Bitbucket automation token for [repoId]
/// (or, without one, for every [forge] repository in [workspaceId] without
/// a token of its own) and stores it. Resolves true once it is saved.
///
/// The server checks the token with the forge before keeping it: a personal
/// token, a refused one, or one that cannot read the repository is refused
/// and the reason shows here.
Future<bool> showAutomationTokenDialog(
  BuildContext context, {
  required String workspaceId,
  required ForgeHost forge,
  required String target,
  String? repoId,
}) async {
  final saved = await showCcDialog<bool>(
    context: context,
    builder: (_) => AutomationTokenDialog(
      workspaceId: workspaceId,
      forge: forge,
      target: target,
      repoId: repoId,
    ),
  );
  return saved ?? false;
}

/// The body of [showAutomationTokenDialog].
class AutomationTokenDialog extends ConsumerStatefulWidget {
  /// Creates an [AutomationTokenDialog].
  const AutomationTokenDialog({
    super.key,
    required this.workspaceId,
    required this.forge,
    required this.target,
    this.repoId,
  });

  /// The workspace the token belongs to.
  final String workspaceId;

  /// GitLab or Bitbucket.
  final ForgeHost forge;

  /// What the token is for, as shown (a repository's name, or the
  /// workspace-wide description).
  final String target;

  /// The repository, or null for the workspace's token.
  final String? repoId;

  @override
  ConsumerState<AutomationTokenDialog> createState() =>
      _AutomationTokenDialogState();
}

class _AutomationTokenDialogState extends ConsumerState<AutomationTokenDialog> {
  final _token = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final token = _token.text.trim();
    if (token.isEmpty || _saving) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final unreadable = await saveAutomationToken(
        ref,
        workspaceId: widget.workspaceId,
        forge: widget.forge,
        token: token,
        repoId: widget.repoId,
      );
      if (!mounted) {
        return;
      }
      if (unreadable.isNotEmpty) {
        CcToastScope.maybeOf(context)?.show(
          AppLocalizations.of(
            context,
          ).automationTokenUnreadable(unreadable.join(', ')),
          variant: CcToastVariant.warning,
        );
      }
      Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          // The server's refusal is already phrased for a person.
          _error = failureMessage(AppLocalizations.of(context), e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return CcDialog(
      title: l10n.automationTokenDialogTitle(widget.forge.displayName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.target,
            style: CcTypography.bodySm.copyWith(
              color: t.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            widget.forge == ForgeHost.gitlab
                ? l10n.automationTokenGitLabHint
                : l10n.automationTokenBitbucketHint,
            style: CcTypography.bodySm.copyWith(color: t.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          CcTextField(
            controller: _token,
            hintText: l10n.pasteValueHere,
            obscureText: true,
            autofocus: true,
            onSubmitted: (_) => unawaited(_save()),
          ),
          if (_error case final error?) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              error,
              style: CcTypography.caption.copyWith(color: t.textErrorPrimary),
            ),
          ],
        ],
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.ghost,
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        CcButton(
          loading: _saving,
          onPressed: _saving ? null : () => unawaited(_save()),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
