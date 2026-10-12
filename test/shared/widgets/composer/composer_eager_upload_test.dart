import 'dart:async';
import 'dart:convert';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/composer/attachments/attachment_strip.dart';
import 'package:control_center/shared/widgets/composer/attachments/composer_drop_target.dart';
import 'package:control_center/shared/widgets/composer/composer.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/composer_text_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_wrap.dart';

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

Finder _action(String tooltip) => find.byWidgetPredicate(
  (widget) => widget is CcIconButton && widget.tooltip == tooltip,
);

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
  late ComposerTextController controller;
  late List<Completer<UploadedAttachment>> transfers;
  late List<ComposerSubmission> submissions;
  late List<String> discarded;

  setUp(() {
    controller = ComposerTextController(text: 'Review this ');
    transfers = [];
    submissions = [];
    discarded = [];
  });

  tearDown(() {
    controller.dispose();
  });

  Future<void> pumpComposer(
    WidgetTester tester, {
    String scope = 'workspace-a',
    TextDirection textDirection = TextDirection.ltr,
    Future<void> Function(ComposerSubmission)? onSubmit,
    Future<UploadedAttachment> Function(ComposerAttachment)? upload,
  }) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await tester.pumpWidget(
      testWrap(
        Align(
          alignment: Alignment.bottomCenter,
          child: Composer(
            controller: controller,
            sources: const [],
            attachmentScope: scope,
            attachmentUpload:
                upload ??
                (attachment) {
                  final transfer = Completer<UploadedAttachment>();
                  transfers.add(transfer);
                  return transfer.future;
                },
            attachmentDiscard: (fileId) async => discarded.add(fileId),
            onSubmit:
                onSubmit ?? (submission) async => submissions.add(submission),
          ),
        ),
        textDirection: textDirection,
      ),
    );
    await tester.pump();
  }

  testWidgets('drop uploads while editing and blocks send until ready', (
    tester,
  ) async {
    await pumpComposer(tester);
    await _dropImage(tester);

    expect(transfers, hasLength(1));
    expect(submissions, isEmpty);
    expect(tester.widget<CcButton>(_send).onPressed, isNull);
    final draft = '${controller.text}without waiting for the upload';
    await tester.enterText(find.byType(EditableText), draft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(submissions, isEmpty);
    expect(controller.text, draft);

    transfers.single.complete(_uploaded('file-ready'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.widget<CcButton>(_send).onPressed, isNotNull);
    await tester.tap(_send);
    await tester.pump();

    expect(submissions, hasLength(1));
    expect(submissions.single.text, draft);
    expect(submissions.single.attachments.single.fileId, 'file-ready');
    expect(submissions.single.attachments.single.blobRef, _blobRef);
    expect(transfers, hasLength(1), reason: 'Send must not upload again.');
    expect(
      discarded,
      isEmpty,
      reason: 'A submitted file now belongs to the message.',
    );
  });

  testWidgets('failed upload stays in the draft and retry unlocks send', (
    tester,
  ) async {
    await pumpComposer(tester, textDirection: TextDirection.rtl);
    await _dropImage(tester);
    final draft = controller.text;
    transfers.single.completeError(StateError('Disconnected'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(controller.text, draft);
    expect(
      tester
          .widget<AttachmentStrip>(find.byType(AttachmentStrip))
          .attachments
          .single
          .uploadState,
      AttachmentUploadState.failed,
    );
    expect(tester.widget<CcButton>(_send).onPressed, isNull);
    await tester.tap(_action('Retry'));
    await tester.pump();
    expect(transfers, hasLength(2));
    expect(tester.widget<CcButton>(_send).onPressed, isNull);

    transfers.last.complete(_uploaded('file-retried'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(_send);
    await tester.pump();
    expect(submissions.single.attachments.single.fileId, 'file-retried');
    expect(discarded, isEmpty);
  });

  testWidgets('removing a pending upload cannot resurrect its attachment', (
    tester,
  ) async {
    await pumpComposer(tester);
    await _dropImage(tester);
    await tester.tap(_action('Remove'));
    await tester.pump();
    expect(find.byType(AttachmentStrip), findsNothing);
    expect(controller.text, isNot(contains('@[file:')));

    transfers.single.complete(_uploaded('file-removed'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(AttachmentStrip), findsNothing);
    expect(discarded, ['file-removed']);
    await tester.tap(_send);
    await tester.pump();
    expect(submissions.single.attachments, isEmpty);
  });

  testWidgets('removing a ready attachment releases its staged file', (
    tester,
  ) async {
    await pumpComposer(tester);
    await _dropImage(tester);
    transfers.single.complete(_uploaded('file-discarded'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(_action('Remove'));
    await tester.pump();
    expect(discarded, ['file-discarded']);
    expect(find.byType(AttachmentStrip), findsNothing);
    expect(submissions, isEmpty);
  });

  testWidgets('changing workspace does not adopt the previous upload', (
    tester,
  ) async {
    await pumpComposer(tester);
    await _dropImage(tester);
    await pumpComposer(tester, scope: 'workspace-b');
    transfers.single.complete(_uploaded('file-old-workspace'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(discarded, ['file-old-workspace']);
    expect(find.byType(AttachmentStrip), findsNothing);
    expect(controller.text, isNot(contains('@[file:')));
    expect(submissions, isEmpty);
  });

  testWidgets('a pending send cannot clear a new workspace draft', (
    tester,
  ) async {
    final sent = Completer<void>();
    await pumpComposer(tester, onSubmit: (_) => sent.future);
    controller.text = 'Review this';
    await tester.pump();
    await tester.tap(_send);
    await tester.pump();

    await pumpComposer(tester, scope: 'workspace-b');
    controller.text = 'Review this';
    sent.complete();
    await tester.pump();
    expect(controller.text, 'Review this');
  });

  testWidgets('retry uses the reconnected transport without losing the draft', (
    tester,
  ) async {
    await pumpComposer(
      tester,
      upload: (_) => Future.error(StateError('Old connection closed')),
    );
    await _dropImage(tester);
    final draft = controller.text;
    final reconnected = Completer<UploadedAttachment>();
    var newUploads = 0;
    await pumpComposer(
      tester,
      upload: (_) {
        newUploads++;
        return reconnected.future;
      },
    );
    await tester.tap(_action('Retry'));
    await tester.pump();
    expect(newUploads, 1);
    expect(controller.text, draft);
    reconnected.complete(_uploaded('file-reconnected'));
    await tester.pump();
    expect(tester.widget<CcButton>(_send).onPressed, isNotNull);
  });
}
