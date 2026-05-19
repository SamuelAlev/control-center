import 'package:cc_data/cc_data.dart' show RpcAccountPoolsRepository;
import 'package:cc_harness/provider.dart';
import 'package:control_center/features/settings/presentation/widgets/account_pool_editor.dart';
import 'package:control_center/features/settings/providers/account_pool_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// The rotation control for one harness provider's stored credentials.
///
/// The same editor the Claude Code adapter uses, because the decision is the
/// same one — which keys may be spent, in what order, and whether to drain them
/// or spread across them. What differs is only the mechanism underneath: here
/// the fallback chain swaps credential mid-stream, so the pool decides which
/// one LEADS rather than which one runs alone.
class HarnessRotationEditor extends StatelessWidget {
  /// Creates a [HarnessRotationEditor].
  const HarnessRotationEditor({required this.info, super.key});

  /// The provider whose credentials are being ordered.
  final HarnessProviderInfo info;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AccountPoolEditor(
      scope: AccountPoolScope(
        lane: RpcAccountPoolsRepository.harnessLane(info.id),
      ),
      candidates: [
        for (final cred in info.credentials)
          AccountPoolCandidate(
            id: cred.credentialId,
            // A key has no name, only a masked tail — which is still the only
            // thing that tells two of them apart.
            label: cred.label?.isNotEmpty ?? false
                ? cred.label!
                : cred.hint ?? cred.credentialId,
            detail: cred.method == HarnessAuthMethod.oauth
                ? l10n.providerSignedInAccount
                : cred.hint,
          ),
      ],
    );
  }
}
