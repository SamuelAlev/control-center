import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// A file the mock picker "returned".
class DemoPickedFile {
  /// Creates a picked entry.
  const DemoPickedFile({
    required this.name,
    required this.mimeType,
    required this.sizeBytes,
    this.imageBytes,
  });

  /// The filename shown on the chip.
  final String name;

  /// The media type recorded with the attachment.
  final String mimeType;

  /// The size the chip and the message metadata report.
  final int sizeBytes;

  /// Real bytes for the picture entry, so the chip's preview renders. They
  /// are never uploaded anywhere — a demo fakes the send too (see
  /// `SpaceMessageSendNotifier._storeAttachments`).
  final Uint8List? imageBytes;
}

/// The mock picker's fictional catalogue, themed to the demo's world.
const List<DemoPickedFile> kDemoPickerFiles = [
  DemoPickedFile(
    name: 'inspection-482-pine.pdf',
    mimeType: 'application/pdf',
    sizeBytes: 18_246_112,
  ),
  DemoPickedFile(
    name: 'disclosure-packet-1150-elm.pdf',
    mimeType: 'application/pdf',
    sizeBytes: 2_884_301,
  ),
  DemoPickedFile(
    name: 'listing-photos-482-pine.zip',
    mimeType: 'application/zip',
    sizeBytes: 64_118_977,
  ),
  DemoPickedFile(
    name: 'comparables-q3.xlsx',
    mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    sizeBytes: 91_204,
  ),
  DemoPickedFile(
    name: 'escrow-timeline.png',
    mimeType: 'image/png',
    sizeBytes: 135,
  ),
];

/// A 64×64 solid-colour PNG, embedded so the demo needs no asset read and no
/// disk write to show a picture preview.
final Uint8List kDemoPickerImageBytes = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAIAAAAlC+aJAAAATklEQVR42u3PQQkAAAgEsGti30ttBN/CYAWWaV+LgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgMBlAaDmMR5YOdA7AAAAAElFTkSuQmCC',
  ),
);

/// Shows the demo's mock file picker and returns what the visitor picked.
///
/// A public demo writes as little as possible to the host: a real picker
/// would read real bytes off the visitor's machine and upload them into the
/// workspace's blob store. This offers the demo world's fictional documents
/// instead, multi-select like the real one, and the send path records the
/// attachment by name without ever moving bytes.
Future<List<DemoPickedFile>> showDemoFilePicker(BuildContext context) async {
  final picked = await showCcDialog<Set<int>>(
    context: context,
    builder: (ctx) => const _DemoFilePickerDialog(),
  );
  if (picked == null || picked.isEmpty) {
    return const [];
  }
  return [
    for (final i in picked.toList()..sort())
      kDemoPickerFiles[i].name == 'escrow-timeline.png'
          ? DemoPickedFile(
              name: kDemoPickerFiles[i].name,
              mimeType: kDemoPickerFiles[i].mimeType,
              sizeBytes: kDemoPickerFiles[i].sizeBytes,
              imageBytes: kDemoPickerImageBytes,
            )
          : kDemoPickerFiles[i],
  ];
}

class _DemoFilePickerDialog extends StatefulWidget {
  const _DemoFilePickerDialog();

  @override
  State<_DemoFilePickerDialog> createState() => _DemoFilePickerDialogState();
}

class _DemoFilePickerDialogState extends State<_DemoFilePickerDialog> {
  final Set<int> _selected = {};

  static String _label(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem;
    final l10n = AppLocalizations.of(context);
    return CcDialog(
      title: l10n.demoFilePickerTitle,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.demoFilePickerBody,
              style: CcTypography.caption.copyWith(
                color: ds?.textTertiary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var i = 0; i < kDemoPickerFiles.length; i++)
                      _DemoFileRow(
                        file: kDemoPickerFiles[i],
                        selected: _selected.contains(i),
                        onTap: () => setState(() {
                          _selected.contains(i)
                              ? _selected.remove(i)
                              : _selected.add(i);
                        }),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).cancel),
        ),
        CcButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.of(context).pop(_selected.toSet()),
          child: Text(AppLocalizations.of(context).demoFilePickerAttach),
        ),
      ],
    );
  }
}

class _DemoFileRow extends StatelessWidget {
  const _DemoFileRow({
    required this.file,
    required this.selected,
    required this.onTap,
  });

  final DemoPickedFile file;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem;
    final size = _DemoFilePickerDialogState._label(file.sizeBytes);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: CcButton(
        variant: selected
            ? CcButtonVariant.secondary
            : CcButtonVariant.ghost,
        fullWidth: true,
        onPressed: onTap,
        child: Row(
          children: [
            Icon(
              selected ? AppIcons.check : AppIcons.file,
              size: 16,
              color: selected ? ds?.accent : ds?.fgTertiary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                file.name,
                overflow: TextOverflow.ellipsis,
                style: CcTypography.body.copyWith(color: ds?.textPrimary),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              size,
              style: CcTypography.caption.copyWith(color: ds?.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
