import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:control_center/l10n/app_localizations.dart';

/// Whether an RPC failure denotes lost authority rather than missing evidence.
bool isSkillCampaignDenied(Object? error) =>
    error is RemoteRpcException &&
    (error.code == RpcErrorCodes.unauthorized ||
        error.code == RpcErrorCodes.workspaceMismatch);

/// A denied read or mutation is not an empty campaign or an execution failure.
String skillCampaignError(AppLocalizations l, Object error) {
  if (isSkillCampaignDenied(error)) {
    return l.denied;
  }
  return l.skillEvalUnavailable(
    error is RemoteRpcException ? error.message : '$error',
  );
}
