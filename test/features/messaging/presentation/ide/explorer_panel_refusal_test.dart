import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/infrastructure/provider_retry.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/explorer_panel.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, Scaffold;

import '../../../../helpers/fake_rpc_client.dart';

/// The Explorer's tree and searches word a refusal of the person's own forge
/// access by its code, and offer the sign-in a missing one needs, instead of
/// the generic "Couldn't load this folder".
void main() {
  late FakeRpcHost host;

  setUp(() {
    host = FakeRpcHost();
  });

  Widget wrap(Widget child, {TextDirection direction = TextDirection.ltr}) =>
      ProviderScope(
        retry: appProviderRetry,
        overrides: [rpcClientProvider.overrideWithValue(host.client())],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Directionality(
            textDirection: direction,
            child: CcTheme(
              data: CcThemeData.light(),
              child: Scaffold(body: child),
            ),
          ),
        ),
      );

  Future<void> pumpPanel(
    WidgetTester tester, {
    TextDirection direction = TextDirection.ltr,
  }) async {
    await tester.pumpWidget(
      wrap(
        const ExplorerPanel(workspaceId: 'ws', onOpenFile: _noopOpen),
        direction: direction,
      ),
    );
    await tester.pump();
    host.emit('workspace.watchReposForWorkspace', {
      'repos': [
        {
          'id': 'r1',
          'name': 'demo',
          'path': '/tmp/demo',
          'remote_owner': 'o',
          'remote_name': 'demo',
        },
      ],
    });
    await tester.pumpAndSettle();
  }

  RemoteRpcException refusal(Map<String, Object?> data) =>
      RemoteRpcException(RpcErrorCodes.unauthorized, 'refused', data);

  testWidgets('a tree load refused with forge_cannot_read reads as that', (
    tester,
  ) async {
    host.onCall = (op, args) {
      if (op == 'repos.listDirectory') {
        throw refusal({'kind': 'forge_cannot_read', 'forge': 'github'});
      }
      return const {};
    };

    await pumpPanel(tester);

    expect(
      find.text("Your GitHub account can't read this repository."),
      findsOneWidget,
    );
    expect(find.text("Couldn't load this folder"), findsNothing);
    // Retrying is still the action: there is nothing to sign in to.
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('a tree load refused with needs_sign_in offers the sign-in', (
    tester,
  ) async {
    var listed = 0;
    host.onCall = (op, args) {
      if (op == 'repos.listDirectory') {
        listed++;
        throw refusal({'kind': 'needs_sign_in', 'lane': 'github'});
      }
      return const {};
    };

    await pumpPanel(tester);

    expect(
      find.text("Sign in to GitHub to see this repository's code."),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsNothing);
    final before = listed;
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('GitHub sign-in needed'), findsOneWidget);
    // The tap opened the sign-in; it did not just list the folder again.
    expect(listed, before);
  });

  testWidgets('a later page refused keeps its entries and names the refusal', (
    tester,
  ) async {
    host.onCall = (op, args) {
      if (op == 'repos.listDirectory') {
        if ((args['cursor'] as String? ?? '').isEmpty) {
          return {
            'entries': [
              {'relativePath': 'a.txt', 'isDirectory': false},
            ],
            'has_more': true,
          };
        }
        throw refusal({'kind': 'forge_unconfirmed', 'forge': 'github'});
      }
      return const {};
    };

    await pumpPanel(tester);

    expect(find.text('a.txt'), findsOneWidget);
    expect(
      find.text("Couldn't confirm your GitHub access. Try again."),
      findsOneWidget,
    );
  });

  testWidgets('any other failure is still the folder failure', (tester) async {
    host.onCall = (op, args) {
      if (op == 'repos.listDirectory') {
        throw RemoteRpcException(RpcErrorCodes.validation, 'bad path');
      }
      return const {};
    };

    await pumpPanel(tester);

    expect(find.text("Couldn't load this folder"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('a refused tree row lays out right to left', (tester) async {
    host.onCall = (op, args) {
      if (op == 'repos.listDirectory') {
        throw refusal({'kind': 'needs_sign_in', 'lane': 'github'});
      }
      return const {};
    };

    await pumpPanel(tester, direction: TextDirection.rtl);

    final message = tester.getTopLeft(
      find.text("Sign in to GitHub to see this repository's code."),
    );
    final action = tester.getTopLeft(find.text('Sign in'));
    expect(action.dx, lessThan(message.dx));
  });
}

void _noopOpen(({String repoId, String path}) _) {}
