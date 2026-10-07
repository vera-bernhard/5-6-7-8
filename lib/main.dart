import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'screens/home.dart';
import 'services/app_settings.dart';
import 'services/song_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SongStorage.init();
  await AppSettings.init();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  final Widget home;

  const MyApp({super.key, this.home = const HomeScreen()});

  @override
  Widget build(BuildContext context) {
    const logoBlueDark = Color(0xFF0A3695);
    // Without a chosen language, MaterialApp follows the system language and
    // falls back to English.
    return ValueListenableBuilder<Locale?>(
      valueListenable: AppSettings.locale,
      builder: (context, locale, _) => MaterialApp(
        title: '5-6-7-8',
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          primaryColor: logoBlueDark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: logoBlueDark,
            primary: logoBlueDark,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: logoBlueDark,
            foregroundColor: Colors.white,
          ),
        ),
        home: home,
      ),
    );
  }
}
