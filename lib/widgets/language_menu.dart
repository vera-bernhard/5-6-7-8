import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/app_settings.dart';

/// Each language in its own language, so it can be found in any of them.
const Map<String, String> _languageNames = <String, String>{
  'en': 'English',
  'de': 'Deutsch',
};

/// A button with the language the app is shown in, that lets the user follow
/// the system language or pick one.
class LanguageMenuButton extends StatelessWidget {
  // The value of the system language entry. A null value would read as a
  // dismissed menu.
  static const String _system = '';

  const LanguageMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final chosen = AppSettings.locale.value?.languageCode ?? _system;
    final shown = Localizations.localeOf(context).languageCode;
    return PopupMenuButton<String>(
      tooltip: l10n.language,
      borderRadius: BorderRadius.circular(20),
      onSelected: (code) => AppSettings.setLocale(
        code == _system ? null : Locale(code),
      ),
      itemBuilder: (context) => [
        CheckedPopupMenuItem<String>(
          value: _system,
          checked: chosen == _system,
          child: Text(l10n.languageSystem),
        ),
        const PopupMenuDivider(),
        for (final locale in AppLocalizations.supportedLocales)
          CheckedPopupMenuItem<String>(
            value: locale.languageCode,
            checked: chosen == locale.languageCode,
            child: Text(
              _languageNames[locale.languageCode] ?? locale.languageCode,
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language, size: 18, color: colors.primary),
            const SizedBox(width: 8),
            Text(
              _languageNames[shown] ?? shown,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: colors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
