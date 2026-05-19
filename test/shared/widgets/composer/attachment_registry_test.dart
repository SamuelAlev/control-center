import 'package:control_center/shared/widgets/composer/attachments/attachment_registry.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ComposerAttachment _entry(String id, {int bytes = 0}) => ComposerAttachment(
  id: id,
  kind: bytes > 0 ? 'image' : 'file',
  label: '$id.png',
  bytes: bytes > 0 ? List<int>.filled(bytes, 0) : null,
);

void main() {
  late ProviderContainer container;
  late AttachmentRegistry registry;

  setUp(() {
    container = ProviderContainer();
    registry = container.read(attachmentRegistryProvider.notifier);
  });

  tearDown(() => container.dispose());

  test('registers and resolves by id', () {
    registry.register([_entry('a'), _entry('b')]);
    expect(registry.resolve('a')?.label, 'a.png');
    expect(registry.resolve('missing'), isNull);
  });

  test('unregister drops the entry', () {
    registry
      ..register([_entry('a')])
      ..unregister('a');
    expect(registry.resolve('a'), isNull);
  });

  test('evicts the oldest past the entry ceiling', () {
    for (var i = 0; i < kAttachmentRegistryMaxEntries + 5; i++) {
      registry.register([_entry('e$i')]);
    }
    expect(
      container.read(attachmentRegistryProvider).length,
      kAttachmentRegistryMaxEntries,
    );
    // The first ones registered are the ones gone.
    expect(registry.resolve('e0'), isNull);
    expect(
      registry.resolve('e${kAttachmentRegistryMaxEntries + 4}'),
      isNotNull,
    );
  });

  // Bytes are the reason this registry is bounded at all: without a size
  // ceiling a session that drags a dozen screenshots through a conversation
  // pins every one of them for as long as the app runs.
  test('evicts past the byte ceiling even when the count is small', () {
    const big = 20 * 1024 * 1024;
    registry
      ..register([_entry('one', bytes: big)])
      ..register([_entry('two', bytes: big)])
      ..register([_entry('three', bytes: big)])
      ..register([_entry('four', bytes: big)]);

    final held = container.read(attachmentRegistryProvider);
    var total = 0;
    for (final entry in held.values) {
      total += entry.bytes?.length ?? 0;
    }
    expect(total, lessThanOrEqualTo(kAttachmentRegistryMaxBytes));
    expect(registry.resolve('four'), isNotNull);
    expect(registry.resolve('one'), isNull);
  });

  // Re-registering is a REFRESH (a mime type resolved, a size learned), not a
  // fresher attachment — promoting it would let a repeatedly-touched entry
  // outlive newer ones.
  test('re-registering refreshes in place without promoting', () {
    registry
      ..register([_entry('a')])
      ..register([_entry('b')])
      ..register([_entry('a').copyWith(mimeType: 'image/png')]);
    expect(container.read(attachmentRegistryProvider).keys.toList(), [
      'a',
      'b',
    ]);
    expect(registry.resolve('a')?.mimeType, 'image/png');
  });
}
