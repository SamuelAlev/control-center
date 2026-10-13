import 'dart:async';
import 'dart:convert';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/providers/space_composer_draft_provider.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/composer/attachments/attachment_strip.dart';
import 'package:control_center/shared/widgets/composer/attachments/composer_drop_target.dart';
import 'package:control_center/shared/widgets/composer/composer.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_popup.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_source.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_wrap.dart';

const _destination = (
  workspaceId: 'workspace-a',
  spaceId: 'space-a',
  conversationId: 'conversation-a',
);
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
);
const _blobRef =
    'blob:sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

UploadedAttachment _uploaded(String id) => UploadedAttachment(
  fileId: id,
  blobRef: _blobRef,
  bytes: _png.length,
  mediaType: 'image/png',
);

class _TicketSource extends MentionSource {
  @override
  String get kind => 'ticket';

  @override
  Set<MentionTrigger> get triggers => {MentionTrigger.hash};

  @override
  Stream<List<MentionSuggestion>> suggest(MentionQuery query) => Stream.value([
    const MentionSuggestion(
      id: 'ticket:123',
      kind: 'ticket',
      label: 'CC-123',
      replacement: '#CC-123 ',
      payload: {'ticketId': '123'},
    ),
  ]);
}

String _text(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText)).controller.text;

Finder get _send => find.ancestor(
  of: find.byIcon(AppIcons.arrowUp),
  matching: find.byType(CcButton),
);

