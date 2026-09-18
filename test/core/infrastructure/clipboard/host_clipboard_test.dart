import 'dart:async';

import 'package:control_center/core/infrastructure/clipboard/host_clipboard.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_clipboard/super_clipboard.dart';

void main() {
  test(
    'clipboard text wins over its synthesized plain-text file flavor',
    () async {
      final reader = _TextAndVirtualFileReader('hello from the host');

      final clipboard = await snapshotFromReader([
        reader,
      ], includeVirtualFiles: false);

      expect(clipboard.text, 'hello from the host');
      expect(clipboard.files, isEmpty);
    },
  );

  test('drop readers still carry a real plain-text file', () async {
    final reader = _TextAndVirtualFileReader('file contents');

    final drop = await snapshotFromReader([reader]);

    expect(drop.text, isNull);
    expect(drop.files, hasLength(1));
    expect(drop.files.single.name, 'note.txt');
    expect(String.fromCharCodes(drop.files.single.bytes), 'file contents');
  });
}

class _TextAndVirtualFileReader implements DataReader {
  _TextAndVirtualFileReader(this.text);

  final String text;

  @override
  bool canProvide(DataFormat format) => getFormats([format]).isNotEmpty;

  @override
  List<DataFormat> getFormats(List<DataFormat> allFormats) => allFormats
      .where(
        (format) =>
            format == Formats.plainText || format == Formats.plainTextFile,
      )
      .toList();

  @override
  ReadProgress? getValue<T extends Object>(
    ValueFormat<T> format,
    AsyncValueChanged<T?> onValue, {
    ValueChanged<Object>? onError,
  }) {
    unawaited(Future<void>.sync(() => onValue(text as T)));
    return _CompleteReadProgress();
  }

  @override
  ReadProgress? getFile(
    FileFormat? format,
    AsyncValueChanged<DataReaderFile> onFile, {
    ValueChanged<Object>? onError,
    bool allowVirtualFiles = true,
    bool synthesizeFilesFromURIs = true,
  }) {
    if (format != Formats.plainTextFile) {
      return null;
    }
    unawaited(
      Future<void>.sync(
        () => onFile(
          _MemoryReaderFile('note.txt', Uint8List.fromList(text.codeUnits)),
        ),
      ),
    );
    return _CompleteReadProgress();
  }

  @override
  Future<String?> getSuggestedName() async => 'note.txt';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryReaderFile implements DataReaderFile {
  _MemoryReaderFile(this.fileName, this.bytes);

  @override
  final String fileName;
  final Uint8List bytes;

  @override
  int get fileSize => bytes.length;

  @override
  Future<Uint8List> readAll() async => bytes;

  @override
  Stream<Uint8List> getStream() => Stream.value(bytes);

  @override
  void close() {}
}

class _CompleteReadProgress implements ReadProgress {
  @override
  final ValueListenable<double?> fraction = ValueNotifier<double?>(1);

  @override
  final ValueListenable<bool> cancellable = ValueNotifier<bool>(false);

  @override
  void cancel() {}
}
