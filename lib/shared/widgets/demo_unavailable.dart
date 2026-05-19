import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Which capability a [DemoUnavailable] notice is standing in for.
///
/// Each case names a REASON, not just a missing feature: a visitor who is told
/// "the demo has no execution surface, which is what makes it safe to open in
/// public" learns something about the product. "Unavailable" on its own reads
/// like the demo is broken.
enum DemoCapability {
  /// Terminals — `terminal.*`, a real PTY on the host.
  terminal,

  /// Enclosures — `rig.*`, a disposable VM.
  rig,

  /// The in-browser editor — `codeServer.*` + `/proxy/vscode/*`.
  editor,

  /// Forge sign-in and stored credentials — `forge.*`, `oauth.*`,
  /// `credentials.*`, `providerApps.*`.
  forge,

  /// LLM provider credentials and model management — `providers.*`, `models.*`.
  models,

  /// The MCP tool surface — `mcp.*` and the `/mcp` + `/sse` routes.
  mcp,

  /// Repos, worktrees and anything git — `repos.*`, `worktree.*`, `fs.*`.
  repos,

  /// Skills install/scan — `skills.*`.
  skills,

  /// Single sign-on — `sso.*`, `scim.*`.
  sso,

  /// Audio capture: meeting recording and dictation.
  audio,

  /// Server administration — backup/export, pairing, membership.
  serverAdmin,
}

/// The honest notice a demo shows where a capability has been removed.
///
/// The demo does not disable these surfaces cosmetically — the RPC ops are
/// absent from the server's registry entirely, so a call returns `opUnknown`.
/// Without this the client renders whatever its generic failure path is: a red
/// error, an endless spinner or a blank panel, all of which read as "the demo
/// is broken" rather than "this is what a demo is".
///
/// Prefer checking `isDemoServerProvider` and rendering this INSTEAD of
/// attempting the call. A round trip that is known to fail is latency the
/// visitor pays to be told no.
class DemoUnavailable extends StatelessWidget {
  /// Creates a notice for [capability].
  const DemoUnavailable({required this.capability, super.key, this.compact = false});

  /// What is missing, and why.
  final DemoCapability capability;

  /// Tighter padding and no icon, for a notice inside a settings card rather
  /// than filling a panel.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.ds;
    final body = switch (capability) {
      DemoCapability.terminal => l10n.demoUnavailableTerminal,
      DemoCapability.rig => l10n.demoUnavailableRig,
      DemoCapability.editor => l10n.demoUnavailableEditor,
      DemoCapability.forge => l10n.demoUnavailableForge,
      DemoCapability.models => l10n.demoUnavailableModels,
      DemoCapability.mcp => l10n.demoUnavailableMcp,
      DemoCapability.repos => l10n.demoUnavailableRepos,
      DemoCapability.skills => l10n.demoUnavailableSkills,
      DemoCapability.sso => l10n.demoUnavailableSso,
      DemoCapability.audio => l10n.demoUnavailableAudio,
      DemoCapability.serverAdmin => l10n.demoUnavailableServerAdmin,
    };

    if (compact) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CcIcons.sparkles, size: 14, color: t.textTertiary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              body,
              style: CcTypography.caption.copyWith(
                color: t.textTertiary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CcIcons.sparkles, size: 24, color: t.fgQuaternary),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.demoUnavailableTitle,
                textAlign: TextAlign.center,
                style: CcTypography.body.copyWith(
                  color: t.textSecondary,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                body,
                textAlign: TextAlign.center,
                style: CcTypography.caption.copyWith(
                  color: t.textTertiary,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