Future<void> _dropImage(WidgetTester tester) async {
  final at = tester.getCenter(find.byType(ComposerDropTarget));
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'com.controlcenter/filedrop',
    const StandardMethodCodec().encodeMethodCall(
      MethodCall('drop', {
        'viewId': tester.view.viewId,
        'x': at.dx,
        'y': at.dy,
        'paths': const <String>[],
        'images': [_png],
      }),
    ),
    (_) {},
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  late ValueNotifier<SpaceComposerDraftKey?> destination;
  late List<Completer<UploadedAttachment>> transfers;
  late List<ComposerSubmission> submissions;
  late List<String> discarded;

  setUp(() {
    destination = ValueNotifier(_destination);
    transfers = [];
    submissions = [];
    discarded = [];
  });

  tearDown(() {
    destination.dispose();
  });

  Future<void> mount(
    WidgetTester tester, {
    Future<void> Function(ComposerSubmission)? onSubmit,
  }) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await tester.pumpWidget(
      testWrap(
        ValueListenableBuilder(
          valueListenable: destination,
          builder: (context, target, _) => target == null
              ? const SizedBox.shrink()
              : Consumer(
                  builder: (context, ref, _) => Align(
                    alignment: Alignment.bottomCenter,
                    child: Composer(
                      draft: ref.watch(spaceComposerDraftProvider(target)),
                      sources: [_TicketSource()],
                      attachmentScope:
                          '${target.workspaceId}/${target.spaceId}/${target.conversationId}',
                      attachmentUpload: (_) {
                        final transfer = Completer<UploadedAttachment>();
                        transfers.add(transfer);
                        return transfer.future;
                      },
                      attachmentDiscard: (fileId) async =>
                          discarded.add(fileId),
                      onSubmit:
                          onSubmit ??
                          (submission) async => submissions.add(submission),
                    ),
                  ),
                ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> navigate(
    WidgetTester tester,
    SpaceComposerDraftKey? target,
  ) async {
    destination.value = target;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets(
    'navigation restores text and uploaded files only in their target',
    (tester) async {
      await mount(tester);
      await tester.enterText(find.byType(EditableText), 'Review this image ');
      await _dropImage(tester);
      transfers.single.complete(_uploaded('uploaded-once'));
      await tester.pump();
      final original = _text(tester);

      for (final other in [
        (
          workspaceId: 'workspace-a',
          spaceId: 'space-a',
          conversationId: 'conversation-b',
        ),
        (
          workspaceId: 'workspace-a',
          spaceId: 'space-b',
          conversationId: 'conversation-a',
        ),
        (
          workspaceId: 'workspace-b',
          spaceId: 'space-a',
          conversationId: 'conversation-a',
        ),
      ]) {
        await navigate(tester, other);
        expect(_text(tester), isEmpty);
        expect(find.byType(AttachmentStrip), findsNothing);
        await tester.enterText(find.byType(EditableText), 'A different draft');
        await navigate(tester, _destination);
        expect(_text(tester), original);
        expect(
          tester
              .widget<AttachmentStrip>(find.byType(AttachmentStrip))
              .attachments
              .single
              .fileId,
          'uploaded-once',
        );
      }

      await navigate(tester, null);
      expect(discarded, isEmpty);
      await navigate(tester, _destination);
      expect(_text(tester), original);
      await tester.tap(_send);
      await tester.pump();
      expect(submissions.single.text, original);
      expect(submissions.single.attachments.single.fileId, 'uploaded-once');
      expect(submissions.single.attachments.single.blobRef, _blobRef);
      expect(transfers, hasLength(1));
      expect(discarded, isEmpty);

      await navigate(tester, null);
      await navigate(tester, _destination);
      expect(_text(tester), isEmpty);
      expect(find.byType(AttachmentStrip), findsNothing);
    },
  );

  testWidgets(
    'upload completes offscreen and removal still discards the file',
    (tester) async {
      await mount(tester);
      await _dropImage(tester);
      final original = _text(tester);
      await navigate(tester, null);
      transfers.single.complete(_uploaded('completed-offscreen'));
      await tester.pump();
      expect(discarded, isEmpty);

      await navigate(tester, _destination);
      expect(_text(tester), original);
      expect(tester.widget<CcButton>(_send).onPressed, isNotNull);
      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is CcIconButton && widget.tooltip == 'Remove',
        ),
      );
      await tester.pump();
      expect(discarded, ['completed-offscreen']);
      await navigate(tester, null);
      await navigate(tester, _destination);
      expect(find.byType(AttachmentStrip), findsNothing);
      expect(_text(tester), isNot(contains('@[file:')));
    },
  );

  testWidgets('an offscreen upload failure retains retryable content', (
    tester,
  ) async {
    await mount(tester);
    await tester.enterText(find.byType(EditableText), 'Keep this context ');
    await _dropImage(tester);
    final original = _text(tester);
    await navigate(tester, null);
    transfers.single.completeError(StateError('Disconnected'));
    await tester.pump();
    await navigate(tester, _destination);
    expect(_text(tester), original);
    expect(tester.widget<CcButton>(_send).onPressed, isNull);
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is CcIconButton && widget.tooltip == 'Retry',
      ),
    );
    await tester.pump();
    transfers.last.complete(_uploaded('retried-after-return'));
    await tester.pump();
    await tester.tap(_send);
    await tester.pump();
    expect(
      submissions.single.attachments.single.fileId,
      'retried-after-return',
    );
    expect(discarded, isEmpty);
  });

  testWidgets('a send finishing offscreen clears only its submitted draft', (
    tester,
  ) async {
    final sent = Completer<void>();
    await mount(
      tester,
      onSubmit: (submission) {
        submissions.add(submission);
        return sent.future;
      },
    );
    await tester.enterText(find.byType(EditableText), 'Send this draft');
    await _dropImage(tester);
    transfers.single.complete(_uploaded('sent-offscreen'));
    await tester.pump();
    await tester.tap(_send);
    await tester.pump();
    await navigate(tester, null);
    const other = (
      workspaceId: 'workspace-b',
      spaceId: 'space-a',
      conversationId: 'conversation-a',
    );
    await navigate(tester, other);
    await tester.enterText(find.byType(EditableText), 'Do not clear this');
    sent.complete();
    await tester.pump();
    expect(_text(tester), 'Do not clear this');
    await navigate(tester, _destination);
    expect(_text(tester), isEmpty);
    expect(find.byType(AttachmentStrip), findsNothing);
    expect(discarded, isEmpty);
    expect(submissions.single.attachments.single.fileId, 'sent-offscreen');
  });

  testWidgets('entity mention identity survives composer remount', (
    tester,
  ) async {
    await mount(tester);
    await tester.enterText(find.byType(EditableText), 'Investigate #CC');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(
      find.descendant(
        of: find.byType(MentionPopup),
        matching: find.text('CC-123'),
      ),
    );
    await tester.pump();
    final original = _text(tester);
    await navigate(tester, null);
    await navigate(tester, _destination);
    expect(_text(tester), original);
    await tester.tap(_send);
    await tester.pump();
    expect(
      submissions.single.mentions
          .singleWhere((m) => m.kind == 'ticket')
          .payload,
      {'ticketId': '123'},
    );
  });
}
