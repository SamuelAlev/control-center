part of 'credentials_screen.dart';

Widget _heading(DesignSystemTokens t, String title) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Text(
    title,
    style: TextStyle(
      color: t.textPrimary,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
  ),
);

Widget _loadError(
  BuildContext context,
  DesignSystemTokens t,
  AppLocalizations l,
  VoidCallback retry,
) => CcCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        l.credentialsLoadFailed,
        style: TextStyle(color: t.textErrorPrimary),
      ),
      const SizedBox(height: 8),
      CcButton(
        size: CcButtonSize.lg,
        variant: CcButtonVariant.secondary,
        onPressed: retry,
        child: Text(l.retry),
      ),
    ],
  ),
);
