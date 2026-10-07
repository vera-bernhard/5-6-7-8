import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';

/// A button that shows who made the app, and with what.
class ImprintButton extends StatelessWidget {
  static const String author = 'Vera Bernhard';
  static const String repository = 'github.com/vera-bernhard/5-6-7-8';

  const ImprintButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextButton.icon(
      onPressed: () => showDialog<void>(
        context: context,
        builder: (context) => const _ImprintDialog(),
      ),
      icon: const Icon(Icons.info_outline, size: 18),
      label: Text(l10n.imprint),
    );
  }
}

/// Like Flutter's about dialog, but without its licenses button.
class _ImprintDialog extends StatelessWidget {
  const _ImprintDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return AlertDialog(
      scrollable: true,
      content: ListBody(
        children: [
          Row(
            children: [
              Image.asset(
                'assets/icon/5678_logo_square.png',
                width: 48,
                height: 48,
              ),
              const SizedBox(width: 24),
              Expanded(
                child: ListBody(
                  children: [
                    Text('5-6-7-8', style: theme.textTheme.headlineSmall),
                    Text('Beta', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.authorLine(ImprintButton.author)),
          const SizedBox(height: 8),
          Text(l10n.madeFor),
          const SizedBox(height: 8),
          Text(l10n.betaNotice),
          const SizedBox(height: 8),
          Wrap(
            children: [
              Text('${l10n.openSource}: '),
              InkWell(
                onTap: () => launchUrl(
                  Uri.https('github.com', '/vera-bernhard/5-6-7-8'),
                ),
                child: Text(
                  ImprintButton.repository,
                  style: TextStyle(
                    color: colors.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: colors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              text: '${l10n.builtWith} ',
              children: const [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: FlutterLogo(size: 16),
                ),
                TextSpan(text: ' Flutter'),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
