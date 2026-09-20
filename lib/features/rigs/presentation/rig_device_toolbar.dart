// Hardware chrome for Android / iOS Simulator rigs: rotate, home, screenshot.
//
// The same strip vocabulary as [RigBrowserToolbar] — a thin bar over the
// canvas, CcIconButton.sm — so a phone tab does not invent a second kind of
// chrome next to a browser tab. Closing the tab still shuts the machine down;
// these buttons are the device's own buttons.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_data/cc_data.dart' show RigView;
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/write_stream_to_file.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rotate / home / screenshot for a live Android or iOS rig.
class RigDeviceToolbar extends ConsumerStatefulWidget {
  /// Creates a [RigDeviceToolbar].
  const RigDeviceToolbar({
    super.key,
    required this.workspaceId,
    required this.rig,
  });

  /// The owning workspace.
  final String workspaceId;

  /// The device rig being driven.
  final RigView rig;

  @override
  ConsumerState<RigDeviceToolbar> createState() => _RigDeviceToolbarState();
}

class _RigDeviceToolbarState extends ConsumerState<RigDeviceToolbar> {
  bool _busy = false;

  bool get _canMutate =>
      widget.rig.controller == null || widget.rig.isHumanControlled;

  Map<String, dynamic> get _homeAction =>
      widget.rig.surfaceKind == RigSurface.ios
      ? const {'action': 'home'}
      : const {'action': 'key', 'key': 'home'};

  Future<
    ({String text, bool isError, String? imageBase64, String? imageMediaType})?
  >
  _act(Map<String, dynamic> action) async {
    if (_busy) {
      return null;
    }
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(rigRepositoryProvider)
          .act(
            workspaceId: widget.workspaceId,
            rigId: widget.rig.id,
            action: action,
          );
      if (result.isError && mounted) {
        CcToastScope.of(
          context,
        ).show(result.text, variant: CcToastVariant.danger);
      }
      return result;
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.of(context).show('$e', variant: CcToastVariant.danger);
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _rotate(String direction) async {
    await _act({'action': 'rotate', 'direction': direction});
  }

  Future<void> _home() async {
    await _act(_homeAction);
  }

  Future<void> _screenshot() async {
    final l10n = AppLocalizations.of(context);
    final result = await _act(const {
      'action': 'screenshot',
      'full_resolution': true,
    });
    if (!mounted || result == null || result.isError) {
      return;
    }
    final encoded = result.imageBase64;
    if (encoded == null || encoded.isEmpty) {
      CcToastScope.of(context).show(result.text);
      return;
    }
    final bytes = Uint8List.fromList(base64Decode(encoded));
    final png = (result.imageMediaType ?? 'image/png') == 'image/png';
    final suggested = 'simulator-screenshot.${png ? 'png' : 'jpg'}';
    try {
      if (kIsWeb) {
        await XFile.fromData(
          bytes,
          mimeType: result.imageMediaType ?? 'image/png',
          name: suggested,
        ).saveTo(suggested);
        if (mounted) {
          CcToastScope.of(
            context,
          ).show(l10n.rigScreenshotSaved, variant: CcToastVariant.success);
        }
        return;
      }
      final location = await getSaveLocation(
        suggestedName: suggested,
        acceptedTypeGroups: [
          XTypeGroup(
            label: png ? 'PNG' : 'JPEG',
            extensions: png ? const ['png'] : const ['jpg', 'jpeg'],
          ),
        ],
      );
      if (location == null || !mounted) {
        return;
      }
      await writeStreamToFile(Stream<List<int>>.value(bytes), location.path);
      if (mounted) {
        CcToastScope.of(
          context,
        ).show(l10n.rigScreenshotSaved, variant: CcToastVariant.success);
      }
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.of(context).show(
          l10n.rigScreenshotSaveFailed('$e'),
          variant: CcToastVariant.danger,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final mutate = _canMutate && !_busy;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
            color: t.bgSecondary,
            border: Border(bottom: BorderSide(color: t.lineStrong)),
          ),
          child: Row(
            children: [
              CcIconButton(
                icon: AppIcons.rotateCcw,
                size: CcButtonSize.sm,
                onPressed: mutate
                    ? () => unawaited(_rotate('counterclockwise'))
                    : null,
                tooltip: l10n.rigRotateCounterclockwise,
              ),
              CcIconButton(
                icon: AppIcons.rotateCw,
                size: CcButtonSize.sm,
                onPressed: mutate
                    ? () => unawaited(_rotate('clockwise'))
                    : null,
                tooltip: l10n.rigRotateClockwise,
              ),
              CcIconButton(
                icon: AppIcons.house,
                size: CcButtonSize.sm,
                onPressed: mutate ? () => unawaited(_home()) : null,
                tooltip: l10n.rigHomeButton,
              ),
              const Spacer(),
              CcIconButton(
                icon: AppIcons.image,
                size: CcButtonSize.sm,
                onPressed: _busy ? null : () => unawaited(_screenshot()),
                tooltip: l10n.rigTakeScreenshot,
              ),
            ],
          ),
        ),
        if (_busy)
          CcProgressBar(
            height: 2,
            color: t.accent,
            trackColor: const Color(0x00000000),
          ),
      ],
    );
  }
}
