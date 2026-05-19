import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'features/pr_review/data/repositories/mock_spec.mocks.dart';

void main() {
  test('mockito when', () {
    final apiClient = MockGitHubApiClient();
    final mockPr = MockGitHubPrClient();
    when(apiClient.pr).thenReturn(mockPr);
    print('OK');
  });
}
