import 'package:cc_domain/cc_domain.dart' show UserDto;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/workspace/member_avatar.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';

/// One row of the audit log ledger: the actor's avatar and name, the op as a
/// [ActivityCodeToken], a [detail] line under them and a trailing timestamp.
/// Rows are separated by the caller's hairlines, not by this widget.
class ActivityLedgerRow extends StatelessWidget {
  /// Creates a row for [name] (resolved from [user] by the caller).
  const ActivityLedgerRow({
    super.key,
    required this.name,
    required this.user,
    required this.action,
    required this.detail,
    required this.createdAt,
  });

  /// The actor's display name, or the localized "unknown user".
  final String name;

  /// The actor, when this session can see them, for the avatar.
  final UserDto? user;

  /// The op name (`agents.upsert`), shown as machine truth.
  final String action;

  /// The second line: a description, outcome or network origin.
  final Widget detail;

  /// When it happened; no timestamp when unknown.
  final DateTime? createdAt;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final at = createdAt;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Optical top alignment: the name's 14/20 line box parks its glyphs
          // ~7px below the box top, so drop the avatar to the cap line rather
          // than aligning it to the (higher) box/chip edge.
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: MemberAvatar(name: name, user: user),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CcTypography.body.copyWith(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ActivityCodeToken(label: action),
                  ],
                ),
                const SizedBox(height: 2),
                detail,
              ],
            ),
          ),
          if (at != null) ...[
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: AppTimestamp.relative(
                at,
                style: CcFonts.code(
                  textStyle: CcTypography.monoNum.copyWith(
                    fontSize: 12,
                    color: t.textTertiary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A machine token (an op name like `agents.upsert`, an outcome like
/// `denied`): monospace, on a quiet surface chip, scannable without
/// pretending to be prose. [color] tints the text (an outcome's tone).
class ActivityCodeToken extends StatelessWidget {
  /// Creates a token showing [label].
  const ActivityCodeToken({super.key, required this.label, this.color});

  /// The token, verbatim.
  final String label;

  /// Text color; secondary text when null.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      color: t.bgTertiary,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        // RTL carve-out: an op name is a machine string read left to right.
        textDirection: TextDirection.ltr,
        style: CcFonts.code(
          textStyle: CcTypography.monoNum.copyWith(
            fontSize: 12,
            color: color ?? t.textSecondary,
          ),
        ),
      ),
    );
  }
}
