import 'dart:async';

import 'package:cc_domain/features/settings/domain/entities/claude_sign_in_state.dart';
import 'package:control_center/features/settings/providers/claude_account_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How often an open sign-in surface asks whether its login finished.
const Duration claudeSignInPollInterval = Duration(seconds: 2);

/// Ids of the accounts a sign-in finished on since this started being watched.
///
/// `claude auth login` runs in a terminal, outside the app, so nothing tells a
/// client that it finished. A surface that handed out the command watches this
/// instead. Every [claudeSignInPollInterval] it asks the server whether an
/// account holds another usable credential than at the first reading, which is
/// a cheap read on the host (no CLI probe). Each time one does, the roster is
/// re-read, so every surface showing that account catches up, not only the one
/// that waited.
///
/// Nobody watching, nothing asked: the provider goes away with its last
/// listener, and its timer with it.
final claudeSignInsProvider =
    NotifierProvider.autoDispose<ClaudeSignInWatch, Set<String>>(
      ClaudeSignInWatch.new,
    );

/// Notifier behind [claudeSignInsProvider].
class ClaudeSignInWatch extends Notifier<Set<String>> {
  /// The first reading, which every later one is compared with.
  Map<String, ClaudeSignInState>? _before;

  /// Whether a reading is on its way, so a slow answer is not asked twice.
  bool _reading = false;

  @override
  Set<String> build() {
    final timer = Timer.periodic(claudeSignInPollInterval, (_) => _read());
    ref.onDispose(timer.cancel);
    // The first reading now, not a tick from now: a sign-in is only noticed
    // against a reading taken before it.
    scheduleMicrotask(_read);
    return const {};
  }

  Future<void> _read() async {
    if (_reading || !ref.mounted) {
      return;
    }
    _reading = true;
    try {
      final now = await ref
          .read(claudeAccountsRepositoryProvider)
          .signInStates();
      if (!ref.mounted) {
        return;
      }
      final before = _before ??= now;
      final signedIn = {
        ...state,
        for (final reading in now.values)
          if (reading.signedInSince(before[reading.accountId]))
            reading.accountId,
      };
      if (signedIn.length > state.length) {
        ref.invalidate(claudeAccountsProvider);
        state = signedIn;
      }
    } on Object {
      // One unanswered reading is not a verdict: the next tick asks again, and
      // closing the surface re-reads the roster either way.
    } finally {
      _reading = false;
    }
  }
}
