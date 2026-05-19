import 'package:cc_data/cc_data.dart' show SyncedStore;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';

/// Runs a mutation with an app-wide optimistic overlay (PRD 19 §6): the change
/// reflects instantly via the PRD 16 [SyncedStore], then reconciles — ack on
/// success, revert on failure. Immediacy never trades against truth (adversarial
/// review): a rejected optimistic write reverts AND surfaces loudly, never
/// silently, so the operator never believes work happened that didn't.
///
/// [store] may be null (the sync kill-switch is off / the store demoted): then
/// there is no overlay and this is just [mutate] with the same loud-failure
/// contract. Returns true when the mutation applied.
Future<bool> runOptimistic({
  required SyncedStore? store,
  required String table,
  required String pk,
  required Map<String, dynamic> overlay,
  required Future<void> Function() mutate,
  void Function(Object error)? onError,
}) async {
  final handle = store?.applyOptimistic(table, pk, overlay);
  try {
    await mutate();
    handle?.ack();
    return true;
  } catch (e) {
    handle?.fail();
    onError?.call(e);
    return false;
  }
}

/// Surfaces an optimistic-mutation failure as a loud danger toast on the root
/// overlay (which sits under the app's [CcToastScope]). Safe to call from a
/// provider/callback with no local context.
void surfaceOptimisticFailure(Object error) {
  final ctx = rootNavigatorKey.currentContext;
  if (ctx == null) {
    return;
  }
  final toaster = CcToastScope.maybeOf(ctx);
  toaster?.show(
    AppLocalizations.of(ctx).optimisticChangeReverted,
    variant: CcToastVariant.danger,
  );
}
