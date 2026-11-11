import 'dart:async';

import 'package:cc_data/cc_data.dart' show RpcClaudeAccountsRepository;
import 'package:cc_domain/features/settings/domain/entities/claude_account.dart';
import 'package:cc_domain/features/settings/domain/entities/claude_sign_in_state.dart';

/// The host's Claude Code accounts as a test scripts them: the roster, the
/// sign-in state behind it, and whether this caller is handed login commands.
///
/// The roster and the sign-in states are two reads of the same [accounts], as
/// on the host, so a test finishes a login once ([signIn]) and both agree.
class FakeClaudeAccountsRepository implements RpcClaudeAccountsRepository {
  /// Creates the fake over [accounts].
  FakeClaudeAccountsRepository({
    List<ClaudeAccount> accounts = const [],
    this.handsOutCommands = true,
  }) : accounts = [...accounts];

  /// The registered accounts, as the host would report them right now.
  List<ClaudeAccount> accounts;

  /// Whether the caller is the server owner: handed login commands and
  /// answered about sign-in states. Anyone else is refused both.
  bool handsOutCommands;

  /// When set, a roster read waits for it. Lets a test look at a surface
  /// while the roster is still on its way.
  Completer<void>? rosterGate;

  /// When set, a sign-in state read waits for it.
  Completer<void>? stateGate;

  /// When set, a sign-in state read fails with it.
  Object? stateFailure;

  /// How often the roster was read (each read starts the CLI on the host).
  int rosterReads = 0;

  /// How often the sign-in states were asked for.
  int stateReads = 0;

  /// Finishes `claude auth login` on [id]: a newer credential, signed in.
  void signIn(String id, {DateTime? expiresAt}) {
    accounts = [
      for (final a in accounts)
        if (a.id == id)
          a.copyWith(
            loggedIn: true,
            clearAuthFailure: true,
            credentialExpiresAt: expiresAt ?? DateTime.utc(2100),
          )
        else
          a,
    ];
  }

  @override
  Future<List<ClaudeAccountView>> list() async {
    rosterReads++;
    await rosterGate?.future;
    return [for (final a in accounts) ClaudeAccountView(account: a)];
  }

  @override
  Future<Map<String, ClaudeSignInState>> signInStates() async {
    stateReads++;
    await stateGate?.future;
    final failure = stateFailure;
    if (failure != null) {
      throw failure;
    }
    if (!handsOutCommands) {
      throw StateError('refused: server owner only');
    }
    return {
      for (final a in accounts)
        a.id: ClaudeSignInState(
          accountId: a.id,
          signedIn: a.loggedIn && a.authFailedAt == null,
          credentialExpiresAt: a.credentialExpiresAt,
        ),
    };
  }

  @override
  Future<({List<String> argv, Map<String, String> environment})?> loginCommand(
    String id, {
    String? email,
    bool console = false,
  }) async {
    if (!handsOutCommands) {
      throw StateError('refused: server owner only');
    }
    return (
      argv: const ['claude', 'auth', 'login'],
      environment: {'CLAUDE_CONFIG_DIR': '/data/claude accounts/$id'},
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}
