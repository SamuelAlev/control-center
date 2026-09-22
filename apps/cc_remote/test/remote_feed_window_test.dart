import 'package:cc_remote/feed_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loadMore grows one page and stops at the cap', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = remoteFeedWindowProvider('space');
    expect(container.read(provider), kRemoteFeedInitialWindow);
    container.read(provider.notifier).loadMore();
    expect(
      container.read(provider),
      kRemoteFeedInitialWindow + kRemoteFeedWindowStep,
    );
    while (container.read(provider) < kRemoteFeedMaxWindow) {
      container.read(provider.notifier).loadMore();
    }
    container.read(provider.notifier).loadMore();
    expect(container.read(provider), kRemoteFeedMaxWindow);
  });
}
