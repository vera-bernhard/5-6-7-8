import 'package:five_six_seven_eight/l10n/app_localizations.dart';
import 'package:five_six_seven_eight/main.dart';
import 'package:five_six_seven_eight/services/app_settings.dart';
import 'package:five_six_seven_eight/widgets/imprint_button.dart';
import 'package:five_six_seven_eight/widgets/language_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The app with a page that shows one translated word, the language menu and
/// the imprint.
Widget app() => MyApp(
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            actions: const [LanguageMenuButton(), ImprintButton()],
          ),
          body: Text(AppLocalizations.of(context).library),
        ),
      ),
    );

void setSystemLocales(WidgetTester tester, List<Locale> locales) {
  tester.platformDispatcher.localesTestValue = locales;
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
}

Future<void> chooseLanguage(WidgetTester tester, String name) async {
  await tester.tap(find.byType(LanguageMenuButton));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(CheckedPopupMenuItem<String>, name));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => AppSettings.locale.value = null);

  testWidgets('follows a German system language', (tester) async {
    setSystemLocales(tester, const [Locale('de', 'CH')]);
    await tester.pumpWidget(app());
    expect(find.text('Bibliothek'), findsOneWidget);
  });

  testWidgets('uses the first system language the app has', (tester) async {
    setSystemLocales(tester, const [Locale('fr', 'FR'), Locale('de', 'DE')]);
    await tester.pumpWidget(app());
    expect(find.text('Bibliothek'), findsOneWidget);
  });

  testWidgets('falls back to English for other system languages',
      (tester) async {
    setSystemLocales(tester, const [Locale('fr', 'FR')]);
    await tester.pumpWidget(app());
    expect(find.text('Library'), findsOneWidget);
  });

  testWidgets('a chosen language overrides the system language',
      (tester) async {
    setSystemLocales(tester, const [Locale('en', 'US')]);
    await tester.pumpWidget(app());

    await chooseLanguage(tester, 'Deutsch');
    expect(find.text('Bibliothek'), findsOneWidget);
    expect(AppSettings.locale.value, const Locale('de'));

    await chooseLanguage(tester, 'Systemsprache');
    expect(find.text('Library'), findsOneWidget);
    expect(AppSettings.locale.value, isNull);
  });

  testWidgets('the imprint names the developer', (tester) async {
    setSystemLocales(tester, const [Locale('en', 'US')]);
    await tester.pumpWidget(app());
    await tester.tap(find.byType(ImprintButton));
    await tester.pumpAndSettle();
    expect(find.text('Developer: Vera Bernhard'), findsOneWidget);
    expect(find.text('github.com/vera-bernhard/5-6-7-8'), findsOneWidget);
    expect(find.textContaining('Built with'), findsOneWidget);
    expect(find.byType(FlutterLogo), findsOneWidget);
    expect(find.text('View licenses'), findsNothing);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await chooseLanguage(tester, 'Deutsch');
    await tester.tap(find.text('Impressum'));
    await tester.pumpAndSettle();
    expect(find.text('Entwicklerin: Vera Bernhard'), findsOneWidget);
  });
}
