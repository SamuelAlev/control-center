import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_sign_in_notice.dart';
import 'package:control_center/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

/// A person's own review, merge or comment can find the repository replaced
/// on its forge; that reads in the app's words, by kind, on every forge.
void main() {
  final l10n = AppLocalizationsEn();

  String fallback(Object _) => 'fallback';

  test('repo_replaced names the forge', () {
    for (final (wire, name) in [('github', 'GitHub'), ('gitlab', 'GitLab')]) {
      expect(
        prErrorMessage(
          l10n,
          RemoteRpcException(
            RpcErrorCodes.unauthorized,
            'repository was replaced',
            {'kind': 'repo_replaced', 'forge': wire},
          ),
          fallback,
        ),
        l10n.repoCodeRepoReplacedOn(name),
      );
    }
  });

  test('repo_replaced without a forge keeps the unnamed copy', () {
    expect(
      prErrorMessage(
        l10n,
        RemoteRpcException(
          RpcErrorCodes.unauthorized,
          'repository was replaced',
          {'kind': 'repo_replaced'},
        ),
        fallback,
      ),
      l10n.repoCodeRepoReplaced,
    );
  });
}
