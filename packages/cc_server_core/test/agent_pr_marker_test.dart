import 'package:cc_server_core/src/pr_review/agent_pr_marker.dart';
import 'package:test/test.dart';

/// Every pull request an agent opens says so, and names who asked, exactly
/// once.
void main() {
  test('appends the marker naming the requester', () {
    expect(
      withAgentPullRequestMarker('Adds it.', requesterLogin: 'ada'),
      'Adds it.\n\n_Opened by a Control Center agent at the request of @ada._',
    );
  });

  test('a run nobody asked for names nobody', () {
    expect(
      withAgentPullRequestMarker('Adds it.'),
      'Adds it.\n\n_Opened by a Control Center agent._',
    );
    expect(
      withAgentPullRequestMarker('', requesterLogin: '  '),
      '_Opened by a Control Center agent._',
    );
  });

  test('any marker already in the body is replaced, never repeated', () {
    const body =
        'Adds it.\n\n'
        '> **opened by a Control Center agent at the request of @eve**\n'
        'More.\n\n'
        '_Opened by a Control Center agent._';
    final once = withAgentPullRequestMarker(body, requesterLogin: 'ada');
    expect(
      RegExp(
        'Opened by a Control Center agent',
        caseSensitive: false,
      ).allMatches(once),
      hasLength(1),
    );
    expect(once, endsWith('at the request of @ada._'));
    expect(once, isNot(contains('@eve')));
    expect(withAgentPullRequestMarker(once, requesterLogin: 'ada'), once);
  });

  test('an edit of a pull request an agent did not open says it edited '
      'it, replacing either marker', () {
    const opened =
        'Adds it.\n\n'
        '_Opened by a Control Center agent at the request of @eve._';
    expect(hasAgentOpenedMarker(opened), isTrue);
    expect(hasAgentOpenedMarker('Written by hand.'), isFalse);
    final edited = withAgentPullRequestMarker(
      opened,
      requesterLogin: 'ada',
      edited: true,
    );
    expect(
      edited,
      'Adds it.\n\n_Edited by a Control Center agent at the request of @ada._',
    );
    expect(hasAgentOpenedMarker(edited), isFalse);
    expect(
      withAgentPullRequestMarker(edited, requesterLogin: 'ada'),
      'Adds it.\n\n_Opened by a Control Center agent at the request of @ada._',
    );
  });
}
