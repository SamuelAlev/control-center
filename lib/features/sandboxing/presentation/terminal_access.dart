import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/core/domain/value_objects/forge_read_refusal.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/forge/presentation/repo_code_refusal.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// A refusal to start a terminal that the view words itself, instead of
/// showing the server's English sentence.
///
/// Only the server owner gets an unsandboxed shell on the server host;
/// everyone else's terminal is sandboxed and opens inside the workspace's own
/// directories, and a terminal in a space needs the person's own forge
/// sign-in to read its repositories. Any other spawn failure (the Linux
/// sandbox refusing its policy, a VM that cannot boot, a missing sign-in)
/// keeps the server's own message.
final class TerminalSpawnRefusal {
  const TerminalSpawnRefusal._(this._message, {this.retryable = false});

  final String Function(AppLocalizations l10n) _message;

  /// Whether asking again can succeed (the forge could not be asked).
  final bool retryable;

  /// The refusal [error] carries for a spawn that asked for
  /// [requestedBackend], or null for any other failure.
  ///
  /// `unauthorized` reads as the host shell being the owner's only when the
  /// host shell (`none`) was asked for; a coded refusal (the forge cannot
  /// read a repository in the space) is read by its `data.kind`.
  /// `validation` without a kind is the working directory lying outside the
  /// workspace's directories: the panel only asks for backends from its own
  /// menu, so confinement is the validation refusal it can meet.
  static TerminalSpawnRefusal? of(
    RemoteRpcException error, {
    String? requestedBackend,
  }) {
    final data = error.data;
    final kind = data is Map ? data['kind'] : null;
    switch (error.code) {
      case RpcErrorCodes.unauthorized:
        final repo = forgeReadRefusalFromRpc(code: error.code, data: data);
        if (repo != null || kind == repoReplacedKind) {
          return TerminalSpawnRefusal._(
            (l10n) => repoCodeRefusalMessage(l10n, error)!,
            retryable: repo?.reason == ForgeReadRefusal.unconfirmed,
          );
        }
        if (kind == null && requestedBackend == 'none') {
          return TerminalSpawnRefusal._(
            (l10n) => l10n.terminalHostShellOwnerOnly,
          );
        }
        return null;
      case RpcErrorCodes.validation when kind == null:
        return TerminalSpawnRefusal._((l10n) => l10n.terminalOutsideWorkspace);
      default:
        return null;
    }
  }

  /// The localized sentence for this refusal.
  String message(AppLocalizations l10n) => _message(l10n);
}

/// Whether a terminal reported as running under [backend] is sandboxed: any
/// named backend except the host shell. Null (a server that did not say) is
/// not claimed either way.
bool isSandboxedTerminalBackend(String? backend) =>
    backend != null && backend != 'none';

/// The quiet strip above a sandboxed terminal for someone who may not use the
/// host: says it is sandboxed, and in one line why some things are missing.
class TerminalSandboxNote extends StatelessWidget {
  /// Creates the note.
  const TerminalSandboxNote({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 6, 8, 0),
      child: Row(
        children: [
          CcBadge(label: l10n.terminalSandboxedBadge, icon: AppIcons.shield),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.terminalSandboxedHint,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: CcTypography.caption.copyWith(color: tokens.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}

/// The quiet strip above a terminal this person may only watch: someone
/// else's, which the server lets them read but not type into, resize or stop.
/// Shown once, in place, rather than as a refusal on every keystroke.
class TerminalReadOnlyNote extends StatelessWidget {
  /// Creates the note.
  const TerminalReadOnlyNote({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 6, 8, 0),
      child: Row(
        children: [
          CcBadge(label: l10n.terminalReadOnlyBadge, icon: AppIcons.eye),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.terminalReadOnlyHint,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: CcTypography.caption.copyWith(color: tokens.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}
