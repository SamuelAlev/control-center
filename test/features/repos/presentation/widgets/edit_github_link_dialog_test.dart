import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/repos/presentation/widgets/edit_github_link_dialog.dart';
import 'package:control_center/features/repos/presentation/widgets/repo_access_warnings_dialog.dart';
import 'package:control_center/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/test_wrap.dart';

/// A linked repository keeps its forge remote: the editor will not save a
/// cleared owner or name, and the server's refusal of one is worded by kind.
void main() {
  final repo = Repo(
    id: 'repo-1',
    name: 'acme/shop-ui',
    path: '/src/shop-ui',
    remoteOwner: 'acme',
    remoteName: 'shop-ui',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  CcButton save(WidgetTester tester) =>
      tester.widget<CcButton>(find.widgetWithText(CcButton, 'Save'));

  testWidgets('Save stays off until both owner and name are filled in', (
    tester,
  ) async {
    (String, String)? result;
    await tester.pumpWidget(
      testWrap(
        Builder(
          builder: (context) => GestureDetector(
            onTap: () async =>
                result = await showEditGitHubLinkDialog(context, repo: repo),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(save(tester).onPressed, isNotNull);

    final owner = find.byType(EditableText).first;
    await tester.enterText(owner, '  ');
    await tester.pump();
    expect(save(tester).onPressed, isNull);

    await tester.enterText(owner, 'acme-labs');
    await tester.pump();
    await tester.tap(find.widgetWithText(CcButton, 'Save'));
    await tester.pumpAndSettle();
    expect(result, ('acme-labs', 'shop-ui'));
  });

  test('a refused clear is worded by its kind', () {
    final l10n = AppLocalizationsEn();
    expect(
      describeRepoLinkError(
        l10n,
        RemoteRpcException(
          RpcErrorCodes.validation,
          'forge owner and name are required',
          {'kind': 'repo_link.forge_remote_required'},
        ),
      ),
      l10n.repoLinkForgeRemoteRequired,
    );
  });
}
