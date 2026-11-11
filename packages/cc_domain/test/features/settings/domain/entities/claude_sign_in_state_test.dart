import 'package:cc_domain/features/settings/domain/entities/claude_sign_in_state.dart';
import 'package:test/test.dart';

ClaudeSignInState _state({bool signedIn = true, DateTime? expiresAt}) =>
    ClaudeSignInState(
      accountId: 'work',
      signedIn: signedIn,
      credentialExpiresAt: expiresAt,
    );

void main() {
  final morning = DateTime.utc(2026, 11, 10, 5);
  final evening = DateTime.utc(2026, 11, 10, 21);

  group('signedInSince', () {
    test('a signed-out account that is now signed in', () {
      expect(
        _state(expiresAt: evening).signedInSince(_state(signedIn: false)),
        isTrue,
      );
      // A credential that states no expiry is still a sign-in.
      expect(_state().signedInSince(_state(signedIn: false)), isTrue);
    });

    test('a signed-in account that holds another credential now', () {
      expect(
        _state(expiresAt: evening).signedInSince(_state(expiresAt: morning)),
        isTrue,
      );
    });

    test('the same credential is not a sign-in, however often it is read', () {
      expect(
        _state(expiresAt: morning).signedInSince(_state(expiresAt: morning)),
        isFalse,
      );
      expect(_state().signedInSince(_state()), isFalse);
    });

    test('the same instant in another time zone is the same credential', () {
      expect(
        _state(
          expiresAt: morning.toLocal(),
        ).signedInSince(_state(expiresAt: morning)),
        isFalse,
      );
    });

    test('an account that is not signed in never finished one', () {
      expect(
        _state(signedIn: false).signedInSince(_state(signedIn: false)),
        isFalse,
      );
      // The credential changed, but a run still could not use it.
      expect(
        _state(
          signedIn: false,
          expiresAt: evening,
        ).signedInSince(_state(expiresAt: morning)),
        isFalse,
      );
    });

    test('an account that did not exist before counts once signed in', () {
      expect(_state().signedInSince(null), isTrue);
      expect(_state(signedIn: false).signedInSince(null), isFalse);
    });
  });

  group('wire shape', () {
    test('round-trips, with the instant in UTC', () {
      final state = _state(expiresAt: evening);

      expect(state.toJson(), {
        'id': 'work',
        'signed_in': true,
        'credential_expires_at': '2026-11-10T21:00:00.000Z',
      });
      expect(ClaudeSignInState.fromJson(state.toJson()), state);
    });

    test('a local instant is sent as the same moment in UTC', () {
      final sent = _state(expiresAt: evening.toLocal()).toJson();

      expect(sent['credential_expires_at'], '2026-11-10T21:00:00.000Z');
    });

    test('omits an expiry the credential does not state', () {
      expect(_state(signedIn: false).toJson(), {
        'id': 'work',
        'signed_in': false,
      });
      expect(
        ClaudeSignInState.fromJson(const {'id': 'work'}),
        _state(signedIn: false),
      );
    });
  });
}
