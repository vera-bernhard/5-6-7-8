// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get library => 'Bibliothek';

  @override
  String get player => 'Player';

  @override
  String get language => 'Sprache';

  @override
  String get languageSystem => 'Systemsprache';

  @override
  String get imprint => 'Impressum';

  @override
  String authorLine(String name) {
    return 'Entwicklerin: $name';
  }

  @override
  String get madeFor =>
      'Mit Herzblut entwickelt für Team Aerobic im TV Lenzburg. 5, 6, 7, 8 und los!';

  @override
  String get betaNotice =>
      'Beta-Version: Es kann noch Bugs und Änderungen geben.';

  @override
  String get openSource => 'Open Source';

  @override
  String get builtWith => 'Entwickelt mit';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get rename => 'Umbenennen';

  @override
  String get done => 'Fertig';

  @override
  String get close => 'Schließen';

  @override
  String get noSongsYet =>
      'Noch keine Songs. Lade unten deinen ersten Song hoch.';

  @override
  String get uploadSong => 'Song hochladen';

  @override
  String get preparingUpload => 'Upload wird vorbereitet...';

  @override
  String timestampCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zeitmarken',
      one: '1 Zeitmarke',
    );
    return '$_temp0';
  }

  @override
  String get audioPickerTimedOut =>
      'Die Dateiauswahl hat zu lange gedauert. Bitte versuche es erneut.';

  @override
  String get audioPickerFailed =>
      'Die Dateiauswahl ist fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String selectAudioFile(String extensions) {
    return 'Bitte wähle eine Audiodatei ($extensions).';
  }

  @override
  String get couldNotReadAudioFile =>
      'Die ausgewählte Audiodatei konnte nicht gelesen werden.';

  @override
  String get couldNotProcessFile =>
      'Die ausgewählte Datei konnte nicht verarbeitet werden.';

  @override
  String get nameSongTitle => 'Song benennen';

  @override
  String get displayNameLabel => 'Anzeigename';

  @override
  String get renameSongTitle => 'Song umbenennen';

  @override
  String get songNameLabel => 'Songname';

  @override
  String get deleteSongTitle => 'Song löschen?';

  @override
  String deleteSongMessage(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zeitmarken',
      one: '1 Zeitmarke',
    );
    return 'Möchtest du „$name“ mit $_temp0 wirklich löschen? Das kann nicht rückgängig gemacht werden.';
  }

  @override
  String get noSongSelected =>
      'Kein Song ausgewählt. Öffne die Bibliothek und wähle einen Song.';

  @override
  String couldNotLoadSong(String name) {
    return '„$name“ konnte nicht geladen werden.';
  }

  @override
  String get audioNotLoaded =>
      'Song ausgewählt, aber das Audio ist noch nicht geladen.';

  @override
  String get analyzing => 'Analyse läuft';

  @override
  String get leadIn => 'Vorlauf';

  @override
  String get leadOut => 'Nachlauf';

  @override
  String get startingIn => 'Start in';

  @override
  String get endingIn => 'Ende in';

  @override
  String get play => 'Abspielen';

  @override
  String get pause => 'Pause';

  @override
  String get stop => 'Stopp';

  @override
  String get saveTimestamp => 'Zeitmarke speichern';

  @override
  String speedTooltip(String speed) {
    return 'Tempo $speed';
  }

  @override
  String shuffleTooltip(int remaining, int total) {
    return 'Zufallswiedergabe ($remaining/$total übrig)';
  }

  @override
  String get noTimestampsYet => 'Noch keine Zeitmarken.';

  @override
  String timestampDefaultName(int number) {
    return 'Zeitmarke $number';
  }

  @override
  String get nameTimestampTitle => 'Zeitmarke benennen';

  @override
  String get timestampNameLabel => 'Name der Zeitmarke';

  @override
  String get timestampNameHint => 'z. B. Beginn Refrain';

  @override
  String get timeLabel => 'Zeit';

  @override
  String get timeHint => 'z. B. 1:23 oder 83,5';

  @override
  String get invalidTime =>
      'Ungültige Zeit. Verwende mm:ss oder Sekunden, z. B. 1:23 oder 83,5.';

  @override
  String get deleteTimestampTitle => 'Zeitmarke löschen?';

  @override
  String get deleteTimestampUnnamed =>
      'Diese Zeitmarke wird endgültig gelöscht.';

  @override
  String deleteTimestampNamed(String label) {
    return '„$label“ wird endgültig gelöscht.';
  }

  @override
  String get shuffleTitle => 'Zufallswiedergabe';

  @override
  String get shuffleNoSegments =>
      'Wähle zuerst Abschnitte für die Zufallswiedergabe aus.';

  @override
  String get shuffleAllPlayed =>
      'Alle ausgewählten Abschnitte wurden schon gespielt. Halte die Zufallstaste gedrückt, um neu zu beginnen.';

  @override
  String get playbackSpeedTitle => 'Wiedergabetempo';

  @override
  String get speedLabel => 'Tempo';

  @override
  String get bpmOverSong => 'BPM-Verlauf';

  @override
  String get showBpmOverSong => 'BPM-Verlauf anzeigen';

  @override
  String get noClearBeat => 'Kein klarer Beat gefunden.';

  @override
  String get bpmChartNote =>
      'Jede Sekunde über 8 s gemessen. Lücken: kein klarer Beat.';
}
